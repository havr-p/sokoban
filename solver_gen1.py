import clingo
import argparse

def generate_sokoban_lp_from_map(map_str, max_steps: int = 20):
    """
    Принимает карту Sokoban в виде строк (с символами #, S, C, X, s, c),
    и возвращает строку с фактами ASP (в формате .lp)
    """
    lines = map_str.splitlines()
    # Удалим пустые строчки и ведущие/хвостовые пробелы
    lines = [ln.strip() for ln in lines if ln.strip() != ""]

    def cell_name(r, c):
        # Генерируем имя клетки как pos_{column+1}_{row+1}
        return f"pos_{c+1}_{r+1}"

    facts = []
    
    # Фиксированные имена объектов
    facts.append("player(player_01).")
    
    # Для хранения позиций
    player_pos = None
    stone_positions = []  # список всех позиций камней
    free_cells = []  # клетки, не являющиеся стенами
    goal_cells = []  # клетки-цели
    wall_cells = []  # клетки-стены

    all_possible_positions = set() 
    rows = len(lines)
    for r in range(rows):
        for c in range(len(lines[r])):
            all_possible_positions.add((r, c))

    # Парсим карту
    for r in range(len(lines)):
        for c in range(len(lines[r])):
            ch = lines[r][c]
            
            # Собираем стены для добавления их в isnongoal
            if ch == '#':
                wall_cells.append((r, c))
                continue
                
            # Это "свободная" клетка
            free_cells.append((r, c))
            
            if ch in ('X', 's', 'c'):
                goal_cells.append((r, c))
            if ch in ('S', 's'):
                player_pos = (r, c)
            if ch in ('C', 'c'):
                stone_positions.append((r, c))

    # Добавляем факты для каждого камня
    for i, pos in enumerate(stone_positions, 1):
        stone_name = f"stone_{str(i).zfill(2)}"  # stone_01, stone_02, etc.
        facts.append(f"stone({stone_name}).")

    # Добавляем isgoal/isnongoal, включая стены
    all_cells = free_cells + wall_cells
    cells_with_goal_facts = set()
    for (r, c) in all_cells:
        cell = cell_name(r, c)
        if (r, c) in goal_cells:
            facts.append(f"isgoal({cell}).")
        else:
            facts.append(f"isnongoal({cell}).")
            if (r,c) in wall_cells:
               pass #print (f"adding wall cell {(r+1,c+1)}")
        cells_with_goal_facts.add((r,c))
    
    assert cells_with_goal_facts == all_possible_positions, \
    f"Missing isgoal/isnongoal facts for positions: {all_possible_positions - cells_with_goal_facts}"

    # Добавляем цель для каждого камня
    for i in range(1, len(stone_positions) + 1):
        stone_name = f"stone_{str(i).zfill(2)}"
        facts.append(f"goal({stone_name}).")

    # Добавляем начальную позицию игрока
    if player_pos:
        facts.append(f"at(player_01,{cell_name(*player_pos)}).")

    # Добавляем начальные позиции всех камней
    for i, pos in enumerate(stone_positions, 1):
        stone_name = f"stone_{str(i).zfill(2)}"
        facts.append(f"at({stone_name},{cell_name(*pos)}).")

    # Отмечаем свободные клетки
    occupied = set()
    if player_pos:
        occupied.add(player_pos)
    occupied = occupied.union(set(stone_positions))
    for (r, c) in free_cells:
        if (r, c) not in occupied:
            facts.append(f"clear({cell_name(r,c)}).")

    # Добавляем горизонтальные и вертикальные перемещения между свободными клетками
    for (r, c) in free_cells:
        for (dr, dc, dname) in [(0,1,"dir_right"), (0,-1,"dir_left"),
                               (-1,0,"dir_down"), (1,0,"dir_up")]:
            nr, nc = r + dr, c + dc
            if (nr, nc) in free_cells:
                facts.append(f"movedir({cell_name(r,c)},{cell_name(nr,nc)},{dname}).")
    
     # Add step facts
    facts.append(f"#const maxsteps = {max_steps}.")
    facts.append(f"step({i}..{max_steps}).")

    return "\n".join(facts)


def run_and_format_solution(domain_asp_file: str, map_str: str, max_steps: int = 20) -> str:
    """
    Runs the Sokoban solver using Clingo and formats its output.
    
    Args:
        domain_asp_file: Path to the ASP logic file with Sokoban rules
        map_str: Input map string
        max_steps: Maximum number of steps for solution
        
    Returns:
        Formatted string with solution steps or message if no solution found
    """
    
    def on_model(model):
        nonlocal solution_found, solution_steps
        solution_found = True
        print("Found solution:", model)  # Print raw model for debugging
        # Get all symbolic atoms from the model
        atoms = [str(atom) for atom in model.symbols(shown=True)]
        # Filter only movement predicates
        moves = [atom for atom in atoms if any(
            atom.startswith(pred) for pred in ['move', 'pushtogoal', 'pushtonongoal']
        )]
        solution_steps.extend(moves)

    # Initialize solution tracking
    solution_found = False
    solution_steps = []
    
    # Set up Clingo control
    ctl = clingo.Control()
    ctl.configuration.solve.models = 1  # Find first model
    
    print("Solving Sokoban...\n")
    #print(f"encoder file:\n {domain_asp_file}")
    #print(f"instance:\n {map_str}")
    
    try:
        # 1. Load domain (Sokoban rules)
        ctl.load(domain_asp_file)
        
        # 2. Generate facts from map
        instance_lp = generate_sokoban_lp_from_map(map_str, max_steps=max_steps)
        
        # 3. Add facts as base part
        ctl.add("base", [], instance_lp)
        
        # 4. Ground
        ctl.ground([("base", [])])
        
        # 5. Run solver
        result = ctl.solve(on_model=on_model)
        #print("Solving finished with:", result)
        
        if not solution_found:
            return "No solution found"
        
        # Parse steps and sort them
        step_dict = {}
        for step in solution_steps:
            # Extract step number from the end of the predicate
            step_num = int(step.split(',')[-1].rstrip(').'))
            step_dict[step_num] = step
        
        # Format output
        formatted_solution = []
        formatted_solution.append(f"Solution found in {max(step_dict.keys())} steps:")
        for step_num in sorted(step_dict.keys()):
            action = step_dict[step_num]
            # Make it more readable by adding spaces after commas
            action = action.replace(',', ', ').replace('  ', ' ')
            formatted_solution.append(f"Step {step_num}: {action}")
        
        return "\n".join(formatted_solution)
        
    except Exception as e:
        return f"Error solving map: {str(e)}"
    

def next_step_map(current_map: str, step: str) -> str:
    """
    Generate the next map state based on the current map and a solution step.
    
    Args:
        current_map: String representation of the current map state
        step: String containing the current solution step (e.g., 'move(player_01, pos_2_2, pos_3_2, dir_right, 17)')
        
    Returns:
        Updated map string reflecting the new state after the step
    """
    # Convert map to 2D list for easier manipulation
    map_lines = current_map.strip().split('\n')
    map_grid = [list(line) for line in map_lines]
    
    def pos_to_coords(pos_str: str) -> tuple[int, int]:
        """Convert 'pos_X_Y' string to (x-1, y-1) coordinates."""
        _, x, y = pos_str.split('_')
        return (int(x)-1, int(y)-1)  # Convert to 0-based indices
    
    def get_cell_type(x: int, y: int) -> str:
        """Get the current cell type at the given coordinates."""
        return map_grid[y][x]
    
    def set_cell(x: int, y: int, new_value: str):
        """Set a cell value, maintaining goal positions."""
        current = map_grid[y][x]
        # If we're moving onto a goal cell
        if current == 'X':
            if new_value == 'S':
                map_grid[y][x] = 's'  # player on goal
            elif new_value == 'C':
                map_grid[y][x] = 'c'  # crate on goal
            else:
                map_grid[y][x] = new_value
        # If we're moving off a goal cell
        elif current in ('s', 'c'):
            map_grid[y][x] = 'X'  # restore goal
        else:
            map_grid[y][x] = new_value
    
    # Parse the step
    if 'move' in step:
        # Handle player movement
        parts = step.split('(')[1].split(')')[0].split(', ')
        _, from_pos, to_pos, _, _ = parts
        
        from_x, from_y = pos_to_coords(from_pos)
        to_x, to_y = pos_to_coords(to_pos)
        
        # Move player
        set_cell(from_x, from_y, ' ')  # Clear old position
        set_cell(to_x, to_y, 'S')      # Set new position
        
    elif 'pushtogoal' in step or 'pushtonongoal' in step:
        # Handle box pushing
        parts = step.split('(')[1].split(')')[0].split(', ')
        _, stone, player_pos, box_pos, target_pos, _, _ = parts
        
        p_x, p_y = pos_to_coords(player_pos)
        b_x, b_y = pos_to_coords(box_pos)
        t_x, t_y = pos_to_coords(target_pos)
        
        # Move player to box's position
        set_cell(p_x, p_y, ' ')    # Clear player's old position
        set_cell(b_x, b_y, 'S')    # Move player to box's position
        set_cell(t_x, t_y, 'C')    # Move box to target position
    
    # Convert back to string
    return '\n'.join(''.join(line) for line in map_grid)

def visualize_solution(initial_map: str, solution_steps: list[str]) -> list[str]:
    """
    Generate a sequence of maps showing the solution progress.
    
    Args:
        initial_map: String representation of the initial map
        solution_steps: List of solution steps strings
        
    Returns:
        List of map strings, one for each step of the solution
    """
    maps = [initial_map]
    current_map = initial_map
    
    for step in solution_steps:
        current_map = next_step_map(current_map, step)
        maps.append(current_map)
        
    return maps


    

import clingo
import argparse

def generate_sokoban_lp_from_map(map_str):
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
                print (f"adding wall cell {(r+1,c+1)}")
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

    return "\n".join(facts)


# ---------------------------
# Пример интеграции с Clingo:
# ---------------------------
def sokoban_solve_from_map(domain_asp_file, map_str, max_steps=20):
    """
    Считывает encodings из domain_asp_file (где у вас правила Sokoban),
    генерирует факты на основе map_str,
    решает задачу через Clingo Python API.
    """
    ctl = clingo.Control()
    ctl.configuration.solve.models = 1  # Найти все модели (0 = неограниченно)

    # 1) Загружаем домен (код Sokoban)
    ctl.load(domain_asp_file)

    # 2) Генерируем факты .lp из карты
    instance_lp = generate_sokoban_lp_from_map(map_str, max_steps=max_steps)

    # 3) Добавляем их как "base" часть
    ctl.add("base", [], instance_lp)

    # 4) Ground
    ctl.ground([("base", [])])

    # 5) Запуск решателя
    print("Solving Sokoban...\n")
    result = ctl.solve(on_model=lambda m: print("Model:", m))
    print("Solving finished with:", result)


if __name__ == "__main__":
    # Пример карты:
    # #########
    # #S  C  X#
    # #########
    # (Здесь три свободные клетки: (1,1) = S, (1,3) = C, (1,5) = X,
    #  все остальное - стены #.)
    map = """\
#########
#S  C  X#
#########
"""
    parser = argparse.ArgumentParser(description="Sokoban Solver using Clingo Python API")
    parser.add_argument("--asp-file", type=str, default="enc.lp", nargs='?',
                        help="Path to the ASP logic file (default: sokoban.lp).")
    parser.add_argument("--map", type=str, default="map1.txt", nargs='?',
                        help="Path to the input file (default: input.lp).")
    parser.add_argument("--timeout", type=int, default=60, nargs='?',
                        help="Timeout for the solver in seconds (default: 60).")

    args = parser.parse_args()

    asp_file = args.asp_file
    with open(args.map, 'r') as file:
        map = file.read()
    timeout = args.timeout

    print(map);


    # Допустим, у вас файл "sokoban_domain.lp" с правилами (Generate/Test/Define).
    domain_file = "sok.lp"

    # Запустим решение:
    sokoban_solve_from_map(domain_file, map, max_steps=5)

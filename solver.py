# solver.py

import clingo
import argparse
import math
from typing import List, Tuple, Set, Optional, Dict


class SokobanSolver:
    """
    A solver for Sokoban puzzles using the Clingo ASP solver.
    """

    def __init__(self, domain_asp_file: str, max_steps: int = 50):
        """
        Initializes the SokobanSolver.

        Args:
            domain_asp_file: Path to the ASP domain rules file.
            max_steps: Maximum number of steps to search for a solution.
        """
        self.domain_asp_file = domain_asp_file
        self.max_steps = max_steps

    @staticmethod
    def cell_index(row: int, col: int) -> str:
        """Generates a unique cell identifier based on row and column."""
        return f"{row}_{col}"

    def generate_facts_from_map(self, map_str: str, max_steps: int) -> str:
        """
        Converts the Sokoban map into ASP facts.

        Args:
            map_str: String representation of the Sokoban map.
            max_steps: Maximum number of steps for the solver.

        Returns:
            A string containing ASP facts derived from the map.
        """
        lines = [line.strip() for line in map_str.splitlines() if line.strip()]
        height = len(lines)
        width = max(len(row) for row in lines) if lines else 0

        sokoban_pos: Optional[Tuple[int, int]] = None
        crate_positions: Set[Tuple[int, int]] = set()
        walls: Set[Tuple[int, int]] = set()
        goal_positions: Set[Tuple[int, int]] = set()

        for r, row in enumerate(lines):
            for c, ch in enumerate(row):
                pos = (r, c)
                if ch == '#':
                    walls.add(pos)
                elif ch in ('S', 's'):
                    sokoban_pos = pos
                    if ch == 's' and pos not in walls:
                        goal_positions.add(pos)
                elif ch in ('C', 'c'):
                    crate_positions.add(pos)
                    if ch == 'c' and pos not in walls:
                        goal_positions.add(pos)
                elif ch == 'X' and pos not in walls:
                    goal_positions.add(pos)

        facts = ["sokoban(sokoban)."]
        for i, _ in enumerate(crate_positions, start=1):
            facts.append(f"crate(crate_{i:02d}).")

        location_list, goal_list, non_goal_list, walls_list = self._categorize_cells(
            lines, height, width, goal_positions, walls
        )

        facts.extend(self._format_facts(location_list, goal_list, non_goal_list, walls_list))
        facts.extend(self._define_relations(lines, height, width))
        facts.extend(self._define_initial_positions(sokoban_pos, crate_positions, height, width, lines, walls))
        #facts.append(f"#const maxsteps={max_steps}.")
        facts.append("time(0..maxsteps).")

        return "\n".join(facts)

    def _categorize_cells(
        self,
        lines: List[str],
        height: int,
        width: int,
        goal_positions: Set[Tuple[int, int]],
        walls: Set[Tuple[int, int]],
    ) -> Tuple[List[str], List[str], List[str], List[str]]:
        """Categorizes cells into locations, goals, non-goals, and walls."""
        location_list, goal_list, non_goal_list, walls_list = [], [], [], []
        for r in range(height):
            row_length = len(lines[r])
            for c in range(row_length):
                cell_id = f"l{self.cell_index(r, c)}"
                location_list.append(cell_id)
                pos = (r, c)
                if pos in goal_positions:
                    goal_list.append(cell_id)
                elif pos not in walls:
                    non_goal_list.append(cell_id)
                if pos in walls:
                    walls_list.append(cell_id)
        assert not set(goal_list) & set(non_goal_list), "Conflict: Cells in both isgoal and isnongoal"
        return location_list, goal_list, non_goal_list, walls_list

    @staticmethod
    def _format_facts(
        locations: List[str],
        goals: List[str],
        non_goals: List[str],
        walls: List[str],
    ) -> List[str]:
        """Formats the categorized cells into ASP facts."""
        facts = []
        if locations:
            facts.append(f"location({';'.join(locations)}).")
        if goals:
            facts.append(f"isgoal({';'.join(goals)}).")
        if non_goals:
            facts.append(f"isnongoal({';'.join(non_goals)}).")
        if walls:
            facts.append(f"wall({';'.join(walls)}).")
        return facts

    def _define_relations(self, lines: List[str], height: int, width: int) -> List[str]:
        """Defines spatial relations (leftOf, below) between cells."""
        relations = []
        for r in range(height):
            row_length = len(lines[r])
            for c in range(row_length):
                current_id = self.cell_index(r, c)
                if c + 1 < row_length:
                    right_id = self.cell_index(r, c + 1)
                    relations.append(f"leftOf(l{current_id}, l{right_id}).")
                if r + 1 < height and c < len(lines[r + 1]):
                    below_id = self.cell_index(r + 1, c)
                    relations.append(f"below(l{below_id}, l{current_id}).")
        return relations

    def _define_initial_positions(
        self,
        sokoban_pos: Optional[Tuple[int, int]],
        crate_positions: Set[Tuple[int, int]],
        height: int,
        width: int,
        lines: List[str],
        walls: Set[Tuple[int, int]],
    ) -> List[str]:
        """Defines the initial positions of the Sokoban and crates."""
        initial_positions = []
        if sokoban_pos:
            sokoban_id = self.cell_index(*sokoban_pos)
            initial_positions.append(f"at(sokoban, l{sokoban_id}, 0).")

        for i, (r, c) in enumerate(crate_positions, start=1):
            crate_name = f"crate_{i:02d}"
            crate_id = self.cell_index(r, c)
            initial_positions.append(f"at({crate_name}, l{crate_id}, 0).")

        occupied = crate_positions.union({sokoban_pos} if sokoban_pos else set())
        for r in range(height):
            row_length = len(lines[r])
            for c in range(row_length):
                pos = (r, c)
                if pos not in occupied and pos not in walls:
                    cell_id = self.cell_index(r, c)
                    initial_positions.append(f"clear(l{cell_id}, 0).")
        return initial_positions

    def solve(self, map_str: str) -> str:
        """
        Solves the Sokoban puzzle based on the provided map.

        Args:
            map_str: String representation of the Sokoban map.

        Returns:
            A formatted string with the solution steps or "No solution found".
        """
        solution_found = False
        solution_steps: List[str] = []
        min_steps = 1

        print("\nSolving Sokoban...\n")
        print(f"Generating plans of length: ", end='')

        for steps in range(min_steps, self.max_steps + 1):
            print(f"{steps}...", end='')
            try:
                #find optimal plan
                maxsteps_string = f"maxsteps={  steps}"
                ctl = clingo.Control(arguments=["--models=0", "--opt-mode=opt", '--const', maxsteps_string])
                ctl.load(self.domain_asp_file)

                instance_facts = self.generate_facts_from_map(map_str, max_steps=steps)
                ctl.add("base", [], instance_facts)
                ctl.ground([("base", [])])

                def handle_model(model: clingo.Model):
                    nonlocal solution_found, solution_steps
                    solution_found = True
                    print(f"\nFound solution: {model}")

                    atoms = [str(atom) for atom in model.symbols(shown=True)]
                    moves = [atom for atom in atoms if atom.startswith("do(")]
                    solution_steps.extend(moves)

                ctl.solve(on_model=handle_model)

                if solution_found:
                    return self._format_solution(solution_steps)
                else:
                    ctl.cleanup()
                    print(f"UNSAT, trying with ", end='')
            except Exception as e:
                print(f"Error at steps={steps}: {str(e)}")

        return "No solution found"

    def _format_solution(self, steps: List[str]) -> str:
        """
        Formats the solution steps into a readable string.

        Args:
            steps: List of action literals.

        Returns:
            A formatted solution string.
        """
        step_to_action: Dict[int, str] = {}
        for action_literal in steps:
            inside = action_literal[len("do("):-1]
            last_comma = inside.rfind(",")
            step_str = inside[last_comma + 1:].strip()
            try:
                step_num = int(step_str)
                action_text = inside[:last_comma].strip()
                step_to_action[step_num] = action_text
            except ValueError:
                continue

        if step_to_action:
            max_step = max(step_to_action.keys())
            result_lines = [f"Solution found in {max_step + 1} steps (0..{max_step}):"]
            for t in sorted(step_to_action.keys()):
                result_lines.append(f"Step {t}: do({step_to_action[t]}, {t})")
            return "\n".join(result_lines)
        return "Solution found (no actions shown?)."

    @staticmethod
    def _estimate_min_steps(map_str: str) -> int:
        """
        Estimates the minimum number of steps required based on the map size.

        Args:
            map_str: String representation of the Sokoban map.

        Returns:
            An estimated minimum number of steps.
        """
        lines = [line.strip() for line in map_str.splitlines() if line.strip()]
        height = len(lines)
        width = max(len(row) for row in lines) if lines else 0
        return math.ceil(math.sqrt(height**2 + width**2))


class SokobanMap:
    """
    Представляет карту Sokoban и предоставляет методы для её обновления и визуализации.
    """

    # Константы для символов
    SYMBOL_WALL = '#'
    SYMBOL_CRATE = 'C'
    SYMBOL_GOAL = 'X'
    SYMBOL_SOKOBAN = 'S'
    SYMBOL_SOKOBAN_GOAL = 's'
    SYMBOL_CRATE_GOAL = 'c'

    def __init__(self, map_str: str):
        """
        Инициализирует SokobanMap.

        Args:
            map_str: Строковое представление карты Sokoban.
        """
        self.map_grid: List[List[str]] = [list(line) for line in map_str.strip().split('\n') if line.strip()]
        self.height = len(self.map_grid)
        self.width = max(len(row) for row in self.map_grid) if self.map_grid else 0
    
    def _set_cell(self, from_r, from_c, symbol): 
        self.map_grid[from_r][from_c] = symbol

    def apply_step(self, step: str) -> None:
        """
        Применяет один шаг для обновления карты.

        Args:
            step: Действие в формате литералов ASP (например, do(push(...)), do(move(...)), do(moveRight(...))).
        """
        if step.startswith("do(push"):
            self._apply_push(step)
        elif step.startswith("do(move"):
            self._apply_move(step)
        else:
            print(f"Неизвестный формат шага: {step}")

    def _apply_push(self, step: str) -> None:
        """
        Применяет действие push к карте.

        Args:
            step: Литерал действия push, например, do(pushRight(sokoban,l1_4,l1_5,l1_6,crate_01), 3).
        """
        try:
            # Извлекаем содержимое внутри do(pushRight(...), step_num)
            inside = step[step.find('(')+1 : step.rfind(')')]  # 'pushRight(sokoban,l1_4,l1_5,l1_6,crate_01), 3'

            # Разделяем на действие и номер шага
            action_str, step_num_str = self._split_step_arguments(inside, expected=2)

            # Парсим строку действия, например, 'pushRight(sokoban,l1_4,l1_5,l1_6,crate_01)'
            action_name_start = action_str.find('(')
            if action_name_start == -1:
                raise ValueError(f"Некорректный формат действия: {action_str}")
            action_name = action_str[:action_name_start]
            action_inside = action_str[action_name_start + 1 : -1]  # 'sokoban,l1_4,l1_5,l1_6,crate_01'

            # Разделяем аргументы действия, ожидается 5 аргументов
            args = self._split_step_arguments(action_inside, expected=5)
            entity, from_l, to_l, crate_to, crate_name = args

            from_r, from_c = self._cell_id_to_coords(to_l)
            to_r, to_c = self._cell_id_to_coords(crate_to)
            self._move_crate(from_r, from_c, to_r, to_c)
            # Перемещаем Sokoban из from_l в to_l
            from_r, from_c = self._cell_id_to_coords(from_l)
            to_r, to_c = self._cell_id_to_coords(to_l)
            self._move_sokoban(from_r, from_c, to_r, to_c)

        except Exception as e:
            print(f"Ошибка при обработке шага push '{step}': {e}")

    def _apply_move(self, step: str) -> None:
        """
        Применяет действие move к карте.

        Args:
            step: Литерал действия move (например, do(move(...), step_num), do(moveRight(...), step_num)).
        """
        try:
            # Извлекаем содержимое внутри do(moveRight(sokoban,l1_2,l1_3), 1)
            start = step.find('(') + 1
            end = step.rfind(')')
            inside = step[start:end]  # 'moveRight(sokoban,l1_2,l1_3), 1'

            # Разделяем на действие и номер шага
            action_str, step_num_str = self._split_step_arguments(inside, expected=2)

            # Теперь парсим строку действия, например, 'moveRight(sokoban,l1_2,l1_3)'
            action_name_start = action_str.find('(')
            if action_name_start == -1:
                raise ValueError(f"Некорректный формат действия: {action_str}")
            action_name = action_str[:action_name_start]
            action_inside = action_str[action_name_start + 1:-1]  # 'sokoban,l1_2,l1_3'

            # Разделяем аргументы действия
            action_parts = self._split_step_arguments(action_inside, expected=3)
            entity, from_l, to_l = action_parts

            from_r, from_c = self._cell_id_to_coords(from_l)
            to_r, to_c = self._cell_id_to_coords(to_l)

            # Перемещаем сущность
            self._move_sokoban(from_r, from_c, to_r, to_c)
        except Exception as e:
            print(f"Ошибка при обработке шага move '{step}': {e}")

    def _move_sokoban(self, from_r: int, from_c: int, to_r: int, to_c: int) -> None:
        """
        Перемещает Sokoban из одной клетки в другую.

        Args:
            from_r: Исходная строка.
            from_c: Исходный столбец.
            to_r: Целевая строка.
            to_c: Целевой столбец.
        """
        current_symbol = self.map_grid[from_r][from_c]
        
        if current_symbol not in (self.SYMBOL_SOKOBAN, self.SYMBOL_SOKOBAN_GOAL):
            raise ValueError(f"На позиции ({from_r}, {from_c}) нет Sokoban.")
        
        # Очистка исходной клетки
        if (current_symbol == self.SYMBOL_SOKOBAN): self._set_cell(from_r, from_c, ' ')
        elif (current_symbol == self.SYMBOL_SOKOBAN_GOAL): self._set_cell(from_r, from_c, self.SYMBOL_GOAL)
        
        # Обновление целевой клетки
        if self.map_grid[to_r][to_c] == self.SYMBOL_GOAL:
            self.map_grid[to_r][to_c] = self.SYMBOL_SOKOBAN_GOAL
        else:
            self.map_grid[to_r][to_c] = self.SYMBOL_SOKOBAN

    def _move_crate(self, from_r: int, from_c: int, to_r: int, to_c: int) -> None:
        """
        Перемещает коробку из одной клетки в другую.

        Args:
            from_r: Исходная строка.
            from_c: Исходный столбец.
            to_r: Целевая строка.
            to_c: Целевой столбец.
        """
        current_symbol = self.map_grid[from_r][from_c]
        if current_symbol not in (self.SYMBOL_CRATE, self.SYMBOL_CRATE_GOAL):
            raise ValueError(f"На позиции ({from_r}, {from_c}) нет коробки.")
        
        # Очистка исходной клетки
        if (current_symbol == self.SYMBOL_CRATE): self._set_cell(from_r, from_c, ' ')
        elif(current_symbol == self.SYMBOL_CRATE_GOAL): self._set_cell(from_r, from_c, self.SYMBOL_GOAL)
        
        # Обновление целевой клетки
        if self.map_grid[to_r][to_c] == self.SYMBOL_GOAL:
            self.map_grid[to_r][to_c] = self.SYMBOL_CRATE_GOAL
        else:
            self.map_grid[to_r][to_c] = self.SYMBOL_CRATE


    def _cell_id_to_coords(self, cell_id: str) -> Tuple[int, int]:
        """
        Преобразует идентификатор клетки в координаты строки и столбца.

        Args:
            cell_id: Идентификатор клетки в формате строки, например, 'l0_1'.

        Returns:
            Кортеж из двух целых чисел (строка, столбец).

        Raises:
            ValueError: Если формат идентификатора клетки некорректен.
        """
        try:
            if cell_id.startswith('l'):
                cell_id = cell_id[1:]
            row_str, col_str = cell_id.split('_')
            row = int(row_str)
            col = int(col_str)
            return row, col
        except Exception as e:
            raise ValueError(f"Некорректный формат cell_id: {cell_id}") from e

    def _split_step_arguments(self, step_str: str, expected: int) -> List[str]:
        """
        Разделяет аргументы шага, учитывая вложенные скобки.

        Args:
            step_str: Строка внутри do(push(...)) или do(move(...)).
            expected: Ожидаемое количество аргументов.

        Returns:
            Список аргументов.

        Raises:
            ValueError: Если количество аргументов не соответствует ожидаемому.
        """
        args = []
        current = ''
        depth = 0
        for char in step_str:
            if char == ',' and depth == 0:
                args.append(current.strip())
                current = ''
            else:
                if char == '(':
                    depth += 1
                elif char == ')':
                    depth -= 1
                current += char
        if current:
            args.append(current.strip())
        if len(args) != expected:
            raise ValueError(f"Ожидалось {expected} аргументов, получено {len(args)} в шаге: {step_str}")
        return args

    def visualize(self) -> None:
        """
        Печатает текущее состояние карты Sokoban.
        """
        for row in self.map_grid:
            print(''.join(row))


def main():
    parser = argparse.ArgumentParser(description="Solve Sokoban puzzles using Clingo.")
    parser.add_argument("domain_file", help="Path to the ASP domain rules file.")
    parser.add_argument("map_file", help="Path to the Sokoban map file.")
    parser.add_argument("--max_steps", type=int, default=50, help="Maximum number of steps to search.")
    args = parser.parse_args()

    with open(args.map_file, 'r') as f:
        map_str = f.read()

    solver = SokobanSolver(domain_asp_file=args.domain_file, max_steps=args.max_steps)
    solution = solver.solve(map_str)

    print(solution)

    # Optional visualization
    # If you want to visualize each step, you can parse the solution and update the map accordingly
    map_obj = SokobanMap(map_str)
    print("initial map state")
    print(map_str)
    solution_steps = [line for line in solution.splitlines() if line.startswith("Step")]
    solution_steps = [line.split(": ", 1)[1] for line in solution_steps]

    for i, step in enumerate(solution_steps):
        map_obj.apply_step(step)
        print(f"\nAfter step {i}:")
        map_obj.visualize()


if __name__ == "__main__":
    main()

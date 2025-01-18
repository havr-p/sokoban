import clingo
import argparse

def generate_sokoban_lp_from_map(map_str: str, max_steps: int = 10) -> str:
    lines = [ln.strip() for ln in map_str.splitlines() if ln.strip() != ""]
    height = len(lines)
    width = max(len(row) for row in lines) if lines else 0

    sokoban_pos = None
    crate_positions = set()
    walls = set()
    goal_positions = set()

    for r, row in enumerate(lines):
        for c, ch in enumerate(row):
            if ch == '#':
                walls.add((r, c))
            elif ch in ('S', 's'):
                sokoban_pos = (r, c)
                if ch == 's' and (r, c) not in walls:
                    goal_positions.add((r, c))
            elif ch in ('C', 'c'):
                crate_positions.add((r, c))
                if ch == 'c' and (r, c) not in walls:
                    goal_positions.add((r, c))
            elif ch == 'X' and (r, c) not in walls:
                goal_positions.add((r, c))

    def cell_index(rr, cc):
        return rr * width + cc + 1

    facts = ["sokoban(sokoban)."]
    for i, pos in enumerate(crate_positions, start=1):
        facts.append(f"crate(crate_{i:02d}).")

    location_list, goal_list, nongoal_list, walls_list = [], [], [], []
    for r in range(height):
        row_len = len(lines[r])
        for c in range(row_len):
            N = cell_index(r, c)
            loc_name = f"l{N}"
            location_list.append(loc_name)
            if (r, c) in goal_positions:
                goal_list.append(loc_name)
            elif (r, c) not in walls:
                nongoal_list.append(loc_name)
            elif (r,c) in walls:
                walls_list.append(loc_name)
    assert not (set(goal_list) & set(nongoal_list)), "Conflict: Cells in both isgoal and isnongoal"
    if location_list:
        facts.append(f"location({';'.join(location_list)}).")
    if goal_list:
        facts.append(f"isgoal({';'.join(goal_list)}).")
    if nongoal_list:
        facts.append(f"isnongoal({';'.join(nongoal_list)}).")
    if walls_list:
        facts.append(f"wall({';'.join(walls_list)}).")

    for r in range(height):
        row_len = len(lines[r])
        for c in range(row_len):
            thisN = cell_index(r, c)
            if c + 1 < row_len:
                rightN = cell_index(r, c + 1)
                facts.append(f"leftOf(l{thisN}, l{rightN}).")
            if r + 1 < height and c < len(lines[r + 1]):
                downN = cell_index(r + 1, c)
                facts.append(f"below(l{downN}, l{thisN}).")

    if sokoban_pos is not None:
        sN = cell_index(*sokoban_pos)
        facts.append(f"at(sokoban, l{sN}, 0).")

    for i, (r, c) in enumerate(crate_positions, start=1):
        crate_name = f"crate_{i:02d}"
        N = cell_index(r, c)
        facts.append(f"at({crate_name}, l{N}, 0).")

    occupied = walls | crate_positions | ({sokoban_pos} if sokoban_pos else set())
    for r in range(height):
        row_len = len(lines[r])
        for c in range(row_len):
            if (r, c) not in occupied:
                cellN = cell_index(r, c)
                facts.append(f"clear(l{cellN}, 0).")

    facts.append(f"#const maxsteps={max_steps}.")
    facts.append("time(0..maxsteps).")

    return "\n".join(facts)






def run_and_format_solution(domain_asp_file: str, map_str: str, max_steps: int = 20) -> str:
    """
    Запускает решатель Clingo, подмешивая:
      1) правила из файла domain_asp_file (где описаны push/move, эффекты и т.д.)
      2) факты, сгенерированные из карты (generate_sokoban_lp_from_map)
    Возвращает строку с упорядоченными действиями плана или сообщение
    "No solution found".
    """
    def on_model(model):
        nonlocal solution_found, solution_steps
        solution_found = True
        print("Found solution:", model)  # Для отладки выводим сырую модель

        # Вытаскиваем все показываемые литералы (shown=True)
        atoms = [str(atom) for atom in model.symbols(shown=True)]

        # Если в domain_asp_file вывод действий задан, например, как "#show do/2",
        # То действия выглядят вроде do(moveLeft(sokoban,l37,l30), 0).
        # Тогда можно так отфильтровать:
        moves = [a for a in atoms if a.startswith("do(")]
        solution_steps.extend(moves)

    # Инициализация
    solution_found = False
    solution_steps = []
    
    print("Solving Sokoban...\n")
    
    try:
        ctl = clingo.Control()
        ctl.configuration.solve.models = 0  # 0 = искать все модели, но обычно хватит 1.
        
        # 1) Загружаем файл с общими правилами (движения, push, эффекты и т.д.)
        ctl.load(domain_asp_file)
        print(f'\n\n\nDOMAIN FILE:\n{domain_asp_file}\n\n')
        # 2) Генерируем факты из карты
        instance_lp = generate_sokoban_lp_from_map(map_str, max_steps)
        print("debug map")
        print_debug_grid(map_str)
        print("INSTANCE\n\n\n")
        print("Instance facts in ASP:\n", instance_lp)
        print("END OF INSTANCE\n\n\n")
        
        # 3) Добавляем факты к "base"-части
        ctl.add("base", [], instance_lp)
        
        # 4) Ground
        ctl.ground([("base", [])])
        
        # 5) Запускаем решатель
        result = ctl.solve(on_model=on_model)
        
        # Если не было ни одной модели
        if not solution_found:
            return "No solution found"
        
        # Обработка вывода
        # Предположим, что каждый do(...) оканчивается на шаг T,
        # формально что-то вроде do(..., T).
        # Нужно извлечь T и отсортировать.
        step_to_action = {}
        for action_literal in solution_steps:
            # Например: do(moveLeft(sokoban,l37,l30), 0)
            # Разберём строку, чтобы взять последний аргумент перед `)`
            # Аккуратно обрежем: do( ..., T)
            inside = action_literal[len("do("):-1]  # что внутри do(...)
            # Разделим по запятым, но нужно быть аккуратным, 
            # т.к. внутри moveLeft(...) тоже запятые.
            # Проще отсечь всё до последней запятой:
            last_comma = inside.rfind(",")
            step_str = inside[last_comma+1:].strip()
            try:
                step_num = int(step_str)
            except ValueError:
                # Если почему-то не распарсится, 
                # пропустим это действие
                continue
            # само действие = всё, кроме ",T"
            action_text = inside[:last_comma].strip()
            step_to_action[step_num] = action_text
        
        # Формируем читабельный вывод
        if step_to_action:
            max_step = max(step_to_action.keys())
            result_lines = [f"Solution found in {max_step + 1} steps (0..{max_step}):"]
            for t in sorted(step_to_action.keys()):
                result_lines.append(f"Step {t}: do({step_to_action[t]}, {t})")
            return "\n".join(result_lines)
        else:
            return "Solution found (no actions shown?)."
        
    except Exception as e:
        return f"Error solving map: {str(e)}"


def next_step_map(current_map: str, step: str) -> str:
    """
    Обновляет текущее состояние карты Sokoban на основе шага решения.

    Аргументы:
        current_map: Строка, представляющая текущую карту Sokoban.
        step: Строка с действием в формате ASP (например, do(push(...)) или do(move(...))).

    Возвращает:
        Обновлённое состояние карты в строковом виде.
    """
    map_lines = current_map.strip().split('\n')
    map_grid = [list(line) for line in map_lines]
    height = len(map_grid)
    width = max(len(row) for row in map_grid) if map_grid else 0

    def cell_num_to_coords(N: int) -> tuple[int, int]:
        """Конвертирует номер клетки lN в координаты (r, c)."""
        r = (N - 1) // width
        c = (N - 1) % width
        return r, c

    def set_cell(r: int, c: int, new_value: str):
        """Устанавливает новое значение в клетке, сохраняя цели ('X')."""
        if r < 0 or r >= height or c < 0 or c >= len(map_grid[r]):
            raise ValueError(f"Неверные координаты: ({r}, {c})")
        current = map_grid[r][c]
        if current == 'X':  # Если это целевая клетка
            if new_value == 'S':
                map_grid[r][c] = 's'  # Сокобан на цели
            elif new_value == 'C':
                map_grid[r][c] = 'c'  # Ящик на цели
            else:
                map_grid[r][c] = 'X'  # Сбрасываем к цели
        elif current in ('s', 'c'):  # Сокобан/ящик на цели
            if new_value == ' ':
                map_grid[r][c] = 'X'  # Возвращаем цель
            else:
                map_grid[r][c] = new_value  # Обновляем значение
        else:
            map_grid[r][c] = new_value  # Просто заменяем значение

    # Парсим шаг
    if step.startswith("do(push"):
        # Пример: do(push(sokoban, l2, l3, crate_01), T)
        try:
            # Извлекаем содержимое внутри do(...)
            inside = step[len("do(push("):-1]
            parts = inside.split(', ')
            sokoban_label = parts[0]
            from_l = parts[1]
            to_l = parts[2]
            crate = parts[3].rstrip(')')
            # Извлекаем номера клеток
            from_N = int(from_l[1:])
            to_N = int(to_l[1:])
            from_r, from_c = cell_num_to_coords(from_N)
            to_r, to_c = cell_num_to_coords(to_N)

            # Обновление позиции Сокобана
            set_cell(from_r, from_c, ' ')  # Сокобан уходит с текущей клетки
            if map_grid[to_r][to_c] == 'X':
                map_grid[to_r][to_c] = 's'  # Сокобан на цели
            else:
                map_grid[to_r][to_c] = 'S'  # Сокобан на новой клетке

            # Обновление позиции ящика
            # Предполагаем, что crate находится в from_l и перемещается в to_l
            # Найдём ящик в from_l
            if map_grid[from_r][from_c] in ('C', 'c'):
                set_cell(from_r, from_c, ' ')  # Ящик уходит
                if map_grid[to_r][to_c] == 'X':
                    map_grid[to_r][to_c] = 'c'  # Ящик на цели
                else:
                    map_grid[to_r][to_c] = 'C'  # Ящик на новой клетке
            else:
                raise ValueError(f"Ожидался ящик в клетке l{from_N}, но найден '{map_grid[from_r][from_c]}'")
        except Exception as e:
            print(f"Ошибка при обработке шага push: {e}")
            return current_map

    elif step.startswith("do(move"):
        # Пример: do(move(sokoban, l2, l3), T)
        try:
            # Извлекаем содержимое внутри do(...)
            inside = step[len("do(move("):-1]
            parts = inside.split(', ')
            sokoban_label = parts[0]
            from_l = parts[1]
            to_l = parts[2].rstrip(')')
            # Извлекаем номера клеток
            from_N = int(from_l[1:])
            to_N = int(to_l[1:])
            from_r, from_c = cell_num_to_coords(from_N)
            to_r, to_c = cell_num_to_coords(to_N)

            # Обновление позиции Сокобана
            set_cell(from_r, from_c, ' ')  # Сокобан уходит с текущей клетки
            if map_grid[to_r][to_c] == 'X':
                map_grid[to_r][to_c] = 's'  # Сокобан на цели
            else:
                map_grid[to_r][to_c] = 'S'  # Сокобан на новой клетке
        except Exception as e:
            print(f"Ошибка при обработке шага move: {e}")
            return current_map

    else:
        print(f"Неизвестный формат шага: {step}")
        return current_map

    # Конвертируем карту обратно в строку
    return '\n'.join(''.join(row) for row in map_grid)




def visualize_solution(initial_map: str, solution_steps: list[str]) -> list[str]:
    """
    (Опционально) Генерируем последовательность карт после каждого шага.
    ...
    """
    maps = [initial_map]
    current_map = initial_map
    for step in solution_steps:
        current_map = next_step_map(current_map, step)
        maps.append(current_map)
    return maps

def print_debug_grid(map_str: str):
    """
    Отображает карту Sokoban с индексами ячеек в каждой клетке в формате сетки.
    Использует символы | и _ для создания границ сетки.
    
    Аргументы:
        map_str: строка с картой Sokoban (символы #, S, C, X, . и т.д.).
    """
    lines = [ln.strip() for ln in map_str.splitlines() if ln.strip() != ""]
    height = len(lines)
    width = max(len(row) for row in lines) if lines else 0

    def cell_index(r, c):
        return r * width + c + 1

    # Построение верхней границы
    grid = []
    grid.append(" " + "____" * width)

    for r, row in enumerate(lines):
        row_top = "|".join(f" l{cell_index(r, c):2d} {lines[r][c]}" for c in range(len(row)))  # Номера ячеек
        grid.append("|" + row_top + "|")
        grid.append("|" + "______" * len(row) + "|")  # Нижняя граница

    # Преобразуем сетку в строку и выводим
    print("\n".join(grid))


import clingo
import argparse

def generate_sokoban_lp_from_map(map_str, max_steps=3):
    """
    Принимает карту Sokoban в виде строк (с символами #, S, C, X, s, c),
    и возвращает строку с фактами ASP (в формате .lp):
      - player/1, stone/1, isgoal/1, isnongoal/1
      - movedir(pos_r_c, pos_r'_c', dir_right/dir_left/dir_up/dir_down)
      - at/2, clear/1
      - goal/1 (если хотим указать, что нужно передвинуть crate (stone))
      - step(1..max_steps)
    """
    lines = map_str.splitlines()
    # Удалим пустые строчки в начале/конце, если есть
    lines = [ln for ln in lines if ln.strip() != ""]

    n_rows = len(lines)
    n_cols = len(lines[0]) if n_rows > 0 else 0

    # Проверяем, что все строки одной длины
    for ln in lines:
        if len(ln) != n_cols:
            raise ValueError("All rows must have the same length (rectangular map).")

    # Вспомогательная функция для имени клетки pos_r_c
    def cell_name(r, c):
        return f"pos_{r}_{c}"

    # Будем собирать факты в список, а затем склеим в строку
    facts = []

    # Заводим для простоты фиксированные имена
    # можно адаптировать, если на карте несколько камней и игроков
    player_name = "player_01"
    stone_name  = "stone_01"

    # Сразу объявим player/1, stone/1 (если точно один игрок и один камень)
    facts.append(f"player({player_name}).")
    facts.append(f"stone({stone_name}).")

    # Парсим карту, определяя стены, пустые клетки, цели, позиции игрока/камня
    # #   - стена
    # S   - Sokoban (игрок)
    # C   - crate (камень)
    # X   - storage/goal
    # s   - Sokoban в goal-клетке
    # c   - crate в goal-клетке
    # ' ' (пробел) - обычная свободная клетка
    # Любые стены мы НЕ будем задавать как isnongoal/... и не генерировать для них movedir/...
    
    # Для хранения того, что мы встретили:
    player_pos = None
    stone_pos  = None

    # Массив для отметки: какие клетки - не стена
    free_cells = []

    # Массив для отметки: какие клетки - goal
    goal_cells = []

    # Проходимся по строкам и столбцам
    for r in range(n_rows):
        for c in range(n_cols):
            ch = lines[r][c]
            if ch == '#':
                # Стена, пропускаем
                continue
            # Это «свободная» клетка (или с объектом), добавим в список
            cell = cell_name(r, c)
            free_cells.append((r, c))

            # Смотрим, что именно
            if ch in ('X', 's', 'c'):
                # Это цель
                goal_cells.append((r, c))

            if ch in ('S', 's'):
                # Позиция игрока
                player_pos = (r, c)
            if ch in ('C', 'c'):
                # Позиция камня
                stone_pos = (r, c)

    # Теперь формируем факты isgoal(...) / isnongoal(...)
    for (r, c) in free_cells:
        cell = cell_name(r, c)
        if (r, c) in goal_cells:
            facts.append(f"isgoal({cell}).")
        else:
            facts.append(f"isnongoal({cell}).")

    # Если хотим, чтобы цель — передвинуть stone_01 на все goal-клетки
    # (или хотя бы одну), можно добавить: goal(stone_01).
    # В классических примерах Sokoban нужно камни загнать на все X;
    # тут для простоты сделаем условие: "нужно загнать 1 камень на 1 goal"
    # (если на карте несколько X, это надо отдельно кодировать).
    facts.append(f"goal({stone_name}).")

    # Позиции игрока/камня (если они есть)
    if player_pos:
        facts.append(f"at({player_name},{cell_name(*player_pos)}).")
    if stone_pos:
        facts.append(f"at({stone_name},{cell_name(*stone_pos)}).")

    # Для всех свободных клеток, которые не заняты камнем/игроком, можно добавить clear(...)
    # (если камень/игрок не стоит там).
    # Но в классическом коде часто `clear(...)` предполагается, что клетка не занята ничем.
    # Проверим, занята ли (r,c) камнем/игроком:
    occupied_positions = set()
    if player_pos:
        occupied_positions.add(player_pos)
    if stone_pos:
        occupied_positions.add(stone_pos)

    for (r, c) in free_cells:
        if (r, c) not in occupied_positions:
            facts.append(f"clear({cell_name(r,c)}).")

    # Генерируем movedir(...) для соседних клеток (вверх/вниз/влево/вправо),
    # при условии, что обе клетки не стена.
    for (r, c) in free_cells:
        for (dr, dc, dname) in [(0,1,"dir_right"), (0,-1,"dir_left"),
                                (1,0,"dir_down"), (-1,0,"dir_up")]:
            nr, nc = r + dr, c + dc
            if (nr, nc) in free_cells:
                facts.append(f"movedir({cell_name(r,c)},{cell_name(nr,nc)},{dname}).")

    # Добавляем шаги (step(1), step(2), ..., step(max_steps))
    for st in range(1, max_steps+1):
        facts.append(f"step({st}).")

    # Склеиваем в одну строку
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

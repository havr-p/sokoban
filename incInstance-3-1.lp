% Определение игрока
player(p1).

% Определение камня
stone(s1).

% Определение локаций (три клетки в ряд)
% [p1,s1][ ][g]
location(loc1;loc2;loc3).

% Определение целевых и не-целевых локаций
isgoal(loc3).
isnongoal(loc1;loc2).

% Направления движения между локациями (слева направо и обратно)
movedir(loc1,loc2,dir_right).
movedir(loc2,loc1,dir_left).
movedir(loc2,loc3,dir_right).
movedir(loc3,loc2,dir_left).

% Начальное состояние
init(at(p1,loc1)). % игрок в левой клетке
init(at(s1,loc2)). % камень в средней клетке
init(clear(loc3)). % правая клетка пуста

% Целевое состояние
goal(at(s1,loc3)). % камень должен быть в правой клетке
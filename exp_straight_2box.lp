% Базовые определения объектов и целей
player(player_01).
stone(stone_01).
stone(stone_02).
isgoal(pos_4_2).
isgoal(pos_2_2).

% Определение нецелевых позиций (исключаем целевые позиции из списка)
isnongoal(pos_1_1). isnongoal(pos_1_2). isnongoal(pos_1_3).
isnongoal(pos_2_1). isnongoal(pos_2_3).
isnongoal(pos_3_1). isnongoal(pos_3_2). isnongoal(pos_3_3).
isnongoal(pos_4_1). isnongoal(pos_4_3).
isnongoal(pos_5_1). isnongoal(pos_5_2). isnongoal(pos_5_3).
isnongoal(pos_6_1). isnongoal(pos_6_2). isnongoal(pos_6_3).

% Определение возможных движений в каждом направлении
% Горизонтальные движения
movedir(pos_2_2,pos_3_2,dir_right). movedir(pos_3_2,pos_2_2,dir_left).
movedir(pos_3_2,pos_4_2,dir_right). movedir(pos_4_2,pos_3_2,dir_left).
movedir(pos_4_2,pos_5_2,dir_right). movedir(pos_5_2,pos_4_2,dir_left).
movedir(pos_5_2,pos_6_2,dir_right). movedir(pos_6_2,pos_5_2,dir_left).

% Вертикальные движения
movedir(pos_2_1,pos_2_2,dir_down). movedir(pos_2_2,pos_2_1,dir_up).
movedir(pos_2_2,pos_2_3,dir_down). movedir(pos_2_3,pos_2_2,dir_up).
movedir(pos_3_1,pos_3_2,dir_down). movedir(pos_3_2,pos_3_1,dir_up).
movedir(pos_3_2,pos_3_3,dir_down). movedir(pos_3_3,pos_3_2,dir_up).
movedir(pos_4_1,pos_4_2,dir_down). movedir(pos_4_2,pos_4_1,dir_up).
movedir(pos_4_2,pos_4_3,dir_down). movedir(pos_4_3,pos_4_2,dir_up).
movedir(pos_5_1,pos_5_2,dir_down). movedir(pos_5_2,pos_5_1,dir_up).
movedir(pos_5_2,pos_5_3,dir_down). movedir(pos_5_3,pos_5_2,dir_up).

% Начальное состояние
at(player_01,pos_4_2).
at(stone_01,pos_5_2).
at(stone_02,pos_3_2).
goal(stone_01).
goal(stone_02).
clear(pos_2_2).
clear(pos_6_2).
step(1..8).
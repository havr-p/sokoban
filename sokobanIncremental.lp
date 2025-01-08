#include <incmode>.
#program base.

% Определение направлений движения
direction(dir_up; dir_down; dir_left; dir_right).

% Соединение клеток по направлениям (будет задаваться в инстансе)
% movedir(From, To, Direction) означает, что из клетки From можно попасть в To двигаясь в направлении Direction
% Это базовое определение для корректности типов
movedir(L1,L2,D) :- location(L1), location(L2), direction(D).

% Определение типов локаций
location(L) :- isgoal(L).    % если клетка целевая - она локация
location(L) :- isnongoal(L). % если клетка не целевая - она локация
location(L) :- at(O,L).      % если на клетке что-то есть - она локация

% Определение начального состояния
holds(F,0) :- init(F).       % все начальные факты верны в момент 0

% Вспомогательные предикаты для камней
stone_at_goal(S,0) :- stone(S), at(S,L), isgoal(L).  % камень на целевой позиции
stone_not_at_goal(S,0) :- stone(S), at(S,L), isnongoal(L). % камень не на целевой позиции

% Определение свободных клеток в начальном состоянии
clear(L,0) :- location(L), not at(_,L).  % клетка свободна если на ней ничего нет

% Определение условий корректности
:- at(O1,L), at(O2,L), O1 != O2.  % на одной клетке не может быть двух объектов
:- at(O,L), not location(L).       % объект может быть только на существующей локации
:- stone(S), not at(S,_).          % каждый камень должен быть где-то
:- player(P), not at(P,_).         % игрок должен быть где-то

#program step(t).

% Генерация действий - на каждом шаге должно быть ровно одно действие
1 <= {
    % Перемещение игрока
    move(P,From,To,Dir,t) : 
        player(P),
        movedir(From,To,Dir),
        From != To;

    % Толкание камня на не-целевую позицию
    pushtonongoal(P,S,Ppos,From,To,Dir,t) : 
        player(P),
        stone(S),
        movedir(Ppos,From,Dir),
        movedir(From,To,Dir),
        isnongoal(To),
        Ppos != To,
        Ppos != From,
        From != To;

    % Толкание камня на целевую позицию
    pushtogoal(P,S,Ppos,From,To,Dir,t) :
        player(P),
        stone(S),
        movedir(Ppos,From,Dir),
        movedir(From,To,Dir),
        isgoal(To),
        Ppos != To,
        Ppos != From,
        From != To;

    % Действие "ничего не делать"
    noop(t)
} <= 1 :- step(t).

% Предусловия для движения
preconditions_m(P,From,To,Dir,t) :- 
    holds(at(P,From),t-1),
    holds(clear(To),t-1),
    movedir(From,To,Dir),
    player(P),
    From != To.

% Предусловия для толкания на не-целевую клетку
preconditions_png(P,S,Ppos,From,To,Dir,t) :- 
    holds(at(P,Ppos),t-1),
    holds(at(S,From),t-1),
    holds(clear(To),t-1),
    movedir(Ppos,From,Dir),
    movedir(From,To,Dir),
    isnongoal(To),
    player(P),
    stone(S),
    Ppos != To,
    Ppos != From,
    From != To.

% Предусловия для толкания на целевую клетку
preconditions_pg(P,S,Ppos,From,To,Dir,t) :- 
    holds(at(P,Ppos),t-1),
    holds(at(S,From),t-1),
    holds(clear(To),t-1),
    movedir(Ppos,From,Dir),
    movedir(From,To,Dir),
    isgoal(To),
    player(P),
    stone(S),
    Ppos != To,
    Ppos != From,
    From != To.

% Запрет действий без выполнения предусловий
:- move(P,From,To,Dir,t), not preconditions_m(P,From,To,Dir,t).
:- pushtonongoal(P,S,Ppos,From,To,Dir,t), not preconditions_png(P,S,Ppos,From,To,Dir,t).
:- pushtogoal(P,S,Ppos,From,To,Dir,t), not preconditions_pg(P,S,Ppos,From,To,Dir,t).

% Эффекты действий
% Для перемещения игрока
holds(at(P,To),t) :- move(P,From,To,Dir,t).
holds(clear(From),t) :- move(P,From,To,Dir,t).
del(at(P,From),t) :- move(P,From,To,Dir,t).
del(clear(To),t) :- move(P,From,To,Dir,t).

% Для толкания на не-целевую клетку
holds(at(P,From),t) :- pushtonongoal(P,S,Ppos,From,To,Dir,t).
holds(at(S,To),t) :- pushtonongoal(P,S,Ppos,From,To,Dir,t).
holds(clear(Ppos),t) :- pushtonongoal(P,S,Ppos,From,To,Dir,t).
del(at(P,Ppos),t) :- pushtonongoal(P,S,Ppos,From,To,Dir,t).
del(at(S,From),t) :- pushtonongoal(P,S,Ppos,From,To,Dir,t).
del(clear(To),t) :- pushtonongoal(P,S,Ppos,From,To,Dir,t).
del(stone_at_goal(S),t) :- pushtonongoal(P,S,Ppos,From,To,Dir,t).

% Для толкания на целевую клетку
holds(at(P,From),t) :- pushtogoal(P,S,Ppos,From,To,Dir,t).
holds(at(S,To),t) :- pushtogoal(P,S,Ppos,From,To,Dir,t).
holds(clear(Ppos),t) :- pushtogoal(P,S,Ppos,From,To,Dir,t).
holds(stone_at_goal(S),t) :- pushtogoal(P,S,Ppos,From,To,Dir,t).
del(at(P,Ppos),t) :- pushtogoal(P,S,Ppos,From,To,Dir,t).
del(at(S,From),t) :- pushtogoal(P,S,Ppos,From,To,Dir,t).
del(clear(To),t) :- pushtogoal(P,S,Ppos,From,To,Dir,t).

% Инерция - сохранение состояний
holds(F,t) :- holds(F,t-1), not del(F,t).

#program check(t).
#external query(t).

% Проверка достижения цели - все целевые камни должны быть на своих местах
:- query(t), goal(F), not holds(F,t).

% Показываем все возможные действия
#show move/5.
#show pushtonongoal/7.
#show pushtogoal/7.
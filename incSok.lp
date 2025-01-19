%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1) БАЗОВАЯ ПРОГРАММА
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#program base.

% Определение Sokoban и ящиков
sokoban(sokoban).
crate(crate_01).
location(l1;l2;l3;l4;l5;l6;l7;l8;l9;l10;l11;l12;l13;l14;l15;l16;l17;l18;l19;l20;l21;l22;l23;l24;l25;l26;l27).
isgoal(l17).
isnongoal(l11;l12;l13;l14;l15;l16).
wall(l1;l2;l3;l4;l5;l6;l7;l8;l9;l10;l18;l19;l20;l21;l22;l23;l24;l25;l26;l27).
leftOf(l1, l2).
below(l10, l1).
leftOf(l2, l3).
below(l11, l2).
leftOf(l3, l4).
below(l12, l3).
leftOf(l4, l5).
below(l13, l4).
leftOf(l5, l6).
below(l14, l5).
leftOf(l6, l7).
below(l15, l6).
leftOf(l7, l8).
below(l16, l7).
leftOf(l8, l9).
below(l17, l8).
below(l18, l9).
leftOf(l10, l11).
below(l19, l10).
leftOf(l11, l12).
below(l20, l11).
leftOf(l12, l13).
below(l21, l12).
leftOf(l13, l14).
below(l22, l13).
leftOf(l14, l15).
below(l23, l14).
leftOf(l15, l16).
below(l24, l15).
leftOf(l16, l17).
below(l25, l16).
leftOf(l17, l18).
below(l26, l17).
below(l27, l18).
leftOf(l19, l20).
leftOf(l20, l21).
leftOf(l21, l22).
leftOf(l22, l23).
leftOf(l23, l24).
leftOf(l24, l25).
leftOf(l25, l26).
leftOf(l26, l27).
at(sokoban, l11, 0).
at(crate_01, l14, 0).
clear(l12, 0).
clear(l13, 0).
clear(l15, 0).
clear(l16, 0).
clear(l17, 0).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2) ПРОГРАММА ШАГА
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#program step(t).

% Генерация возможных ходов
{ do(M,t) : move(M) } 1 :- time(t), t < maxsteps.

% Предусловия для moveLeft
:- do(moveLeft(S,X,Y), t), not holds(at(S,X), t-1).
:- do(moveLeft(S,X,Y), t), not holds(clear(Y), t-1).

% Предусловия для moveRight
:- do(moveRight(S,X,Y), t), not holds(at(S,X), t-1).
:- do(moveRight(S,X,Y), t), not holds(clear(Y), t-1).

% Предусловия для moveUp
:- do(moveUp(S,X,Y), t), not holds(at(S,X), t-1).
:- do(moveUp(S,X,Y), t), not holds(clear(Y), t-1).

% Предусловия для moveDown
:- do(moveDown(S,X,Y), t), not holds(at(S,X), t-1).
:- do(moveDown(S,X,Y), t), not holds(clear(Y), t-1).

% Предусловия для pushLeft
:- do(pushLeft(S,X,Y,Z,C), t), not holds(at(S,X), t-1).
:- do(pushLeft(S,X,Y,Z,C), t), not holds(at(C,Y), t-1).
:- do(pushLeft(S,X,Y,Z,C), t), not holds(clear(Z), t-1).

% Предусловия для pushRight
:- do(pushRight(S,X,Y,Z,C), t), not holds(at(S,X), t-1).
:- do(pushRight(S,X,Y,Z,C), t), not holds(at(C,Y), t-1).
:- do(pushRight(S,X,Y,Z,C), t), not holds(clear(Z), t-1).

% Предусловия для pushUp
:- do(pushUp(S,X,Y,Z,C), t), not holds(at(S,X), t-1).
:- do(pushUp(S,X,Y,Z,C), t), not holds(at(C,Y), t-1).
:- do(pushUp(S,X,Y,Z,C), t), not holds(clear(Z), t-1).

% Предусловия для pushDown
:- do(pushDown(S,X,Y,Z,C), t), not holds(at(S,X), t-1).
:- do(pushDown(S,X,Y,Z,C), t), not holds(at(C,Y), t-1).
:- do(pushDown(S,X,Y,Z,C), t), not holds(clear(Z), t-1).

% Эффекты для moveLeft
holds(at(sokoban, Y), t) :- do(moveLeft(sokoban,X,Y), t), holds(at(sokoban,X), t-1), holds(clear(Y), t-1).
-holds(at(sokoban, X), t) :- do(moveLeft(sokoban,X,Y), t), holds(at(sokoban,X), t-1).
holds(clear(X), t) :- do(moveLeft(sokoban,X,Y), t), holds(at(sokoban,X), t-1), holds(clear(Y), t-1).
-holds(clear(Y), t) :- do(moveLeft(sokoban,X,Y), t), holds(at(sokoban,X), t-1), holds(clear(Y), t-1).

% Эффекты для moveRight
holds(at(sokoban, Y), t) :- do(moveRight(sokoban,X,Y), t), holds(at(sokoban,X), t-1), holds(clear(Y), t-1).
-holds(at(sokoban, X), t) :- do(moveRight(sokoban,X,Y), t), holds(at(sokoban,X), t-1).
holds(clear(X), t) :- do(moveRight(sokoban,X,Y), t), holds(at(sokoban,X), t-1), holds(clear(Y), t-1).
-holds(clear(Y), t) :- do(moveRight(sokoban,X,Y), t), holds(at(sokoban,X), t-1), holds(clear(Y), t-1).

% Эффекты для moveUp
holds(at(sokoban, Y), t) :- do(moveUp(sokoban,X,Y), t), holds(at(sokoban,X), t-1), holds(clear(Y), t-1).
-holds(at(sokoban, X), t) :- do(moveUp(sokoban,X,Y), t), holds(at(sokoban,X), t-1).
holds(clear(X), t) :- do(moveUp(sokoban,X,Y), t), holds(at(sokoban,X), t-1), holds(clear(Y), t-1).
-holds(clear(Y), t) :- do(moveUp(sokoban,X,Y), t), holds(at(sokoban,X), t-1), holds(clear(Y), t-1).

% Эффекты для moveDown
holds(at(sokoban, Y), t) :- do(moveDown(sokoban,X,Y), t), holds(at(sokoban,X), t-1), holds(clear(Y), t-1).
-holds(at(sokoban, X), t) :- do(moveDown(sokoban,X,Y), t), holds(at(sokoban,X), t-1).
holds(clear(X), t) :- do(moveDown(sokoban,X,Y), t), holds(at(sokoban,X), t-1), holds(clear(Y), t-1).
-holds(clear(Y), t) :- do(moveDown(sokoban,X,Y), t), holds(at(sokoban,X), t-1), holds(clear(Y), t-1).

% Эффекты для pushLeft
holds(at(sokoban, Y), t) :- do(pushLeft(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(at(sokoban, X), t) :- do(pushLeft(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1).
holds(at(crate_01, Z), t) :- do(pushLeft(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(at(crate_01, Y), t) :- do(pushLeft(sokoban,X,Y,Z,crate_01), t), holds(at(crate_01,Y), t-1).
holds(clear(X), t) :- do(pushLeft(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(clear(Z), t) :- do(pushLeft(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(clear(Y), t) :- do(pushLeft(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).

% Эффекты для pushRight
holds(at(sokoban, Y), t) :- do(pushRight(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(at(sokoban, X), t) :- do(pushRight(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1).
holds(at(crate_01, Z), t) :- do(pushRight(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(at(crate_01, Y), t) :- do(pushRight(sokoban,X,Y,Z,crate_01), t), holds(at(crate_01,Y), t-1).
holds(clear(X), t) :- do(pushRight(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(clear(Z), t) :- do(pushRight(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(clear(Y), t) :- do(pushRight(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).

% Эффекты для pushUp
holds(at(sokoban, Y), t) :- do(pushUp(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(at(sokoban, X), t) :- do(pushUp(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1).
holds(at(crate_01, Z), t) :- do(pushUp(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(at(crate_01, Y), t) :- do(pushUp(sokoban,X,Y,Z,crate_01), t), holds(at(crate_01,Y), t-1).
holds(clear(X), t) :- do(pushUp(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(clear(Z), t) :- do(pushUp(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(clear(Y), t) :- do(pushUp(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).

% Эффекты для pushDown
holds(at(sokoban, Y), t) :- do(pushDown(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(at(sokoban, X), t) :- do(pushDown(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1).
holds(at(crate_01, Z), t) :- do(pushDown(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(at(crate_01, Y), t) :- do(pushDown(sokoban,X,Y,Z,crate_01), t), holds(at(crate_01,Y), t-1).
holds(clear(X), t) :- do(pushDown(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(clear(Z), t) :- do(pushDown(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).
-holds(clear(Y), t) :- do(pushDown(sokoban,X,Y,Z,crate_01), t), holds(at(sokoban,X), t-1), holds(at(crate_01,Y), t-1), holds(clear(Z), t-1).

% Deadlock definitions
adjacentWallLeftOrRight(L) :- wall(L1), leftOf(L, L1).
adjacentWallLeftOrRight(L) :- wall(L1), leftOf(L1, L).

adjacentWallAboveOrBelow(L) :- wall(L2), below(L, L2).
adjacentWallAboveOrBelow(L) :- wall(L2), below(L2, L).

deadlock(L) :-
    location(L),
    adjacentWallLeftOrRight(L),
    adjacentWallAboveOrBelow(L),
    not isgoal(L).

% Запрет на перемещение ящика в тупиковую клетку
:- do(pushLeft(S,X,Y,Z,C), T), deadlock(Z).
:- do(pushRight(S,X,Y,Z,C), T), deadlock(Z).
:- do(pushUp(S,X,Y,Z,C), T), deadlock(Z).
:- do(pushDown(S,X,Y,Z,C), T), deadlock(Z).

% Запрет на перемещение ящика в стену
:- do(pushLeft(S,X,Y,Z,C), T), wall(Z).
:- do(pushRight(S,X,Y,Z,C), T), wall(Z).
:- do(pushUp(S,X,Y,Z,C), T), wall(Z).
:- do(pushDown(S,X,Y,Z,C), T), wall(Z).

% Запрет на перемещение Sokoban в стену
:- do(moveLeft(S,X,Y), T), wall(Y).
:- do(moveRight(S,X,Y), T), wall(Y).
:- do(moveUp(S,X,Y), T), wall(Y).
:- do(moveDown(S,X,Y), T), wall(Y).

% Инерция: объекты остаются на местах, если не изменились
holds(F,t) :- holds(F,t-1), not -holds(F,t).
-holds(F,t) :- holds(F,t-1), not holds(F,t).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3) ПРОГРАММА ПРОВЕРКИ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#program check(t).
#external query(t).

% Проверка, что все ящики достигли целей
reached_goal(C,t) :- holds(at(C,L),t), isgoal(L), crate(C).

% Требуем, чтобы все ящики достигли целей
:- query(t), crate(C), not reached_goal(C,t).

% Запрет на оставание Sokoban на месте, если цели еще не достигнуты
:- query(t), holds(at(sokoban,L),t), holds(at(sokoban,L),t-1), not goal_achieved(t-1).

% Определение момента достижения цели
goal_achieved(t) :- reached_goal(C,t), crate(C).

#show do/2.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4) ЦЕЛЬ: ЯЩИК В L2 (ХОТЯ БЫ В ОДИН МОМЕНТ ВРЕМЕНИ)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- isgoal(L), isnongoal(L).

% reachedGoal(C) — говорит, что ящик C
% в некоторый момент T оказался в клетке L, помеченной как isgoal(L).
reachedGoal(C) :- at(C,L,T), isgoal(L), time(T).

% Требуем, чтобы для КАЖДОГО ящика было доказуемо reachedGoal(C).
% Если найдётся хотя бы один ящик, у которого reachedGoal(C) не выполнится,
% программа станет непротиворечивой только при нарушении этого правила, что нельзя.
:- crate(C), not reachedGoal(C).

% Если сокобан S находится в двух разных локациях L1 и L2
% в один и тот же момент T, это запрещено.
:- at(sokoban, L1, T), at(sokoban, L2, T), L1 != L2.

% crate C не может находиться в (L1) и (L2) в момент T, если L1 != L2
:- crate(C), at(C, L1, T), at(C, L2, T), L1 != L2.

% Два ящика C1 и C2 не могут оказаться в одной клетке L в момент T
:- crate(C1), crate(C2), C1 != C2, at(C1, L, T), at(C2, L, T).

% Сокобан и ящик не могут находиться в одной клетке L в момент T
:- crate(C), at(C, L, T), at(sokoban, L, T).

% Стена слева или справа от клетки L
adjacentWallLeftOrRight(L) :- wall(L1), leftOf(L, L1).
adjacentWallLeftOrRight(L) :- wall(L1), leftOf(L1, L).

% Стена сверху или снизу от клетки L
adjacentWallAboveOrBelow(L) :- wall(L2), below(L, L2).
adjacentWallAboveOrBelow(L) :- wall(L2), below(L2, L).

% Клетка считается тупиком, если она соседствует с двумя стенами (слева/справа и сверху/снизу),
% а также сама не является целью
deadlock(L) :-
    location(L),
    adjacentWallLeftOrRight(L),
    adjacentWallAboveOrBelow(L),
    not isgoal(L).

% Запрет на перемещение ящика в тупиковую клетку
:- do(push(C, L1, L2), T), deadlock(L2).
:- do(push(C, L1, L2), T), wall(L2).
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 5) ВЫБОР ДЕЙСТВИЙ: ровно 1 действие на шаг
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Для каждого T < maxsteps: выбираем 1 из всех move/push (с подходящими параметрами),
% или вообще никакого действия, если хотите - тогда меняйте 1{..}1 на 0..1{..}.
%
% Но ниже мы генерим "граничное" множество ground-действий через правила.
% 
% Способ А: отдельный предикат do(Action,T). 
% Способ Б: напрямую "moveLeft(S,X,Y,T)" как действие. 
% Я покажу способ А, чтобы было ближе к классической записи:

{ do(M,T) : move(M) } 1 :- time(T), T < maxsteps.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 6) ОПРЕДЕЛЕНИЕ "move(M)" (ГЕНЕРАЦИЯ ВСЕХ ВОЗМОЖНЫХ ДЕЙСТВИЙ)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Мы не пишем action(...), а сразу "move(...)" — любой ground-term:
% moveLeft(S,X,Y), pushLeft(S,X,Y,Z,C), etc.

% --- moveLeft ---
move(moveLeft(S,X,Y)) :-
  sokoban(S),
  location(X;Y),
  leftOf(Y,X).

% --- moveRight ---
move(moveRight(S,X,Y)) :-
  sokoban(S),
  location(X;Y),
  leftOf(X,Y).

% --- moveUp ---
move(moveUp(S,X,Y)) :-
  sokoban(S),
  location(X;Y),
  below(X,Y).

% --- moveDown ---
move(moveDown(S,X,Y)) :-
  sokoban(S),
  location(X;Y),
  below(Y,X).

% --- pushLeft ---
move(pushLeft(S,X,Y,Z,C)) :-
  sokoban(S), crate(C),
  location(X;Y;Z),
  leftOf(Y,X),
  leftOf(Z,Y).

% --- pushRight ---
move(pushRight(S,X,Y,Z,C)) :-
  sokoban(S), crate(C),
  location(X;Y;Z),
  leftOf(X,Y),
  leftOf(Y,Z).

% --- pushUp ---
move(pushUp(S,X,Y,Z,C)) :-
  sokoban(S), crate(C),
  location(X;Y;Z),
  below(X,Y),
  below(Y,Z).

% --- pushDown ---
move(pushDown(S,X,Y,Z,C)) :-
  sokoban(S), crate(C),
  location(X;Y;Z),
  below(Y,X),
  below(Z,Y).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 7) ИНЕРЦИЯ (БЕЗ holds(...), a at(...,T) -> at(...,T+1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% "Если объект O был в локации L в момент T, и нет доказательства,
%  что он перестал там быть в момент T+1, то он остаётся."
at(O,L,T+1) :-
  at(O,L,T),
  not -at(O,L,T+1),
  time(T).

% Точно так же для clear(L,T)
clear(L,T+1) :-
  clear(L,T),
  not -clear(L,T+1),
  time(T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 8) ПРЕДУСЛОВИЯ (ОГРАНИЧЕНИЯ)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Если действие moveLeft(S,X,Y) выбрано, то sokoban S ДОЛЖЕН находиться в X на шаге T,
% и Y ДОЛЖНО быть clear на шаге T.

% moveLeft
:- do(moveLeft(S,X,Y), T), not at(S,X,T).
:- do(moveLeft(S,X,Y), T), not clear(Y,T).

% moveRight
:- do(moveRight(S,X,Y), T), not at(S,X,T).
:- do(moveRight(S,X,Y), T), not clear(Y,T).

% moveUp
:- do(moveUp(S,X,Y), T), not at(S,X,T).
:- do(moveUp(S,X,Y), T), not clear(Y,T).

% moveDown
:- do(moveDown(S,X,Y), T), not at(S,X,T).
:- do(moveDown(S,X,Y), T), not clear(Y,T).

% pushLeft
:- do(pushLeft(S,X,Y,Z,C), T), not at(S,X,T).
:- do(pushLeft(S,X,Y,Z,C), T), not at(C,Y,T).
:- do(pushLeft(S,X,Y,Z,C), T), not clear(Z,T).

% pushRight
:- do(pushRight(S,X,Y,Z,C), T), not at(S,X,T).
:- do(pushRight(S,X,Y,Z,C), T), not at(C,Y,T).
:- do(pushRight(S,X,Y,Z,C), T), not clear(Z,T).

% pushUp
:- do(pushUp(S,X,Y,Z,C), T), not at(S,X,T).
:- do(pushUp(S,X,Y,Z,C), T), not at(C,Y,T).
:- do(pushUp(S,X,Y,Z,C), T), not clear(Z,T).

% pushDown
:- do(pushDown(S,X,Y,Z,C), T), not at(S,X,T).
:- do(pushDown(S,X,Y,Z,C), T), not at(C,Y,T).
:- do(pushDown(S,X,Y,Z,C), T), not clear(Z,T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 9) ПОЛОЖИТЕЛЬНЫЕ И ОТРИЦАТЕЛЬНЫЕ ЭФФЕКТЫ
%%    (НЕТ holds(...) => ЯВНО at(...,T+1) И -at(...,T+1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%========== moveLeft ==========

% (а) Если sokoban шёл слева-направо, то на T+1 сокобан в Y
at(S, Y, T+1) :-
  do(moveLeft(S,X,Y), T),
  at(S,X,T),
  clear(Y,T).

% (б) Убираем "sokoban в X" на T+1
-at(S, X, T+1) :-
  do(moveLeft(S,X,Y), T),
  at(S,X,T).

% (в) Старая клетка X освобождается
clear(X,T+1) :-
  do(moveLeft(S,X,Y), T),
  at(S,X,T),
  clear(Y,T).

% (г) Новая клетка Y перестаёт быть свободной
-clear(Y,T+1) :-
  do(moveLeft(S,X,Y), T),
  at(S,X,T),
  clear(Y,T).

%========== moveRight ==========

at(S,Y,T+1) :-
  do(moveRight(S,X,Y), T),
  at(S,X,T),
  clear(Y,T).

-at(S,X,T+1) :-
  do(moveRight(S,X,Y), T),
  at(S,X,T).

clear(X,T+1) :-
  do(moveRight(S,X,Y), T),
  at(S,X,T),
  clear(Y,T).

-clear(Y,T+1) :-
  do(moveRight(S,X,Y), T),
  at(S,X,T),
  clear(Y,T).

%========== moveUp ==========

at(S,Y,T+1) :-
  do(moveUp(S,X,Y), T),
  at(S,X,T),
  clear(Y,T).

-at(S,X,T+1) :-
  do(moveUp(S,X,Y), T),
  at(S,X,T).

clear(X,T+1) :-
  do(moveUp(S,X,Y), T),
  at(S,X,T),
  clear(Y,T).

-clear(Y,T+1) :-
  do(moveUp(S,X,Y), T),
  at(S,X,T),
  clear(Y,T).

%========== moveDown ==========

at(S,Y,T+1) :-
  do(moveDown(S,X,Y), T),
  at(S,X,T),
  clear(Y,T).

-at(S,X,T+1) :-
  do(moveDown(S,X,Y), T),
  at(S,X,T).

clear(X,T+1) :-
  do(moveDown(S,X,Y), T),
  at(S,X,T),
  clear(Y,T).

-clear(Y,T+1) :-
  do(moveDown(S,X,Y), T),
  at(S,X,T),
  clear(Y,T).

%========== pushLeft ==========

% pushLeft(S,X,Y,Z,C): sokoban в X, ящик в Y, Z свободно,
% толкаем ящик с Y на Z, а сокoban переходит с X на Y

at(S, Y, T+1) :-
  do(pushLeft(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

-at(S,X,T+1) :-
  do(pushLeft(S,X,Y,Z,C), T),
  at(S,X,T).

at(C, Z, T+1) :-
  do(pushLeft(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

-at(C,Y,T+1) :-
  do(pushLeft(S,X,Y,Z,C), T),
  at(C,Y,T).

clear(X,T+1) :-
  do(pushLeft(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

% Новая локация Z перестаёт быть свободной
-clear(Z,T+1) :-
  do(pushLeft(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

% Локация Y теперь будет занята сокобаном, так что
% она перестаёт быть free
-clear(Y,T+1) :-
  do(pushLeft(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

%========== pushRight ==========

at(S, Y, T+1) :-
  do(pushRight(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

-at(S,X,T+1) :-
  do(pushRight(S,X,Y,Z,C), T),
  at(S,X,T).

at(C,Z,T+1) :-
  do(pushRight(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

-at(C,Y,T+1) :-
  do(pushRight(S,X,Y,Z,C), T),
  at(C,Y,T).

clear(X,T+1) :-
  do(pushRight(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

-clear(Z,T+1) :-
  do(pushRight(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

-clear(Y,T+1) :-
  do(pushRight(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

%========== pushUp ==========

at(S,Y,T+1) :-
  do(pushUp(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

-at(S,X,T+1) :-
  do(pushUp(S,X,Y,Z,C), T),
  at(S,X,T).

at(C,Z,T+1) :-
  do(pushUp(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

-at(C,Y,T+1) :-
  do(pushUp(S,X,Y,Z,C), T),
  at(C,Y,T).

clear(X,T+1) :-
  do(pushUp(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

-clear(Z,T+1) :-
  do(pushUp(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

-clear(Y,T+1) :-
  do(pushUp(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

%========== pushDown ==========

at(S,Y,T+1) :-
  do(pushDown(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

-at(S,X,T+1) :-
  do(pushDown(S,X,Y,Z,C), T),
  at(S,X,T).

at(C,Z,T+1) :-
  do(pushDown(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

-at(C,Y,T+1) :-
  do(pushDown(S,X,Y,Z,C), T),
  at(C,Y,T).

clear(X,T+1) :-
  do(pushDown(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

-clear(Z,T+1) :-
  do(pushDown(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

-clear(Y,T+1) :-
  do(pushDown(S,X,Y,Z,C), T),
  at(S,X,T),
  at(C,Y,T),
  clear(Z,T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 10) МИНИМИЗАЦИЯ КОЛИЧЕСТВА ШАГОВ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#minimize { 1,T : do(M,T) }.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 11) ВЫВОД ДЕЙСТВИЙ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#show do/2.
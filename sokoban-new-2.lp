%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1) ПАРАМЕТРЫ И ВРЕМЯ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sokoban(sokoban).
crate(crate_01).
crate(crate_02).
crate(crate_03).
location(l1;l2;l3;l4;l5;l6;l7;l8;l9;l10;l11;l12;l13;l14;l15;l16;l17;l18;l19;l20;l21;l22;l23;l24;l25;l26;l27;l28;l29;l30).
isgoal(l8;l17;l20).
isnongoal(l1;l2;l3;l4;l5;l6;l7;l9;l10;l11;l12;l13;l14;l15;l16;l18;l19;l21;l22;l23;l24;l25;l26;l27;l28;l29;l30).
leftOf(l1, l2).
below(l1, l7).
leftOf(l2, l3).
below(l2, l8).
leftOf(l3, l4).
below(l3, l9).
leftOf(l4, l5).
below(l4, l10).
leftOf(l5, l6).
below(l5, l11).
below(l6, l12).
leftOf(l7, l8).
below(l7, l13).
leftOf(l8, l9).
below(l8, l14).
leftOf(l9, l10).
below(l9, l15).
leftOf(l10, l11).
below(l10, l16).
leftOf(l11, l12).
below(l11, l17).
below(l12, l18).
leftOf(l13, l14).
below(l13, l19).
leftOf(l14, l15).
below(l14, l20).
leftOf(l15, l16).
below(l15, l21).
leftOf(l16, l17).
below(l16, l22).
leftOf(l17, l18).
below(l17, l23).
below(l18, l24).
leftOf(l19, l20).
below(l19, l25).
leftOf(l20, l21).
below(l20, l26).
leftOf(l21, l22).
below(l21, l27).
leftOf(l22, l23).
below(l22, l28).
leftOf(l23, l24).
below(l23, l29).
below(l24, l30).
leftOf(l25, l26).
leftOf(l26, l27).
leftOf(l27, l28).
leftOf(l28, l29).
leftOf(l29, l30).
at(sokoban, l8, 0).
at(crate_00, l16, 0).
at(crate_01, l14, 0).
at(crate_02, l15, 0).
clear(l9, 0).
clear(l10, 0).
clear(l11, 0).
clear(l17, 0).
clear(l20, 0).
clear(l21, 0).
clear(l22, 0).
clear(l23, 0).
#const maxsteps=20.
time(0..maxsteps).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2) ОПРЕДЕЛЕНИЕ ДОСТИЖЕНИЯ ЦЕЛИ КАЖДЫМ ЯЩИКОМ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- isgoal(L), isnongoal(L).

% reachedGoal(C) — говорит, что ящик C
% в некоторый момент T оказался в клетке L, помеченной как isgoal(L).
reachedGoal(C) :- at(C,L,T), isgoal(L), time(T).

% Требуем, чтобы для КАЖДОГО ящика было доказуемо reachedGoal(C).
% Если найдётся хотя бы один ящик, у которого reachedGoal(C) не выполнится,
% программа станет непротиворечивой только при нарушении этого правила, что нельзя.
:- crate(C), not reachedGoal(C).

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

0 { do(M,T) : move(M) } 1 :- time(T), T < maxsteps.

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
#minimize { 1 : do(M,T) }.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 11) ВЫВОД ДЕЙСТВИЙ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#show do/2.

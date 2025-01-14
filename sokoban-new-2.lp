%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1) ПАРАМЕТРЫ И ВРЕМЯ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#const maxsteps=15.
time(0..maxsteps).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2) ОБЪЕКТЫ, ЛОКАЦИИ, СТАТИЧЕСКИЕ ОТНОШЕНИЯ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% У нас один сокобан, один ящик
sokoban(sokoban).
crate(crate2).

% Локации
location(l1;l2;l5;l6;l9;l10;l11;l12;l13;l14;l15;l16;l17;l18).

% Горизонтальные связи
leftOf(l1,l2).
leftOf(l5,l6).
leftOf(l9,l10). leftOf(l10,l11). leftOf(l11,l12).
leftOf(l13,l14). leftOf(l14,l15). leftOf(l15,l16).
leftOf(l17,l18).

% Вертикальные связи
below(l5,l1). below(l6,l2).
below(l9,l5). below(l10,l6).
below(l13,l9).  below(l14,l10). below(l15,l11). below(l16,l12).
below(l17,l13). below(l18,l14).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3) НАЧАЛЬНОЕ СОСТОЯНИЕ (ВМЕСТО holds(...) => at(...,0)/clear(...,0))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Сокобан и ящик на шагах T=0
at(sokoban, l10, 0).
at(crate2,  l15, 0).

% Какие локации свободны изначально (T=0)
clear(l1, 0).
clear(l2, 0).
clear(l5, 0).
clear(l6, 0).
clear(l9, 0).
clear(l11, 0).
clear(l12, 0).
clear(l13, 0).
clear(l14, 0).
clear(l16, 0).
clear(l17, 0).
clear(l18, 0).

% ВАЖНО: l10 и l15 НЕ свободны, т.к. там sokoban и crate2.
% По умолчанию не пишем clear(l10,0) и clear(l15,0).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4) ЦЕЛЬ: ЯЩИК В L2 (ХОТЯ БЫ В ОДИН МОМЕНТ ВРЕМЕНИ)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
goal :- at(crate2, l2, T), time(T).
:- not goal.

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

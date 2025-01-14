%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1) ПАРАМЕТРЫ И ВРЕМЯ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#const maxsteps=22.
time(0..maxsteps).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2) ОБЪЕКТЫ, ЛОКАЦИИ, СТАТИЧЕСКИЕ ОТНОШЕНИЯ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% У нас один сокобан, один ящик
sokoban(sokoban).
crate(crate2).
crate(crate1).

% Locations (grid style, left to right, top to bottom)
location(l1;l2;l3;l4;l5;l6;l7;
        l8;l9;l10;l11;l12;l13;l14;
        l15;l16;l17;l18;l19;l20;l21;
        l22;l23;l24;l25;l26;l27;l28;
        l29;l30;l31;l32;l33;l34;l35;
        l36;l37;l38;l39;l40;l41;l42;
        l43;l44;l45;l46;l47;l48;l49).

% Horizontal connections (leftOf)
leftOf(l30,l31). leftOf(l31,l32). leftOf(l32,l33). leftOf(l33,l34).
leftOf(l36,l37). leftOf(l37,l38). leftOf(l38,l39). leftOf(l39,l40). leftOf(l40,l41).
leftOf(l43,l44). leftOf(l44,l45). leftOf(l45,l46). leftOf(l46,l47). leftOf(l47,l48).

% Vertical connections (below)
below(l29,l22). below(l30,l23). below(l31,l24). below(l32,l25). below(l33,l26). below(l34,l27).
below(l36,l29). below(l37,l30). below(l38,l31). below(l39,l32). below(l40,l33). below(l41,l34).
below(l43,l36). below(l44,l37). below(l45,l38). below(l46,l39). below(l47,l40). below(l48,l41).

% Initial state
at(sokoban, l37, 0).  % S position
at(crate1, l39, 0).   % C position

% Clear locations initially
clear(l30, 0).
clear(l31, 0).
clear(l32, 0).
clear(l33, 0).
clear(l34, 0).
clear(l36, 0).
clear(l40, 0).
clear(l41, 0).
clear(l43, 0).
clear(l44, 0).
clear(l45, 0).
clear(l46, 0).
clear(l47, 0).
clear(l48, 0).

% Goal state
goal :- at(crate1, l31, T), time(T).
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

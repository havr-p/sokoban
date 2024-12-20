%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SOKOBAN Rules (ASP)
%%% Пример адаптации к чистому ASP синтаксису
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Определяем флюенты:
fluent(free(L)) :- location(L).
fluent(box_in(L)) :- location(L).
fluent(sokoban_in(L)) :- location(L).
fluent(reachable(A)) :- location(A).
non_inertial(reachable(A)) :- location(A).

% Действия:
action(push(From,D,To)) :-
   location(From),
   location(To),
   step(_Sokoban,D,From),
   straight_connection(From,To,D,_).

% Применимость действия (ранее указывалась через списки):
% Теперь просто указываем условия в теле правила.
executable(push(From,D,To)) :-
   action(push(From,D,To)),
   step(PushPlace,D,From),
   reachable(PushPlace),
   box_in(From),
   straight_connection(From,To,D,Path),
   path_no_boxes(Path).

% path_no_boxes(Path) должна гарантировать, что на пути нет коробок.
% Ранее вы пытались делать это через списки, теперь предположим,
% что straight_connection/4 порождает факты path_cell(Path,Cell), и мы проверяем,
% что на всех path_cell(Path,Cell) нет box_in(Cell).
% Пример (нужно адаптировать под вашу логику):
path_no_boxes(Path) :-
   not path_contains_box(Path).

path_contains_box(Path) :-
   path_cell(Path,L),
   box_in(L).

% Эффекты действия push:
causes(push(From,D,To), box_in(To)) :-
   action(push(From,D,To)).

causes(push(From,D,To), not box_in(From)) :-
   action(push(From,D,To)).

causes(push(From,D,To), sokoban_in(S)) :-
   action(push(From,D,To)),
   step(S,D,To).

causes(push(From,D,To), free(From)) :-
   action(push(From,D,To)),
   not step(From,D,To).

causes(push(From,D,To), free(S)) :-
   action(push(From,D,To)),
   location(S),
   S != To,
   not step(S,D,To),
   sokoban_in(S).

% Статические законы:
caused([sokoban_in(A)],reachable(A)) :-
    location(A).

caused([reachable(B),free(C)],reachable(C)) :-
    location(B),location(C),
    step(B,D,C),direction(D).

caused([free(L)], not box_in(L)) :- location(L).
caused([free(L)], not sokoban_in(L)) :- location(L).

caused([sokoban_in(L)], not free(L)) :- location(L).
caused([sokoban_in(L)], not box_in(L)) :- location(L).
caused([sokoban_in(L1)], not sokoban_in(L2)) :-
    location(L1),location(L2),L1 != L2.

caused([box_in(L)], not free(L)) :- location(L).
caused([box_in(L)], not sokoban_in(L)) :- location(L).

% Инициализация:
initially(box_in(L)) :- location(L), box(L).
initially(not box_in(L)) :- location(L), not box(L).

initially(sokoban_in(L)) :- location(L), sokoban(L).
initially(not sokoban_in(L)) :- location(L), not sokoban(L).

initially(free(L)) :- location(L), not box(L), not sokoban(L).
initially(not free(L)) :- location(L), box(L).
initially(not free(L)) :- location(L), sokoban(L).

initially(reachable(A)) :- location(A), sokoban(A).
initially(reachable(L)) :-
    location(L),
    sokoban(S),
    reach_path(S,L,[S]).
initially(not reachable(L)) :-
    location(L),
    not initially(reachable(L)).

% Цель
goal(box_in(L)) :- location(L), solution(L).

% Вспомогательные предикаты:
% reach_path/3 - изначально был prolog-стиль, его нужно заменить или 
% закодировать в ASP-стиле. Ниже просто заглушка.
% В реальном ASP вам нужно будет явно задавать факты о достижимости.
reach_path(From,From,_Visited).
reach_path(From,To,Visited) :-
    step(From,_,Int),
    not member(Int,Visited),
    not box(Int),
    reach_path(Int,To,[Int|Visited]).

% member/2 тоже Prolog-предикат. В ASP надо либо задавать множество
% посещённых как факты, либо иначе кодировать достижимость. Ниже - заглушка.
% Для ASP можно вообще убрать такой код или заменить на генерацию путей и проверку условий.

% location/1:
location(Loc) :-
   top(L1,L2), (Loc=L1; Loc=L2);
   right(L3,L4), (Loc=L3; Loc=L4).

direction(up).
direction(left).
direction(right).
direction(down).

% straight_connection - тоже была prolog-рекурсия. Нужно заранее задать все пути или 
% переписать логику. Здесь просто заглушка для примера:
straight_connection(From,From,_D,Path) :- Path=FromPath, FromPath=From.
straight_connection(From,To,D,Path) :-
   step(From,D,Int),
   % В реальном ASP нельзя просто "Path=[From|Rest]" - нужно генерировать факты типа:
   path_cell(Path,From),
   straight_connection(Int,To,D,Path).

step(From,right,To) :- right(From,To).
step(From,left,To) :- right(To,From).
step(From,up,To) :- top(From,To).
step(From,down,To) :- top(To,From).

% neq/2 заменен на сравнение !=

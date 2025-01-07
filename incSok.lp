%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1) #program base.  -- БАЗОВАЯ ЧАСТЬ (факты, нач. состояние)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#program base.

% -- Доменные факты. Примерно так (у вас может быть своя карта):
%    player(p1).      % игрок
%    stone(s1; s2).   % камни
%    isgoal(cell5).   % клетки, где цель
%    isnongoal(cell1; cell2; cell3; ...)   % обычные клетки
%    movedir(cell1,cell2,right). etc.
%    ... 
% Вместо этого блока вставьте свои определения из PDDL / PLASP и т.п.

% -- Инициальные факты (то, что в исходном коде задавалось через at(...,0), clear(...,0), atgoal(...,0))
%    Допустим, вы писали так:
%       at(P,To,0) :- at(P,To).
%       clear(P,0) :- clear(P).
%       atgoal(S,0) :- isgoal(S), stone(S), at(S,To).
%    В инкрементальном режиме удобнее сначала завести init(...):

init(at(P,Pos)) :- at(P,Pos).      
init(clear(Pos)) :- clear(Pos).
init(atgoal(S)) :- stone(S), isgoal(Pos), at(S,Pos).

% -- Правило, которое говорит: "Если что-то инициализировано, то при t=0 оно holds(...)":
holds(F,0) :- init(F).

% -- Также можно определить goal/1 (какой именно goal проверяем):
%    (Иногда goal(...) хранят здесь, иногда — в check(t).)
goal( atgoal(S) ) :- stone(S).

% Если у вас цель: "все камни должны быть на клетках-целях",
% можно оставить goal(atgoal(S)) и далее проверить, что все нужные S удовлетворяют.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2) #program step(t). -- ЛОГИКА ОДНОГО ШАГА
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#program step(t).

%---------------------
% GENERATE
%---------------------
% Ваше кардинальное ограничение:
% 1 <= { 
%   pushtonongoal( P,S,Ppos,From,To,Dir,t ) : ... ;
%   move( P,From,To,Dir,t ) : ... ;
%   pushtogoal( P,S,Ppos,From,To,Dir,t ) : ... ;
%   noop(t)
% } <= 1 :- step(t).

1 <= { 
  pushtonongoal(P,S,Ppos,From,To,Dir,t) : 
    movedir(Ppos,From,Dir),
    movedir(From,To,Dir),
    isnongoal(To),
    player(P),
    stone(S),
    Ppos != To,
    Ppos != From,
    From != To;

  move(P,From,To,Dir,t) :
    movedir(From,To,Dir),
    player(P),
    From != To;

  pushtogoal(P,S,Ppos,From,To,Dir,t) :
    movedir(Ppos,From,Dir),
    movedir(From,To,Dir),
    isgoal(To),
    player(P),
    stone(S),
    Ppos != To,
    Ppos != From,
    From != To;

  noop(t)
} <= 1 :- step(t).

%---------------------
% TEST (предусловия и прочие constraints)
%---------------------

% --- push-to-nongoal ---
:- pushtonongoal(P,S,Ppos,From,To,Dir,t),
   not preconditions_png(P,S,Ppos,From,To,Dir,t),
   movedir(Ppos,From,Dir),
   movedir(From,To,Dir),
   isnongoal(To),
   player(P),
   stone(S),
   Ppos != To, Ppos != From, From != To.

preconditions_png(P,S,Ppos,From,To,Dir,t) :-
   at(P,Ppos,t-1),
   at(S,From,t-1),
   clear(To,t-1),
   movedir(Ppos,From,Dir),
   movedir(From,To,Dir),
   isnongoal(To),
   player(P),
   stone(S),
   Ppos != To, Ppos != From, From != To,
   step(t).

% --- move ---
:- move(P,From,To,Dir,t),
   not preconditions_m(P,From,To,Dir,t),
   movedir(From,To,Dir),
   player(P),
   From != To.

preconditions_m(P,From,To,Dir,t) :-
   at(P,From,t-1),
   clear(To,t-1),
   movedir(From,To,Dir),
   player(P),
   From != To,
   step(t).

% --- push-to-goal ---
:- pushtogoal(P,S,Ppos,From,To,Dir,t),
   not preconditions_pg(P,S,Ppos,From,To,Dir,t),
   movedir(Ppos,From,Dir),
   movedir(From,To,Dir),
   isgoal(To),
   player(P),
   stone(S),
   Ppos != To, Ppos != From, From != To,
   step(t).

preconditions_pg(P,S,Ppos,From,To,Dir,t) :-
   at(P,Ppos,t-1),
   at(S,From,t-1),
   clear(To,t-1),
   movedir(Ppos,From,Dir),
   movedir(From,To,Dir),
   isgoal(To),
   player(P),
   stone(S),
   Ppos != To, Ppos != From, From != To,
   step(t).

%---------------------
% DEFINE (EFFECTS)
%---------------------

% Примерно в таком же стиле переносим ваши del(...)/at(...).
% push-to-nongoal
del(at(P,Ppos),t) :- 
   pushtonongoal(P,S,Ppos,From,To,Dir,t),
   movedir(Ppos,From,Dir),
   movedir(From,To,Dir),
   isnongoal(To),
   player(P),
   stone(S),
   Ppos != To, Ppos != From, From != To.

del(at(S,From),t) :-
   pushtonongoal(P,S,Ppos,From,To,Dir,t),
   movedir(Ppos,From,Dir),
   movedir(From,To,Dir),
   isnongoal(To),
   player(P),
   stone(S),
   Ppos != To, Ppos != From, From != To.

del(clear(To),t) :-
   pushtonongoal(P,S,Ppos,From,To,Dir,t),
   ... etc.

at(P,From,t) :-
   pushtonongoal(P,S,Ppos,From,To,Dir,t), 
   ... etc.

at(S,To,t) :-
   pushtonongoal(...).

clear(Ppos,t) :-
   pushtonongoal(...).

del(atgoal(S),t) :-
   pushtonongoal(...).

% move
del(at(P,From),t) :- move(P,From,To,Dir,t), ...
del(clear(To),t)   :- move(P,From,To,Dir,t), ...
at(P,To,t)         :- move(P,From,To,Dir,t), ...
clear(From,t)      :- move(P,From,To,Dir,t), ...

% push-to-goal
del(at(P,Ppos),t) :- pushtogoal(...).
del(at(S,From),t) :- pushtogoal(...).
del(clear(To),t)  :- pushtogoal(...).
at(P,From,t)       :- pushtogoal(...).
at(S,To,t)         :- pushtogoal(...).
clear(Ppos,t)      :- pushtogoal(...).
atgoal(S,t)        :- pushtogoal(...).

%---------------------
% INERTIA: если что-то не удалено, оно остаётся
%---------------------
clear(L,t)   :- clear(L,t-1),   not del(clear(L,t)),   step(t).
atgoal(S,t)  :- atgoal(S,t-1),  not del(atgoal(S,t)),  stone(S), step(t).
at(X,L,t)    :- at(X,L,t-1),    not del(at(X,L,t)),    step(t).

% (Можно добавить ещё inertia для других предикатов, если нужно.)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3) #program check(t). -- ПРОВЕРКА ДОСТИЖЕНИЯ ЦЕЛИ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#program check(t).

% Пример: считаем, что "goalreached" -- если все goal(F) выполняются
goalreached :- 
  step(t),
  N = #count{ G : goal(G) },
  M = #count{ G : goal(G), holdsgoal(G,t) },  % либо atgoal(S,t), смотря как вы проверяете
  N == M.

% Либо, как в вашем исходном коде:
% goalreached :- step(t), N = #count{ X,T : atgoal(X,t), goal(X) }, N = #count{ X : goal(X) }.

:- not goalreached.

% Или, если нужна конкретная проверка: 
% :- query(t), goal(F), not holds(F,t).
% #show move/5, pushtonongoal/7, ...

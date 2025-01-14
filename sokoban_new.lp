%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1) Bounded horizon and time steps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#const maxT=13.
time(0..maxT).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2) Domain objects & static relations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% We have exactly one sokoban player, one crate, and a set of locations.
sokoban(sokoban).
crate(crate2).

location(l1).  location(l2).  location(l5).  location(l6).
location(l9).  location(l10). location(l11). location(l12).
location(l13). location(l14). location(l15). location(l16).
location(l17). location(l18).

% Horizontal adjacency
leftOf(l1, l2).
leftOf(l5, l6).
leftOf(l9, l10).   leftOf(l10, l11).  leftOf(l11, l12).
leftOf(l13, l14). leftOf(l14, l15).  leftOf(l15, l16).
leftOf(l17, l18).

% Vertical adjacency
below(l5, l1).  below(l6, l2).
below(l9, l5).  below(l10, l6).
below(l13, l9).  below(l14, l10). below(l15, l11). below(l16, l12).
below(l17, l13). below(l18, l14).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3) State representation: holds/2
%%    - holds(F,t) = fluent F is true at time t
%%
%%    Fluent examples:
%%      at(Object, Location)
%%      clear(Location)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Inertia Axioms:
% If a fluent holds at time t+1 but is not set true by an action at t, then it must have held at time t
holds(F, T+1) :- holds(F, T), not neg(F, T).
% If a fluent does NOT hold at time t+1 but is not set false by an action at t, then it must not have held at time t
neg(F, T+1) :- neg(F, T), not holds(F, T).

% Shorthand to say "neg(F,T)" is "not holds(F,T)" at time T
% but we treat them carefully via explicit negation to handle inertia.

% By default, a fluent F is either in holds(F,T) or neg(F,T).
{ holds(F,T) ; neg(F,T) } :- fluent(F), time(T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4) Fluent declarations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fluent(at(O,L)) :- sokoban(O); crate(O), location(L).
fluent(clear(L)) :- location(L).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 5) Initial state (time=0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% We know exactly which fluents hold initially:
holds(at(sokoban, l10), 0).
holds(at(crate2,   l15), 0).

holds(clear(l1), 0).
holds(clear(l2), 0).
holds(clear(l5), 0).
holds(clear(l6), 0).
holds(clear(l9), 0).
holds(clear(l11),0).
holds(clear(l12),0).
holds(clear(l13),0).
holds(clear(l14),0).
holds(clear(l16),0).
holds(clear(l17),0).
holds(clear(l18),0).

% The remainder are assumed false initially:
neg(at(sokoban, L), 0) :- location(L), L != l10.
neg(at(crate2,   L), 0) :- location(L), L != l15.
neg(clear(L),       0) :- location(L), not holds(clear(L), 0).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 6) Action schema:
%%    do(Action, T) means "Action is done at time T"
%%    We define preconditions as constraints,
%%    and define effects by specifying how
%%    they set holds(...) or neg(...) at T+1.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Exactly zero or one action at each time step (you can change to "at most one" if you prefer).
{ do(A,T) : action(A) } 1 :- time(T), T < maxT.

% 6.1) moveLeft(sokoban, X, Y)
action(moveLeft(S,X,Y)) :-
  sokoban(S), location(X), location(Y), leftOf(Y,X).

% Precondition:
:- do(moveLeft(S,X,Y), T),
   not holds(at(S,X), T).
:- do(moveLeft(S,X,Y), T),
   not holds(clear(Y), T).

% Effects (when done at time T, sets holds(...) at T+1):
holds(at(S,Y), T+1) :-
  do(moveLeft(S,X,Y), T).
neg(at(S,X), T+1) :-
  do(moveLeft(S,X,Y), T).
holds(clear(X), T+1) :-
  do(moveLeft(S,X,Y), T).
neg(clear(Y), T+1) :-
  do(moveLeft(S,X,Y), T).

% 6.2) moveRight(sokoban, X, Y)
action(moveRight(S,X,Y)) :-
  sokoban(S), location(X), location(Y), leftOf(X,Y).

:- do(moveRight(S,X,Y), T),
   not holds(at(S,X), T).
:- do(moveRight(S,X,Y), T),
   not holds(clear(Y), T).

holds(at(S,Y), T+1) :-
  do(moveRight(S,X,Y), T).
neg(at(S,X), T+1) :-
  do(moveRight(S,X,Y), T).
holds(clear(X), T+1) :-
  do(moveRight(S,X,Y), T).
neg(clear(Y), T+1) :-
  do(moveRight(S,X,Y), T).

% 6.3) moveUp(sokoban, X, Y)
action(moveUp(S,X,Y)) :-
  sokoban(S), location(X), location(Y), below(X,Y).

:- do(moveUp(S,X,Y), T),
   not holds(at(S,X), T).
:- do(moveUp(S,X,Y), T),
   not holds(clear(Y), T).

holds(at(S,Y), T+1) :-
  do(moveUp(S,X,Y), T).
neg(at(S,X), T+1) :-
  do(moveUp(S,X,Y), T).
holds(clear(X), T+1) :-
  do(moveUp(S,X,Y), T).
neg(clear(Y), T+1) :-
  do(moveUp(S,X,Y), T).

% 6.4) moveDown(sokoban, X, Y)
action(moveDown(S,X,Y)) :-
  sokoban(S), location(X), location(Y), below(Y,X).

:- do(moveDown(S,X,Y), T),
   not holds(at(S,X), T).
:- do(moveDown(S,X,Y), T),
   not holds(clear(Y), T).

holds(at(S,Y), T+1) :-
  do(moveDown(S,X,Y), T).
neg(at(S,X), T+1) :-
  do(moveDown(S,X,Y), T).
holds(clear(X), T+1) :-
  do(moveDown(S,X,Y), T).
neg(clear(Y), T+1) :-
  do(moveDown(S,X,Y), T).

% 6.5) pushLeft(sokoban, X, Y, Z, Crate)
action(pushLeft(S,X,Y,Z,C)) :-
  sokoban(S), crate(C),
  location(X;Y;Z),
  leftOf(Y,X), leftOf(Z,Y).

% Precondition:
:- do(pushLeft(S,X,Y,Z,C), T),
   not holds(at(S,X), T).
:- do(pushLeft(S,X,Y,Z,C), T),
   not holds(at(C,  Y), T).
:- do(pushLeft(S,X,Y,Z,C), T),
   not holds(clear(Z), T).

% Effects:
holds(at(S,Y), T+1) :-
  do(pushLeft(S,X,Y,Z,C), T).
neg(at(S,X), T+1) :-
  do(pushLeft(S,X,Y,Z,C), T).

holds(at(C,Z), T+1) :-
  do(pushLeft(S,X,Y,Z,C), T).
neg(at(C,Y), T+1) :-
  do(pushLeft(S,X,Y,Z,C), T).

holds(clear(X), T+1) :-
  do(pushLeft(S,X,Y,Z,C), T).
neg(clear(Y), T+1) :-
  do(pushLeft(S,X,Y,Z,C), T).
neg(clear(Z), T+1) :-
  do(pushLeft(S,X,Y,Z,C), T).

% 6.6) pushRight(sokoban, X, Y, Z, C)
action(pushRight(S,X,Y,Z,C)) :-
  sokoban(S), crate(C),
  location(X;Y;Z),
  leftOf(X,Y), leftOf(Y,Z).

:- do(pushRight(S,X,Y,Z,C), T),
   not holds(at(S,X), T).
:- do(pushRight(S,X,Y,Z,C), T),
   not holds(at(C,Y), T).
:- do(pushRight(S,X,Y,Z,C), T),
   not holds(clear(Z), T).

holds(at(S,Y), T+1) :-
  do(pushRight(S,X,Y,Z,C), T).
neg(at(S,X), T+1) :-
  do(pushRight(S,X,Y,Z,C), T).

holds(at(C,Z), T+1) :-
  do(pushRight(S,X,Y,Z,C), T).
neg(at(C,Y), T+1) :-
  do(pushRight(S,X,Y,Z,C), T).

holds(clear(X), T+1) :-
  do(pushRight(S,X,Y,Z,C), T).
neg(clear(Y), T+1) :-
  do(pushRight(S,X,Y,Z,C), T).
neg(clear(Z), T+1) :-
  do(pushRight(S,X,Y,Z,C), T).

% 6.7) pushUp(sokoban, X, Y, Z, C)
action(pushUp(S,X,Y,Z,C)) :-
  sokoban(S), crate(C),
  location(X;Y;Z),
  below(X,Y), below(Y,Z).

:- do(pushUp(S,X,Y,Z,C), T),
   not holds(at(S,X), T).
:- do(pushUp(S,X,Y,Z,C), T),
   not holds(at(C,Y), T).
:- do(pushUp(S,X,Y,Z,C), T),
   not holds(clear(Z), T).

holds(at(S,Y), T+1) :-
  do(pushUp(S,X,Y,Z,C), T).
neg(at(S,X), T+1) :-
  do(pushUp(S,X,Y,Z,C), T).

holds(at(C,Z), T+1) :-
  do(pushUp(S,X,Y,Z,C), T).
neg(at(C,Y), T+1) :-
  do(pushUp(S,X,Y,Z,C), T).

holds(clear(X), T+1) :-
  do(pushUp(S,X,Y,Z,C), T).
neg(clear(Y), T+1) :-
  do(pushUp(S,X,Y,Z,C), T).
neg(clear(Z), T+1) :-
  do(pushUp(S,X,Y,Z,C), T).

% 6.8) pushDown(sokoban, X, Y, Z, C)
action(pushDown(S,X,Y,Z,C)) :-
  sokoban(S), crate(C),
  location(X;Y;Z),
  below(Y,X), below(Z,Y).

:- do(pushDown(S,X,Y,Z,C), T),
   not holds(at(S,X), T).
:- do(pushDown(S,X,Y,Z,C), T),
   not holds(at(C,Y), T).
:- do(pushDown(S,X,Y,Z,C), T),
   not holds(clear(Z), T).

holds(at(S,Y), T+1) :-
  do(pushDown(S,X,Y,Z,C), T).
neg(at(S,X), T+1) :-
  do(pushDown(S,X,Y,Z,C), T).

holds(at(C,Z), T+1) :-
  do(pushDown(S,X,Y,Z,C), T).
neg(at(C,Y), T+1) :-
  do(pushDown(S,X,Y,Z,C), T).

holds(clear(X), T+1) :-
  do(pushDown(S,X,Y,Z,C), T).
neg(clear(Y), T+1) :-
  do(pushDown(S,X,Y,Z,C), T).
neg(clear(Z), T+1) :-
  do(pushDown(S,X,Y,Z,C), T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 7) Goal: the crate must be at l2 at some time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We want: holds(at(crate2, l2), T) for some T <= maxT
:- not satisfiesGoal.

satisfiesGoal :- 
  time(T), holds(at(crate2, l2), T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 8) Output and finishing touches
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#show do/2.

#include <incmode>.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% #program base: Static knowledge and initial conditions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#program base.

#external horizon.           % We'll set this from Python or command line
time(0..H) :- horizon(H).    % Time domain: 0..horizon

%% Objects
sokoban(sokoban).
crate(crate1).

%% Locations
location(l1; l2; l3; l4; l5; l6; l7;
         l8; l9; l10; l11; l12; l13; l14;
         l15; l16; l17; l18; l19; l20; l21;
         l22; l23; l24; l25; l26; l27; l28;
         l29; l30; l31; l32; l33; l34; l35;
         l36; l37; l38; l39; l40; l41; l42;
         l43; l44; l45; l46; l47; l48; l49).

%% Adjacencies
leftOf(l30,l31). leftOf(l31,l32). leftOf(l32,l33). leftOf(l33,l34).
leftOf(l36,l37). leftOf(l37,l38). leftOf(l38,l39). leftOf(l39,l40). leftOf(l40,l41).
leftOf(l43,l44). leftOf(l44,l45). leftOf(l45,l46). leftOf(l46,l47). leftOf(l47,l48).

below(l29,l22). below(l30,l23). below(l31,l24). below(l32,l25).
below(l33,l26). below(l34,l27).
below(l36,l29). below(l37,l30). below(l38,l31). below(l39,l32).
below(l40,l33). below(l41,l34).
below(l43,l36). below(l44,l37). below(l45,l38). below(l46,l39).
below(l47,l40). below(l48,l41).

%% We want crate1 at l31 as the goal
%% => define "goal(X)" where X is at(crate1,l31)
goal(at(crate1,l31)).

%% INITIAL STATE
%% Instead of "init(at(...))", we directly define time=0:
at(sokoban,l37,0).
at(crate1,l39,0).

clear(l30,0).
clear(l31,0).
clear(l32,0).
clear(l33,0).
clear(l34,0).
clear(l36,0).
clear(l40,0).
clear(l41,0).
clear(l43,0).
clear(l44,0).
clear(l45,0).
clear(l46,0).
clear(l47,0).
clear(l48,0).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BRIDGING: "holds(...)"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% If you want to mimic the example's style "holds(F,t)" for checking,
%% define:
holds(at(O,L),  T) :- at(O,L,T).
holds(clear(X), T) :- clear(X,T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% #program step(t): Transitions and action constraints (time t)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#program step(t).

%% We generate exactly 1 action do(M,t) for t>0
{ do(M,t) : move(M) } 1 :- time(t), t>0.

%% All possible moves
move(moveLeft(S,X,Y)) :-
  sokoban(S), location(X;Y), leftOf(Y,X).

move(moveRight(S,X,Y)) :-
  sokoban(S), location(X;Y), leftOf(X,Y).

move(moveUp(S,X,Y)) :-
  sokoban(S), location(X;Y), below(X,Y).

move(moveDown(S,X,Y)) :-
  sokoban(S), location(X;Y), below(Y,X).

move(pushLeft(S,X,Y,Z,C)) :-
  sokoban(S), crate(C), location(X;Y;Z),
  leftOf(Y,X), leftOf(Z,Y).

move(pushRight(S,X,Y,Z,C)) :-
  sokoban(S), crate(C), location(X;Y;Z),
  leftOf(X,Y), leftOf(Y,Z).

move(pushUp(S,X,Y,Z,C)) :-
  sokoban(S), crate(C), location(X;Y;Z),
  below(X,Y), below(Y,Z).

move(pushDown(S,X,Y,Z,C)) :-
  sokoban(S), crate(C), location(X;Y;Z),
  below(Y,X), below(Z,Y).

%% Action preconditions at time t
:- do(moveLeft(S,X,Y),t), not at(S,X,t).
:- do(moveLeft(S,X,Y),t), not clear(Y,t).

:- do(moveRight(S,X,Y),t), not at(S,X,t).
:- do(moveRight(S,X,Y),t), not clear(Y,t).

:- do(moveUp(S,X,Y),t), not at(S,X,t).
:- do(moveUp(S,X,Y),t), not clear(Y,t).

:- do(moveDown(S,X,Y),t), not at(S,X,t).
:- do(moveDown(S,X,Y),t), not clear(Y,t).

:- do(pushLeft(S,X,Y,Z,C),t), not at(S,X,t).
:- do(pushLeft(S,X,Y,Z,C),t), not at(C,Y,t).
:- do(pushLeft(S,X,Y,Z,C),t), not clear(Z,t).

:- do(pushRight(S,X,Y,Z,C),t), not at(S,X,t).
:- do(pushRight(S,X,Y,Z,C),t), not at(C,Y,t).
:- do(pushRight(S,X,Y,Z,C),t), not clear(Z,t).

:- do(pushUp(S,X,Y,Z,C),t), not at(S,X,t).
:- do(pushUp(S,X,Y,Z,C),t), not at(C,Y,t).
:- do(pushUp(S,X,Y,Z,C),t), not clear(Z,t).

:- do(pushDown(S,X,Y,Z,C),t), not at(S,X,t).
:- do(pushDown(S,X,Y,Z,C),t), not at(C,Y,t).
:- do(pushDown(S,X,Y,Z,C),t), not clear(Z,t).

%% Inertia
at(O,L,t)   :- at(O,L,t-1), not -at(O,L,t).
clear(X,t)  :- clear(X,t-1), not -clear(X,t).

%% Positive & negative effects (incremental style)
% same as before, just indexing (t) for new state from (t-1)

%========== moveLeft ==========
at(S,Y,t) :-
  do(moveLeft(S,X,Y),t),
  at(S,X,t-1),
  clear(Y,t-1).

-at(S,X,t) :-
  do(moveLeft(S,X,Y),t),
  at(S,X,t-1).

clear(X,t) :-
  do(moveLeft(S,X,Y),t),
  at(S,X,t-1),
  clear(Y,t-1).

-clear(Y,t) :-
  do(moveLeft(S,X,Y),t),
  at(S,X,t-1),
  clear(Y,t-1).

%========== moveRight ==========
at(S,Y,t) :-
  do(moveRight(S,X,Y),t),
  at(S,X,t-1),
  clear(Y,t-1).

-at(S,X,t) :-
  do(moveRight(S,X,Y),t),
  at(S,X,t-1).

clear(X,t) :-
  do(moveRight(S,X,Y),t),
  at(S,X,t-1),
  clear(Y,t-1).

-clear(Y,t) :-
  do(moveRight(S,X,Y),t),
  at(S,X,t-1),
  clear(Y,t-1).

%========== moveUp ==========
at(S,Y,t) :-
  do(moveUp(S,X,Y),t),
  at(S,X,t-1),
  clear(Y,t-1).

-at(S,X,t) :-
  do(moveUp(S,X,Y),t),
  at(S,X,t-1).

clear(X,t) :-
  do(moveUp(S,X,Y),t),
  at(S,X,t-1),
  clear(Y,t-1).

-clear(Y,t) :-
  do(moveUp(S,X,Y),t),
  at(S,X,t-1),
  clear(Y,t-1).

%========== moveDown ==========
at(S,Y,t) :-
  do(moveDown(S,X,Y),t),
  at(S,X,t-1),
  clear(Y,t-1).

-at(S,X,t) :-
  do(moveDown(S,X,Y),t),
  at(S,X,t-1).

clear(X,t) :-
  do(moveDown(S,X,Y),t),
  at(S,X,t-1),
  clear(Y,t-1).

-clear(Y,t) :-
  do(moveDown(S,X,Y),t),
  at(S,X,t-1),
  clear(Y,t-1).

%========== pushLeft ==========
at(S,Y,t) :-
  do(pushLeft(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-at(S,X,t) :-
  do(pushLeft(S,X,Y,Z,C),t),
  at(S,X,t-1).

at(C,Z,t) :-
  do(pushLeft(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-at(C,Y,t) :-
  do(pushLeft(S,X,Y,Z,C),t),
  at(C,Y,t-1).

clear(X,t) :-
  do(pushLeft(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-clear(Z,t) :-
  do(pushLeft(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-clear(Y,t) :-
  do(pushLeft(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

%========== pushRight ==========
at(S,Y,t) :-
  do(pushRight(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-at(S,X,t) :-
  do(pushRight(S,X,Y,Z,C),t),
  at(S,X,t-1).

at(C,Z,t) :-
  do(pushRight(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-at(C,Y,t) :-
  do(pushRight(S,X,Y,Z,C),t),
  at(C,Y,t-1).

clear(X,t) :-
  do(pushRight(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-clear(Z,t) :-
  do(pushRight(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-clear(Y,t) :-
  do(pushRight(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

%========== pushUp ==========
at(S,Y,t) :-
  do(pushUp(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-at(S,X,t) :-
  do(pushUp(S,X,Y,Z,C),t),
  at(S,X,t-1).

at(C,Z,t) :-
  do(pushUp(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-at(C,Y,t) :-
  do(pushUp(S,X,Y,Z,C),t),
  at(C,Y,t-1).

clear(X,t) :-
  do(pushUp(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-clear(Z,t) :-
  do(pushUp(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-clear(Y,t) :-
  do(pushUp(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

%========== pushDown ==========
at(S,Y,t) :-
  do(pushDown(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-at(S,X,t) :-
  do(pushDown(S,X,Y,Z,C),t),
  at(S,X,t-1).

at(C,Z,t) :-
  do(pushDown(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-at(C,Y,t) :-
  do(pushDown(S,X,Y,Z,C),t),
  at(C,Y,t-1).

clear(X,t) :-
  do(pushDown(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-clear(Z,t) :-
  do(pushDown(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).

-clear(Y,t) :-
  do(pushDown(S,X,Y,Z,C),t),
  at(S,X,t-1),
  at(C,Y,t-1),
  clear(Z,t-1).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% #program check(t): Goal checking each step
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#program check(t).
#external query(t).

%% If query(t) is turned on from Python, require that all "goal(F)" are satisfied:
%% i.e., if goal(F) is e.g. goal(at(crate1,l31)), then holds(at(crate1,l31), t) must be true
:- query(t), goal(F), not holds(F,t).

#show do/2.
#show clear/2.

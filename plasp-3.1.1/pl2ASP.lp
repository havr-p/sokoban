% Time representation
time(0..maxsteps).

% Direction encoding for movements
direction(up;down;left;right).

% Movement deltas for each direction
delta(up,-W) :- width(W).
delta(down,W) :- width(W).
delta(left,-1).
delta(right,1).

% Define valid positions based on the input map
% We'll assume these are provided as facts:
% position(P) - valid positions
% wall(P) - wall positions
% initial_sokoban(P) - starting position of Sokoban
% initial_crate(P) - starting positions of crates
% goal(P) - goal positions
% width(W) - width of the map

% State representation at each time step
0 { sokoban(P,T) : position(P) } 1 :- time(T).
0 { crate(P,T) : position(P) } N :- time(T), N = #count{ P : initial_crate(P) }.

% Initial state
sokoban(P,0) :- initial_sokoban(P).
crate(P,0) :- initial_crate(P).

% Movement rules
% Player can move to an adjacent empty position
1 { move(D,T) : direction(D) } 1 :- time(T), T < maxsteps.

% Calculate new position after move
newpos(P1,P2,D) :- position(P1), position(P2), direction(D),
                   delta(D,Delta), P2 = P1 + Delta,
                   not wall(P2).

% Player movement without pushing
sokoban(P2,T+1) :- move(D,T), sokoban(P1,T),
                   newpos(P1,P2,D),
                   not crate(P2,T),
                   time(T).

% Crate remains in place if not pushed
crate(P,T+1) :- crate(P,T),
                not pushed(P,T),
                time(T).

% Pushing crates
pushed(P1,T) :- move(D,T), sokoban(P,T),
                newpos(P,P1,D), crate(P1,T),
                newpos(P1,P2,D), not wall(P2),
                not crate(P2,T).

crate(P2,T+1) :- pushed(P1,T),
                 move(D,T),
                 newpos(P1,P2,D).

% Frame axioms - things that don't change stay the same
sokoban(P,T+1) :- sokoban(P,T), not moved(T).
moved(T) :- move(_,T).

% Goal conditions
goal_reached :- time(T),
               #count{ P : crate(P,T), goal(P) } = N,
               #count{ P : goal(P) } = N.

% At least one solution must reach the goal
:- not goal_reached.

% Optimization: minimize number of moves
#minimize{ 1,T : move(_,T) }.

% Show only important predicates
#show move/2.
#show sokoban/2.
#show crate/2.
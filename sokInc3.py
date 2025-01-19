import clingo

def solve():
    asp_code_base = """
 #program base.

% Define Sokoban puzzle elements
sokoban(sokoban).
crate(crate_01).
object(sokoban; crate_01).

location(l1; l2; l3; l4; l5; l6; l7; l8; l9; l10; l11; l12; l13; l14; l15; l16; l17; l18; l19; l20; l21; l22; l23; l24; l25; l26; l27).
isgoal(l17).

% Walls
wall(l1; l2; l3; l4; l5; l6; l7; l8; l9; l10; l18; l19; l20; l21; l22; l23; l24; l25; l26; l27).

% Adjacency relations
leftOf(l1, l2). leftOf(l2, l3). leftOf(l3, l4). leftOf(l4, l5). leftOf(l5, l6). leftOf(l6, l7). leftOf(l7, l8). leftOf(l8, l9).
leftOf(l10, l11). leftOf(l11, l12). leftOf(l12, l13). leftOf(l13, l14). leftOf(l14, l15). leftOf(l15, l16). leftOf(l16, l17). leftOf(l17, l18).
leftOf(l19, l20). leftOf(l20, l21). leftOf(l21, l22). leftOf(l22, l23). leftOf(l23, l24). leftOf(l24, l25). leftOf(l25, l26). leftOf(l26, l27).

below(l10, l1). below(l11, l2). below(l12, l3). below(l13, l4). below(l14, l5). below(l15, l6). below(l16, l7). below(l17, l8). below(l18, l9).
below(l19, l10). below(l20, l11). below(l21, l12). below(l22, l13). below(l23, l14). below(l24, l15). below(l25, l16). below(l26, l17). below(l27, l18).

% Initialize positions
init(at(sokoban, l11)).
init(at(crate_01, l14)).

% Holds at time 0
holds(F,0) :- init(F).
    """

    asp_code_step = """
       % Generate actions
{ do(Action, t) : action(Action, t) } = 1.

% Action definitions
% MoveLeft
action(moveLeft(S,X,Y), t) :-
    sokoban(S),
    holds(at(S,X), t-1),
    leftOf(Y,X),
    holds(clear(Y), t-1),
    not wall(Y).

% MoveRight
action(moveRight(S,X,Y), t) :-
    sokoban(S),
    holds(at(S,X), t-1),
    leftOf(X,Y),
    holds(clear(Y), t-1),
    not wall(Y).

% MoveUp
action(moveUp(S,X,Y), t) :-
    sokoban(S),
    holds(at(S,X), t-1),
    below(X,Y),
    holds(clear(Y), t-1),
    not wall(Y).

% MoveDown
action(moveDown(S,X,Y), t) :-
    sokoban(S),
    holds(at(S,X), t-1),
    below(Y,X),
    holds(clear(Y), t-1),
    not wall(Y).

% PushLeft
action(pushLeft(S,X,Y,Z,C), t) :-
    sokoban(S),
    crate(C),
    holds(at(S,X), t-1),
    holds(at(C,Y), t-1),
    leftOf(Y,X),
    leftOf(Z,Y),
    holds(clear(Z), t-1),
    not wall(Z).

% PushRight
action(pushRight(S,X,Y,Z,C), t) :-
    sokoban(S),
    crate(C),
    holds(at(S,X), t-1),
    holds(at(C,Y), t-1),
    leftOf(X,Y),
    leftOf(Y,Z),
    holds(clear(Z), t-1),
    not wall(Z).

% PushUp
action(pushUp(S,X,Y,Z,C), t) :-
    sokoban(S),
    crate(C),
    holds(at(S,X), t-1),
    holds(at(C,Y), t-1),
    below(X,Y),
    below(Y,Z),
    holds(clear(Z), t-1),
    not wall(Z).

% PushDown
action(pushDown(S,X,Y,Z,C), t) :-
    sokoban(S),
    crate(C),
    holds(at(S,X), t-1),
    holds(at(C,Y), t-1),
    below(Y,X),
    below(Z,Y),
    holds(clear(Z), t-1),
    not wall(Z).

% Moved predicates
% For Sokoban
moved(S, t) :- do(moveLeft(S,X,Y), t), sokoban(S).
moved(S, t) :- do(moveRight(S,X,Y), t), sokoban(S).
moved(S, t) :- do(moveUp(S,X,Y), t), sokoban(S).
moved(S, t) :- do(moveDown(S,X,Y), t), sokoban(S).
moved(S, t) :- do(pushLeft(S,X,Y,Z,C), t), sokoban(S).
moved(S, t) :- do(pushRight(S,X,Y,Z,C), t), sokoban(S).
moved(S, t) :- do(pushUp(S,X,Y,Z,C), t), sokoban(S).
moved(S, t) :- do(pushDown(S,X,Y,Z,C), t), sokoban(S).

% For Crate
moved(C, t) :- do(pushLeft(S,X,Y,Z,C), t), crate(C).
moved(C, t) :- do(pushRight(S,X,Y,Z,C), t), crate(C).
moved(C, t) :- do(pushUp(S,X,Y,Z,C), t), crate(C).
moved(C, t) :- do(pushDown(S,X,Y,Z,C), t), crate(C).

% Update holds predicates
% For Sokoban
holds(at(S,Y), t) :- do(moveLeft(S,X,Y), t).
holds(at(S,Y), t) :- do(moveRight(S,X,Y), t).
holds(at(S,Y), t) :- do(moveUp(S,X,Y), t).
holds(at(S,Y), t) :- do(moveDown(S,X,Y), t).
holds(at(S,Y), t) :- do(pushLeft(S,X,Y,Z,C), t).
holds(at(S,Y), t) :- do(pushRight(S,X,Y,Z,C), t).
holds(at(S,Y), t) :- do(pushUp(S,X,Y,Z,C), t).
holds(at(S,Y), t) :- do(pushDown(S,X,Y,Z,C), t).

% For Crate
holds(at(C,Z), t) :- do(pushLeft(S,X,Y,Z,C), t).
holds(at(C,Z), t) :- do(pushRight(S,X,Y,Z,C), t).
holds(at(C,Z), t) :- do(pushUp(S,X,Y,Z,C), t).
holds(at(C,Z), t) :- do(pushDown(S,X,Y,Z,C), t).

% Frame axioms
holds(at(O,L), t) :- holds(at(O,L), t-1), not moved(O,t), object(O).

% Occupied locations
occupied(L,t) :- holds(at(O,L), t), object(O).

% Clear locations
holds(clear(L), t) :- location(L), not occupied(L,t), not wall(L).

% Constraints
:- holds(at(O,L),t), holds(at(O2,L),t), O != O2.
:- holds(at(S,L), t), wall(L), sokoban(S).

% Goal
goal(at(crate_01, l17)).

    """

    asp_code_check = """
        #program check(t).
        #external query(t).
        % Test
        :- query(t), goal(F), not holds(F,t).
        #show do/2.
    """

    def on_model(model):
        print("Found solution:", model)

    max_step = 10  # увеличил максимальное количество шагов, так как эта задача может требовать больше ходов
    control = clingo.Control()
    control.configuration.solve.models = 1

    # add each #program
    control.add("base", [], asp_code_base)
    control.add("step", ["t"], asp_code_step)
    control.add("check", ["t"], asp_code_check)

    parts = []
    parts.append(("base", []))
    control.ground(parts)
    ret, step = None, 1

    while step <= max_step and (step == 1 or not ret.satisfiable):
        parts = []
        control.release_external(clingo.Function("query", [clingo.Number(step - 1)]))
        parts.append(("step", [clingo.Number(step)]))
        parts.append(("check", [clingo.Number(step)]))
        control.cleanup()
        control.ground(parts)
        control.assign_external(clingo.Function("query", [clingo.Number(step)]), True)
        print(f"Solving step: t={step}")
        ret = control.solve(on_model=on_model)
        print(f"Returned: {ret}")
        step += 1

if __name__ == "__main__":
    try:
        solve()
    except Exception as e:
        print(f"An error occurred: {e}")
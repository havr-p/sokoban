import clingo

def solve():
    asp_code_base = """
        #include <incmode>.
        % Define
        location(table).
        location(X) :- block(X).
        holds(F,0) :- init(F).
        block(b0).
        block(b1).
        block(b2).
        init(on(b1,table)).
        init(on(b2,b0)).
        init(on(b0,table)).
        goal(on(b1,b0)).
        goal(on(b2,b1)).
        goal(on(b0,table)).
        #show move/3.
    """
    asp_code_step = """
        % Generate
        { move(X,Y,t) : block(X), location(Y), X != Y } = 1.
        % Test
        :- move(X,Y,t), holds(on(A,X),t-1).
        :- move(X,Y,t), holds(on(B,Y),t-1), B != X, Y != table.
        % Define
        moved(X,t) :- move(X,Y,t).
        holds(on(X,Y),t) :- move(X,Y,t).
        holds(on(X,Z),t) :- holds(on(X,Z),t-1), not moved(X,t).
    """
    asp_code_check = """
        #external query(t).
        % Test
        :- query(t), goal(F), not holds(F,t).
    """
    
    def on_model(model):
        print("Found solution:", model)

    # this is an arbitrary upper limit set to ensure process terminates
    max_step = 5
    control = clingo.Control()
    control.configuration.solve.models = 1  # find one answer only
    
    # add each #program
    control.add("base", [], asp_code_base)
    control.add("step", ["t"], asp_code_step)
    control.add("check", ["t"], asp_code_check)
    
    # for grounding, we make use of a parts array
    parts = []
    parts.append(("base", []))
    control.ground(parts)
    ret, step = None, 1
    
    # try solving until max number of steps or until solved
    while step <= max_step and (step == 1 or not ret.satisfiable):
        parts = []
        # handle #external call
        control.release_external(clingo.Function("query", [clingo.Number(step - 1)]))
        parts.append(("step", [clingo.Number(step)]))
        parts.append(("check", [clingo.Number(step)]))
        control.cleanup()  # cleanup previous grounding call, so we can ground again
        control.ground(parts)
        # finish handling #external call
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
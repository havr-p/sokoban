import clingo

def solve():
    asp_code_base = """
        #include <incmode>.
        #program base.
        side(left;right).
        object(wolf;cabbage;goat).
        init(at(goat,left)).
        init(at(wolf,left)).
        init(at(cabbage,left)).
        init(at(farmer,left)).
        goal(at(goat,right)).
        goal(at(wolf,right)).
        goal(at(cabbage,right)).
        holds(F,0) :- init(F).
    """

    asp_code_step = """
        #program step(t).
        % Generate 
        { move(O,X,Y,t) : object(O), side(X),side(Y), X != Y, holds(at(O,X),t-1), holds(at(farmer,X),t-1);
          move(farmer,X,Y,t) : side(X),side(Y), X != Y, holds(at(farmer,X),t-1) } = 1. 
        % Test 
        :- holds(at(wolf,X),t), holds(at(goat,X),t), not holds(at(farmer,X),t).
        :- holds(at(cabbage,X),t), holds(at(goat,X),t), not holds(at(farmer,X),t).
        % Define 
        holds(at(O,Y),t) :- move(O,X,Y,t). 
        holds(at(farmer,Y),t) :- move(O,X,Y,t), O != farmer. 
        moved(O,t) :- move(O,X,Y,t). 
        holds(at(O,X),t) :- holds(at(O,X),t-1), object(O), side(X), not moved(O,t).
        holds(at(farmer,X),t) :- holds(at(farmer,X),t-1), not moved(farmer,t).
    """

    asp_code_check = """
        #program check(t).
        #external query(t).
        % Test
        :- query(t), goal(F), not holds(F,t).
        #show move/4.
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
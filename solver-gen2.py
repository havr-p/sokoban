import clingo

# We'll store the last (best) stable model found at each step in this variable.
last_model_atoms = None

def on_model(model):
    """
    Callback to process each stable model that Clingo finds.
    We'll save the 'shown' atoms and also print them immediately.
    """
    global last_model_atoms
    # Collect the atoms that are shown by the ASP code (#show do/2).
    shown = model.symbols(shown=True)
    last_model_atoms = shown
    print("Intermediate model:", shown)

def main():
    ctl = clingo.Control()

    # 1) Load your incremental ASP code (e.g. inc2.lp).
    ctl.load("inc2.lp")

    # 2) Set the horizon (max time steps).
    horizon = 10
    from clingo import Number, Function
    ctl.assign_external(Function("horizon", [Number(horizon)]), True)

    # 3) Ground the base part once.
    ctl.ground([("base", [])])

    # 4) Iterate t in 0..horizon, ground step(t) & check(t) each time, then solve.
    for t in range(horizon + 1):
        # Release the old query(t-1) if t>0
        if t > 0:
            ctl.release_external(Function("query", [Number(t - 1)]))

        # Ground the step and check programs for time t
        ctl.ground([("step", [Number(t)]),
                    ("check", [Number(t)])])

        # Turn on query(t) so we require the goal to be satisfied at step t
        ctl.assign_external(Function("query", [Number(t)]), True)

        # Solve and print intermediate results via on_model
        print(f"\nSolving at step = {t} ...")
        ret = ctl.solve(on_model=on_model)

        # Check if satisfiable (goal reached) 
        if ret.satisfiable:
            # Print the final plan from t=0..t (the last model we saw).
            print(f"Goal satisfied at step={t}!")
            if last_model_atoms:
                print("Final plan (do(...)):", list(last_model_atoms))
            break
        else:
            # If no solution yet, continue to the next step
            print(f"Result: {ret}")
            print(f"No solution at step={t}, continuing ...")

    else:
        # If we exit normally (no break), no plan found up to horizon
        print(f"\nNo solution found up to step={horizon}.")

if __name__ == "__main__":
    main()

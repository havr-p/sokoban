import clingo

def on_model(model):
    """
    Print the current model's do/2 atoms,
    which are shown by the #show do/2 directive in the ASP code.
    """
    # Gather do(...) atoms from the model
    moves = [str(atom) for atom in model.symbols(shown=True)]
    print("Found solution with moves:")
    for m in moves:
        print("  ", m)

def main():
    # The non-incremental ASP file you posted
    asp_file = "sokoban-new-2.lp"

    # We will do iterative deepening up to this limit
    MAX_LIMIT = 128

    steps = 1
    found_solution = False

    while steps <= MAX_LIMIT and not found_solution:
        print("=" * 50)
        print(f"Trying maxsteps = {steps}")

        # 1) Create a new control object, passing -c maxsteps=steps to override #const maxsteps=10.
        ctl = clingo.Control(["-c", f"maxsteps={steps}"])

        # 2) Load your non-incremental Sokoban program
        ctl.load(asp_file)

        # 3) Ground the base part (the program is single-shot, so we just do one ground call)
        ctl.ground([("base", [])])

        # 4) Solve, printing any model found
        result = ctl.solve(on_model=on_model)

        # 5) Check satisfiability
        if result.satisfiable:
            print(f"SOLUTION FOUND with maxsteps={steps}")
            found_solution = True
        else:
            print(f"No solution at maxsteps={steps}; will increase.")
            steps *= 2

    if not found_solution:
        print(f"No solution found up to maxsteps={MAX_LIMIT}")

if __name__ == "__main__":
    main()

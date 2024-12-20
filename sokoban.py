import clingo
import argparse

def on_model(model):
    """
    Callback function to process the model found by the ASP solver.
    """
    print("Solution:")
    for symbol in model.symbols(shown=True):
        print(symbol)

def sokoban_solver(asp_file, input_file, timeout):
    """
    Solve the Sokoban problem using Clingo's Python API.
    """
    ctl = clingo.Control()
    ctl.configuration.solve.models = 0  # Find all models

    try:
        # Load ASP rules file
        ctl.load(asp_file)

        # Load input instance
        with open(input_file, 'r') as f:
            ctl.add("base", [], f.read())

        # Ground the program
        ctl.ground([("base", [])])

        print("Solving Sokoban...")
        ctl.solve(on_model=on_model)

    except FileNotFoundError as e:
        print(f"File not found: {e.filename}")
    except Exception as e:
        print(f"Error: {e}")

def main():
    parser = argparse.ArgumentParser(description="Sokoban Solver using Clingo Python API")
    parser.add_argument("--asp-file", type=str, default="enc.lp",
                        help="Path to the ASP logic file (default: sokoban.lp).")
    parser.add_argument("--input-file", type=str, default="input.lp",
                        help="Path to the input file (default: input.lp).")
    parser.add_argument("--timeout", type=int, default=60,
                        help="Timeout for the solver in seconds (default: 60).")

    args = parser.parse_args()

    asp_file = args.asp_file
    input_file = args.input_file
    timeout = args.timeout

    print(f"Solving Sokoban with ASP file: {asp_file} and input file: {input_file}")
    sokoban_solver(asp_file, input_file, timeout)

if __name__ == "__main__":
    main()

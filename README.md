
# README

## Sokoban solver and visualizer

### Overview

This project provides a solution to the classic Sokoban puzzle using Answer Set Programming (ASP) with Clingo. It includes a Python-based graphical user interface (GUI) that allows users to load Sokoban maps, solve them, and visualize the solution steps.

### Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Directory Structure](#directory-structure)
- [Usage](#usage)
  - [Running the Solver](#running-the-solver)
  - [Using the Visualizer](#using-the-visualizer)
- [Control Switches](#control-switches)
- [Sample Input and Output](#sample-input-and-output)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [License](#license)

### Prerequisites

Ensure that you have the following installed on your system:

- **Python 3.7 or higher**
- **Clingo ASP Solver**
- **pip** (Python package installer)

### Installation

1. **Clone the Repository**

   ```bash
   git clone https://github.com/yourusername/sokoban-asp-solver.git
   cd sokoban-asp-solver
   ```

2. **Install Python Dependencies**

   It's recommended to use a virtual environment:

   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **Install Clingo**

   Follow the installation instructions from the [Clingo website](https://potassco.org/clingo/).

### Directory Structure

```
sokoban-asp-solver/
├── maps/
│   ├── map1.txt
│   ├── map2.txt
│   └── ...
├── expected/
│   ├── expected1.txt
│   ├── expected2.txt
│   └── ...
├── maps_out/
│   └── generated_map1.txt
├──sokoban_map.py
├── conftest.py
├── test_solver.py
├── solver.py
└── visualizer.py
├── sokoban.lp
├── requirements.txt
├── README.md
└── Documentation.md
```

### Usage

#### Running the solver

To solve a Sokoban puzzle using the ASP solver:

```bash
python src/solver.py sokoban.lp maps/map1.txt --max_steps=50
```

**Arguments:**

- `sokoban.lp`: Path to the ASP domain rules file.
- `maps/map1.txt`: Path to the Sokoban map file.
- `--max_steps`: (Optional) Maximum number of steps to search for a solution. Default is 50.

**Example:**

```bash
python solver.py sokoban.lp maps/map1.txt --max_steps=30
```

**Output:**

```
Solving Sokoban on map map1.txt

Solution steps:
do(moveRight(sokoban,l1_2,l1_3), 1)
do(pushRight(sokoban,l1_3,l1_4,l1_5,crate_01), 2)
...

initial map state:
#########
#S  C  X#
#########

After step 1: moveRight(sokoban,l1_2,l1_3)
#########
# S C  X#
#########

After step 2: pushRight(sokoban,l1_3,l1_4,l1_5,crate_01)
#########
#  S C X#
#########
```

#### Using the Visualizer

To launch the GUI visualizer:

```bash
python visualizer.py
```

**Features:**

- **Map Selection:** Choose from available Sokoban maps.
- **Run Test:** Solve the selected map and visualize the solution.
- **Visualization:** Step through each move to see the Sokoban puzzle being solved.
- **ASP Map Display:** View the generated ASP facts for the selected map.
- **Pytest Output:** Review test results and solver output. All generated maps are stored in maps_out folder. You can provide them as a second argument for clingo directly:
```bash
clingo sokoban.lp maps/map1.txt -c max_steps=10
```  
but python solver does essentialy same thing:  
```bash
python src/solver.py sokoban.lp maps/map1.txt --max_steps=10
```

### Control Switches

- `--map=<map_file>`: Specify a single map to test (e.g., `--map=map1.txt`). If not provided, all maps are tested.
(by commenting out tests from get_test_cases in conftest.py you can force to run several selected tests with "pytest" command)

### Sample Input and Output

**Sample Map (`maps/map1.txt`):**

```
#########
#S  C  X#
#########
```

**Running the Solver:**

```bash
python src/solver.py sokoban.lp maps/map1.txt --max_steps=10
```

**Sample Output:**

```
Solving Sokoban on map map1.txt

Solution steps:
do(moveRight(sokoban,l1_2,l1_3), 1)
do(pushRight(sokoban,l1_3,l1_4,l1_5,crate_01), 2)

initial map state:
#########
#S  C  X#
#########

After step 1: moveRight(sokoban,l1_2,l1_3)
#########
# S C  X#
#########

After step 2: pushRight(sokoban,l1_3,l1_4,l1_5,crate_01)
#########
#  S C X#
#########
```

### Testing

The project includes automated tests using `pytest`. To run the tests:

```bash
pytest test_solver.py --map=map1.txt --tb=short -v -s
```

**Options:**

- `--map=<map_file>`: Run tests for a specific map. If omitted, all maps are tested.

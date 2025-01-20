
# Sokoban Solver as a Planning Problem in ASP

## Table of Contents

1. [Introduction](#introduction)
2. [Problem Description](#problem-description)
3. [Planning in ASP](#planning-in-asp)
   - [Actions, Preconditions, and Effects](#actions-preconditions-and-effects)
   - [Frame Problem Solution](#frame-problem-solution)
   - [Background Knowledge](#background-knowledge)
4. [Encoding the Problem](#encoding-the-problem)
   - [Goal Definition](#goal-definition)
   - [Action Selection](#action-selection)
   - [Defining Actions](#defining-actions)
   - [Inertia](#inertia)
   - [Preconditions](#preconditions)
   - [Positive and Negative Effects](#positive-and-negative-effects)
   - [Minimizing Steps](#minimizing-steps)
   - [Constraints on Walls and Crates](#constraints-on-walls-and-crates)
   - [Output Actions](#output-actions)
5. [Implementation](#implementation)
6. [Solving the Frame Problem](#solving-the-frame-problem)
7. [Experience and Reflections](#experience-and-reflections)
8. [Conclusion](#conclusion)

## Introduction

**Author:** Havriil Pietukhin  
**Date:** January 20, 2025  
**Title:** Solving Sokoban as a Planning Problem Using Answer Set Programming  
**Purpose:** Explains modeling and solving Sokoban puzzles using Answer Set Programming (ASP).

## Problem Description

Sokoban is a grid-based puzzle where Sokoban pushes crates onto storage locations. The goal is to position all crates on their targets with minimal moves, avoiding unsolvable states.

### Key Components:

- **Grid Layout:** Comprises walls, empty spaces, crates, storage locations, and Sokoban.
- **Crates:** Movable boxes.
- **Storage Locations:** Targets for crates.
- **Sokoban:** The player character.

## Planning in ASP

ASP is ideal for Sokoban due to its ability to model complex rules and constraints declaratively.

### Actions, Preconditions, and Effects

**Actions:**

1. **Move:** Sokoban moves one cell without pushing.
2. **Push:** Sokoban moves and pushes a crate into the next cell.

**Preconditions:**

- **Move:**
  - Target cell is empty or a storage location.
  - No crate or wall in the target cell.

- **Push:**
  - Adjacent cell contains a crate.
  - Destination cell is empty or a storage location.
  - No wall blocking.

**Effects:**

- **Move:**
  - Sokoban's position updates.

- **Push:**
  - Sokoban and crate positions update.

### Frame Problem Solution

Utilizes inertia rules to assume states persist unless altered by actions, avoiding exhaustive non-change specifications.

### Background Knowledge

Defines spatial relations, entity properties, and constraints to model the environment accurately.

## Encoding the Problem

Translates Sokoban into ASP for Clingo to process, covering goals, actions, inertia, and constraints.

### Goal Definition

Ensures all crates reach storage locations at least once.

**Key Rules:**

- Goals and walls are mutually exclusive.
- Crates must reach goals.
- Prevent overlapping entities.
- Detect and prohibit deadlocks.

### Action Selection

Ensures one action per timestep and prevents Sokoban from idling unless goals are achieved.

### Defining Actions

Enumerates all possible move and push actions with necessary parameters.

### Inertia

Maintains state persistence for object positions and cell statuses unless changed by actions.

### Preconditions

Validates that actions are only executed when necessary conditions are met, such as Sokoban's position and cell clarity.

### Positive and Negative Effects

Defines how actions alter the game state, updating positions and cell statuses accordingly.

### Minimizing Steps

Uses ASP directives to minimize the number of actions and the overall plan duration for efficiency.

### Constraints on Walls and Crates

Ensures walls and crates remain consistent throughout the plan, preventing their unintended creation or destruction.

### Output Actions

Specifies which predicates to display, focusing on actions and summary information.

## Implementation

Consists of ASP encoding and a Python interface.

1. **ASP Encoding (`sokoban.lp`):** Formal representation of the Sokoban problem.
2. **Python Interface:**
   - **Solver (`solver.py`):** Interfaces with Clingo, translates maps, and processes solutions.
   - **Visualizer (`visualizer.py`):** GUI for map selection and solution visualization.
   - **Testing (`test_solver.py` & `conftest.py`):** Automated tests using `pytest`.

### Workflow

1. **Map Input:** Users provide maps in text files.
2. **Fact Generation:** Solver converts maps to ASP facts.
3. **Solving:** Clingo finds action sequences.
4. **Visualization:** GUI displays the solution steps.

### Key Modules

- **`solver.py`:** Manages solving process.
- **`visualizer.py`:** Handles user interface.
- **`test_solver.py`:** Ensures solver correctness.
- **`conftest.py`:** Configures testing environment.

### Detailed Implementation Aspects

- **Fact Generation:** Parses maps to identify walls, crates, storage, and Sokoban.
- **Action Modeling:** Encodes actions with preconditions and effects.
- **Inertia Rules:** Maintains state unless actions change it.
- **Optimization:** Seeks minimal-step solutions.

## Solving the Frame Problem

Addresses state persistence using inertia rules, ensuring only relevant state changes occur.

### Approach in Encoding

1. **Inertia Rules:** Maintain object positions and cell statuses unless altered.
2. **Negative Effects:** Explicitly remove previous positions when objects move.
3. **Selective Updates:** Only affected entities are updated.
4. **Conciseness:** Avoids over-specification with `not -` constructs.

### Example Scenario

Sokoban performs a `pushRight`:

1. **Preconditions:** Sokoban at `X`, crate at `Y`, `Z` clear.
2. **Execution:** Sokoban moves to `Y`, crate to `Z`.
3. **Frame Handling:** Updates only affected positions, preserving others.

## Experience and Reflections

Gained insights into declarative programming and ASP's strengths in modeling planning problems.

### Challenges

- Designing effective inertia rules.
- Optimizing performance.
- Integrating ASP with a user-friendly GUI.

### Key Learnings

- Enhanced ASP proficiency.
- Effective problem decomposition.
- Importance of thorough testing.

## Conclusion

Successfully modeled and solved Sokoban using ASP, demonstrating ASP's capability in AI planning. Future enhancements include handling more complex puzzles, optimizing heuristics, and improving visualization.

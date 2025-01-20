from typing import List, Tuple


class SokobanMap:
    """
    Represents a Sokoban map and provides methods for updating and visualizing it.
    """

    # Constants for symbols
    SYMBOL_WALL = '#'
    SYMBOL_CRATE = 'C'
    SYMBOL_GOAL = 'X'
    SYMBOL_SOKOBAN = 'S'
    SYMBOL_SOKOBAN_GOAL = 's'
    SYMBOL_CRATE_GOAL = 'c'

    def __init__(self, map_str: str):
        """
        Initializes SokobanMap.

        Args:
            map_str: String representation of the Sokoban map.
        """
        self.map_grid: List[List[str]] = [list(line) for line in map_str.strip().split('\n') if line.strip()]
        self.height = len(self.map_grid)
        self.width = max(len(row) for row in self.map_grid) if self.map_grid else 0
    

    @classmethod
    def read_map_file(cls, file_path: str) -> str:
        """
        Reads the content of a map file and returns it as a string.

        Args:
            file_path: Path to the map file.

        Returns:
            A string containing the map.
        """
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                return file.read()
        except FileNotFoundError:
            raise FileNotFoundError(f"Map file not found: {file_path}")
        except Exception as e:
            raise Exception(f"Error reading map file {file_path}: {e}")

    @staticmethod
    def write_map_file(file_path: str, map_str: str) -> None:
        """
        Writes the map string to a file.

        Args:
            file_path: Path to the output map file.
            map_str: String representation of the Sokoban map.
        """
        try:
            with open(file_path, 'w', encoding='utf-8') as file:
                file.write(map_str)
        except Exception as e:
            raise Exception(f"Error writing map file {file_path}: {e}")
        
    def to_string(self) -> str:
        """
        Converts the current map grid to a string representation.

        Returns:
            A string representing the current state of the map.
        """
        return '\n'.join(''.join(row) for row in self.map_grid)

    def get_map_steps(self, steps: List[str]) -> List[str]:
        """
        Applies a list of steps to the map and returns the map state after each step.

        Args:
            steps: A list of step actions.

        Returns:
            A list of map strings representing the state after each step.
        """
        map_states = [self.to_string()]  # Initial state
        for step in steps:
            self.apply_step(step)
            map_str = self.to_string()
            map_states.append(map_str)
        return map_states
    
    def _set_cell(self, from_r, from_c, symbol): 
        self.map_grid[from_r][from_c] = symbol

    def apply_step(self, step: str) -> None:
        """
        Applies one step to update the map.

        Args:
            step: Action in the format of ASP literals (e.g., do(push(...)), do(move(...)), do(moveRight(...))).
        """
        if step.startswith("do(push"):
            self._apply_push(step)
        elif step.startswith("do(move"):
            self._apply_move(step)
        else:
            print(f"Unknown step format: {step}")

    def _apply_push(self, step: str) -> None:
        """
        Applies a push action to the map.

        Args:
            step: Push action literal, e.g., do(pushRight(sokoban,l1_4,l1_5,l1_6,crate_01), 3).
        """
        try:
            # Extract content inside do(pushRight(...), step_num)
            inside = step[step.find('(')+1 : step.rfind(')')]  # 'pushRight(sokoban,l1_4,l1_5,l1_6,crate_01), 3'

            # Split into action and step number
            action_str, step_num_str = self._split_step_arguments(inside, expected=2)

            # Parse action string, e.g., 'pushRight(sokoban,l1_4,l1_5,l1_6,crate_01)'
            action_name_start = action_str.find('(')
            if action_name_start == -1:
                raise ValueError(f"Incorrect action format: {action_str}")
            action_name = action_str[:action_name_start]
            action_inside = action_str[action_name_start + 1 : -1]  # 'sokoban,l1_4,l1_5,l1_6,crate_01'

            # Split action arguments, expecting 5 arguments
            args = self._split_step_arguments(action_inside, expected=5)
            #print(f"args: {args}")
            entity, from_l, to_l, crate_to, crate_name = args

            from_r, from_c = self._cell_id_to_coords(to_l)
            to_r, to_c = self._cell_id_to_coords(crate_to)
            self._move_crate(from_r, from_c, to_r, to_c)
            # Move Sokoban from from_l to to_l
            from_r, from_c = self._cell_id_to_coords(from_l)
            to_r, to_c = self._cell_id_to_coords(to_l)
            self._move_sokoban(from_r, from_c, to_r, to_c)

        except Exception as e:
            print(f"Error processing push step '{step}': {e}")

    def _apply_move(self, step: str) -> None:
        """
        Applies a move action to the map.

        Args:
            step: Move action literal (e.g., do(move(...), step_num), do(moveRight(...), step_num)).
        """
        try:
            # Extract content inside do(moveRight(sokoban,l1_2,l1_3), 1)
            start = step.find('(') + 1
            end = step.rfind(')')
            inside = step[start:end]  # 'moveRight(sokoban,l1_2,l1_3), 1'

            # Split into action and step number
            action_str, step_num_str = self._split_step_arguments(inside, expected=2)

            # Now parse action string, e.g., 'moveRight(sokoban,l1_2,l1_3)'
            action_name_start = action_str.find('(')
            if action_name_start == -1:
                raise ValueError(f"Incorrect action format: {action_str}")
            action_name = action_str[:action_name_start]
            action_inside = action_str[action_name_start + 1:-1]  # 'sokoban,l1_2,l1_3'

            # Split action arguments
            action_parts = self._split_step_arguments(action_inside, expected=3)
            entity, from_l, to_l = action_parts

            from_r, from_c = self._cell_id_to_coords(from_l)
            to_r, to_c = self._cell_id_to_coords(to_l)

            # Move the entity
            self._move_sokoban(from_r, from_c, to_r, to_c)
        except Exception as e:
            print(f"Error processing move step '{step}': {e}")

    def _move_sokoban(self, from_r: int, from_c: int, to_r: int, to_c: int) -> None:
        """
        Moves Sokoban from one cell to another.

        Args:
            from_r: Starting row.
            from_c: Starting column.
            to_r: Target row.
            to_c: Target column.
        """
        current_symbol = self.map_grid[from_r][from_c]
        #print(f"current symbol: '{current_symbol}'")
        print(f"current location: {(from_r, from_c)}")
        
        if current_symbol not in (self.SYMBOL_SOKOBAN, self.SYMBOL_SOKOBAN_GOAL):
            raise ValueError(f"There is no Sokoban at position ({from_r}, {from_c}).")
        
        # Clear the original cell
        if current_symbol == self.SYMBOL_SOKOBAN:
            self._set_cell(from_r, from_c, ' ')
        elif current_symbol == self.SYMBOL_SOKOBAN_GOAL:
            self._set_cell(from_r, from_c, self.SYMBOL_GOAL)
        
        # Update the target cell
        if self.map_grid[to_r][to_c] == self.SYMBOL_GOAL:
            self.map_grid[to_r][to_c] = self.SYMBOL_SOKOBAN_GOAL
        else:
            self.map_grid[to_r][to_c] = self.SYMBOL_SOKOBAN

    def _move_crate(self, from_r: int, from_c: int, to_r: int, to_c: int) -> None:
        """
        Moves a crate from one cell to another.

        Args:
            from_r: Starting row.
            from_c: Starting column.
            to_r: Target row.
            to_c: Target column.
        """
        current_symbol = self.map_grid[from_r][from_c]
        #print(f"current symbol: '{current_symbol}'")
        print(f"current location: {(from_r, from_c)}")
        assert current_symbol in (self.SYMBOL_CRATE, self.SYMBOL_CRATE_GOAL), f"There is no crate at position ({from_r}, {from_c})."
        if current_symbol not in (self.SYMBOL_CRATE, self.SYMBOL_CRATE_GOAL):
            raise ValueError(f"There is no crate at position ({from_r}, {from_c}).")
        
        # Clear the original cell
        if current_symbol == self.SYMBOL_CRATE:
            self._set_cell(from_r, from_c, ' ')
        elif current_symbol == self.SYMBOL_CRATE_GOAL:
            self._set_cell(from_r, from_c, self.SYMBOL_GOAL)
        
        # Update the target cell
        if self.map_grid[to_r][to_c] == self.SYMBOL_GOAL:
            self.map_grid[to_r][to_c] = self.SYMBOL_CRATE_GOAL
        else:
            self.map_grid[to_r][to_c] = self.SYMBOL_CRATE


    def _cell_id_to_coords(self, cell_id: str) -> Tuple[int, int]:
        """
        Converts a cell identifier to row and column coordinates.

        Args:
            cell_id: Cell identifier in string format, e.g., 'l0_1'.

        Returns:
            A tuple of two integers (row, column).

        Raises:
            ValueError: If the cell identifier format is incorrect.
        """
        try:
            if cell_id.startswith('l'):
                cell_id = cell_id[1:]
            row_str, col_str = cell_id.split('_')
            row = int(row_str)
            col = int(col_str)
            return row, col
        except Exception as e:
            raise ValueError(f"Incorrect cell_id format: {cell_id}") from e

    def _split_step_arguments(self, step_str: str, expected: int) -> List[str]:
        """
        Splits step arguments, considering nested parentheses.

        Args:
            step_str: String inside do(push(...)) or do(move(...)).
            expected: Expected number of arguments.

        Returns:
            List of arguments.

        Raises:
            ValueError: If the number of arguments does not match the expected.
        """
        args = []
        current = ''
        depth = 0
        for char in step_str:
            if char == ',' and depth == 0:
                args.append(current.strip())
                current = ''
            else:
                if char == '(':
                    depth += 1
                elif char == ')':
                    depth -= 1
                current += char
        if current:
            args.append(current.strip())
        if len(args) != expected:
            raise ValueError(f"Expected {expected} arguments, got {len(args)} in step: {step_str}")
        return args

    def visualize(self) -> None:
        """
        Prints the current state of the Sokoban map.
        """
        for row in self.map_grid:
            print(''.join(row))


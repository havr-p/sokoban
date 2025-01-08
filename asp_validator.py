from typing import Dict, Set, List, Tuple
import re
from dataclasses import dataclass
from collections import defaultdict

@dataclass(frozen=True)
class Position:
    x: int
    y: int
    
    @classmethod
    def from_pos_str(cls, pos_str: str) -> 'Position':
        """Convert 'pos_x_y' string to Position object."""
        _, x, y = pos_str.split('_')
        return cls(int(x), int(y))
    
    def is_adjacent(self, other: 'Position') -> bool:
        """Check if positions are adjacent."""
        return abs(self.x - other.x) + abs(self.y - other.y) == 1
    
    def __str__(self) -> str:
        return f"pos_{self.x}_{self.y}"

    def get_adjacent_positions(self) -> List[Tuple['Position', str]]:
        """Get all adjacent positions with their direction names."""
        return [
            (Position(self.x-1, self.y), 'left'),
            (Position(self.x+1, self.y), 'right'),
            (Position(self.x, self.y+1), 'up'),
            (Position(self.x, self.y-1), 'down')
        ]

class SokobanASPValidator:
    """Validates Sokoban map encodings with focus on semantic correctness."""
    
    CELL_TYPES = {
        '#': 'wall',
        'S': 'player',
        'C': 'stone',
        'X': 'goal',
        's': 'player_on_goal',
        'c': 'stone_on_goal',
        ' ': 'free'
    }
    
    DIRECTIONS = ['left', 'right', 'up', 'down']

    def __init__(self, original_map: str, asp_facts: str):
        self.map_grid = self._parse_map(original_map)
        self.facts = self._parse_facts(asp_facts)
        self.errors: List[str] = []
        
        # Extract key positions
        self.walls = self._get_positions_of_type('wall')
        self.goals = self._get_positions_of_type(['goal', 'player_on_goal', 'stone_on_goal'])
        self.stones = self._get_positions_of_type(['stone', 'stone_on_goal'])
        player_positions = self._get_positions_of_type(['player', 'player_on_goal'])
        self.player = next(iter(player_positions)) if player_positions else None

    def _parse_map(self, map_str: str) -> Dict[Position, str]:
        """Parse map into a grid with Position objects as keys."""
        grid = {}
        for y, line in enumerate(map_str.strip().split('\n'), start=1):
            for x, char in enumerate(line, start=1):
                if char in self.CELL_TYPES:
                    grid[Position(x, y)] = self.CELL_TYPES[char]
        return grid

    def _parse_facts(self, facts_str: str) -> Dict[str, Set[str]]:
        """Parse and categorize ASP facts."""
        categorized = defaultdict(set)
        for fact in facts_str.strip().split('\n'):
            fact = fact.strip()
            if not fact:  # Skip empty lines
                continue
            predicate = fact.split('(')[0]
            categorized[predicate].add(fact)
        return dict(categorized)

    def _get_positions_of_type(self, types: str | list[str]) -> Set[Position]:
        """Get all positions of specified type(s)."""
        if isinstance(types, str):
            types = [types]
        return {pos for pos, type_ in self.map_grid.items() if type_ in types}

    def _extract_position(self, fact: str) -> Position:
        """Extract position from fact string."""
        match = re.search(r'pos_(\d+)_(\d+)', fact)
        if match:
            return Position(int(match.group(1)), int(match.group(2)))
        raise ValueError(f"No position found in fact: {fact}")

    def validate(self) -> bool:
        """Run all semantic validation checks."""
        validators = [
            self._validate_walls_behavior,
            self._validate_movement_rules,
            self._validate_walls_behavior,
        ]
        
        for validator in validators:
            validator()
        
        if self.errors:
            raise AssertionError("ASP Encoding Validation Failed:\n" + 
                               "\n".join(self.errors))
        return True

    def _validate_walls_behavior(self):
        """Validate wall semantics."""
        self._validate_wall_movement()
        self._validate_wall_clear()

    def _validate_wall_movement(self):
        """Check that walls properly block movement."""
        for fact in self.facts.get('movedir', []):
            try:
                match = re.match(r'movedir\((pos_\d+_\d+),(pos_\d+_\d+),dir_\w+\)', fact)
                if match:
                    from_pos = self._extract_position(match.group(1))
                    to_pos = self._extract_position(match.group(2))
                    
                    if from_pos in self.walls or to_pos in self.walls:
                        self._add_error(f"Invalid movedir through wall: {fact}")
                    
                    if not from_pos.is_adjacent(to_pos):
                        self._add_error(f"Non-adjacent positions in movedir: {fact}")
            except (ValueError, AttributeError) as e:
                self._add_error(f"Malformed movedir fact: {fact} - {str(e)}")

    def _validate_wall_clear(self):
        """Check that walls are never marked as clear."""
        for fact in self.facts.get('clear', []):
            try:
                pos = self._extract_position(fact)
                if pos in self.walls:
                    self._add_error(f"Wall position marked as clear: {fact}")
            except ValueError as e:
                self._add_error(f"Malformed clear fact: {fact} - {str(e)}")

    def _validate_movement_rules(self):
        """Validate movement semantics and completeness."""
        self._validate_direction_names()
        self._validate_movement_completeness()
        self._validate_movement_connectivity()

    def _validate_direction_names(self):
        """Check that all direction names are valid."""
        valid_dirs = set(self.DIRECTIONS)
        for fact in self.facts.get('movedir', []):
            match = re.search(r'dir_(\w+)', fact)
            if match and match.group(1) not in valid_dirs:
                self._add_error(f"Invalid direction in fact: {fact}")

    def _validate_movement_completeness(self):
        """Verify all possible valid movements are present."""
        expected_movedir = set()
        
        # Only generate movedir facts for non-wall positions
        for pos in self.map_grid:
            if pos not in self.walls:  # Only consider non-wall positions
                for next_pos, dir_name in pos.get_adjacent_positions():
                    # Only add movedir if both positions are in grid and neither is a wall
                    if (next_pos in self.map_grid and 
                        next_pos not in self.walls):
                        expected = f"movedir({pos},{next_pos},dir_{dir_name})."
                        expected_movedir.add(expected)
                    
        actual_movedir = set(self.facts.get('movedir', []))
        
        if missing := expected_movedir - actual_movedir:
            self._add_error("Missing movedir facts:\n" + 
                          "\n".join(f"  {fact}" for fact in sorted(missing)))
        if extra := actual_movedir - expected_movedir:
            self._add_error("Unexpected movedir facts:\n" + 
                          "\n".join(f"  {fact}" for fact in sorted(extra)))

    def _validate_movement_connectivity(self):
        """Check that non-wall positions have valid moves."""
        for pos in self.map_grid:
            if pos not in self.walls:
                outgoing_moves = self._get_outgoing_moves(pos)
                if not outgoing_moves:
                    self._add_error(f"Position {pos} has no valid moves")

    def _get_outgoing_moves(self, pos: Position) -> Set[Position]:
        """Get all valid moves from a position."""
        moves = set()
        for fact in self.facts.get('movedir', []):
            if str(pos) in fact:
                try:
                    to_pos = self._extract_position(fact.split(',')[1])
                    moves.add(to_pos)
                except (ValueError, IndexError):
                    continue
        return moves

    def _add_error(self, message: str):
        """Add validation error."""
        self.errors.append(message)


def validate_asp_encoding(original_map: str, asp_facts: str) -> bool:
    """
    Validate the semantic correctness of a Sokoban map encoding in ASP format.
    
    Args:
        original_map: Original map encoding as a string
        asp_facts: ASP encoding of the map as a string
    
    Returns:
        True if encoding is valid, otherwise raises AssertionError with details
    """
    validator = SokobanASPValidator(original_map, asp_facts)
    return validator.validate()
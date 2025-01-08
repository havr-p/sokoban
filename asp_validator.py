from typing import Dict, Set, List, Tuple
import re
from dataclasses import dataclass
from collections import defaultdict

@dataclass(frozen=True)  # Make Position immutable and hashable
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
            
            # Categorize based on predicate name
            predicate = fact.split('(')[0]
            categorized[predicate].add(fact)
            
        return dict(categorized)  # Convert defaultdict to regular dict

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
        self._validate_walls_behavior()
        self._validate_movement_rules()
        self._validate_stone_behavior()
        self._validate_player_behavior()
        self._validate_goal_behavior()
        
        if self.errors:
            raise AssertionError("ASP Encoding Validation Failed:\n" + 
                               "\n".join(self.errors))
        return True

    def _validate_walls_behavior(self):
        """Validate wall semantics."""
        # 1. Walls should block movement
        for fact in self.facts.get('movedir', []):
            try:
                # Extract positions from movedir fact
                match = re.match(r'movedir\((pos_\d+_\d+),(pos_\d+_\d+),dir_\w+\)', fact)
                if match:
                    from_pos = self._extract_position(match.group(1))
                    to_pos = self._extract_position(match.group(2))
                    
                    # Check if movement passes through wall
                    if from_pos in self.walls or to_pos in self.walls:
                        self._add_error(f"Invalid movedir through wall: {fact}")
                    
                    # Check if positions are adjacent
                    if not from_pos.is_adjacent(to_pos):
                        self._add_error(f"Non-adjacent positions in movedir: {fact}")
            except (ValueError, AttributeError) as e:
                self._add_error(f"Malformed movedir fact: {fact} - {str(e)}")

        # 2. Walls should never be clear
        for fact in self.facts.get('clear', []):
            try:
                pos = self._extract_position(fact)
                if pos in self.walls:
                    self._add_error(f"Wall position marked as clear: {fact}")
            except ValueError as e:
                self._add_error(f"Malformed clear fact: {fact} - {str(e)}")

    def _validate_movement_rules(self):
        """Validate movement semantics."""
        # Check movement directions are valid
        valid_dirs = set(self.DIRECTIONS)
        for fact in self.facts.get('movedir', []):
            match = re.search(r'dir_(\w+)', fact)
            if match and match.group(1) not in valid_dirs:
                self._add_error(f"Invalid direction in fact: {fact}")
                
        # Validate movement connectivity
        for pos in self.map_grid:
            if pos not in self.walls:
                outgoing_moves = self._get_outgoing_moves(pos)
                if not outgoing_moves:
                    self._add_error(f"Position {pos} has no valid moves")

    def _validate_stone_behavior(self):
        """Validate stone semantics."""
        # 1. Stones cannot occupy the same position
        stone_positions = set()
        for fact in self.facts.get('at', []):
            if 'stone' in fact:
                try:
                    pos = self._extract_position(fact)
                    if pos in stone_positions:
                        self._add_error(f"Multiple stones in same position: {fact}")
                    stone_positions.add(pos)
                except ValueError as e:
                    self._add_error(f"Malformed stone position: {fact} - {str(e)}")

        # 2. Stones cannot be in walls
        for pos in stone_positions:
            if pos in self.walls:
                self._add_error(f"Stone in wall position: {pos}")

    def _validate_player_behavior(self):
        """Validate player semantics."""
        if not self.player:
            self._add_error("No player position found in map")
            return

        # 1. Ensure single player position
        player_positions = set()
        for fact in self.facts.get('at', []):
            if 'player' in fact:
                try:
                    pos = self._extract_position(fact)
                    player_positions.add(pos)
                except ValueError as e:
                    self._add_error(f"Malformed player position: {fact} - {str(e)}")
        
        if len(player_positions) != 1:
            self._add_error(f"Expected exactly one player position, found {len(player_positions)}")

        # 2. Player cannot be in wall
        if self.player in self.walls:
            self._add_error(f"Player in wall position: {self.player}")

    def _validate_goal_behavior(self):
        """Validate goal semantics."""
        # 1. Goals cannot be in walls
        for pos in self.goals:
            if pos in self.walls:
                self._add_error(f"Goal in wall position: {pos}")

        # 2. Validate goal/nongoal consistency
        positions = set(self.map_grid.keys())
        goal_facts = {self._extract_position(f) for f in self.facts.get('isgoal', [])}
        nongoal_facts = {self._extract_position(f) for f in self.facts.get('isnongoal', [])}
        
        # Check that every position is either goal or nongoal
        if positions != goal_facts.union(nongoal_facts):
            self._add_error("Not all positions are marked as goal or nongoal")
        
        # Check no position is both goal and nongoal
        if goal_facts.intersection(nongoal_facts):
            self._add_error("Some positions are marked as both goal and nongoal")

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
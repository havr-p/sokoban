import re
from asp_validator import validate_asp_encoding
import pytest # type: ignore
import difflib
from typing import Dict, Set, List, Tuple
from tabulate import tabulate # type: ignore
import os

from solver_gen1 import generate_sokoban_lp_from_map

# how to run: pytest map_test.py --tb=short -v -s

# Directories for maps and expected outputs
MAPS_DIR = os.path.join(os.path.dirname(__file__), 'maps')
EXPECTED_DIR = os.path.join(os.path.dirname(__file__), 'expected')

def read_file(file_path: str) -> str:
    """Reads the content of a file and returns it as a string."""
    with open(file_path, 'r', encoding='utf-8') as file:
        print(f"current map: {file.name}")
        return file.read()

def format_facts_by_type(facts: Set[str]) -> str:
    """Groups facts by predicates and formats them for output."""
    facts_by_type = {}
    for fact in facts:
        predicate = fact.split('(')[0]
        if predicate not in facts_by_type:
            facts_by_type[predicate] = []
        facts_by_type[predicate].append(fact)
    
    result = []
    for predicate, fact_list in sorted(facts_by_type.items()):
        result.append(f"\n{predicate} facts:")
        result.extend(f"  {fact}" for fact in sorted(fact_list))
    return '\n'.join(result)

def compare_facts_side_by_side(expected: Set[str], actual: Set[str]) -> str:
    """
    Compares expected and actual facts and returns a table with their comparison.
    Missing facts are marked as 'Missing', extra facts as 'Extra'.
    """
    common_facts = expected.intersection(actual)
    missing_facts = sorted(expected - actual)
    extra_facts = sorted(actual - expected)
    
    table: List[Tuple[str, str, str]] = []
    
    for fact in sorted(common_facts):
        table.append((fact, fact, ""))
    
    for fact in missing_facts:
        table.append((fact, "", "Missing"))
    
    for fact in extra_facts:
        table.append(("", fact, "Extra"))
    
    header = ["Expected", "Actual", "Status"]
    table_str = tabulate(table, headers=header, tablefmt="grid", stralign="left")
    
    return table_str

def compare_facts_detailed(expected: str, actual: str) -> str:
    """
    Compares expected and actual facts, sorted, and returns a detailed diff with line lengths.
    """
    expected_lines = sorted(line.strip() for line in expected.strip().splitlines() if line.strip())
    actual_lines = sorted(line.strip() for line in actual.strip().splitlines() if line.strip())
    
    diff = difflib.unified_diff(
        expected_lines, actual_lines, 
        fromfile='expected', tofile='actual', 
        lineterm=''
    )
    
    diff_output = []
    for line in diff:
        if line.startswith('---') or line.startswith('+++') or line.startswith('@@'):
            diff_output.append(line)
        elif line.startswith('+') or line.startswith('-'):
            fact = line[1:].strip()
            diff_output.append(f"{line} (length: {len(fact)})")
        else:
            fact = line.strip()
            diff_output.append(f"{line} (length: {len(fact)})")
    return "\n".join(diff_output)

@pytest.mark.parametrize("map_file,expected_file", [
    # ("map1.txt", "expected1.txt"),
    # ("map2.txt", "expected2.txt"),
    # ("map3.txt", "expected3.txt"),
    ("map4.txt", "expected4.txt"),
    ("map5.txt", "expected5.txt"),
    # ("map6.txt", "expected6.txt"),
    # ("map7.txt", "expected7.txt"),
    # ("map8.txt", "expected8.txt"),
])
def test_generate_sokoban_lp(map_file: str, expected_file: str):
    """
    Parameterized test for the generate_sokoban_lp_from_map function,
    which checks various maps and their expected ASP facts.
    """
    map_path = os.path.join(MAPS_DIR, map_file)
    expected_path = os.path.join(EXPECTED_DIR, expected_file)
    
    map_str = read_file(map_path)
    print('\ncurrent map\n')
    print(map_str)
    expected_output = read_file(expected_path)
    
    actual_output = generate_sokoban_lp_from_map(map_str)
    
    output_dir = os.path.join(os.path.dirname(__file__), 'maps_out')
    os.makedirs(output_dir, exist_ok=True)
    
    actual_output_path = os.path.join(output_dir, f"generated_{map_file}")
    
    with open(actual_output_path, 'w', encoding='utf-8') as file:
        file.write(actual_output)
    
    try:
        validate_asp_encoding(map_str, actual_output)
    except AssertionError as e:
        print(f"\nTest failed for {map_file}! Differences found:\n\n{str(e)}")
    
    expected_facts = set(line.strip() for line in expected_output.strip().split('\n') if line.strip())
    actual_facts = set(line.strip() for line in actual_output.strip().split('\n') if line.strip())
    
    if expected_facts != actual_facts:
        error_msg = f"\nTest failed for {map_file}! Differences found:\n\n"
        error_msg += compare_facts_side_by_side(expected_facts, actual_facts)
        pytest.fail(error_msg)
    else:
        print("MAP GENERATED CORRECTLY")

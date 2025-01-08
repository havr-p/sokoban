from typing import Set
import pytest
import textwrap
from solver_gen1 import generate_sokoban_lp_from_map

def test_generate_sokoban_lp():
    """
    Test for generate_sokoban_lp_from_map function that converts Sokoban map to ASP facts.

    How to run:
    1. Install pytest: 
       pip install pytest

    2. Save this test in test_sokoban.py in the same directory as your main code
    
    3. Run test:
       pytest test_sokoban.py
       
    4. For more detailed output use:
       pytest test_sokoban.py -v

    5. To see print statements during test:
       pytest test_sokoban.py -s
    """
    # Test input map без ведущих пробелов
    test_map = textwrap.dedent("""\
        #########
        #S  C  X#
        #########""")
    
    # Ожидаемый ASP facts output
    expected_output = """player(player_01).
stone(stone_01).
isgoal(pos_8_2).
isnongoal(pos_1_1).
isnongoal(pos_2_1).
isnongoal(pos_3_1).
isnongoal(pos_4_1).
isnongoal(pos_5_1).
isnongoal(pos_6_1).
isnongoal(pos_1_2).
isnongoal(pos_2_2).
isnongoal(pos_2_3).
isnongoal(pos_3_2).
isnongoal(pos_3_3).
isnongoal(pos_4_2).
isnongoal(pos_4_3).
isnongoal(pos_5_2).
isnongoal(pos_5_3).
isnongoal(pos_6_2).
isnongoal(pos_6_3).
isnongoal(pos_7_2).
isnongoal(pos_7_3).
movedir(pos_2_2,pos_3_2,dir_right).
movedir(pos_3_2,pos_2_2,dir_left).
movedir(pos_2_2,pos_2_3,dir_right).
movedir(pos_2_3,pos_2_2,dir_left).
movedir(pos_2_4,pos_2_5,dir_right).
movedir(pos_2_5,pos_2_4,dir_left).
movedir(pos_2_5,pos_2_6,dir_right).
movedir(pos_2_6,pos_2_5,dir_left).
movedir(pos_2_6,pos_2_7,dir_right).
movedir(pos_2_7,pos_2_6,dir_left).
movedir(pos_2_7,pos_2_8,dir_right).
movedir(pos_2_8,pos_2_7,dir_left).
at(player_01,pos_2_2).
at(stone_01,pos_5_2).
clear(pos_3_2).
clear(pos_4_2).
clear(pos_6_2).
clear(pos_7_2).
clear(pos_8_2).
goal(stone_01)."""

    def format_differences_with_length(missing_facts: Set[str], extra_facts: Set[str]) -> str:
        differences = []
        if missing_facts:
            differences.append("\nMissing facts:")
            for fact in sorted(missing_facts):
                differences.append(f"  {fact} (length: {len(fact)})")
        if extra_facts:
            differences.append("\nExtra facts:")
            for fact in sorted(extra_facts):
                differences.append(f"  {fact} (length: {len(fact)})")
        return "\n".join(differences)
    
    def format_facts_by_type(facts: Set[str]) -> str:
        """Group facts by their predicate and format them nicely"""
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

    # Получаем факты из функции
    actual_output = generate_sokoban_lp_from_map(test_map)

    # Преобразуем выводы в множества для сравнения
    expected_facts = set(expected_output.strip().split('\n'))
    actual_facts = set(actual_output.strip().split('\n'))

    # Если факты не совпадают, создаём подробное сообщение об ошибке
    if expected_facts != actual_facts:
        missing_facts = expected_facts - actual_facts
        extra_facts = actual_facts - expected_facts
        
        error_msg = "\nTest failed! Differences found:"
        
        # if missing_facts:
        #     error_msg += "\n\nMissing facts (should be present but aren't):" 
        #     error_msg += format_facts_by_type(missing_facts)
        
        # if extra_facts:
        #     error_msg += "\n\nExtra facts (shouldn't be present but are):"
        #     error_msg += format_facts_by_type(extra_facts)
            
        # error_msg += "\n\nExpected facts:"
        # error_msg += format_facts_by_type(expected_facts)
        
        # error_msg += "\n\nActual facts:"
        # error_msg += format_facts_by_type(actual_facts)
        error_msg += format_differences_with_length(missing_facts, extra_facts)
        
        pytest.fail(error_msg)
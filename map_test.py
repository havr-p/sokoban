import pytest
import textwrap
import difflib
from typing import Set, List, Tuple

from solver_gen1 import generate_sokoban_lp_from_map  # Убедитесь, что путь импорта корректен

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
    # Используем textwrap.dedent для удаления общих отступов
    test_map = textwrap.dedent("""\
        #########
        #S  C  X#
        #########""")
    
    # Ожидаемый ASP facts output
    expected_output = """player(player_01).
stone(stone_01).
isgoal(pos_8_2).
isnongoal(pos_1_1).
isnongoal(pos_1_2).
isnongoal(pos_1_3).
isnongoal(pos_2_1).
isnongoal(pos_2_2).
isnongoal(pos_2_3).
isnongoal(pos_3_1).
isnongoal(pos_3_2).
isnongoal(pos_3_3).
isnongoal(pos_4_1).
isnongoal(pos_4_2).
isnongoal(pos_4_3).
isnongoal(pos_5_1).
isnongoal(pos_5_2).
isnongoal(pos_5_3).
isnongoal(pos_6_1).
isnongoal(pos_6_2).
isnongoal(pos_6_3).
isnongoal(pos_7_1).
isnongoal(pos_7_2).
isnongoal(pos_7_3).
isnongoal(pos_8_1).
isnongoal(pos_8_3).
isnongoal(pos_9_1).
isnongoal(pos_9_2).
isnongoal(pos_9_3).
movedir(pos_2_2,pos_3_2,dir_right).
movedir(pos_3_2,pos_2_2,dir_left).
movedir(pos_3_2,pos_4_2,dir_right).
movedir(pos_4_2,pos_3_2,dir_left).
movedir(pos_4_2,pos_5_2,dir_right).
movedir(pos_5_2,pos_4_2,dir_left).
movedir(pos_5_2,pos_6_2,dir_right).
movedir(pos_6_2,pos_5_2,dir_left).
movedir(pos_6_2,pos_7_2,dir_right).
movedir(pos_7_2,pos_6_2,dir_left).
movedir(pos_7_2,pos_8_2,dir_right).
movedir(pos_8_2,pos_7_2,dir_left).
at(player_01,pos_2_2).
at(stone_01,pos_5_2).
clear(pos_3_2).
clear(pos_4_2).
clear(pos_6_2).
clear(pos_7_2).
clear(pos_8_2).
goal(stone_01)."""
    
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
    
    def compare_facts_side_by_side(expected: Set[str], actual: Set[str]) -> str:
        """
        Compare expected and actual facts and return a side-by-side comparison.
        Missing facts will have an empty string in actual column.
        Extra facts will have an empty string in expected column.
        """
        # Найти общие, отсутствующие и дополнительные факты
        common_facts = expected.intersection(actual)
        missing_facts = sorted(expected - actual)
        extra_facts = sorted(actual - expected)
        
        # Подготовка таблицы
        table: List[Tuple[str, str, str]] = []
        
        # Добавляем общие факты
        for fact in sorted(common_facts):
            table.append((fact, fact, ""))
        
        # Добавляем отсутствующие факты
        for fact in missing_facts:
            table.append((fact, "", "Missing"))
        
        # Добавляем дополнительные факты
        for fact in extra_facts:
            table.append(("", fact, "Extra"))
        
        # Определение ширины колонок
        expected_col_width = max((len(fact) for fact in expected), default=0)
        actual_col_width = max((len(fact) for fact in actual), default=0)
        
        # Заголовки таблицы
        header = f"{'Expected':<{expected_col_width}} | {'Actual':<{actual_col_width}} | {'Status'}"
        separator = f"{'-'*expected_col_width}-+-{'-'*actual_col_width}-+-{'-'*6}"
        table_rows = [header, separator]
        
        # Добавляем строки таблицы
        for exp, act, status in table:
            table_rows.append(f"{exp:<{expected_col_width}} | {act:<{actual_col_width}} | {status}")
        
        return "\n".join(table_rows)
    
    def compare_facts_detailed(expected: str, actual: str) -> str:
        """
        Compare expected and actual ASP facts, sorted, and return a detailed diff with line lengths.
        """
        # Разделяем строки и сортируем
        expected_lines = sorted(line.strip() for line in expected.strip().splitlines() if line.strip())
        actual_lines = sorted(line.strip() for line in actual.strip().splitlines() if line.strip())
        
        # Генерируем дифф
        diff = difflib.unified_diff(
            expected_lines, actual_lines, 
            fromfile='expected', tofile='actual', 
            lineterm=''
        )
        
        # Форматируем дифф с длиной строк
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
    
    # Получаем факты из функции
    actual_output = generate_sokoban_lp_from_map(test_map)
    
    # Преобразуем выводы в множества для сравнения, убирая лишние пробелы
    expected_facts = set(line.strip() for line in expected_output.strip().split('\n') if line.strip())
    actual_facts = set(line.strip() for line in actual_output.strip().split('\n') if line.strip())
    
    # Если факты не совпадают, создаём подробное сообщение об ошибке
    if expected_facts != actual_facts:
        missing_facts = expected_facts - actual_facts
        extra_facts = actual_facts - expected_facts
        
        error_msg = "\nTest failed! Differences found:\n\n"
        
        # Добавляем различия в виде таблицы
        error_msg += compare_facts_side_by_side(expected_facts, actual_facts)
        
        # Добавляем подробный дифф
        # error_msg += "\n\nDetailed Diff (sorted lines with lengths):\n"
        # error_msg += compare_facts_detailed(expected_output, actual_output)
        
        # # Дополнительно можно вывести все факты по типам
        # error_msg += "\n\nExpected facts grouped by type:"
        # error_msg += format_facts_by_type(expected_facts)
        
        # error_msg += "\n\nActual facts grouped by type:"
        # error_msg += format_facts_by_type(actual_facts)
        
        pytest.fail(error_msg)

def test_map1():
    

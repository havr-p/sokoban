import pytest
import textwrap
import difflib
from typing import Set, List, Tuple
from tabulate import tabulate
import os

from solver_gen1 import generate_sokoban_lp_from_map
#how to run: pytest map_test.py --tb=short -v

MAPS_DIR = os.path.join(os.path.dirname(__file__), 'maps')
EXPECTED_DIR = os.path.join(os.path.dirname(__file__), 'expected')

def read_file(file_path: str) -> str:
    """Читает содержимое файла и возвращает его как строку."""
    with open(file_path, 'r', encoding='utf-8') as file:
        return file.read()

def format_facts_by_type(facts: Set[str]) -> str:
    """Группирует факты по предикатам и форматирует их для вывода."""
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
    Сравнивает ожидаемые и фактические факты и возвращает таблицу с их сопоставлением.
    Отсутствующие факты отмечены как 'Missing', дополнительные как 'Extra'.
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
    header = ["Expected", "Actual", "Status"]
    
    # Используем tabulate для красивого вывода таблицы
    table_str = tabulate(table, headers=header, tablefmt="grid", stralign="left")
    
    return table_str

def compare_facts_detailed(expected: str, actual: str) -> str:
    """
    Сравнивает ожидаемые и фактические факты, отсортированные, и возвращает подробный дифф с длиной строк.
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
    Параметризованный тест для функции generate_sokoban_lp_from_map,
    который проверяет различные карты и их ожидаемые ASP факты.
    """
    # Полные пути к файлам
    map_path = os.path.join(MAPS_DIR, map_file)
    expected_path = os.path.join(EXPECTED_DIR, expected_file)
    
    # Чтение карты и ожидаемого вывода
    map_str = read_file(map_path)
    expected_output = read_file(expected_path)
    
    # Генерируем факты с помощью функции
    actual_output = generate_sokoban_lp_from_map(map_str)
    
    # Преобразуем выводы в множества для сравнения, убирая лишние пробелы
    expected_facts = set(line.strip() for line in expected_output.strip().split('\n') if line.strip())
    actual_facts = set(line.strip() for line in actual_output.strip().split('\n') if line.strip())
    
    # Если факты не совпадают, создаём подробное сообщение об ошибке
    if expected_facts != actual_facts:
        missing_facts = expected_facts - actual_facts
        extra_facts = actual_facts - expected_facts
        
        error_msg = f"\nTest failed for {map_file}! Differences found:\n\n"
        
        # Добавляем различия в виде таблицы
        error_msg += compare_facts_side_by_side(expected_facts, actual_facts)
        
        # Добавляем подробный дифф
        error_msg += "\n\nDetailed Diff (sorted lines with lengths):\n"
        error_msg += compare_facts_detailed(expected_output, actual_output)
        
        # Дополнительно можно вывести все факты по типам
        error_msg += "\n\nExpected facts grouped by type:"
        error_msg += format_facts_by_type(expected_facts)
        
        error_msg += "\n\nActual facts grouped by type:"
        error_msg += format_facts_by_type(actual_facts)
        
        pytest.fail(error_msg)
    else:
        print("MAP GENERATED CORRECTLY")
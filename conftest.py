# conftest.py

from typing import List, Tuple
import pytest


def get_test_cases() -> List[Tuple[str, str]]:
    """Define all available test cases."""
    return [
        ("map1.txt", "expected1.txt"),
        #("map2.txt", "expected2.txt"),
        #("map3.txt", "expected3.txt"),
        ("map4.txt", "expected4.txt"),
        ("map5.txt", "expected5.txt"),
        ("map6.txt", "expected6.txt"),
        #("map7.txt", "expected7.txt"),
        ("map8.txt", "expected8.txt"),
    ]


def pytest_addoption(parser):
    """Add a custom command-line option to pytest."""
    parser.addoption(
        "--map",
        action="store",
        default=None,
        help="Specify a single map to test (e.g., --map=map1.txt). If not provided, all maps are tested.",
    )


def pytest_generate_tests(metafunc):
    """Parametrize test functions based on the presence of 'map_file' and 'expected_file' parameters."""
    if "map_file" in metafunc.fixturenames and "expected_file" in metafunc.fixturenames:
        selected_map = metafunc.config.getoption("--map")
        
        if selected_map is not None:
            # Filter test cases to only include the selected map
            test_cases = [(m, e) for m, e in get_test_cases() if m == selected_map]
            if not test_cases:
                raise ValueError(f"No test case found for map: {selected_map}")
        else:
            # Use all test cases
            test_cases = get_test_cases()
        
        metafunc.parametrize("map_file,expected_file", test_cases)


@pytest.fixture
def selected_map(request):
    """Fixture to retrieve the selected map from command-line options."""
    return request.config.getoption("--map")


def pytest_keyboard_interrupt(excinfo):
    """Handle keyboard interrupts gracefully."""
    # Implement any necessary teardown here
    pass

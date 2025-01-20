# conftest.py

import pytest


def pytest_addoption(parser):
    parser.addoption(
        "--map",
        action="store",
        default=None,
        help="Specify the map file to test (e.g., map4.txt)."
    )

@pytest.fixture
def selected_map(request):
    return request.config.getoption("--map")

def pytest_keyboard_interrupt(excinfo):
    # Calling tearDown.
    pass
"""
Tests for pylaschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pylaschooldata
    assert pylaschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pylaschooldata
    assert hasattr(pylaschooldata, 'fetch_enr')
    assert callable(pylaschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pylaschooldata
    assert hasattr(pylaschooldata, 'get_available_years')
    assert callable(pylaschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pylaschooldata
    assert hasattr(pylaschooldata, '__version__')
    assert isinstance(pylaschooldata.__version__, str)

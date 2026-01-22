import pytest
import sys
import os

# Add the parent directory to the path to import modules
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def test_imports():
    """Test that all main modules can be imported"""
    try:
        import deshboard
        import store_data_in_db
        import is_clientId_project_validate
        import Final_setup
        import fetch_meter_from_db
        assert True
    except ImportError as e:
        pytest.fail(f"Failed to import module: {e}")

def test_streamlit_import():
    """Test that streamlit is properly imported"""
    try:
        import streamlit as st
        assert st.__version__ is not None
    except ImportError:
        pytest.fail("Streamlit is not installed")

def test_database_imports():
    """Test that database modules can be imported"""
    try:
        import psycopg2
        import sqlalchemy
        assert True
    except ImportError as e:
        pytest.fail(f"Failed to import database module: {e}")

def test_pandas_import():
    """Test that pandas is properly imported"""
    try:
        import pandas as pd
        assert pd.__version__ is not None
    except ImportError:
        pytest.fail("Pandas is not installed")

def test_langchain_imports():
    """Test that LangChain modules can be imported"""
    try:
        import langchain
        import langgraph
        assert True
    except ImportError as e:
        pytest.fail(f"Failed to import LangChain module: {e}")

def test_helper_functions():
    """Test helper function imports"""
    try:
        import sys
        import os
        sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        from helper_function import parse_test_data, get_commandType_only
        assert True
    except ImportError as e:
        pytest.fail(f"Failed to import helper functions: {e}")
    except Exception as e:
        pytest.fail(f"Error importing helper functions: {e}")

def test_main_entry():
    """Test that main.py can be executed without errors"""
    import subprocess
    import sys
    
    # Test that main.py exists and is readable
    assert os.path.exists("main.py"), "main.py does not exist"
    
    # Test that main.py can be imported
    try:
        import main
        assert True
    except ImportError as e:
        pytest.fail(f"Failed to import main module: {e}")

def test_requirements_file():
    """Test that requirements.txt exists and contains expected packages"""
    assert os.path.exists("requirements.txt"), "requirements.txt does not exist"
    
    with open("requirements.txt", "r") as f:
        requirements = f.read()
        
    expected_packages = [
        "psycopg2-binary",
        "sqlalchemy", 
        "pandas",
        "streamlit",
        "python-dotenv",
        "langchain",
        "langgraph",
        "requests",
        "openpyxl",
        "xlsxwriter"
    ]
    
    for package in expected_packages:
        assert package in requirements, f"Package {package} not found in requirements.txt"

def test_dockerfile_exists():
    """Test that Dockerfile exists and has expected content"""
    assert os.path.exists("dockerfile"), "dockerfile does not exist"
    
    with open("dockerfile", "r") as f:
        dockerfile_content = f.read()
        
    assert "FROM python:" in dockerfile_content, "Dockerfile should have Python base image"
    assert "streamlit" in dockerfile_content, "Dockerfile should include streamlit command"
    assert "EXPOSE 8501" in dockerfile_content, "Dockerfile should expose port 8501"

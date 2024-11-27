import pytest

from package import BigQuery
from package import SecretManager 

def test_bigquery_instantiation():
    """
    Simply tests if the BigQuery class can be instantiated without errors.
    """
    bq = BigQuery("my-project-id") 
    assert isinstance(bq, BigQuery)  # Check if it's an instance of the class

def test_secret_manager_instantiation():
    """
    Simply tests if the SecretManager class can be instantiated without errors.
    """
    sm = SecretManager("my-project-id")  
    assert isinstance(sm, SecretManager)  # Check if it's an instance of the class
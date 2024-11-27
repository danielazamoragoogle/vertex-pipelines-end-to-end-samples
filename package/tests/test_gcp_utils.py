import pytest

from package import BigQuery

def test_bigquery_instantiation():
    """
    Simply tests if the BigQuery class can be instantiated without errors.
    """
    bq = BigQuery("my-project-id") 
    assert isinstance(bq, BigQuery)  # Check if it's an instance of the class
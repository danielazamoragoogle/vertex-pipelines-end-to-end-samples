import pandas as pd

from google.cloud import bigquery
from google.oauth2 import service_account

import json

class BigQuery:
    def __init__(self, project_id: str=None) -> None:
        self.project_id = project_id
        
    def bq_to_df(
        self, query: str, credentials=None, sa_info: str = None, 
    ):
        """
        Run a BQ query and place the results in a pandas dataframe.

        This function provides flexibility in authentication, allowing you to use either:

        1. **Existing Credentials:** Pass an existing `google.oauth2.service_account.Credentials`
           object directly.
        2. **Default Credentials:** Attempt to use the default Google Cloud credentials.

        Args:
            project_id: Google Cloud project ID.
            query: SQL query to execute.
            credentials: (Optional) Existing `google.oauth2.service_account.Credentials` object.

        Returns:
            pandas.DataFrame: DataFrame containing the results of the query.
        """
        if credentials:
            bq_client = bigquery.Client(
                credentials=credentials, project=credentials.project_id
            )
        elif sa_info:
            credentials = service_account.Credentials.from_service_account_info(
                json.loads(sa_info)
            )
            bq_client = bigquery.Client(
                credentials=credentials, project=credentials.project_id
            )
        else:
            bq_client = bigquery.Client(project=self.project_id)

        df = bq_client.query(query).to_dataframe()
        return df
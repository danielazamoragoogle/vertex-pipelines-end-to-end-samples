import pandas as pd

from google.cloud import bigquery
from google.oauth2 import service_account

from google.cloud import secretmanager
import google_crc32c

from pathlib import Path
from jinja2 import Template

import json

class SecretManager:
    def __init__(self, project_id: str) -> None:
        self.project_id = project_id
        
    def create_secret(
        self, secret_id: str, 
    ) -> secretmanager.Secret:
        """
        Create a new secret with the given name. A secret is a logical wrapper
        around a collection of secret versions. Secret versions hold the actual
        secret material.

         Args:
            project_id (str): The project ID where the secret is to be created.
            secret_id (str): The ID to assign to the new secret. This ID must be unique within the project.
            ttl (Optional[str]): An optional string that specifies the secret's time-to-live in seconds with
                                 format (e.g., "900s" for 15 minutes). If specified, the secret
                                 versions will be automatically deleted upon reaching the end of the TTL period.

        Returns:
            secretmanager.Secret: An object representing the newly created secret, containing details like the
                                  secret's name, replication settings, and optionally its TTL.

        Example:
            # Create a secret with automatic replication and no TTL
            new_secret = create_secret("my-project", "my-new-secret")

            # Create a secret with a TTL of 30 days
            new_secret_with_ttl = create_secret("my-project", "my-timed-secret", "7776000s")
        """

        # Import the Secret Manager client library.
        from google.cloud import secretmanager

        # Create the Secret Manager client.
        client = secretmanager.SecretManagerServiceClient()

        # Build the resource name of the parent project.
        parent = f"projects/{self.project_id}"

        # Create the secret.
        response = client.create_secret(
            request={
                "parent": parent,
                "secret_id": secret_id,
                "secret": {"replication": {"automatic": {}}, "ttl": None},
            }
        )

        # Print the new secret name.
        print(f"Created secret: {response.name}")


    def add_secret_version(
        self, secret_id: str, payload: str
    ) -> secretmanager.SecretVersion:
        """
        Add a new secret version to the given secret with the provided payload.
        """

        # Create the Secret Manager client.
        client = secretmanager.SecretManagerServiceClient()

        # Build the resource name of the parent secret.
        parent = client.secret_path(self.project_id, secret_id)

        # Convert the string payload into a bytes. This step can be omitted if you
        # pass in bytes instead of a str for the payload argument.
        payload_bytes = payload.encode("UTF-8")

        # Calculate payload checksum. Passing a checksum in add-version request
        # is optional.
        crc32c = google_crc32c.Checksum()
        crc32c.update(payload_bytes)

        # Add the secret version.
        response = client.add_secret_version(
            request={
                "parent": parent,
                "payload": {
                    "data": payload_bytes,
                    "data_crc32c": int(crc32c.hexdigest(), 16),
                },
            }
        )

        # Print the new secret version name.
        print(f"Added secret version: {response.name}")


    def access_secret_version(
        self, secret_id: str, version_id: str
    ) -> secretmanager.AccessSecretVersionResponse:
        """
        Access the payload for the given secret version if one exists. The version
        can be a version number as a string (e.g. "5") or an alias (e.g. "latest").

        Args:
            project_id: Google Cloud project ID.
            secret_id: ID of the secret stored in Secret Manager.
            version_id: (Optional) Version of the secret to access, defaults to "latest".

        Returns:
            str: Secret payload as a string, or None if the secret is not found.

        Raises:
            google.api_core.exceptions.GoogleAPIError: For any errors during Secret Manager interaction.
        """
        client = secretmanager.SecretManagerServiceClient()
        name = f"projects/{self.project_id}/secrets/{secret_id}/versions/{version_id}"

        try:
            response = client.access_secret_version(request={"name": name})
        except Exception as e:
            print(f"Error retrieving {secret_id}. {e}")
            return None

        crc32c = google_crc32c.Checksum()
        crc32c.update(response.payload.data)
        if response.payload.data_crc32c != int(crc32c.hexdigest(), 16):
            print("Data corruption detected.")
            return None  # Or raise an exception depending on your error handling

        payload = response.payload.data.decode("UTF-8")
        return payload

class BigQuery:
    def __init__(self, project_id: str=None) -> None:
        self.project_id = project_id
        
    def bq_to_df(
        self, query: str, sa_bq_secret_id: str = None, version_id: str = "latest", credentials=None, sa_info: str = None, 
    ):
        """
        Run a BQ query and place the results in a pandas dataframe.

        This function provides flexibility in authentication, allowing you to use either:

        1. **Service Account Credentials from Secret Manager:** Provide the `sa_bq_secret_id`
           to fetch credentials from Google Secret Manager.
        2. **Existing Credentials:** Pass an existing `google.oauth2.service_account.Credentials`
           object directly.
        3. **Default Credentials:** If both `sa_bq_secret_id` and `credentials` are None, the
           function will attempt to use the default Google Cloud credentials.

        Args:
            project_id: Google Cloud project ID.
            query: SQL query to execute.
            sa_bq_secret_id: (Optional) Secret ID in Secret Manager storing service account
                             credentials.
            credentials: (Optional) Existing `google.oauth2.service_account.Credentials` object.

        Returns:
            pandas.DataFrame: DataFrame containing the results of the query.

        Raises:
            ValueError: If both `sa_bq_secret_id` and `credentials` are provided.
            google.api_core.exceptions.GoogleAPIError: For any errors during BigQuery interaction.
        """

        if sa_bq_secret_id and credentials:
            raise ValueError(
                "Please provide either 'sa_bq_secret_id' or 'credentials', not both."
            )

        if sa_bq_secret_id:
            sm = SecretManager(self.project_id)
            config = sm.access_secret_version(sa_bq_secret_id, version_id)
            credentials = service_account.Credentials.from_service_account_info(
                json.loads(config)
            )
            bq_client = bigquery.Client(
                credentials=credentials, project=credentials.project_id
            )
        elif credentials:
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
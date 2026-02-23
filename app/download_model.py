import os
import sys
from azure.ai.ml import MLClient
from azure.identity import ClientSecretCredential

def download_model(model_name: str, model_version: str, download_path: str = "./model"):
    """Download model from Azure ML registry into the container image."""

    print(f"Downloading model: {model_name} v{model_version}")

    credential = ClientSecretCredential(
        tenant_id=os.environ["ARM_TENANT_ID"],
        client_id=os.environ["ARM_CLIENT_ID"],
        client_secret=os.environ["ARM_CLIENT_SECRET"],
    )

    ml_client = MLClient(
        credential=credential,
        subscription_id=os.environ["ARM_SUBSCRIPTION_ID"],
        resource_group_name=os.environ["AZURE_RESOURCE_GROUP"],
        workspace_name=os.environ["AML_WORKSPACE_NAME"],
    )

    ml_client.models.download(
        name=model_name,
        version=model_version,
        download_path=download_path,
    )

    print(f"Model downloaded to: {download_path}")


if __name__ == "__main__":
    model_name    = sys.argv[1]
    model_version = sys.argv[2]
    download_model(model_name, model_version)
import azure.functions as func
import logging
import json
import urllib.request
import os

app = func.FunctionApp()

@app.event_grid_trigger(arg_name="event")
def model_registered_handler(event: func.EventGridEvent):
    """
    Triggered when Azure ML fires a 'Microsoft.MachineLearningServices.ModelRegistered' event.
    Dispatches the API deployment GitHub Actions worlow.
    """
    logging.info("Model registry event received.")

    event_data = event.get_json()
    model_name    = event_data.get("modelName", "unknown")
    model_version = event_data.get("modelVersion", "unknown")

    logging.info(f"Model registered: {model_name} v{model_version}")

    # ── Trigger the API deployment workflow ──────────────────────────────────
    _trigger_github_workflow(
        model_name=model_name,
        model_version=str(model_version),
    )


def _trigger_github_workflow(model_name: str, model_version: str):
    """Call GitHub API to dispatch the API deployment workflow."""

    token       = os.environ["GITHUB_TOKEN"]
    owner       = os.environ["GITHUB_OWNER"]
    repo        = os.environ["GITHUB_REPO"]
    workflow_id = os.environ["GITHUB_WORKFLOW_ID"]   # e.g. "deploy-api.yml"
    ref         = os.environ.get("GITHUB_REF", "main")

    url = f"https://api.github.com/repos/{owner}/{repo}/actions/workflows/{workflow_id}/dispatches"

    payload = json.dumps({
        "ref": ref,
        "inputs": {
            "model_name":    model_name,
            "model_version": model_version,
        }
    }).encode("utf-8")

    headers = {
        "Authorization":        f"Bearer {token}",
        "Accept":               "application/vnd.github+json",
        "Content-Type":         "application/json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent":           "AzureFunction-MLOps",
    }

    req = urllib.request.Request(url, data=payload, headers=headers, method="POST")

    try:
        with urllib.request.urlopen(req) as resp:
            logging.info(f"GitHub workflow dispatched. Status: {resp.status}")
    except urllib.error.HTTPError as e:
        logging.error(f"GitHub API error {e.code}: {e.read().decode()}")
        raise
# ══════════════════════════════════════════════════════════════════════════════
# STAGE 1 — builder
# Downloads the model from Azure ML. This entire stage is discarded
# after the build. Credentials never reach the final image.
# ══════════════════════════════════════════════════════════════════════════════
FROM python:3.11-slim AS builder

WORKDIR /download

# Install only what's needed to download the model
COPY download_model.py .
RUN pip install --no-cache-dir azure-ai-ml azure-identity

# Receive credentials as build args — scoped to this stage only
ARG MODEL_NAME
ARG MODEL_VERSION
ARG ARM_TENANT_ID
ARG ARM_CLIENT_ID
ARG ARM_CLIENT_SECRET
ARG ARM_SUBSCRIPTION_ID
ARG AZURE_RESOURCE_GROUP
ARG AML_WORKSPACE_NAME

# Set as env vars so download_model.py can read them
ENV ARM_TENANT_ID=$ARM_TENANT_ID
ENV ARM_CLIENT_ID=$ARM_CLIENT_ID
ENV ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET
ENV ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID
ENV AZURE_RESOURCE_GROUP=$AZURE_RESOURCE_GROUP
ENV AML_WORKSPACE_NAME=$AML_WORKSPACE_NAME

# Download model — lands in /download/model/
RUN python download_model.py $MODEL_NAME $MODEL_VERSION

# ══════════════════════════════════════════════════════════════════════════════
# STAGE 2 — final
# Clean image. No credentials, no Azure SDK, no download script.
# Only the model files and API code come through.
# ══════════════════════════════════════════════════════════════════════════════
FROM python:3.11-slim AS final

WORKDIR /app

# Install only API dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy API source code
COPY main.py .

# ── Copy ONLY the model files from the builder stage ──────────────────────────
# Everything else from builder (credentials, Azure SDK, scripts) is left behind
COPY --from=builder /download/model ./model

# No secrets, no ARGs, no Azure SDK in this stage
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
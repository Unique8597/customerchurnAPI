# customerchurnAPI
az ml model download \
  --name customerchurnmodel\
  --version 2 \
  --download-path "./model" \
  --resource-group CustomerChurnProject \
  --workspace-name churnprediction12
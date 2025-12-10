#!/bin/bash
# Script to create the Cloud Build logs bucket

PROJECT_ID="jobvibes-d2cac"
BUCKET_NAME="${PROJECT_ID}_cloudbuild"
REGION="asia-south1"

echo "Creating logs bucket: gs://${BUCKET_NAME}"

# Create the bucket
gsutil mb -p ${PROJECT_ID} -l ${REGION} gs://${BUCKET_NAME} 2>/dev/null || echo "Bucket may already exist"

# Grant Cloud Build service account access
SERVICE_ACCOUNT="${PROJECT_ID}@cloudbuild.gserviceaccount.com"
echo "Granting permissions to service account: ${SERVICE_ACCOUNT}"

gsutil iam ch serviceAccount:${SERVICE_ACCOUNT}:roles/storage.objectCreator gs://${BUCKET_NAME}
gsutil iam ch serviceAccount:${SERVICE_ACCOUNT}:roles/storage.objectViewer gs://${BUCKET_NAME}

echo "Bucket setup complete!"


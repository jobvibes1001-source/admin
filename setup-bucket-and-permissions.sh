#!/bin/bash
# Script to create the Cloud Build logs bucket and grant permissions to Firebase service account

PROJECT_ID="jobvibes-d2cac"
BUCKET_NAME="${PROJECT_ID}_cloudbuild"
REGION="asia-south1"
SERVICE_ACCOUNT="firebase-adminsdk-fbsvc@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Setting up logs bucket for Cloud Build..."
echo "Project: ${PROJECT_ID}"
echo "Bucket: gs://${BUCKET_NAME}"
echo "Service Account: ${SERVICE_ACCOUNT}"
echo ""

# Create the bucket (ignore error if it already exists)
echo "Creating bucket..."
gsutil mb -p ${PROJECT_ID} -l ${REGION} gs://${BUCKET_NAME} 2>/dev/null && echo "✓ Bucket created" || echo "✓ Bucket already exists"

# Grant Cloud Build service account access
echo "Granting permissions to Firebase service account..."
gsutil iam ch serviceAccount:${SERVICE_ACCOUNT}:roles/storage.objectCreator gs://${BUCKET_NAME}
gsutil iam ch serviceAccount:${SERVICE_ACCOUNT}:roles/storage.objectViewer gs://${BUCKET_NAME}

# Also grant to the default Cloud Build service account (in case it's used)
CLOUD_BUILD_SA="${PROJECT_ID}@cloudbuild.gserviceaccount.com"
echo "Granting permissions to Cloud Build service account..."
gsutil iam ch serviceAccount:${CLOUD_BUILD_SA}:roles/storage.objectCreator gs://${BUCKET_NAME} 2>/dev/null || echo "Note: Cloud Build SA permissions may be managed automatically"

echo ""
echo "✓ Setup complete! The bucket is ready for Cloud Build logs."


#!/bin/bash

# ==============================================================================
# MinIO Initialization Script
# ==============================================================================
# This script creates the required bucket in MinIO for Langfuse
# Run this after starting the MinIO container
# ==============================================================================

set -e

echo "Waiting for MinIO to be ready..."
sleep 10

# MinIO credentials (update these to match your .env file)
MINIO_ENDPOINT="http://localhost:9000"
MINIO_ACCESS_KEY="${MINIO_ROOT_USER:-minio_admin}"
MINIO_SECRET_KEY="${MINIO_ROOT_PASSWORD:-changeme_use_strong_password}"
BUCKET_NAME="${S3_BUCKET_NAME:-langfuse}"

# Install mc (MinIO Client) if not already installed
if ! command -v mc &> /dev/null; then
    echo "MinIO client (mc) not found. Installing..."

    # Detect OS
    OS="$(uname -s)"
    case "${OS}" in
        Linux*)
            wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /tmp/mc
            chmod +x /tmp/mc
            sudo mv /tmp/mc /usr/local/bin/mc
            ;;
        Darwin*)
            brew install minio/stable/mc 2>/dev/null || {
                curl https://dl.min.io/client/mc/release/darwin-amd64/mc -o /tmp/mc
                chmod +x /tmp/mc
                sudo mv /tmp/mc /usr/local/bin/mc
            }
            ;;
        *)
            echo "Unsupported OS: ${OS}"
            echo "Please install MinIO client manually from: https://min.io/docs/minio/linux/reference/minio-mc.html"
            exit 1
            ;;
    esac
fi

echo "Configuring MinIO client..."
mc alias set langfuse-minio $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY

echo "Creating bucket: $BUCKET_NAME"
mc mb langfuse-minio/$BUCKET_NAME --ignore-existing

echo "Setting bucket policy to public read (for uploaded assets)..."
cat > /tmp/bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": ["*"]
      },
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::$BUCKET_NAME/*"]
    }
  ]
}
EOF

mc anonymous set-json /tmp/bucket-policy.json langfuse-minio/$BUCKET_NAME

echo "MinIO setup complete!"
echo "Bucket '$BUCKET_NAME' is ready for use."
echo "MinIO Console: http://localhost:9001"
echo "Username: $MINIO_ACCESS_KEY"

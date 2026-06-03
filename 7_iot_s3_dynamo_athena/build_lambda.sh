#!/bin/bash
set -e

LAMBDA_DIR="lambdas/s3_to_postgres"
PACKAGE_DIR="$LAMBDA_DIR/package"

echo "Empaquetando Lambda s3_to_postgres..."

rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

pip install \
  --target "$PACKAGE_DIR" \
  --platform manylinux2014_x86_64 \
  --implementation cp \
  --python-version 3.12 \
  --only-binary=:all: \
  -r "$LAMBDA_DIR/requirements.txt"

cp "$LAMBDA_DIR/handler.py" "$PACKAGE_DIR/handler.py"

echo "Lambda empaquetada en $PACKAGE_DIR"
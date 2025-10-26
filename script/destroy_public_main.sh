#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 환경 변수 로드 (프로젝트 루트의 .envrc가 있으면)
if [ -f "$PROJECT_ROOT/.envrc" ]; then
  set -a
  . "$PROJECT_ROOT/.envrc"
  set +a
fi

ROOT="$PROJECT_ROOT/terraform/001_public_main"
terraform -chdir="$ROOT" destroy -target=aws_instance.public_main -auto-approve

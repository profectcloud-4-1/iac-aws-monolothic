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

# SSH 키 경로 확인 및 확장 (NOTE: 당장은 ssh 접속하지 않지만, 추후를 위해 validation은 남겨둠)
if [ -z "$SSH_KEY_PATH" ]; then
  echo "SSH_KEY_PATH 환경변수가 설정되어 있지 않습니다. 프로젝트 루트의 .envrc를 확인하세요: $PROJECT_ROOT/.envrc" >&2
  exit 1
fi
KEY_EXPANDED=$(eval echo "$SSH_KEY_PATH")
if [ ! -f "$KEY_EXPANDED" ]; then
  echo "SSH 키 파일을 찾을 수 없습니다: $KEY_EXPANDED" >&2
  exit 1
fi

ROOT="$PROJECT_ROOT/terraform"

# terraform 실행
terraform -chdir="$ROOT" init -input=false
terraform -chdir="$ROOT" apply -auto-approve
PUBLIC_IP=$(terraform -chdir="$ROOT" output -raw public_ip)
PRIVATE_IP=$(terraform -chdir="$ROOT" output -raw private_ip)

echo "Public IP: $PUBLIC_IP"
echo "Private IP: $PRIVATE_IP"

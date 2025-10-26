#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$PROJECT_ROOT/.envrc"

# packer 초기화
packer init "$PROJECT_ROOT/packer/001_public_main/ami.pkr.hcl"

# ami 생성
packer build \
  -var "region=${AWS_DEFAULT_REGION}" \
  -var "subnet_id=${PUBLIC_SUBNET_ID}" \
  -var "ssh_new_port=${SSH_NEW_PORT}" \
  -var "ssh_key_path=${SSH_KEY_PATH}" \
  "$PROJECT_ROOT/packer/001_public_main/ami.pkr.hcl"
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

# SSH 키 경로 확인 및 확장
if [ -z "$SSH_KEY_PATH" ]; then
  echo "SSH_KEY_PATH 환경변수가 설정되어 있지 않습니다. 프로젝트 루트의 .envrc를 확인하세요: $PROJECT_ROOT/.envrc" >&2
  exit 1
fi
KEY_EXPANDED=$(eval echo "$SSH_KEY_PATH")
if [ ! -f "$KEY_EXPANDED" ]; then
  echo "SSH 키 파일을 찾을 수 없습니다: $KEY_EXPANDED" >&2
  exit 1
fi

if [ -z "$SSH_NEW_PORT" ]; then
  echo "변경할 SSH 포트 번호를 설정해주세요. (SSH_NEW_PORT)" >&2
  exit 1
fi

ROOT="$PROJECT_ROOT/terraform/001_public_main"

# 1. ec2 인스턴스 생성
terraform -chdir="$ROOT" init -input=false
terraform -chdir="$ROOT" apply -auto-approve -var="phase=init" -var="ssh_private_key_path=$SSH_KEY_PATH"
PUBLIC_IP=$(terraform -chdir="$ROOT" output -raw public_ip)

echo "Public IP: $PUBLIC_IP"

# 2. ssh 포트 변경
# 2-1. 임시 인벤토리 생성 (public_main 그룹에 현재 IP 매핑)
TMP_INV=$(mktemp)
cat > "$TMP_INV" <<EOF
[public_main]
$PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=$KEY_EXPANDED ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF
# 2-2. ansible playbook 실행
ansible-playbook -i "$TMP_INV" "$PROJECT_ROOT/ansible/001_public_main/setup/ssh.yaml" --extra-vars "ssh_new_port=$SSH_NEW_PORT"

# 3. 기본 ssh 포트(22) deny
terraform -chdir="$ROOT" apply -auto-approve -var="phase=post" -var="ssh_private_key_path=$SSH_KEY_PATH"

# 임시 인벤토리 정리
rm -f "$TMP_INV"
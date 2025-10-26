# Goorm IaC

## 목표

스크립트 한번의 실행으로 다음 과정을 모두 수행하여 서비스 오픈

- vpc, subnet, nacl, security group 등 네트워크 인프라 세팅
- public subnet에 ec2 생성 후 nginx 실행, ssh 포트 변경
- private subnet에 ec2 생성 후 구름닷컴 컨테이너 실행

### 준비

- IAM 사용자 및 액세스키 생성
- AWS 키페어 생성 후 키파일(.pem)을 로컬환경에 준비

### 구동/종료

```bash
# 구동
bash ./script/deploy.sh

# 종료
bash ./script/destroy_public_main.sh
```

## 현재 단계

- public 서브넷에 ec2 인스턴스 생성
  - packer를 통해 생성한 ami를 기반으로 생성
  - ssh 포트 변경
  - nginx 설치

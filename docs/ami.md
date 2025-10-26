# packer를 이용한 ami 생성

- `ROOT/packer/\*\*/ami.pkr.hcml` 파일에 어떤 ami를 만들지를 정의합니다.
- packer는 해당 파일을 읽어 임시 ec2를 생성하고, 이 ec2를 본떠 ami를 생성합니다. (이후 임시 ec2는 자동으로 제거됩니다)
- ami가 생성되었다면, terraform에서 해당 ami를 통해 ec2를 생성할 수 있도록 `ami` 필드를 수정합니다.

## AMI 001: public main

ubuntu 24.04 위에 다음 내용이 적용된 이미지입니다.

- nginx 설치
- ssh 포트 변경

변경할 ssh 포트는 `.envrc`의 `SSH_NEW_PORT`에 기입합니다.

# private ec2로의 ssh 접속

public ec2를 bastion host로 두고 연결

```
client --ssh--> public ec2
public ec2 --ssh--> private ec2
```

⬇️

```
client --ssh--> public ec2 --ssh--> private ec2
```

⬇️

```
client ----ssh via public ec2-----> private ec2
```

명령어

```bash
ssh -i <키파일경로> -o ProxyCommand="ssh -W %h:%p -p <public_ec2의 ssh port> -i <키파일경로> ubuntu@<public_ec2의 public_ip>" ubuntu@<private_ec2의 private_ip>
```

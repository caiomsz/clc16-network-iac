## Cria Security Group para permitir acesso HTTP (porta 80)
## e SSH (porta 22) na instância EC2

resource "aws_security_group" "sg_web" {
  name        = "sg_web_tf"
  description = "Permite acesso HTTP e SSH"
  vpc_id      = aws_vpc.clc_vpc.id

  ## Libera acesso HTTP para qualquer origem
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ## Libera acesso SSH para qualquer origem
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ## Permite saída para qualquer destino
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_web_tf"
  }
}

## Busca automaticamente a AMI mais recente do Amazon Linux

data "aws_ami" "amazon_linux" {

  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}

## Cria instância EC2 pública para hospedar o Apache

resource "aws_instance" "web_server" {

  ## Utiliza a última AMI Amazon Linux encontrada
  ami = data.aws_ami.amazon_linux.id

  ## Tipo da instância
  instance_type = "t2.micro"

  ## Subnet pública onde a EC2 será criada
  subnet_id = aws_subnet.public_subnet_1a.id

  ## Associa o Security Group criado anteriormente
  vpc_security_group_ids = [
    aws_security_group.sg_web.id
  ]

  ## Garante a associação de IP público
  associate_public_ip_address = true

  ## Script executado na inicialização da máquina
  user_data = <<-EOF
#!/bin/bash

dnf install httpd -y

systemctl enable httpd
systemctl start httpd

cat <<HTML > /var/www/html/index.html
<html>
<head>
<title>CLC16</title>
</head>
<body>
<h1>CHEGUEI ATÉ AQUI - Caio Mauricio de Souza - CLC 16</h1>
</body>
</html>
HTML
EOF

  tags = {
    Name = "ec2_web_clc16"
  }
}

## ID do Security Group da aplicação web
output "sg_web" {
  value = aws_security_group.sg_web.id
}

## ID da instância EC2
output "ec2_id" {
  value = aws_instance.web_server.id
}

## IP público da instância EC2
output "ec2_public_ip" {
  value = aws_instance.web_server.public_ip
}

## DNS público da instância EC2
output "ec2_public_dns" {
  value = aws_instance.web_server.public_dns
}
# Passo 1: Use o Claude para Gerar o Código Terraform

1. Crie uma conta gratuita no https://claude.ai 

2. Inicie uma conversa com o Claude.

3. Peça ao Claude para criar um código Terraform para um bucket S3. Use um prompt como:
"Por favor, forneça um código Terraform para criar um bucket S3 na AWS com um nome único na região us-east-1."

4. O Claude deve gerar um código semelhante a este:

```plaintext
    provider "aws" {
    region = "us-east-1"  # Substitua pela região desejada
    }

    resource "random_id" "bucket_suffix" {
    byte_length = 8
    }

    resource "aws_s3_bucket" "my_bucket" {
    bucket = "my-unique-bucket-name-${random_id.bucket_suffix.hex}"

    tags = {
        Name        = "My bucket"
        Environment = "Dev"
    }
    }

```


## Passo 2: Crie uma Instância EC2

1. Crie uma conta gratuita na AWS: https://aws.amazon.com/free/
2. Vá para o painel EC2 no AWS Management Console.
3. Clique em "Launch Instance".
4. Escolha uma AMI Amazon Linux 2.
5. Selecione um tipo de instância t2.micro.
6. Configure os detalhes da instância:
    - Network: VPC padrão
    - Subnet: Qualquer disponível
    - Auto-assign Public IP: Enable
7. Mantenha as configurações de armazenamento padrão.
8. Adicione uma tag: Key="Name", Value="workstation".
9. Crie um security group permitindo acesso SSH do seu IP.
10. Revise e lance, selecionando ou criando um key pair.# multicloud-devopsAI-challange

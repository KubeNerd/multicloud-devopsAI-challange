```markdown
# Missão - Aula 2

## Objetivo

Nesta aula, a missão é utilizar a instância EC2 criada na aula 1 para instalar o Docker e subir a aplicação. Além disso, utilizamos o Docker Compose para facilitar a gestão dos containers, subimos um Nginx e configuramos um proxy reverso.

## Inicializando o Terraform

Antes de iniciar a configuração do EC2 e a criação da base de dados DynamoDB, execute:

```sh
terraform init
```

## Formatando e validando o Terraform

Para garantir que o código está bem formatado e livre de erros:

```sh
terraform fmt && terraform validate
```

## Planejando a criação dos recursos

Executa um dry-run para visualizar as mudanças antes da aplicação:

```sh
terraform plan
```

## Aplicando o plano

Cria os recursos na AWS, incluindo a base de dados DynamoDB:

```sh
terraform apply
```

## Instalação do Docker no EC2

Com a instância EC2 criada, conecte-se a ela via SSH e instale o Docker:

```sh
sudo apt update -y
sudo apt install docker.io -y
sudo systemctl enable docker
sudo systemctl start docker
```

## Instalação do Docker Compose

```sh
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Verifique a instalação:

```sh
docker-compose --version
```

## Subindo a aplicação com Docker Compose e configurando o proxy reverso

Crie um arquivo `docker-compose.yml` e defina os serviços necessários:

```yaml
version: '3.8'
services:
  app:
    image: minha-aplicacao:latest
    restart: always
    networks:
      - app_network

  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - app
    networks:
      - app_network

networks:
  app_network:
    driver: bridge
```

## Configurando o Proxy Reverso

Crie um arquivo `nginx.conf` com a seguinte configuração:

```nginx
server {
    listen 80;

    location / {
        proxy_pass http://app:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Iniciando os containers

Para iniciar todos os serviços, execute:

```sh
docker-compose up -d
```

Com isso, a aplicação estará rodando com um proxy reverso configurado via Nginx.


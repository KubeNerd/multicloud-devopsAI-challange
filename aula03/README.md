```markdown
# Missão - Aula 3

## Objetivo

Nesta aula, a missão é criar um cluster EKS (Elastic Kubernetes Service) na AWS e gerar os manifestos necessários para rodar a aplicação no EKS.

## Criando o Cluster EKS

### Crie um novo repositório no GitHub called cloudmart

### Comece fazendo o push das alterações no código-fonte da aplicação CloudMart para o GitHub

```bash
git status
git add -A
git commit -m "app enviada para o repo"
git push
```


### **Configurar o AWS CodePipeline**

1. **Criar um Novo Pipeline:**
    - Acesse o AWS CodePipeline.
    - Inicie o processo de 'Criar pipeline'.
    - Nome: `cloudmart-cicd-pipeline`
    - Use o repositório do GitHub `cloudmart-application` como a fonte.
    - Adicione o projeto 'cloudmartBuild' como estágio de construção.
    - Adicione o projeto 'cloudmartDeploy' como estágio de implantação.

### Configurar **o AWS CodeBuild para Construir a Imagem Docker**

1. **Criar um Projeto de Construção:**
    - Dê um nome ao projeto (por exemplo, **`cloudmartBuild`**).
    - Conecte-o ao seu repositório GitHub existente (**`cloudmart-application`**).
    - **Image: amazonlinux2-x86_64-standard:4.0**
    - Configure o ambiente para dar suporte às construções Docker. Habilite “Enable this flag if you want to build Docker images or want your builds to get elevated privileges”
    - Adicione a variável de ambiente **ECR_REPO** com a URI do repositório ECR.
    - Para a especificação de construção, utilize o seguinte **`buildspec.yml`**:

```yaml
version: 0.2
phases:
  install:
    runtime-versions:
      docker: 20
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws --version
      - REPOSITORY_URI=$ECR_REPO
      - aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/l4c0j8h9
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t $REPOSITORY_URI:latest .
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$CODEBUILD_RESOLVED_SOURCE_VERSION
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $REPOSITORY_URI:latest
      - docker push $REPOSITORY_URI:$CODEBUILD_RESOLVED_SOURCE_VERSION
      - export imageTag=$CODEBUILD_RESOLVED_SOURCE_VERSION
      - printf '[{\"name\":\"cloudmart-app\",\"imageUri\":\"%s\"}]' $REPOSITORY_URI:$imageTag > imagedefinitions.json
      - cat imagedefinitions.json
      - ls -l

env:
  exported-variables: ["imageTag"]

artifacts:
  files:
    - imagedefinitions.json
    - cloudmart-frontend.yaml

```


1. **Adicione a permissão AmazonElasticContainerRegistryPublicFullAccess ao ECR na role de serviço**
    - Acesse o console do IAM > Funções (Roles).
    - Procure pela função criada "cloudmartBuild" para o CodeBuild.
    - Adicione a permissão **AmazonElasticContainerRegistryPublicFullAccess**.

### Configurar o AWS CodeBuild para Implantação da Aplicação

1. **Criar um Projeto de Implantação:**
    - Repita o processo de criação de projetos no CodeBuild.
    - Dê a este projeto um nome diferente (por exemplo, **`cloudmartDeployToProduction`**).
    - Configure as variáveis de ambiente AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY para as credenciais do usuário **`eks-user`** no Cloud Build, para que ele possa autenticar-se no cluster Kubernetes.
    
    *Observe: em um ambiente de produção do mundo real, é recomendável usar uma função do IAM para essa finalidade. Neste exercício prático, estamos usando diretamente as credenciais do usuário **`eks-user`** para facilitar o processo, já que nosso foco é na CI/CD e não na autenticação do usuário neste momento. A configuração desse processo no EKS é mais extensa. Consulte a seção de Referência e consulte "Habilitando o acesso de princípio do IAM ao seu cluster"*
    
    - Para a especificação de implantação, utilize o seguinte **`buildspec.yml`**:


```yaml
version: 0.2

phases:
  install:
    runtime-versions:
      docker: 20
    commands:
      - curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/kubectl
      - chmod +x ./kubectl
      - mv ./kubectl /usr/local/bin
      - kubectl version --short --client
  post_build:
    commands:
      - aws eks update-kubeconfig --region us-east-1 --name cloudmart
      - kubectl get nodes
      - ls
      - IMAGE_URI=$(jq -r '.[0].imageUri' imagedefinitions.json)
      - echo $IMAGE_URI
      - sed -i "s|CONTAINER_IMAGE|$IMAGE_URI|g" cloudmart-frontend.yaml
      - kubectl apply -f cloudmart-frontend.yaml

```


- Substitua a URI da imagem na linha 18 dos arquivos **`cloudmart-frontend.yaml`** por CONTAINER_IMAGE.
- Faça um commit e envie as alterações.

```yaml
git add -A
git commit -m "replaced image uri with CONTAINER_IMAGE"
git push

```

### **Teste sua Pipeline de CI/CD**

1. **Faça uma Alteração no GitHub:**
    - Atualize o código da aplicação no repositório **`cloudmart-application`**.
    - Arquivo `src/components/MainPage/index.jsx` linha 93
    - Faça um commit e envie as alterações.



```yaml
git add -A
git commit -m "alternado para Main Products"
git push

```

2. **Observe a Execução da Pipeline:**
    - Observe como o CodePipeline aciona automaticamente a compilação.
    - Após a compilação, a fase de implantação deve começar.
3. **Verifique a Implantação:**
    - Verifique o Kubernetes usando os comandos **`kubectl`** para confirmar a atualização da aplicação.



### Planejando a criação do cluster EKS

Executa um dry-run para visualizar as mudanças antes da aplicação:


## Configurando o Kubectl para acessar o EKS

Após a criação do cluster, configure o `kubectl` para acessá-lo:

```sh
aws eks --region <regiao> update-kubeconfig --name <nome-do-cluster>
```

Verifique se o cluster está acessível:

```sh
kubectl get nodes
```

## Criando os manifestos Kubernetes

Crie um diretório para armazenar os manifestos:

```sh
mkdir -p k8s-manifestos && cd k8s-manifestos
```

Crie os arquivos YAML necessários:

### Deployment da aplicação

Crie um arquivo `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minha-aplicacao
spec:
  replicas: 3
  selector:
    matchLabels:
      app: minha-aplicacao
  template:
    metadata:
      labels:
        app: minha-aplicacao
    spec:
      containers:
        - name: minha-aplicacao
          image: minha-aplicacao:latest
          ports:
            - containerPort: 80
```

### Service para a aplicação

Crie um arquivo `service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: minha-aplicacao
spec:
  selector:
    app: minha-aplicacao
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
```

### Ingress com Nginx (Proxy Reverso)

Crie um arquivo `ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minha-aplicacao-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
    - host: minha-aplicacao.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: minha-aplicacao
                port:
                  number: 80
```

## Aplicando os manifestos no cluster

Para criar os recursos no cluster, execute:

```sh
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```
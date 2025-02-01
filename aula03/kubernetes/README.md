## Setup do Cluster no AWS Elastic Kubernetes Services (EKS)

1. Crie um usuário chamado `eksuser` com privilegio de Admin e se autentique com ele

```bash
    aws configure
```

## Instale a ferramenta CLI eksctl 

```bash
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    
    sudo cp /tmp/eksctl /usr/bin
    eksctl version
```

## Instale a ferramenta CLI kubectl 

```bash
    curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/kubectl

    chmod +x ./kubectl
    mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/   

    kubectl && export PATH=$PATH:$HOME/bin
    echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
    kubectl version --short --client
```

## Crie um EKS Cluster

```bash
    eksctl create cluster \
    --name cloudmart \
    --region us-east-1 \
    --nodegroup-name standard-workers \
    --node-type t3.medium \
    --nodes 1 \
    --with-oidc \
    --managed
```

## Conecte-se ao cluster EKS usando a configuração do kubectl 

```bash
    aws eks update-kubeconfig --name cloudmart
```

##  Verifique a conectividade do Cluster

```bash
kubectl get svc
kubectl get nodes
```


## Crie uma Role & Service Account para fornecer aos pods acesso aos serviços usados pela aplicação (DynamoDB, Bedrock, etc).

```bash
    eksctl create iamserviceaccount \
    --cluster=cloudmart \
    --name=cloudmart-pod-execution-role \
    --role-name CloudMartPodExecutionRole \
    --attach-policy-arn=arn:aws:iam::aws:policy/AdministratorAccess\
    --region us-east-1 \
    --approve
```
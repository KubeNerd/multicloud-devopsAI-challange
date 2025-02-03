# Configuração do Agente Amazon Bedrock

Siga estes passos para criar manualmente o Agente Bedrock para CloudMart:


# Criação de recursos usando o Terraform

Navegue para a pasta que contém o arquivo `main.tf` e baixe o arquivo zip contendo a função Lambda que será usada pelo Bedrock


```bash
        cd challenge-day2/backend/src/lambda
        cp list_products.zip ../../../../terraform-project/
        cd ../../../../terraform-project
    ```

    Adicione as linhas abaixo no final do arquivo main.tf

    ```yaml
    # IAM Role for Lambda function
    resource "aws_iam_role" "lambda_role" {
    name = "cloudmart_lambda_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
            Service = "lambda.amazonaws.com"
            }
        }
        ]
    })
    }

    # IAM Policy for Lambda function
    resource "aws_iam_role_policy" "lambda_policy" {
    name = "cloudmart_lambda_policy"
    role = aws_iam_role.lambda_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Effect = "Allow"
            Action = [
            "dynamodb:Scan",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
            ]
            Resource = [
            aws_dynamodb_table.cloudmart_products.arn,
            aws_dynamodb_table.cloudmart_orders.arn,
            aws_dynamodb_table.cloudmart_tickets.arn,
            "arn:aws:logs:*:*:*"
            ]
        }
        ]
    })
    }

    # Lambda function for listing products
    resource "aws_lambda_function" "list_products" {
    filename         = "list_products.zip"
    function_name    = "cloudmart-list-products"
    role             = aws_iam_role.lambda_role.arn
    handler          = "index.handler"
    runtime          = "nodejs20.x"
    source_code_hash = filebase64sha256("list_products.zip")

    environment {
        variables = {
        PRODUCTS_TABLE = aws_dynamodb_table.cloudmart_products.name
        }
    }
    }

    # Lambda permission for Bedrock
    resource "aws_lambda_permission" "allow_bedrock" {
    statement_id  = "AllowBedrockInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.list_products.function_name
    principal     = "bedrock.amazonaws.com"
    }

    # Output the ARN of the Lambda function
    output "list_products_function_arn" {
    value = aws_lambda_function.list_products.arn
    }

```
Acesso ao Modelo:


1. No console Amazon Bedrock, vá para "Model access" no painel de navegação.
2. Escolha "Enable specific models".
3. Selecione o modelo Claude 3 Sonnet.
4. Aguarde até que o status de acesso ao modelo mude para "Access granted".


## Criar o Agente:

1. No console Amazon Bedrock, escolha "Agents" em "Builder tools" no painel de navegação.
2. Clique em "Create agent".
3. Nomeie o agente "cloudmart-product-recommendation-agent".
4. Selecione "Claude 3 Sonnet" como o modelo base.
5. Cole as instruções do agente abaixo na seção "Instructions for the Agent".


```textplain
You are a product recommendations agent for CloudMart, an online e-commerce store. Your role is to assist customers in finding products that best suit their needs. Follow these instructions carefully:

1. Begin each interaction by retrieving the full list of products from the API. This will inform you of the available products and their details.

2. Your goal is to help users find suitable products based on their requirements. Ask questions to understand their needs and preferences if they're not clear from the user's initial input.

3. Use the 'name' parameter to filter products when appropriate. Do not use or mention any other filter parameters that are not part of the API.

4. Always base your product suggestions solely on the information returned by the API. Never recommend or mention products that are not in the API response.

5. When suggesting products, provide the name, description, and price as returned by the API. Do not invent or modify any product details.

6. If the user's request doesn't match any available products, politely inform them that we don't currently have such products and offer alternatives from the available list.

7. Be conversational and friendly, but focus on helping the user find suitable products efficiently.

8. Do not mention the API, database, or any technical aspects of how you retrieve the information. Present yourself as a knowledgeable sales assistant.

9. If you're unsure about a product's availability or details, always check with the API rather than making assumptions.

10. If the user asks about product features or comparisons, use only the information provided in the product descriptions from the API.

11. Be prepared to assist with a wide range of product inquiries, as our e-commerce store may carry various types of items.

12. If a user is looking for a specific type of product, use the 'name' parameter to search for relevant items, but be aware that this may not capture all categories or types of products.

Remember, your primary goal is to help users find the best products for their needs from what's available in our store. Be helpful, informative, and always base your recommendations on the actual product data provided by the API.

```


## Configurar a Função IAM:

1. Na visão geral do Agente Bedrock, localize a seção 'Permissions'.
2. Clique no link da função IAM. Isso o levará ao console IAM com a função correta selecionada.
3. No console IAM, escolha "Add permissions" e depois "Create inline policy".
4. Na aba JSON, cole a seguinte política:


```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "arn:aws:lambda:*:*:function:cloudmart-list-products"
    },
    {
      "Effect": "Allow",
      "Action": "bedrock:InvokeModel",
      "Resource": "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
    }
  ]
}

```


1. Substitua cloudmart-list-products pelo nome real da sua função Lambda, se for diferente.
2. Nomeie a política (por exemplo, "BedrockAgentLambdaAccess") e crie-a.
3. Verifique se a nova política está anexada à função.

## Configurar o Action Group:

1. Na seção "Action groups", crie um novo grupo chamado "Get-Product-Recommendations".
2. Defina o tipo de grupo de ação como "Define with API schemas".
3. Selecione a função Lambda "cloudmart-list-products" como executor do grupo de ação.
4. Na seção "Action group schema", escolha "Define via in-line schema editor".
5. Cole o esquema OpenAPI abaixo no editor de esquema.


```json
{
    "openapi": "3.0.0",
    "info": {
        "title": "Product Details API",
        "version": "1.0.0",
        "description": "This API retrieves product information. Filtering parameters are passed as query strings. If query strings are empty, it performs a full scan and retrieves the full product list."
    },
    "paths": {
        "/products": {
            "get": {
                "summary": "Retrieve product details",
                "description": "Retrieves a list of products based on the provided query string parameters. If no parameters are provided, it returns the full list of products.",
                "parameters": [
                    {
                        "name": "name",
                        "in": "query",
                        "description": "Retrieve details for a specific product by name",
                        "schema": {
                            "type": "string"
                        }
                    }
                ],
                "responses": {
                    "200": {
                        "description": "Successful response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "type": "array",
                                    "items": {
                                        "type": "object",
                                        "properties": {
                                            "name": {
                                                "type": "string"
                                            },
                                            "description": {
                                                "type": "string"
                                            },
                                            "price": {
                                                "type": "number"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    },
                    "500": {
                        "description": "Internal Server Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/ErrorResponse"
                                }
                            }
                        }
                    }
                }
            }
        }
    },
    "components": {
        "schemas": {
            "ErrorResponse": {
                "type": "object",
                "properties": {
                    "error": {
                        "type": "string",
                        "description": "Error message"
                    }
                },
                "required": [
                    "error"
                ]
            }
        }
    }
}
```


## Revisar e Criar:

1. Revise todas as configurações do agente.
2. Clique em "Prepare agent" para finalizar a criação.

## Testar o Agente:

1. Após a criação, use o painel "Test Agent" para ter conversas com o chatbot.
2. Verifique se o agente está fazendo perguntas relevantes sobre o gênero do destinatário, ocasião e categoria desejada.
3. Confirme se o agente está consultando a API e apresentando recomendações de produtos apropriadas.

## Criar um Alias para o Agente:

1. Na página de detalhes do agente, vá para a seção "Aliases".
2. Clique em "Create alias".
3. Nomeie o alias "cloudmart-prod".
4. Selecione a versão mais recente do agente.
5. Clique em "Create alias" para finalizar.

Nota: Certifique-se de que o nome da função Lambda na política IAM corresponda ao nome real da sua função e ajuste a região nos ARNs se você não estiver usando us-east-1.

# Configuração do Assistente OpenAI

Siga estes passos para criar um assistente OpenAI para CloudMart:

## Acesso ao OpenAI:

1. Acesse a plataforma OpenAI (https://platform.openai.com/).
2. Faça login ou crie uma conta se ainda não tiver uma.

## Acesso ao OpenAI:

1. Acesse a plataforma OpenAI (https://platform.openai.com/).
2. Faça login ou crie uma conta se ainda não tiver uma.


OBS: Você precisará colocar pelo menos $5.00 de crédito para a API funcionar. Siga os passos abaixo:


## Criar o Assistente:

1. Navegue até a seção "Assistants".
2. Clique em "Create New Assistant".
3. Nomeie o assistente "CloudMart Customer Support".
4. Selecione o modelo `gpt-4o`.

## Configurar o Assistente:

1. Na seção "Instructions", cole o seguinte:

Você é um agente de suporte ao cliente para CloudMart, uma plataforma de e-commerce. Seu papel é auxiliar os clientes com consultas gerais, problemas de pedidos e fornecer informações úteis sobre o uso da plataforma CloudMart. Você não tem acesso direto a informações específicas de produtos ou inventário. Seja sempre educado, paciente e foque em fornecer um excelente atendimento ao cliente. Se um cliente perguntar sobre produtos específicos ou inventário, explique educadamente que você não tem acesso a essas informações e sugira que eles verifiquem o site ou falem com um representante de vendas.


Em "Capabilities", você pode habilitar "Code Interpreter" se quiser que o assistente ajude com aspectos técnicos do uso da plataforma.


```yaml
Você é um agente de suporte ao cliente para CloudMart, uma plataforma de e-commerce. Seu papel é auxiliar os clientes com consultas gerais, problemas de pedidos e fornecer informações úteis sobre o uso da plataforma CloudMart. Você não tem acesso direto a informações específicas de produtos ou inventário. Seja sempre educado, paciente e foque em fornecer um excelente atendimento ao cliente. Se um cliente perguntar sobre produtos específicos ou inventário, explique educadamente que você não tem acesso a essas informações e sugira que eles verifiquem o site ou falem com um representante de vendas.
```

Em "Capabilities", você pode habilitar "Code Interpreter" se quiser que o assistente ajude com aspectos técnicos do uso da plataforma.


2. Em "Capabilities", você pode habilitar "Code Interpreter" se quiser que o assistente ajude com aspectos técnicos do uso da plataforma.

## Salvar o Assistente:

1. Clique em "Save" para criar o assistente.
2. Anote o ID do Assistente, você precisará dele para suas variáveis de ambiente.

## Gerar Chave de API:

1. Vá para a seção API Keys em sua conta OpenAI.
2. Gere uma nova chave de API.
3. Copie esta chave, você precisará dela para suas variáveis de ambiente.

# Faça o redeployment do backend com os AI Assistants

## Atualize o arquivo `cloudmart-backend.yaml` com as informações dos AI Assistants

Abra o arquivo `cloudmart-backend.yaml`:


```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudmart-backend-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cloudmart-backend-app
  template:
    metadata:
      labels:
        app: cloudmart-backend-app
    spec:
      serviceAccountName: cloudmart-pod-execution-role
      containers:
      - name: cloudmart-backend-app
        image: public.ecr.aws/l4c0j8h9/cloudmaster-backend:latest
        env:
        - name: PORT
          value: "5000"
        - name: AWS_REGION
          value: "us-east-1"
        - name: BEDROCK_AGENT_ID
          value: "xxxx"
        - name: BEDROCK_AGENT_ALIAS_ID
          value: "xxxx"
        - name: OPENAI_API_KEY
          value: "xxxx"
        - name: OPENAI_ASSISTANT_ID
          value: "xxxx"
---

apiVersion: v1
kind: Service
metadata:
  name: cloudmart-backend-app-service
spec:
  type: LoadBalancer
  selector:
    app: cloudmart-backend-app
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
```
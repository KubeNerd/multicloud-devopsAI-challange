APP=cloudmart
TAG = latest
DOCKERFILE = ./Dockerfile
PORT = 8080:80

build:
	@docker build -t $(APP):$(TAG) -f $(DOCKERFILE) .

run:
	@docker run -d --name $(APP) -p $(PORT) $(APP):$(TAG)
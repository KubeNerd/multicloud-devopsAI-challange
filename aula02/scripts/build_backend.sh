docker build -t cloudmart-api .
docker run -d -p 5000:5000 --env-file .env cloudmart-backend
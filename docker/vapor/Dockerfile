# Swift Vapor docker, which includes all dependencies 
FROM vapor-app:latest

ADD ./app/ /app
WORKDIR /app
# update this
CMD ["pm2-docker", "process.yml", "--only", "APP"]

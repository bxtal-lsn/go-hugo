# Example of building minimal Golang Docker images  
Golang alpine builds are typically relatively small in size.  
There is often a need to use certificates in SEV secure environment.  
This example uses 
``` go
go mod vendor
```
which tells GO to use the vendor folder for dependencies, instead of go mod.  
This approach lets you build docker images offline, with all dependencies included in the project.  
To disable, remove the flag
```go
-mod=vendor 
```

the chmod ensures that the docker container and user has access to build the GO app
```dockerfile
RUN chmod +x /app/dwApi
```

The final step copies the app and builds a minimal image


```dockerfile
# base go image

FROM golang:1.23-alpine AS builder

COPY ./cert.cer /usr/local/share/ca-certificates/cert.cer

RUN update-ca-certificates

RUN mkdir /app

COPY . /app

WORKDIR /app

RUN CGO_ENABLED=0 go build -mod=vendor -o exampleApi ./

RUN chmod +x /app/exampleApi

# build a minimal docker image

FROM alpine:latest

RUN mkdir /app

COPY --from=builder /app/exampleApi /app

CMD ["/app/exampleApi"]
```
**P.S.** if you want to get the .env file into the container, copy it into the final image build.
Also, consider using Viper for configuration and environment management.

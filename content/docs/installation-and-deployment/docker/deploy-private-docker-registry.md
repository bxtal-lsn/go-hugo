Deploy and manage a private docker repository

Create a volume to persist the registry

```bash
docker volume create registry
```

Start a container named `registry` and mount the volume to `/var/lib/registry`

```bash
docker run -d --name registry --mount src=registry,dst=/var/lib/registry -p 5000:5000 registry:2
```

Or run in swarm mode as a service
```bash
docker service create \
  --name registry \
  --mount type=volume,src=registry,dst=/var/lib/registry \
  --publish published=3005,target=5000 \
  registry:2
```

test the registry with nginx
```bash
docker pull nginx:latest
```

tag the image with the registry address and name and tag
```bash
docker tag nginx:latest localhost:5000/nginx:latest
```

check the image and tag
```bash
docker images
```

push the image to the local registry
```bash
docker push localhost:5000/nginx:latest
```

delete all nginx images locally

pull the docker image from the registry
```bash
docker pull localhost:5000/nginx
```

now the registry image should be pulled.

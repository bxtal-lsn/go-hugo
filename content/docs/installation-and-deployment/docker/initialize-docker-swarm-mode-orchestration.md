# Initialization

initialze docker swarm on main manager node
```bash
dokcer swarm init --advertise-addr <ip-address>
```

Use the join token to join a worker to the cluster
This should be done on the worker server.
```bash
 docker swarm join --token <token> <ip-address>:2377
```

to grab tokens for joining workers or managers to the cluster run:
```bash

docker swarm join-token worker
```

```bash
 docker swarm join-token manager
```

To see information about the cluster or node
```bash
docker node ls
```

see info about the docker instances
```bash
docker info
```
# deploy docker containers

create a swarm service
```bash
docker service create --name <service-name> -p 80:80 nginx:latest
```

info status about service
```bash
docker service ls
```

info about a specific service
```bash
docker service ps <service-name>
```
```bash
docker ps
```

```bash
docker service inspect --pretty <service-name>
```

see the nginx data on port 80
```bash
curl http://<ip>
```

see logs for service
```bash
docker service logs <service-name>
```

swarm mode creates a separate network called ingress and has the mode of swarm
```bash
docker network ls
```

inspect the ingress network
```bash
docker network inspect ingress
```

scale the service with
```bash
docker service scale <service-name>=2
```

see the scaling with
```bash
docker service ps <service-name>
```

also see the service here
```bash
docker ps
```

scale the service to 4
```bash
docker service scale <service-name>=2
```

check the services again
```bash
docker service ps <service-name>
```

take a node offline for maintenance
```bash
 docker node update --availability drain <host-name>
```

```bash
docker node ls
docker ps
```

to activate the node again
```bash
 docker node update --availability active <host-name>
```

remove a service with 
```bash
docker service rm <service-name>
```

# Stack Deploy (docker compose), secrets management, and secrets injection

Here is gitea used as example with postgresql as backend

create secrets
```bash
echo "gitea_secure_password" | docker secret create GITEA_DB_PASSWD -
echo "gitea_user" | docker secret create GITEA_DB_USER -
echo "gitea" | docker secret create GITEA_DB_NAME -
```

verify that the secrets are created
```bash
docker secret ls
```

create a docker compose file like this
```yaml
networks:
  gitea-net:
    driver: overlay

services:
  gitea:
    image: docker.io/gitea/gitea:1.23.1
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__database__DB_TYPE=postgres
      - GITEA__database__HOST=db:5432
    secrets:
      - GITEA_DB_PASSWD
      - GITEA_DB_USER
      - GITEA_DB_NAME
    volumes:
      - gitea-data:/data
    networks:
      - gitea-net
    ports:
      - "3000:3000"
      - "222:22"
    deploy:
      replicas: 2

  db:
    image: postgres:14
    environment:
      - POSTGRES_USER_FILE=/run/secrets/GITEA_DB_USER
      - POSTGRES_PASSWORD_FILE=/run/secrets/GITEA_DB_PASSWD
      - POSTGRES_DB_FILE=/run/secrets/GITEA_DB_NAME
    secrets:
      - GITEA_DB_PASSWD
      - GITEA_DB_USER
      - GITEA_DB_NAME
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - gitea-net
    deploy:
      replicas: 2

secrets:
  GITEA_DB_PASSWD:
    external: true
  GITEA_DB_USER:
    external: true
  GITEA_DB_NAME:
    external: true

volumes:
  gitea-data:
    driver: local
  postgres-data:
    driver: local
```

deploy the stack with
```bash
docker stack deploy -c docker-compose.yml --detach=true gitea-stack
```

verify deployment
```bash
docker stack services gitea-stack
```

secrets are stored in the container at
```bash
cat /run/secrets/<secret-name>
```

stop stack with
```
docker stack rm gitea-stack
```



Rotate secrets while the service is running

If you need to update a secret:

Create a new version of the secret:
```bash
echo "new_password" | docker secret create GITEA_DB_PASSWD_V2 -
```

Update the service to use the new secret:
```bash
docker service update --secret-rm GITEA_DB_PASSWD --secret-add GITEA_DB_PASSWD_V2 gitea-stack_gitea
```

Remove the old secret (once it’s no longer in use):
```bash
docker secret rm GITEA_DB_PASSWD
```

inspect sercets with
```
docker secret ls
docker secret inspect <secret_name>
```

remove secrets with
```
docker secret rm <secret_name>
```

verify stack is removed
```
docker stack ls
docker service ls
```


increase replicas
```
docker service scale gitea-stack_gitea=3
```


# Caddy web Server Guide
Caddy is a modern, open-source web server written in Go that prioritizes simplicity and security.  
It features automatic HTTPS by default, obtaining and renewing TLS certificates from Let's Encrypt without configuration.  
Caddy uses a straightforward JSON-based configuration format (Caddyfile) that's significantly more readable than traditional web servers.  
It includes built-in features like HTTP/2 and HTTP/3 support, reverse proxying, load balancing, static file serving, and middleware for URL rewriting and redirects.  
Caddy runs as a single binary with no dependencies, making deployment simple across platforms.  
Its process management includes API-driven configuration and automatic reloading.  
Caddy is particularly valued for development environments and production deployments where ease of use and modern security practices are priorities, requiring minimal setup compared to alternatives like Nginx or Apache.

## Install
run
```bash
sudo dnf install 'dnf-command(copr)'
sudo dnf copr enable @caddy/caddy
sudo dnf install caddy
```

start caddy service on server
```bash
sudo systemctl start caddy
```

enable service on server
```bash
sudo systemctl enable caddy
```

## Configure Caddy

Go to Caddy directory
```bash
cd /etc/caddy
```
Create backup of Caddyfile
```bash
sudo mv Caddyfile Caddyfile.dist
```
Create and alter a new Caddyfile

```bash
sudo vim Caddyfile
```
```bash
{
        email   user@sev.fo
}

(static) {
        @static {
                file
                path *.ico *.css *.js *.gif *.jpg *.jpeg *.png *.svg *.woff *.json
        }
        header @static Cache-Control max-age=5184000
}

(security) {
        header {
                # enable HSTS
                Strict-Transport-Security max-age=31536000;
                # disable clients from sniffing the media type
                X-Content-Type-Options nosniff
                # keep referrer data off of HTTP connections
                Referrer-Policy no-referrer-when-downgrade
        }
}

import conf.d/*.conf

```

```bash
sudo mkdir conf.d
cd conf.d/
```
```bash
sudo vim sev.conf
```

```bash
localhost {
        encode zstd gzip
        import static
        import security

#        root * /var/www/sev

#        file_server

        reverse_proxy localhost:8080

#       log {
#               output file /var/logs/...
#               format single_field common_log
#       }
}

```

```bash
sudo cp sev.conf www.conf
```
```bash
sudo vim www.conf
```
```bash
www.sev.fo {
        encode zstd gzip
        import static
        import security

#        root * /var/www/www

#        file_server

        reverse_proxy localhost:8080

#       log {
#               output file /var/logs/...
#               format single_field common_log
#       }
}

```
go ahead and start or restart Caddy if not done already.
At least it needs to be restarted whenever changes are made to any Caddy related files.
```bash
sudo systemctl start caddy
```
```bash
sudo systemctl reload caddy
```
```bash
sudo systemctl status caddy
```
## Local Development

**TLDR; edit the .conf file for localhost and internal tls, and lastly run command sudo caddy trust.**

Testing Caddy locally on server do the following:

Install Caddy if not installed, run
```bash
sudo dnf install 'dnf-command(copr)'
sudo dnf copr enable @caddy/caddy
sudo dnf install caddy
```

## Configure Caddy

Go to Caddy directory
```bash
cd /etc/caddy
```
Create backup of Caddyfile
```bash
sudo mv Caddyfile Caddyfile.dist
```
Create and alter a new Caddyfile

```bash
sudo vim Caddyfile
```
```bash
{
        email   user@sev.fo
}

(static) {
        @static {
                file
                path *.ico *.css *.js *.gif *.jpg *.jpeg *.png *.svg *.woff *.json
        }
        header @static Cache-Control max-age=5184000
}

(security) {
        header {
                # enable HSTS
                Strict-Transport-Security max-age=31536000;
                # disable clients from sniffing the media type
                X-Content-Type-Options nosniff
                # keep referrer data off of HTTP connections
                Referrer-Policy no-referrer-when-downgrade
        }
}

import conf.d/*.conf

```

```bash
sudo mkdir conf.d
cd conf.d/
```
```bash
sudo vim sev.conf
```

```bash
localhost {
#        encode zstd gzip
#        import static
#        import security
         tls internal

#        root * /var/www/sev

#        file_server

        reverse_proxy localhost:8080

#       log {
#               output file /var/logs/...
#               format single_field common_log
#       }
}


```

```
sudo dnf install nss-tools
```


go ahead and start or restart Caddy if not done already.
At least it needs to be restarted whenever changes are made to any Caddy related files.
```bash
sudo systemctl start caddy
```

Last but not least **IMPORTANT** run

```bash
sudo caddy trust
```
This commands makes the local certificates trust caddy, and https is possible.


```bash
sudo systemctl reload caddy
```
```bash
sudo systemctl status caddy
```

## Interact with API Behind Caddy on Remote Machine

On your local development machine, create an ssh tunnel to the server.
```bash
 ssh -L 8443:localhost:443 user@sev.fo@ktpv-server
```
add flag ```-fN```  to run ssh tunnel in background.

Use curl to request endpoint. It is important here to run the flak ```-k``` or else the development machine won't trust the server certificate.
```bash
 curl -k -X POST https://localhost:8443/login -H "Content-Type: application/json"   -d '{"user_name": "username", "password": "password"}'
```

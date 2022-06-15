#!/bin/bash

echo "Email: $1"
echo "Domain name: $2"

curl https://raw.githubusercontent.com/nginx-proxy/nginx-proxy/main/nginx.tmpl > nginx.tmpl

docker run --detach \
    --name nginx-proxy \
    --publish 80:80 \
    --publish 443:443 \
    --volume conf:/etc/nginx/conf.d  \
    --volume vhost:/etc/nginx/vhost.d \
    --volume html:/usr/share/nginx/html \
    --volume certs:/etc/nginx/certs \
    nginx

docker run --detach \
    --name nginx-proxy-gen \
    --volumes-from nginx-proxy \
    --volume $(pwd)/nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro \
    --volume /var/run/docker.sock:/tmp/docker.sock:ro \
    nginxproxy/docker-gen \
    -notify-sighup nginx-proxy -watch -wait 5s:30s /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf


docker run --detach \
    --name nginx-proxy-acme \
    --volumes-from nginx-proxy \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    --volume acme:/etc/acme.sh \
    --env "NGINX_DOCKER_GEN_CONTAINER=nginx-proxy-gen" \
    --env "DEFAULT_EMAIL=$1" \
    nginxproxy/acme-companion

docker run \
  -d \
  --name blueocean \
  --rm \
  -u root \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v blueocean-data:/var/jenkins_home \
  -v "$HOME":/home \
  --env "VIRTUAL_HOST=$2" \
  --env "LETSENCRYPT_HOST=$2" \
  --env "VIRTUAL_PORT=8080" \
  jenkinsci/blueocean
  
docker logs blueocean
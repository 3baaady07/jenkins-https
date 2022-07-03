#!/bin/bash


echo "Checking Docker installation!"

docker -v
dockerInstalled=1

if [ $? -ne 0 ]; then
    echo "This setup requires a docker installation!"
    dockerInstalled=0

else
    echo "Docker is ready."
fi

if [ $dockerInstalled == 1 ]; then
    # 1 is for true and 0 for false
    argChk=1;
    volumeName="$3"

    if [ -z "$1" ]; then 
        echo "ERROR: An email must be specified."
        argChk=0;
    fi

    if [ -z "$2" ]; then 
        echo "ERROR: A domain name must be specified."
        argChk=0;
    fi

    if [ -z "$3" ]; then 
        volumeName="jenkins-vol"
    fi

    if [ $argChk == 1 ]; then 
        echo "Email: $1"
        echo "Domain name: $2"
        echo "Jenkins volume name: $volumeName"
        
        curl https://raw.githubusercontent.com/nginx-proxy/nginx-proxy/main/nginx.tmpl > nginx.tmpl
        curl https://raw.githubusercontent.com/3baaady07/jenkins-https/main/Dockerfile > Dockerfile

        docker network create jenkins

        docker run --detach \
            --name nginx-proxy \
            --publish 80:80 \
            --publish 443:443 \
            -v conf:/etc/nginx/conf.d  \
            -v vhost:/etc/nginx/vhost.d \
            -v html:/usr/share/nginx/html \
            -v certs:/etc/nginx/certs \
            nginx

        docker run --detach \
            --name nginx-proxy-gen \
            --volumes-from nginx-proxy \
            -v $(pwd)/nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro \
            -v /var/run/docker.sock:/tmp/docker.sock:ro \
            nginxproxy/docker-gen \
            -notify-sighup nginx-proxy -watch -wait 5s:30s /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf


        docker run --detach \
            --name nginx-proxy-acme \
            --volumes-from nginx-proxy \
            -v /var/run/docker.sock:/var/run/docker.sock:ro \
            -v acme:/etc/acme.sh \
            --env NGINX_DOCKER_GEN_CONTAINER=nginx-proxy-gen \
            --env DEFAULT_EMAIL=$1 \
            nginxproxy/acme-companion

        docker run \
            --name jenkins-docker \
            --rm \
            --detach \
            --privileged \
            --network-alias docker \
            --env VIRTUAL_PORT=2375 \
            --env NETWORK_ACCESS=internal \
            --env DOCKER_TLS_CERTDIR=/certs \
            -v jenkins-docker-certs:/certs/client \
            -v $volumeName:/var/jenkins_home \
            --publish 2375:2375 \
            docker:dind \
            --storage-driver overlay2

        docker build -t myjenkins-blueocean:2.346.1-1 .

        docker run \
            --name jenkins-blueocean \
            --restart=on-failure \
            --detach \
            -v $volumeName:/var/jenkins_home \
            --env DOCKER_HOST=tcp://docker:2375 \
            --env DOCKER_CERT_PATH=/certs/client \
            --env DOCKER_TLS_VERIFY=1 \
            --env VIRTUAL_HOST=$2 \
            --env LETSENCRYPT_HOST=$2 \
            --env VIRTUAL_PORT=8080 \
            --volume jenkins-docker-certs:/certs/client:ro \
            myjenkins-blueocean:2.346.1-1 
    fi
fi
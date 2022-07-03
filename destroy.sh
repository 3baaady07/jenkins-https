#!/bin/bash

docker rm -f nginx-proxy
docker rm -f nginx-proxy-gen
docker rm -f nginx-proxy-acme
docker rm -f jenkins-blueocean
docker rm -f jenkins-docker
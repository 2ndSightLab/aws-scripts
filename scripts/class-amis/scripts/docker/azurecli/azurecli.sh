#!/bin/bash
processor=$1

echo "****get Azure cli as docker container***"
docker pull mcr.microsoft.com/azure-cli

#to use: docker run -it mcr.microsoft.com/azure-cli
history -c

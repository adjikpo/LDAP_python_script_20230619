#!/bin/sh

set -e
set -u

export DEBIAN_FRONTEND=noninteractive

# Mettre à jour le catalogue des paquets debian
apt-get update --allow-releaseinfo-change

apt-get install -y \
    apt-transport-https \
    ca-certificates \
    git \
    curl \
    wget \
    vim \
    gnupg2 \
    software-properties-common \
    net-tools \
    make
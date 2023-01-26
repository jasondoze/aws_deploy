#!/bin/bash

sudo apt update

# Install NginX
if ( which nginx ) 
then
  echo -e "\n==== NginX present ====\n"
else 
  echo -e "\n==== Installing NginX && NPM ====\n"
  sudo apt install -y nginx
fi

# Install Docker
if ( which docker ) 
then
  echo -e "\n==== Docker present ====\n"
else 
  echo -e "\n==== Installing Docker ====\n"
  curl -fsSL https://get.docker.com | bash
fi

# Copy service file and reload daemon
if [ systemctl is-active docker.service ] 
then
  echo -e "\n==== Docker service is running ====\n"
else 
  echo -e "\n==== Copying webserver.service ====\n"
  sudo systemctl restart docker.service
fi

# Restart the webserver service
if ( systemctl is-active nginx.service ) 
then
  echo -e "\n==== Crownapp running ====\n"
else 
  echo -e "\n==== Starting crownapp ====\n"
  sudo systemctl restart nginx.service
fi

# make sure docker is running   
docker run -p 80:80 -d --name my-nginx my-nginx

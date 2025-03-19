#!/bin/bash
set -e

# Pull the Docker image from Docker Hub
docker pull khushi0311/simple-python-app:tagname

# Run the Docker image as a container
docker run -d -p 5000:5000 khushi0311/simple-python-flask-app

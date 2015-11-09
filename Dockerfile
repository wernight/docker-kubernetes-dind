FROM docker:dind

# Install kubectl
RUN LATEST_DOCKER_COMPOSE="https://github.com$(curl -L https://github.com/docker/compose/releases/latest | grep -Eo '/docker/compose/releases/download/[^/]*/docker-compose-Linux-x86_64')" \
 && curl -L $LATEST_DOCKER_COMPOSE > /root/docker-compose \
 && chmod +x /root/docker-compose

# Docker Registry port
EXPOSE 5000

ADD start.sh /
ADD kubectl /usr/local/bin/

# Start Docker Registry
CMD ["/start.sh"]

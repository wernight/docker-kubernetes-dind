FROM docker:dind

# Docker Registry port
EXPOSE 5000

ADD start.sh /
ADD kubectl /usr/local/bin/

# Start Docker Registry
CMD ["/start.sh"]

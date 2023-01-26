# syntax=docker/dockerfile:1
FROM nginx:latest
COPY webserver.sh /usr/local/bin/webserver.sh
RUN chmod +x /usr/local/bin/webserver.sh
# ADD webserver.sh /usr/local/bin/webserver.sh
CMD ["/usr/local/bin/webserver.sh"]
EXPOSE 80

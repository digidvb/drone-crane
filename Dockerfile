FROM gcr.io/go-containerregistry/crane/debug:v0.5.1

ENV HOME /root
ENV USER root
ENV DOCKER_CONFIG /root/.docker/

# add the wrapper which acts as a drone plugin
COPY plugin.sh /plugin.sh
ENTRYPOINT [ "/plugin.sh" ]

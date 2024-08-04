ARG STACK_VERSION
FROM docker.elastic.co/elasticsearch/elasticsearch:$STACK_VERSION

ARG ES_PASSWORD
ARG KIBANA_PASSWORD
ENV ES_PASSWORD=$ES_PASSWORD
ENV KIBANA_PASSWORD=$KIBANA_PASSWORD

USER root

WORKDIR /usr/share/elasticsearch

RUN apt-get update

COPY . .

RUN chmod +x ./setup.sh

CMD ./setup.sh

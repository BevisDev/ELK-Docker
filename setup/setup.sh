#!/bin/bash

# check exists elasticsearch password
if [ -z $ELASTIC_PASSWORD ]; then
    echo "ELASTIC_PASSWORD is empty";
    exit 1;
fi;

# check exists kibana passoword
if [ -z $KIBANA_PASSWORD ]; then
    echo "KIBANA_PASSWORD is empty";
    exit 1;
fi;

# create CA
if [ ! -f config/certs/ca.zip ]; then
    echo "=========Creating CA";
    yes | bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip;
    
    # check certs
    if [ ! -f config/certs/ca.zip ]; then
        echo "==========Create CA failed";
        exit 1;
    fi
    
    unzip config/certs/ca.zip -d config/certs;
fi;

# create certs
if [ ! -f config/certs/certs.zip ]; then
    echo "=========Creating certs";
    yes | bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key;
    
    # check certs
    if [ ! -f config/certs/certs.zip ]; then
        echo "==========Create certs failed";
        exit 1;
    fi

    unzip config/certs/certs.zip -d config/certs;
fi;

# Health check elasticsearch
echo "=========Waiting for Elasticsearch availability"
until curl -s $ES01_HOST --cacert config/certs/ca/ca.crt | grep -q "missing authentication credentials"; do sleep 30; done;

echo "=========Setting kibana_system password";
until curl -s -X POST $ES01_HOST/_security/user/kibana_system/_password -u "elastic:$ELASTIC_PASSWORD" -H "Content-Type: application/json" -d "{\"password\":\"$KIBANA_PASSWORD\"}" --cacert config/certs/ca/ca.crt | grep -q "^{}"; do sleep 10; done;

echo "=========Setting logstash_system password";
until curl -s -X POST $ES01_HOST/_security/user/logstash_system/_password -u "elastic:$ELASTIC_PASSWORD" -H "Content-Type: application/json" -d "{\"password\":\"$LOGSTASH_PASSWORD\"}" --cacert config/certs/ca/ca.crt | grep -q "^{}"; do sleep 10; done;
                
echo "=========All done!";

#!/bin/bash

# check exists elasticsearch password
if [ -z $ES_PASSWORD ]; then
    echo "ES_PASSWORD is empty";
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
echo "=========Health check Elasticsearch"
until curl -s --cacert config/certs/ca/ca.crt https://es01:9200 | grep -q "missing authentication credentials"; do sleep 30; done;
echo "Test curl"
curl --cacert config/certs/ca.cert https://es01:9200 | -u"elastic:$ES_PASSWORD"
echo "=========Setting kibana_system password";
until curl -s -X POST --cacert config/certs/ca/ca.crt -u "elastic:$ES_PASSWORD" -H "Content-Type: application/json" https://es01:9200/_security/user/kibana_system/_password -d "{\"password\":\"$KIBANA_PASSWORD\"}" | grep -q "^{}"; do sleep 10; done;
        
echo "=========All done!";

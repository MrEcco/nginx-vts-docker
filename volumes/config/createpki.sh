#!/bin/bash
openssl dhparam -out dhparam.pem 2048
openssl rand 80 > session_ticket.rand
openssl genrsa -out sslgap.key 4096
openssl req -x509 -new -key sslgap.key -days 10000 -out sslgap.crt -subj "/C=NN/CN=SELF-SIGNED GAP, NOT FOR PRODUCTION USE"

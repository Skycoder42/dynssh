#!/bin/bash
set -exo pipefail

host=dynssh-test-client.example.com
ipv4=127.0.0.1
apiKey=d12cf992-39d8-4f91-923f-536386984412

basicAuth=$(echo -n "$host:$apiKey" | base64 -w0 -)
authHeader="Authorization: Basic $basicAuth"

curl --verbose \
  -H "$authHeader" \
  "localhost:23293/dynssh/update?fqdn=$host&ipv4=$ipv4"

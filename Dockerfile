FROM python:alpine

RUN apk add git curl jq

ENV BOSH_VERSION=6.4.1
RUN curl -sL https://github.com/cloudfoundry/bosh-cli/releases/download/v${BOSH_VERSION}/bosh-cli-6.4.1-linux-amd64 | \
  install /dev/stdin /usr/local/bin/bosh

RUN pip install yq

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

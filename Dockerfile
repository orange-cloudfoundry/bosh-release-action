FROM python:alpine

RUN apk add git curl jq bash

# renovate: datasource=github-releases depName=cloudfoundry/bosh-cli
ENV BOSH_VERSION=7.5.6
RUN curl -sL https://github.com/cloudfoundry/bosh-cli/releases/download/v${BOSH_VERSION}/bosh-cli-${BOSH_VERSION}-linux-amd64 | \
  install /dev/stdin /usr/local/bin/bosh && bosh --version

RUN pip install yq

# renovate: datasource=github-releases depName=carvel-dev/vendir
ENV VENDIR_VERSION=0.40.1
RUN curl -sL https://github.com/carvel-dev/vendir/releases/download/v${VENDIR_VERSION}/vendir-linux-amd64 | \
  install /dev/stdin /usr/local/bin/vendir && vendir -v

# renovate: datasource=github-releases depName=mikefarah/yq
ENV YQ_VERSION="v4.43.1"
RUN echo "Installing yq version ${YQ_VERSION}" ; \
    curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" |\
    install /dev/stdin /usr/local/bin/yq && \
    /usr/local/bin/yq --version

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

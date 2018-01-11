FROM python:2.7-alpine
LABEL maintainer "igor.fomenko@logimethods.com"

ENV TERRAFORM_VERSION=0.11.1
ENV TERRAFORM_SHA256SUM=4e3d5e4c6a267e31e9f95d4c1b00f5a7be5a319698f0370825b459cb786e2f35
ENV GSUTIL_VERSION=4.28

#install deps and install gsutil
RUN apk add --update git curl openssh && \
    curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    echo "${TERRAFORM_SHA256SUM}  terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    sha256sum -cs terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin && \
    rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    apk add --virtual build-deps \
    gcc \
    libffi-dev \
    python-dev \
    linux-headers \
    musl-dev \
    openssl-dev \
  && pip install gsutil \
  && apk del build-deps \
  && rm -rf /var/cache/apk/*

ENTRYPOINT ["/bin/sh"]
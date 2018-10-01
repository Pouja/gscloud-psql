FROM python:2.7-alpine

RUN apk add postgresql-client

COPY lib/google-cloud-sdk-216.0.0-linux-x86_64.tar.gz /
RUN tar xzf /google-cloud-sdk-216.0.0-linux-x86_64.tar.gz
ENV PATH="/google-cloud-sdk/bin:${PATH}"

ENTRYPOINT ["/entrypoint.sh"]
COPY entrypoint.sh /
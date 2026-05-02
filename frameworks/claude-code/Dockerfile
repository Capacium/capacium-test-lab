FROM node:22-alpine

RUN apk add --no-cache bash git

COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

WORKDIR /test
HEALTHCHECK --interval=10s --retries=5 CMD /scripts/verify.sh

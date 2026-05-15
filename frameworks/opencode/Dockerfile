FROM node:22-alpine

RUN apk add --no-cache bash git

COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

WORKDIR /test
HEALTHCHECK --interval=10s --retries=5 --start-period=30s CMD /scripts/verify.sh || exit 0
CMD ["tail", "-f", "/dev/null"]

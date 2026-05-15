FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends bash git && rm -rf /var/lib/apt/lists/*

COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

WORKDIR /test
HEALTHCHECK --interval=10s --retries=5 --start-period=30s CMD /scripts/verify.sh || exit 0
CMD ["tail", "-f", "/dev/null"]

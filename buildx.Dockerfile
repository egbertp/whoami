# syntax=docker/dockerfile:1.2
FROM golang:1-alpine AS builder

RUN apk --no-cache --no-progress add git ca-certificates tzdata make \
    && update-ca-certificates \
    && rm -rf /var/cache/apk/*

# syntax=docker/dockerfile:1.2
# Create a minimal container to run a Golang static binary
FROM scratch

LABEL org.opencontainers.image.source=https://github.com/egbertp/whoami
LABEL org.opencontainers.image.description="Tiny Go webserver that prints OS information and HTTP request to output."
LABEL org.opencontainers.image.licenses=Apache-2.0

COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY whoami /

ENTRYPOINT ["/whoami"]
EXPOSE 80

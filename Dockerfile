FROM golang:1-alpine AS builder

RUN apk --no-cache --no-progress add git ca-certificates tzdata make \
    && update-ca-certificates \
    && rm -rf /var/cache/apk/*

WORKDIR /go/whoami

# Download go modules
COPY go.mod .
COPY go.sum .
RUN GO111MODULE=on GOPROXY=https://proxy.golang.org go mod download

COPY . .

RUN make build

# Create a minimal container to run a Golang static binary
FROM scratch

LABEL org.opencontainers.image.source=https://github.com/egbertp/whoami
LABEL org.opencontainers.image.description="Tiny Go webserver that prints OS information and HTTP request to output."
LABEL org.opencontainers.image.licenses=Apache-2.0

COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /go/whoami/whoami .

ENTRYPOINT ["/whoami"]
EXPOSE 80

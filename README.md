# whoami

Tiny Go webserver that prints OS information and HTTP request to output.

This project is inspired from the [Traefik whoami](https://github.com/traefik/whoami/) service. I'm planning on upgrading the functionality of this service to include more features. 

## Deploy

### Directly exposed to the internet

#### As a binary

Download the latest version from the [releases](https://github.com/egbertp/whoami/releases/) page. 

This example downloads the latest version for `Linux` on `amd64` architecture

```shell
$ curl -L -O https://github.com/egbertp/whoami/releases/download/v1.0.2/whoami_1.0.2_checksums.txt
$ curl -L -O https://github.com/egbertp/whoami/releases/download/v1.0.2/whoami_v1.0.2_linux_amd64.tar.gz
```

```shell
$ shasum -c whoami_1.0.2_checksums.txt

whoami_v1.0.2_linux_amd64.tar.gz: OK
```

```shell
$ tar -xzvf whoami_v1.0.2_linux_amd64.tar.gz
```

```shell
$ ./whoami -name whoami-service -port 5678
```

Check if the service is responsive

```shell
$ curl http://localhost:5678
Name: whoami-service
Hostname: Macbook.local
IP: 127.0.0.1
IP: ::1
IP: fe80::1
RemoteAddr: [::1]:63065
GET / HTTP/1.1
Host: localhost:5678
User-Agent: curl/8.7.1
Accept: */*
```

#### As a docker container

```shell
$ docker run -d -P --name whoami-container ghcr.io/egbertp/whoami:latest
```

```shell
$ docker inspect --format '{{ .NetworkSettings.Ports }}'  whoami-container
map[80/tcp:[{0.0.0.0 55001}]]
```

```shell
$ curl http://0.0.0.0:55001
Hostname: d6cabf2879f0
IP: 127.0.0.1
IP: ::1
IP: 172.17.0.2
RemoteAddr: 172.17.0.1:55758
GET / HTTP/1.1
Host: 0.0.0.0:55001
User-Agent: curl/8.7.1
Accept: */*
```

```shell
$ docker logs -f whoami-container

2025/04/21 20:26:26 Starting up on port 80
```


### Behind a reverse proxy like [`Traefik`](https://traefik.io/traefik/)

Create a Docker compose file `compose.yaml`

```yaml
services:
  whoami:
    image: "ghcr.io/egbertp/whoami"
    container_name: "whoami-service"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.whoami-http.entrypoints=web"
      - "traefik.http.routers.whoami-http.rule=Host(`whoami-service.knutsel.space`)"
      - "traefik.http.routers.whoami-http.middlewares=whoami-https"
      - "traefik.http.middlewares.whoami-https.redirectscheme.scheme=https"
      - "traefik.http.routers.whoami.entrypoints=websecure"
      - "traefik.http.routers.whoami.rule=Host(`whoami-service.knutsel.space`)"
      - "traefik.http.routers.whoami.tls=true"
      - "traefik.http.routers.whoami.tls.certresolver=myresolver"
```

Start the service using
```shell
docker compose up

[+] Running 1/1
 ✔ Container whoami-service  Created                                                                                                                                                                          0.0s
Attaching to whoami-service
whoami-service  | 2025/04/21 20:29:05 Starting up on port 80
```

## Usage of endpoints

### Paths

#### `/[?wait=d]`

Returns the whoami information (request and network information).

The optional `wait` query parameter can be provided to tell the server to wait before sending the response.
The duration is expected in Go's [`time.Duration`](https://golang.org/pkg/time/#ParseDuration) format (e.g. `/?wait=100ms` to wait 100 milliseconds).

The optional `env` query parameter can be set to `true` to add the environment variables to the response.

#### `/api`

Returns the whoami information (and some extra information) as JSON.

The optional `env` query parameter can be set to `true` to add the environment variables to the response.

#### `/bench`

Always return the same response (`1`).

#### `/data?size=n[&unit=u]`

Creates a response with a size `n`.

The unit of measure, if specified, accepts the following values: `KB`, `MB`, `GB`, `TB` (optional, default: bytes).

#### `/echo`

WebSocket echo.

#### `/health`

Heath check.

- `GET`, `HEAD`, ...: returns a response with the status code defined by the `POST`
- `POST`: changes the status code of the `GET` (`HEAD`, ...) response.

### Flags

| Flag      | Env var              | Description                             |
|-----------|----------------------|-----------------------------------------|
| `cert`    |                      | Give me a certificate.                  |
| `key`     |                      | Give me a key.                          |
| `cacert`  |                      | Give me a CA chain, enforces mutual TLS |
| `port`    | `WHOAMI_PORT_NUMBER` | Give me a port number. (default: `80`)  |
| `name`    | `WHOAMI_NAME`        | Give me a name.                         |
| `verbose` |                      | Enable verbose logging.                 |



```shell
# updates health check status
$ curl -X POST -d '500' http://localhost:55001/health
```

## Development

#### Test / Test coverage

```shell
$ make test

go test -v -cover ./...
=== RUN   Test_contentReader_Read
=== RUN   Test_contentReader_Read/simple
=== PAUSE Test_contentReader_Read/simple
=== CONT  Test_contentReader_Read/simple
--- PASS: Test_contentReader_Read (0.00s)
    --- PASS: Test_contentReader_Read/simple (0.00s)
=== RUN   Test_contentReader_ReadSeek
=== RUN   Test_contentReader_ReadSeek/simple
=== PAUSE Test_contentReader_ReadSeek/simple
=== CONT  Test_contentReader_ReadSeek/simple
--- PASS: Test_contentReader_ReadSeek (0.00s)
    --- PASS: Test_contentReader_ReadSeek/simple (0.00s)
PASS
coverage: 18.2% of statements
ok  	knutsel.space/whoami	(cached)	coverage: 18.2% of statements
```


#### Linting

```shell
$ make check

golangci-lint run
0 issues.
```


#### Make docker image

```shell
$ make image

docker build -t ghcr.io/egbertp/whoami .
[+] Building 13.7s (16/16) FINISHED                                                  docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                 0.0s
 => => transferring dockerfile: 650B                                                                 0.0s
 => WARN: FromAsCasing: 'as' and 'FROM' keywords' casing do not match (line 1)                       0.0s
 => [internal] load metadata for docker.io/library/golang:1-alpine                                   1.6s
 => [internal] load .dockerignore                                                                    0.0s
 => => transferring context: 2B                                                                      0.0s
 => [builder 1/8] FROM docker.io/library/golang:1-alpine@sha256:7772cb5322baa875edd74705556d08f0eec  6.4s
 => => resolve docker.io/library/golang:1-alpine@sha256:7772cb5322baa875edd74705556d08f0eeca7b9c4b5  0.0s
 => => sha256:f06f02e45fb5a5503c3c2f5b8560550514ddfd8de6dd5437947e380e6e709d36 2.10kB / 2.10kB       0.0s
 => => sha256:6e771e15690e2fabf2332d3a3b744495411d6e0b00b2aea64419b58b0066cf81 3.99MB / 3.99MB       0.4s
 => => sha256:26e33b27c9b76515e1154a131a67e2f0fe88ba9e9bc48a1a704c790a0561e068 297.87kB / 297.87kB   0.2s
 => => sha256:a002eda2038f0953467f843586445333b2af3e827e57b15849040931f2903fb4 75.20MB / 75.20MB     2.3s
 => => sha256:7772cb5322baa875edd74705556d08f0eeca7b9c4b5367754ce3f2f00041ccee 10.29kB / 10.29kB     0.0s
 => => sha256:3fdeba361d51263b1145c5422ec4724e124733f60019f275bc86ae0f499d3519 1.92kB / 1.92kB       0.0s
 => => sha256:ffc8c2e8d985822b3b6ac5ae3a8c130feb27393e9e165e3e1cebea69d9e30f32 127B / 127B           0.4s
 => => extracting sha256:6e771e15690e2fabf2332d3a3b744495411d6e0b00b2aea64419b58b0066cf81            0.1s
 => => sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1 32B / 32B             0.6s
 => => extracting sha256:26e33b27c9b76515e1154a131a67e2f0fe88ba9e9bc48a1a704c790a0561e068            0.0s
 => => extracting sha256:a002eda2038f0953467f843586445333b2af3e827e57b15849040931f2903fb4            3.8s
 => => extracting sha256:ffc8c2e8d985822b3b6ac5ae3a8c130feb27393e9e165e3e1cebea69d9e30f32            0.0s
 => => extracting sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1            0.0s
 => [internal] load build context                                                                    0.1s
 => => transferring context: 6.32MB                                                                  0.1s
 => [builder 2/8] RUN apk --no-cache --no-progress add git ca-certificates tzdata make     && updat  1.4s
 => [builder 3/8] WORKDIR /go/whoami                                                                 0.0s
 => [builder 4/8] COPY go.mod .                                                                      0.0s
 => [builder 5/8] COPY go.sum .                                                                      0.0s
 => [builder 6/8] RUN GO111MODULE=on GOPROXY=https://proxy.golang.org go mod download                0.2s
 => [builder 7/8] COPY . .                                                                           0.0s
 => [builder 8/8] RUN make build                                                                     3.8s
 => [stage-1 1/3] COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo                        0.0s
 => [stage-1 2/3] COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/             0.0s
 => [stage-1 3/3] COPY --from=builder /go/whoami/whoami .                                            0.0s
 => exporting to image                                                                               0.0s
 => => exporting layers                                                                              0.0s
 => => writing image sha256:0c298c77f287b7b0db9b12588e0ff10ef977ebbf049087fa376acca6bfe3321b         0.0s
 => => naming to ghcr.io/egbertp/whoami                                                              0.0s

 1 warning found (use docker --debug to expand):
 - FromAsCasing: 'as' and 'FROM' keywords' casing do not match (line 1)

What's next:
    View a summary of image vulnerabilities and recommendations → docker scout quickview
```
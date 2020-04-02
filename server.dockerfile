FROM golang:alpine as build

# Native build dependencies
RUN apk add git g++

WORKDIR /src/github.com/drone

ENV GO111MODULE=on

RUN git clone https://github.com/jakehamilton/drone drone

WORKDIR /src/github.com/drone/drone

RUN go install -tags "oss nolimit" github.com/drone/drone/cmd/drone-server

FROM alpine:3.11 as certificates

RUN apk add -U --no-cache ca-certificates

FROM alpine:3.11

EXPOSE 80 443

VOLUME /data

RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV GODEBUG netdns=go
ENV XDG_CACHE_HOME /data
ENV DRONE_DATABASE_DRIVER sqlite3
ENV DRONE_DATABASE_DATASOURCE /data/database.sqlite
ENV DRONE_RUNNER_OS=linux
ENV DRONE_RUNNER_ARCH=amd64
ENV DRONE_SERVER_PORT=:80
ENV DRONE_SERVER_HOST=localhost
ENV DRONE_DATADOG_ENABLED=true
ENV DRONE_DATADOG_ENDPOINT=https://stats.drone.ci/api/v1/series

COPY --from=certificates /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=build /go/bin/drone-server /bin/drone-server

ENTRYPOINT ["/bin/drone-server"]

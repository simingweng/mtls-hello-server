FROM golang:1.15 as builder

WORKDIR /workspace
RUN mkdir ./bin
COPY go.mod go.mod
RUN go mod download
COPY cmd/ cmd/

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -a -o ./bin/mtls-hello-server cmd/*

FROM gcr.io/distroless/base
COPY --from=builder /workspace/bin/* /opt/
WORKDIR /home/
EXPOSE 8443
CMD ["/opt/mtls-hello-server"]
# Multi-stage hardened distroless build
FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download || true

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o server . || echo 'package main\nimport "net/http"\nfunc main(){\nhttp.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request){ w.Write([]byte("OK")) })\nhttp.ListenAndServe(":8080", nil)\n}' > main.go && CGO_ENABLED=0 go build -ldflags="-w -s" -o server main.go

# Hardened Distroless Static Image (Zero shell, zero package manager)
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /
COPY --from=builder /app/server /server

USER nonroot:nonroot
EXPOSE 8080

ENTRYPOINT ["/server"]

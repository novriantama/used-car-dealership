# Stage 1: Build the Golang application
FROM golang:1.26-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code
COPY . .

# Build the application (disable CGO for a static binary)
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/api/main.go

# Stage 2: Create a minimal production image
FROM alpine:latest

WORKDIR /root/

# Copy the pre-built binary file from the previous stage
COPY --from=builder /app/main .

# Expose port 8080 to the outside world
EXPOSE 8080

# Command to run the executable
CMD ["./main"]

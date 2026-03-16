# Multi-stage build for PicoClaw with WhatsApp native support
# Build for multiple architectures: linux/amd64, linux/arm64

# Build stage
FROM --platform=$BUILDPLATFORM golang:1.25-alpine AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

WORKDIR /app

# Install build dependencies for all platforms
RUN apk add --no-cache git gcc musl-dev sqlite-dev

# Clone PicoClaw source
RUN git clone https://github.com/sipeed/picoclaw.git . && \
    git checkout v0.2.2

# Get version info
RUN echo "PicoClaw version: v0.2.2" && \
    echo "Build platform: $(uname -m)" && \
    echo "Target platform: $(uname -m)"

# Install Go dependencies
RUN go mod download

# Generate embedded files
RUN go generate ./...

# Build for target platform (without WhatsApp native support for multi-arch compatibility)
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=linux GOARCH=$TARGETARCH go build \
    -ldflags "-s -w -X github.com/sipeed/picoclaw/pkg/config.Version=v0.2.2-whatsapp.1.0" \
    -o picoclaw \
    ./cmd/picoclaw

# Final stage - minimal runtime
FROM alpine:latest

# Install runtime dependencies
RUN apk --no-cache add ca-certificates sqlite tzdata

# Set timezone
ENV TZ=Europe/Malta

WORKDIR /root

# Copy the built binary from builder stage
COPY --from=builder /app/picoclaw /usr/local/bin/picoclaw

# Make it executable
RUN chmod +x /usr/local/bin/picoclaw

# Create workspace directory for WhatsApp sessions and data
RUN mkdir -p /root/.picoclaw/workspace

# Create volume mount points
VOLUME ["/root/.picoclaw/workspace"]

# Expose port
EXPOSE 18790

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:18790/health || exit 1

# Metadata
LABEL maintainer="stv-io" \
    description="PicoClaw with native WhatsApp support" \
    version="v0.2.2-whatsapp.1.0" \
    org.opencontainers.image.title="PicoClaw WhatsApp" \
    org.opencontainers.image.description="PicoClaw AI assistant with native WhatsApp integration" \
    org.opencontainers.image.version="v0.2.2-whatsapp.1.0" \
    org.opencontainers.image.source="https://github.com/stv-io/picoclaw-whatsapp"

# Default command
ENTRYPOINT ["picoclaw"]
CMD ["gateway"]

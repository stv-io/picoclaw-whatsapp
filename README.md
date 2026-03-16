# PicoClaw WhatsApp

PicoClaw AI assistant with native WhatsApp integration via whatsmeow.

## Overview

This repository provides a custom Docker build of [PicoClaw](https://github.com/sipeed/picoclaw) with native WhatsApp support enabled. The official PicoClaw Docker images don't include WhatsApp support to keep the binary size small, so this build includes the `whatsapp_native` build tag.

## Versioning

Images are versioned using the format: `{picoclaw-version}-whatsapp.{whatsapp-tool-version}`

- **PicoClaw Version**: v0.2.2 (base PicoClaw release)
- **WhatsApp Tool Version**: 1.0 (our WhatsApp integration version)
- **Example**: `v0.2.2-whatsapp.1.0`

## Features

- ✅ Native WhatsApp integration (no external bridge needed)
- ✅ Multi-architecture support (linux/amd64, linux/arm64)
- ✅ Automated builds via GitHub Actions
- ✅ SBOM generation for security
- ✅ Health checks and monitoring
- ✅ Persistent session storage

## Quick Start

### Docker Pull

```bash
docker pull ghcr.io/stv-io/picoclaw-whatsapp:v0.2.2-whatsapp.1.0
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: picoclaw-gateway
spec:
  template:
    spec:
      containers:
      - name: picoclaw
        image: ghcr.io/stv-io/picoclaw-whatsapp:v0.2.2-whatsapp.1.0
        ports:
        - containerPort: 18790
        env:
        - name: PICOCLAW_GATEWAY_HOST
          value: "0.0.0.0"
        volumeMounts:
        - name: workspace
          mountPath: /root/.picoclaw/workspace
      volumes:
      - name: workspace
        persistentVolumeClaim:
          claimName: picoclaw-workspace
```

### Configuration

Create a `config.json` with WhatsApp native support:

```json
{
  "model_list": [
    {
      "model_name": "gemini-3.1-pro",
      "model": "openai/gemini-3.1-pro-preview",
      "api_key": "your-api-key",
      "api_base": "https://generativelanguage.googleapis.com/v1beta/openai/"
    }
  ],
  "agents": {
    "defaults": {
      "model": "gemini-3.1-pro"
    }
  },
  "channels": {
    "whatsapp": {
      "enabled": true,
      "use_native": true,
      "session_store_path": "",
      "allow_from": []
    }
  }
}
```

## WhatsApp Setup

1. Deploy the container
2. Check the logs for the QR code:
   ```bash
   kubectl logs picoclaw-gateway-xxxxx | grep -i qr
   ```
3. Open WhatsApp → Settings → Linked Devices
4. Scan the QR code
5. Session will be stored in `/root/.picoclaw/workspace/whatsapp/`

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   WhatsApp      │    │  PicoClaw       │    │   LLM API       │
│   (Client)      │◄──►│  (Gateway)      │◄──►│  (Gemini/etc.)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
     whatsmeow           native support         HTTP API
```

## Building

### Local Build

```bash
# Clone the repository
git clone https://github.com/stv-io/picoclaw-whatsapp.git
cd picoclaw-whatsapp

# Build for current platform
docker build -t picoclaw-whatsapp .

# Build multi-arch
docker buildx build --platform linux/amd64,linux/arm64 -t picoclaw-whatsapp .
```

### Automated Build

Push to `main` branch or create a tag to trigger automated builds:

```bash
# Trigger build with version tag
git tag v0.2.2-whatsapp.1.0
git push origin v0.2.2-whatsapp.1.0
```

## Image Tags

- `v0.2.2-whatsapp.1.0` - Versioned release
- `latest` - Latest main branch build
- `main-YYYYMMDD-HHmmss` - Timestamped builds from main branch

## Security

- ✅ SBOM generated for all builds
- ✅ Minimal Alpine-based runtime
- ✅ Non-root user (where possible)
- ✅ Health checks enabled

## Support

- **Base PicoClaw**: [sipeed/picoclaw](https://github.com/sipeed/picoclaw)
- **WhatsApp Library**: [whatsmeow](https://github.com/tulir/whatsmeow)
- **Issues**: [GitHub Issues](https://github.com/stv-io/picoclaw-whatsapp/issues)

## License

This build follows the same license as PicoClaw. See the [PicoClaw repository](https://github.com/sipeed/picoclaw) for details.

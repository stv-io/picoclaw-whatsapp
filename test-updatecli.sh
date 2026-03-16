#!/bin/bash

# Test script to verify UpdateCLI patterns match current files

echo "Testing UpdateCLI patterns..."

# Test current version
CURRENT_VERSION="0.2.2"
NEW_VERSION="0.2.3"

echo "Current version: v$CURRENT_VERSION"
echo "New version: v$NEW_VERSION"
echo ""

# Test Dockerfile patterns
echo "=== Testing Dockerfile patterns ==="
if grep -q "git checkout v$CURRENT_VERSION" Dockerfile; then
    echo "✓ Dockerfile checkout pattern matches"
else
    echo "✗ Dockerfile checkout pattern failed"
fi

if grep -q "v$CURRENT_VERSION-whatsapp.1.0" Dockerfile; then
    echo "✓ Dockerfile build version pattern matches"
else
    echo "✗ Dockerfile build version pattern failed"
fi

# Test Dockerfile.native patterns
echo ""
echo "=== Testing Dockerfile.native patterns ==="
if grep -q "git checkout v$CURRENT_VERSION" Dockerfile.native; then
    echo "✓ Dockerfile.native checkout pattern matches"
else
    echo "✗ Dockerfile.native checkout pattern failed"
fi

if grep -q "v$CURRENT_VERSION-whatsapp.1.0" Dockerfile.native; then
    echo "✓ Dockerfile.native build version pattern matches"
else
    echo "✗ Dockerfile.native build version pattern failed"
fi

# Test Makefile patterns
echo ""
echo "=== Testing Makefile patterns ==="
if grep -q "PICOCLAW_VERSION ?= v$CURRENT_VERSION" Makefile; then
    echo "✓ Makefile version pattern matches"
else
    echo "✗ Makefile version pattern failed"
fi

# Test GitHub Actions patterns
echo ""
echo "=== Testing GitHub Actions patterns ==="
echo "ℹ️  GitHub Actions workflow dynamically extracts version from Dockerfile - no update needed"

# Test README patterns
echo ""
echo "=== Testing README patterns ==="
if grep -q "docker pull ghcr.io/stv-io/picoclaw-whatsapp:v$CURRENT_VERSION-whatsapp.1.0" README.md; then
    echo "✓ README Docker pull pattern matches"
else
    echo "✗ README Docker pull pattern failed"
fi

if grep -q "image: ghcr.io/stv-io/picoclaw-whatsapp:v$CURRENT_VERSION-whatsapp.1.0" README.md; then
    echo "✓ README Kubernetes image pattern matches"
else
    echo "✗ README Kubernetes image pattern failed"
fi

if grep -q "\`v$CURRENT_VERSION-whatsapp.1.0\` - Versioned release" README.md; then
    echo "✓ README image tags pattern matches"
else
    echo "✗ README image tags pattern failed"
fi

echo ""
echo "Pattern verification complete!"

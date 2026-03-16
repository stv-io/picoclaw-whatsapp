# PicoClaw WhatsApp Build Makefile

# Variables
REGISTRY ?= ghcr.io/stv-io
IMAGE_NAME ?= picoclaw-whatsapp
PICOCLAW_VERSION ?= v0.2.2
WHATSAPP_VERSION ?= 1.0
VERSION ?= $(PICOCLAW_VERSION)-whatsapp.$(WHATSAPP_VERSION)

# Docker buildx builder
BUILDER ?= picoclaw-builder

.PHONY: help build build-local build-multi-arch push clean test

help: ## Show this help
	@echo "PicoClaw WhatsApp Build Helper"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup-builder: ## Setup Docker buildx builder
	docker buildx create --name $(BUILDER) --use --bootstrap 2>/dev/null || docker buildx use $(BUILDER)

build-local: ## Build for current platform only (multi-arch version)
	docker build -t $(IMAGE_NAME):$(VERSION) .
	docker tag $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest

build-native: ## Build with WhatsApp native support (single arch)
	docker build -f Dockerfile.native -t $(IMAGE_NAME):$(VERSION)-native .
	docker tag $(IMAGE_NAME):$(VERSION)-native $(IMAGE_NAME):latest-native

build-multi-arch: setup-builder ## Build for multiple architectures (amd64, arm64)
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--tag $(REGISTRY)/$(IMAGE_NAME):$(VERSION) \
		--tag $(REGISTRY)/$(IMAGE_NAME):latest \
		--push .

push-multi-arch: ## Push multi-arch build to registry
	docker tag $(IMAGE_NAME):$(VERSION) $(REGISTRY)/$(IMAGE_NAME):$(VERSION)
	docker tag $(IMAGE_NAME):latest $(REGISTRY)/$(IMAGE_NAME):latest
	docker push $(REGISTRY)/$(IMAGE_NAME):$(VERSION)
	docker push $(REGISTRY)/$(IMAGE_NAME):latest

push-native: ## Push native build to registry
	docker tag $(IMAGE_NAME):$(VERSION)-native $(REGISTRY)/$(IMAGE_NAME):$(VERSION)-native
	docker tag $(IMAGE_NAME):latest-native $(REGISTRY)/$(IMAGE_NAME):latest-native
	docker push $(REGISTRY)/$(IMAGE_NAME):$(VERSION)-native
	docker push $(REGISTRY)/$(IMAGE_NAME):latest-native

test-multi-arch: ## Test the multi-arch built image
	docker run --rm -p 18790:18790 $(IMAGE_NAME):$(VERSION) &
	@sleep 5
	@curl -f http://localhost:18790/health || (echo "Health check failed" && exit 1)
	@docker stop $$(docker ps -q --filter ancestor=$(IMAGE_NAME):$(VERSION))

test-native: ## Test the native built image
	docker run --rm -p 18790:18790 $(IMAGE_NAME):$(VERSION)-native &
	@sleep 5
	@curl -f http://localhost:18790/health || (echo "Health check failed" && exit 1)
	@docker stop $$(docker ps -q --filter ancestor=$(IMAGE_NAME):$(VERSION)-native)

clean: ## Clean up Docker resources
	docker buildx rm $(BUILDER) 2>/dev/null || true
	docker system prune -f

version: ## Show version info
	@echo "PicoClaw Version: $(PICOCLAW_VERSION)"
	@echo "WhatsApp Version: $(WHATSAPP_VERSION)"
	@echo "Full Version: $(VERSION)"
	@echo "Registry: $(REGISTRY)"
	@echo "Image: $(IMAGE_NAME)"

tag-release: ## Create and push a release tag
	@echo "Creating release tag v$(VERSION)"
	git tag v$(VERSION)
	git push origin v$(VERSION)

# Development targets
dev-build: ## Quick development build (multi-arch version)
	docker build -t $(IMAGE_NAME):dev .

dev-build-native: ## Quick development build (native version)
	docker build -f Dockerfile.native -t $(IMAGE_NAME):dev-native .

dev-run: ## Run development container (multi-arch version)
	docker run -it --rm -p 18790:18790 \
		-v $(PWD)/workspace:/root/.picoclaw/workspace \
		$(IMAGE_NAME):dev

dev-run-native: ## Run development container (native version)
	docker run -it --rm -p 18790:18790 \
		-v $(PWD)/workspace:/root/.picoclaw/workspace \
		$(IMAGE_NAME):dev-native

# CI/CD helpers
ci-build-multi-arch: ## CI multi-arch build (used by GitHub Actions)
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--tag $(REGISTRY)/$(IMAGE_NAME):$(VERSION) \
		--label "org.opencontainers.image.version=$(VERSION)" \
		--label "org.opencontainers.image.source=https://github.com/stv-io/picoclaw-whatsapp" \
		--cache-from type=gha \
		--cache-to type=gha,mode=max \
		--push .

ci-build-native: ## CI native build (used by GitHub Actions)
	docker buildx build \
		--platform linux/amd64 \
		--file Dockerfile.native \
		--tag $(REGISTRY)/$(IMAGE_NAME):$(VERSION)-native \
		--label "org.opencontainers.image.version=$(VERSION)" \
		--label "org.opencontainers.image.source=https://github.com/stv-io/picoclaw-whatsapp" \
		--cache-from type=gha \
		--cache-to type=gha,mode=max \
		--push .

# Security scanning
scan-multi-arch: ## Scan multi-arch image with Trivy (requires trivy)
	trivy image $(REGISTRY)/$(IMAGE_NAME):$(VERSION)

scan-native: ## Scan native image with Trivy (requires trivy)
	trivy image $(REGISTRY)/$(IMAGE_NAME):$(VERSION)-native

sbom-multi-arch: ## Generate SBOM for multi-arch image
	docker sbom $(REGISTRY)/$(IMAGE_NAME):$(VERSION)

sbom-native: ## Generate SBOM for native image
	docker sbom $(REGISTRY)/$(IMAGE_NAME):$(VERSION)-native

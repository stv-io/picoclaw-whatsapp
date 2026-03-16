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

build-local: ## Build for current platform only
	docker build -t $(IMAGE_NAME):$(VERSION) .
	docker tag $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest

build-multi-arch: setup-builder ## Build for multiple architectures (amd64, arm64)
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--tag $(REGISTRY)/$(IMAGE_NAME):$(VERSION) \
		--tag $(REGISTRY)/$(IMAGE_NAME):latest \
		--push .

push: ## Push current local build to registry
	docker tag $(IMAGE_NAME):$(VERSION) $(REGISTRY)/$(IMAGE_NAME):$(VERSION)
	docker tag $(IMAGE_NAME):latest $(REGISTRY)/$(IMAGE_NAME):latest
	docker push $(REGISTRY)/$(IMAGE_NAME):$(VERSION)
	docker push $(REGISTRY)/$(IMAGE_NAME):latest

test: ## Test the built image
	docker run --rm -p 18790:18790 $(IMAGE_NAME):$(VERSION) &
	@sleep 5
	@curl -f http://localhost:18790/health || (echo "Health check failed" && exit 1)
	@docker stop $$(docker ps -q --filter ancestor=$(IMAGE_NAME):$(VERSION))

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
dev-build: ## Quick development build
	docker build -t $(IMAGE_NAME):dev .

dev-run: ## Run development container
	docker run -it --rm -p 18790:18790 \
		-v $(PWD)/workspace:/root/.picoclaw/workspace \
		$(IMAGE_NAME):dev

# CI/CD helpers
ci-build: ## CI build (used by GitHub Actions)
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--tag $(REGISTRY)/$(IMAGE_NAME):$(VERSION) \
		--label "org.opencontainers.image.version=$(VERSION)" \
		--label "org.opencontainers.image.source=https://github.com/stv-io/picoclaw-whatsapp" \
		--cache-from type=gha \
		--cache-to type=gha,mode=max \
		--push .

# Security scanning
scan: ## Scan image with Trivy (requires trivy)
	trivy image $(REGISTRY)/$(IMAGE_NAME):$(VERSION)

sbom: ## Generate SBOM
	docker sbom $(REGISTRY)/$(IMAGE_NAME):$(VERSION)

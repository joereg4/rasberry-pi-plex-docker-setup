.PHONY: test test-docker test-local build-test help

# Detect platform
PLATFORM := $(shell uname -m | sed 's/x86_64/linux\/amd64/; s/arm64/linux\/arm64/; s/aarch64/linux\/arm64/')

help:
	@echo "Available targets:"
	@echo "  test          - Run tests in Docker (works best on Linux/Raspberry Pi)"
	@echo "  test-local    - Run tests locally (recommended on macOS)"
	@echo "  build-test    - Build the test Docker image"
	@echo "  test-shell    - Open a shell in the test container"
	@echo ""
	@echo "Detected platform: $(PLATFORM)"
	@echo "Note: On macOS, use 'make test-local' for best results"

test: build-test
	@echo "Running tests in Docker..."
	@docker run --rm \
		--platform $(PLATFORM) \
		--privileged \
		-v $$(pwd):/rasberry-pi-plex-docker-setup \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-e DEBIAN_FRONTEND=noninteractive \
		rasberry-pi-plex-docker-setup-test:latest \
		/bin/bash -c "cd /rasberry-pi-plex-docker-setup && ./scripts/test/run_tests.sh"

test-local:
	@echo "Running tests locally..."
	@chmod +x scripts/test/*.sh
	@./scripts/test/run_tests.sh

build-test:
	@echo "Building test Docker image for $(PLATFORM)..."
	@echo "Note: Using buildx for cross-platform support"
	@docker buildx create --use --name test-builder 2>/dev/null || docker buildx use test-builder
	@DOCKER_BUILDKIT=1 docker buildx build \
		--platform $(PLATFORM) \
		--load \
		-t rasberry-pi-plex-docker-setup-test:latest \
		-f Dockerfile.test .
	@echo "✓ Build complete"

test-shell: build-test
	@echo "Opening shell in test container..."
	@docker run --rm -it \
		--platform $(PLATFORM) \
		--privileged \
		-v $$(pwd):/rasberry-pi-plex-docker-setup \
		-v /var/run/docker.sock:/var/run/docker.sock \
		rasberry-pi-plex-docker-setup-test:latest \
		/bin/bash

clean:
	@echo "Cleaning up test containers and volumes..."
	@docker-compose -f docker-compose.test.yml down -v 2>/dev/null || true
	@docker rmi rasberry-pi-plex-docker-setup-test:latest 2>/dev/null || true
	@echo "✓ Cleanup complete"

clean-all: clean
	@echo "Performing full cleanup..."
	@docker system prune -f


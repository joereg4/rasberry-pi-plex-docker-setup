# Testing Guide

This guide explains how to run tests for the Raspberry Pi 5 Plex setup project.

## Quick Start

### Run Tests Locally (Recommended on macOS)

```bash
# Works on macOS, Linux, and Raspberry Pi
make test-local

# Or directly
./scripts/test/run_tests.sh
```

### Run Tests in Docker

**Note**: Docker testing works best on Linux systems or actual Raspberry Pi hardware. On macOS, Docker Desktop may have issues with ARM64 containers, so use `make test-local` instead.

```bash
# Using Make
make test

# Or using docker-compose directly
docker-compose -f docker-compose.test.yml run --rm test
```

## Test Setup

### Prerequisites

- **Docker** installed on your system
- **Docker Compose** (v2 recommended)
- **Make** (optional, for convenience commands)

### Test Environment

The test environment uses:
- **Base Image**: Ubuntu 22.04 LTS (supports both ARM64 and x86_64)
- **Docker-in-Docker**: For testing Docker Compose functionality
- **Privileged Mode**: Required for Docker-in-Docker and device access

## Available Tests

The test suite includes:

1. **Script Executability** - Verifies all shell scripts are executable
2. **Docker Compose Validation** - Validates docker-compose.yml syntax
3. **Environment Variables** - Checks .env.example has required variables
4. **Common Functions** - Tests common.sh utility functions
5. **USB Detection** - Validates USB storage detection logic
6. **Hardware Transcoding** - Ensures Intel Quick Sync is removed
7. **Directory Structure** - Verifies required directories are defined
8. **Shell Syntax** - Validates all shell scripts have correct syntax
9. **Documentation** - Checks required documentation files exist
10. **USB Function Structure** - Validates USB detection function structure

## Make Commands

```bash
# Run all tests in Docker
make test

# Run tests locally (requires Ubuntu 22.04)
make test-local

# Build the test Docker image
make build-test

# Open a shell in the test container (for debugging)
make test-shell

# Clean up test containers and volumes
make clean
```

## Docker Compose Commands

```bash
# Build test image
docker-compose -f docker-compose.test.yml build

# Run tests
docker-compose -f docker-compose.test.yml run --rm test

# Run specific test script
docker-compose -f docker-compose.test.yml run --rm test \
    ./scripts/test/test_usb_detection.sh

# Open interactive shell
docker-compose -f docker-compose.test.yml run --rm test /bin/bash

# Clean up
docker-compose -f docker-compose.test.yml down -v
```

## Test Scripts

### Main Test Runner

**Location**: `scripts/test/run_tests.sh`

Runs all automated tests and provides a summary.

```bash
./scripts/test/run_tests.sh
```

### USB Detection Test

**Location**: `scripts/test/test_usb_detection.sh`

Tests the USB storage detection logic.

```bash
./scripts/test/test_usb_detection.sh
```

## Running on Raspberry Pi 5

The tests are designed to work on both:
- **x86_64** systems (CI/CD, development machines)
- **ARM64** systems (Raspberry Pi 5)

On Raspberry Pi 5, Docker will automatically use the ARM64 architecture:

```bash
# On Raspberry Pi 5
make test
```

## Continuous Integration

The test setup is CI/CD friendly. Example GitHub Actions workflow:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: make test
```

## Adding New Tests

To add a new test:

1. **Add test function** to `scripts/test/run_tests.sh`:
   ```bash
   run_test "Test Name" "test_command_here"
   ```

2. **Or create a new test script** in `scripts/test/`:
   ```bash
   #!/bin/bash
   # Your test logic here
   ```

3. **Update this documentation** with the new test description

## Test Coverage

Current test coverage includes:
- ✅ Script syntax validation
- ✅ Configuration file validation
- ✅ Function availability checks
- ✅ USB detection logic structure
- ✅ Docker Compose configuration
- ✅ Documentation completeness

**Note**: Full integration tests (actual USB device mounting, Plex container startup) require physical hardware or more complex virtualization setup.

## Troubleshooting

### Architecture Mismatch Error (`cannot execute binary file`)

If you see `/bin/bash: cannot execute binary file`, this means Docker built the image for the wrong architecture.

**Solution:**
```bash
# Clean up old images
make clean

# Rebuild for your platform
make build-test

# Run tests
make test
```

**On macOS (Apple Silicon):**
- Docker should automatically use ARM64
- If issues persist, ensure Docker Desktop is using the correct architecture

**On x86_64 systems:**
- Docker will use AMD64 automatically
- If you need ARM64 (for Raspberry Pi testing), use: `docker buildx build --platform linux/arm64`

### Docker-in-Docker Issues

If you see Docker-in-Docker errors:
```bash
# Ensure Docker socket is accessible
sudo chmod 666 /var/run/docker.sock

# Or run with sudo
sudo make test
```

### Permission Errors

```bash
# Make scripts executable
chmod +x scripts/test/*.sh
```

### Test Container Won't Start

```bash
# Clean up and rebuild
make clean
make build-test
make test
```

## Best Practices

1. **Run tests before committing**:
   ```bash
   make test
   ```

2. **Run tests locally** when possible for faster feedback

3. **Use test-shell** for debugging:
   ```bash
   make test-shell
   ```

4. **Clean up** after testing:
   ```bash
   make clean
   ```

## Future Improvements

Potential enhancements:
- [ ] Integration tests with actual USB device simulation
- [ ] Plex container startup tests
- [ ] Performance benchmarks
- [ ] ARM64-specific test optimizations
- [ ] Automated test coverage reporting

---

For questions or issues with testing, please open an issue on GitHub.


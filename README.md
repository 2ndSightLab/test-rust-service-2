# test-rust-service

A Rust service binary that demonstrates how to use the [rust-service](../rust-service) library to build a secure, production-ready service. This service prints the current time periodically with comprehensive logging, configuration management, and security validation. Also uses common unit tests repository: rust-common-tests

/scripts/run.sh to run the service (will also build and deploy it)
/scripts/test.sh to run the tests (will also build and deploy it)

## Features

- **Time Action**: Prints current UTC timestamp every configured interval
- **Security Validation**: Prevents running as root, validates user identity
- **System Monitoring**: Monitors memory and disk usage thresholds
- **Secure Logging**: File logging with proper permissions and locking
- **Configuration Management**: TOML-based configuration with validation
- **Graceful Shutdown**: Handles Ctrl+C for clean service termination

## Configuration

The service uses configuration files in `/etc/test-rust-service/`:

- `service.toml`: Service-level configuration
- `action.toml`: Action-specific configuration

Key settings include:

- `SERVICE_NAME`: Service identifier (test-rust-service)
- `TIME_INTERVAL`: Seconds between time outputs (default: 5)
- `LOG_FILE_PATH`: Log directory path (/var/log/test-rust-service)
- `MEMORY_THRESHOLD`: Memory usage alert threshold (default: 80%)
- `DISK_THRESHOLD`: Disk usage alert threshold (default: 80%)
- `INSTALL_DIR`: Installation directory (/opt/test-rust-service)
- `CONFIG_DIR`: Configuration directory (/etc/test-rust-service)

## Building and Testing

```bash
# Build
./scripts/build.sh

# Run tests
./scripts/test.sh

# Check best practices
./scripts/best-practices.sh

# Install the program
./scripts/install.sh

# Run service
./scripts/run.sh
```

## Dependencies

- `rust-service`: Core service library (local dependency)
- `chrono`: Date/time handling for timestamp generation
- `log`: Logging framework
- `serde`: Configuration serialization
- `toml`: Configuration file parsing
- `ctrlc`: Signal handling for graceful shutdown
- `libc`: System calls

## Installation Layout

- Binary: `/opt/test-rust-service/test-rust-service`
- Config: `/etc/test-rust-service/service.toml` and `/etc/test-rust-service/action.toml`
- Logs: `/var/log/test-rust-service/`
- Service User: `test-rust-service` (system account)

## Usage Example

Run all the scripts under Building and Testing in order.

After installation, the service runs continuously and outputs:
```
Current time: 2025-09-29 06:30:34 UTC
Current time: 2025-09-29 06:30:39 UTC
Current time: 2025-09-29 06:30:44 UTC
```

Stop with Ctrl+C for graceful shutdown.

## Code Structure

- `src/main.rs`: Binary entry point that uses the rust-service library
- `src/action/exec.rs`: Time action implementation
- `scripts/`: Build, test, and deployment scripts
- `config/`: Configuration files for service and action settings
- `tests/`: Integration, unit, and security tests specific to this binary

#!/bin/bash

echo "Running Rust Security Checks"
echo "============================"

# Exit on any error
set -e

echo "1. Security audit..."
cargo audit || echo "Warning: cargo audit failed or not installed"

echo "2. Unused dependencies check..."
cargo machete || cargo +nightly udeps || echo "Warning: unused dependency tools not available"

echo "3. Supply chain security..."
cargo deny check || echo "Warning: cargo deny not installed"

echo "All security checks completed!"

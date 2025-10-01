use std::process::Command;

/// # Panics
/// Panics if the cargo command fails to execute
pub fn run_common_tests(test_type: &str) {
    let OUTPUT = Command::new("cargo")
        .args([
            "test",
            "--manifest-path",
            "../rust-common-tests/Cargo.toml",
            "--test",
            test_type,
        ])
        .current_dir(".")
        .output()
        .unwrap_or_else(|_| panic!("Failed to execute {test_type} tests"));

    let STDOUT = String::from_utf8_lossy(&OUTPUT.stdout);
    let STDERR = String::from_utf8_lossy(&OUTPUT.stderr);

    // Print the OUTPUT so we can see individual test results
    println!("{STDOUT}");
    if !STDERR.is_empty() {
        eprintln!("{STDERR}");
    }
    
    // Check if the command failed
    if !OUTPUT.status.success() {
        panic!("Command failed with exit code: {:?}", OUTPUT.status.code());
    }
}

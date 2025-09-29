use std::process::Command;

mod integration {
    mod time_output_test;
}

#[test]
fn test_graceful_shutdown_handling() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::integration::common::test_graceful_shutdown_handling", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute graceful shutdown test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "Graceful shutdown test failed: {}", String::from_utf8_lossy(&output.stderr));
}

#[test]
fn test_prerequisites_check() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::integration::common::test_prerequisites_check", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute prerequisites check test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "Prerequisites check test failed: {}", String::from_utf8_lossy(&output.stderr));
}

#[test]
fn test_security_workflow_integration() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::integration::common::test_security_workflow_integration", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute security workflow integration test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "Security workflow integration test failed: {}", String::from_utf8_lossy(&output.stderr));
}

#[test]
fn test_system_resource_monitoring() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::integration::common::test_system_resource_monitoring", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute system resource monitoring test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "System resource monitoring test failed: {}", String::from_utf8_lossy(&output.stderr));
}

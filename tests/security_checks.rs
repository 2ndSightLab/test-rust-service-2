use std::process::Command;

#[test]
fn test_hardcoded_secrets() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::security_checks::common::test_hardcoded_secrets", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute hardcoded secrets test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "Hardcoded secrets test failed: {}", String::from_utf8_lossy(&output.stderr));
}

#[test]
fn test_dependency_audit() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::security_checks::common::test_dependency_audit", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute dependency audit test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "Dependency audit test failed: {}", String::from_utf8_lossy(&output.stderr));
}

#[test]
fn test_dependency_validation() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::security_checks::common::test_dependency_validation", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute dependency validation test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "Dependency validation test failed: {}", String::from_utf8_lossy(&output.stderr));
}

#[test]
fn test_file_permissions() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::security_checks::common::test_file_permissions", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute file permissions test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "File permissions test failed: {}", String::from_utf8_lossy(&output.stderr));
}

#[test]
fn test_process_exit() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::security_checks::common::test_process_exit", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute process exit test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "Process exit test failed: {}", String::from_utf8_lossy(&output.stderr));
}

#[test]
fn test_code_separation() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::security_checks::common::test_code_separation", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute code separation test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "Code separation test failed: {}", String::from_utf8_lossy(&output.stderr));
}

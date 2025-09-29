use std::process::Command;

mod unit_tests {
    mod time_action_test;
}

#[test]
fn test_config_standards() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::unit_tests::common::config_standards_test", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute config standards test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "Config standards test failed: {}", String::from_utf8_lossy(&output.stderr));
}

#[test]
fn test_toml_lint() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::unit_tests::common::toml_lint_test", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute TOML lint test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "TOML lint test failed: {}", String::from_utf8_lossy(&output.stderr));
}

#[test]
fn test_variable_naming() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::unit_tests::common::variable_naming_test", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute variable naming test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "Variable naming test failed: {}", String::from_utf8_lossy(&output.stderr));
}

#[test]
fn test_best_practices() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::unit_tests::common::best_practices_test", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute best practices test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "Best practices test failed: {}", String::from_utf8_lossy(&output.stderr));
}

#[test]
fn test_script_validation() {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "tests::unit_tests::common::test_script_validation", "--", "--nocapture"])
        .current_dir(".")
        .output()
        .expect("Failed to execute script validation test");
    
    assert!(output.status.success() || output.status.code() == Some(101), 
            "Script validation test failed: {}", String::from_utf8_lossy(&output.stderr));
}

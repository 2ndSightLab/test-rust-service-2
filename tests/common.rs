use std::process::Command;

pub fn run_common_tests(test_type: &str) {
    let output = Command::new("cargo")
        .args(&["test", "--manifest-path", "../rust-common-tests/Cargo.toml", "--test", test_type])
        .current_dir(".")
        .output()
        .expect(&format!("Failed to execute {} tests", test_type));
    
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    
    // Print the output so we can see individual test results
    println!("{}", stdout);
    if !stderr.is_empty() {
        eprintln!("{}", stderr);
    }
}

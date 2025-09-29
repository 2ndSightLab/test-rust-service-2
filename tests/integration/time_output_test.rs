#[cfg(test)]
mod tests {
    use std::path::Path;

    #[test]
    fn test_service_binary_exists() {
        assert!(Path::new("./target/debug/test-rust-service").exists(), 
                "Service binary should exist");
    }
}

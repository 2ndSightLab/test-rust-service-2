use chrono::Utc;
use rust_service::service::{Action, ServiceError};
use rust_service::Config;

pub struct TimeAction;

impl Action<Config> for TimeAction {
    fn name(&self) -> &str {
        "time"
    }

    fn execute(&self, _config: &Config) -> Result<(), ServiceError> {
        println!("Current time: {}", Utc::now().format("%Y-%m-%d %H:%M:%S UTC"));
        Ok(())
    }
}

pub fn new() -> Result<Box<dyn Action<Config>>, Box<dyn std::error::Error>> {
    Ok(Box::new(TimeAction))
}

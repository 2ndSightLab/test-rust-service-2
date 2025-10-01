use rust_service::Config;
use rust_service::service::{Action, ServiceError};
use std::thread;
use std::time::Duration;

pub struct MessageAction;

impl Action<Config> for MessageAction {
    fn name(&self) -> &str {
        "message"
    }

    fn execute(&self, _config: &Config) -> Result<(), ServiceError> {
        let config_content =
            std::fs::read_to_string("config/action.toml").map_err(|e| ServiceError::Io(e))?;
        let config: toml::Value =
            toml::from_str(&config_content).map_err(|e| ServiceError::Parse(e))?;

        let message = config["MESSAGE"].as_str().unwrap_or("Hello");
        let time_interval = config["TIME_INTERVAL"].as_integer().unwrap_or(5) as u64;

        loop {
            println!("{}", message);
            thread::sleep(Duration::from_secs(time_interval));
        }
    }
}

pub fn new() -> Result<Box<dyn Action<Config>>, Box<dyn std::error::Error>> {
    Ok(Box::new(MessageAction))
}

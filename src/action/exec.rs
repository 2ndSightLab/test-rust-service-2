use log::info;
use rust_service::action::config::ActionConfig;
use rust_service::service::config_reader::load_action_config;
use rust_service::service::{Action, Config, ServiceError};

struct ExecAction {
    ACTION_CONFIG: ActionConfig,
}

impl ExecAction {
    /// Creates a new `ExecAction` instance.
    ///
    /// # Errors
    /// Returns `ServiceError` if action configuration cannot be loaded.
    fn new() -> Result<Self, ServiceError> {
        let ACTION_CONFIG = load_action_config()?;
        Ok(Self { ACTION_CONFIG })
    }
}

impl Action<Config> for ExecAction {
    fn execute(&self, _config: &Config) -> Result<(), ServiceError> {
        let MESSAGE: String = self
            .ACTION_CONFIG
            .get("MESSAGE")
            .unwrap_or_else(|| "Default message".to_string());
        let TIME_INTERVAL: u64 = self.ACTION_CONFIG.get("TIME_INTERVAL").unwrap_or(5);

        loop {
            println!("{MESSAGE}");
            info!("{MESSAGE}");
            std::thread::sleep(std::time::Duration::from_secs(TIME_INTERVAL));
        }
    }

    fn name(&self) -> &'static str {
        "message"
    }
}

/// # Errors
/// Returns `ServiceError` if action configuration cannot be loaded.
pub fn new() -> Result<Box<dyn Action<Config>>, ServiceError> {
    Ok(Box::new(ExecAction::new()?))
}

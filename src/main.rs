// This file should not change. Only the code in the action directory should change.

pub mod action;

use action::exec;
use rust_service::service::{Config, ServiceRunner};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    ServiceRunner::<Config>::new()
        .add_action(exec::new()?)
        .run()
}

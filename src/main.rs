pub mod action;

pub use action::exec;
pub use rust_service::Config;

use rust_service::service::ServiceRunner;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    ServiceRunner::<Config>::new()
        .add_action(exec::new()?)
        .run()
}

use std::env;
use std::process::{Command};
use std::io::{self, Write};

fn main() {
    let out_dir = env::var("OUT_DIR").unwrap();

    env::set_current_dir("build").unwrap();

    let output = Command::new("make")
        .arg("verilator")
        .arg(format!("VERILATOR_OUT={}", out_dir))
        .output().unwrap();

    io::stdout().write_all(&output.stdout).unwrap();
    io::stderr().write_all(&output.stderr).unwrap();

    assert!(output.status.success());

    println!(r"cargo:rustc-link-search={}", out_dir);
}

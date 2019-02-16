extern crate clap;
extern crate directories;
extern crate log;
extern crate rustyline;
extern crate stderrlog;

use clap::{App, Arg};
use directories::ProjectDirs;
use log::{info, warn, error};
use rustyline::error::ReadlineError;
use rustyline::Editor;
use std::fs;
use std::io;
use std::net::TcpStream;
use std::process;
use std::path::Path;
use std::str::FromStr;

mod lib;
use lib::instruction::Instruction;

#[derive(Debug)]
enum MainError {
    ConnectionRefused,
    Other(io::Error),
}

struct RunArgs<'a> {
    port: u16,
    history_file_path: Option<&'a Path>
}

fn run(args: RunArgs) -> Result<(), MainError> {
    let RunArgs {
        port,
        history_file_path
    } = args;

    let mut rl = Editor::<()>::new();

    if let Some(file) = history_file_path {
        if rl.load_history(&file).is_err() {
            info!("No existing history file");
        }
    }

    let mut stream = TcpStream::connect(("localhost", port))
        .map_err(|e| match e.kind() {
            io::ErrorKind::ConnectionRefused => MainError::ConnectionRefused,
            _ => MainError::Other(e)
        })?;

    stream.set_nodelay(true)
        .map_err(MainError::Other)?;

    loop {
        match rl.readline("> ") {
            Ok(line) => {
                rl.add_history_entry(line.as_ref());
                print!("Ins {:?}", Instruction::from_str(&line));
                if let Some(file) = history_file_path {
                    if rl.save_history(file).is_err() {
                        warn!("Error saving history to file");
                    }
                }
                println!("Line: {}", line);
            }
            Err(ReadlineError::Interrupted) => {
                break;
            }
            Err(ReadlineError::Eof) => {
                break;
            }
            Err(err) => {
                error!("{:?}", err);
                break;
            }
        }
    }
    Ok(())
}

fn main() {
    stderrlog::new()
        .module(module_path!())
        .verbosity(3)
        .init()
        .unwrap();

    let history_file =
        ProjectDirs::from("", "physical-computation", "narvie")
            .map(|p| p.data_dir().to_owned())
            .ok_or_else(|| warn!("No project dir found"))
            .map(|dir| {
                if fs::create_dir_all(&dir).is_err() {
                    warn!("Could not create project dir")
                }
                dir
            })
            .map(|dir| dir.join("history.txt"))
            .ok();

    let matches = App::new("narve CLI")
        .version("0.1.0")
        .author("Harry Sarson <harry.sarson@hotmail.co.uk>")
        .about("Native RISCV instruction evaluator")
        .arg(
            Arg::with_name("port")
                .required(true)
                .value_name("address")
                .takes_value(true)
                .long("port")
                .help("tcp port address"),
        )
        .get_matches();

    let port = matches
        .value_of("port")
        .and_then(|p|
            p.parse::<u16>()
                .ok()

        )
        .unwrap_or_else(|| {
            error!("The --port argument must be an integer");
            process::exit(1);
        });

    run(RunArgs {
        port,
        history_file_path: history_file.as_ref().map(|p| p.as_path()),
    })
        .unwrap_or_else(|e| {
            match e {
                MainError::ConnectionRefused =>
                    error!("Cannot connect to narvie processor!
    Check the processor is running and the that you are using the
    correct address. Then run the narvie CLI again."),
                MainError::Other(error) =>
                    error!("Unrecognised error: {}", error),
            }
            process::exit(1)
        })
}

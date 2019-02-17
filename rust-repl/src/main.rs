extern crate byteorder;
extern crate clap;
extern crate directories;
extern crate log;
extern crate prettytable;
extern crate rustyline;
extern crate stderrlog;

mod lib;

use byteorder::{LittleEndian, ReadBytesExt, WriteBytesExt};
use clap::{App, Arg};
use directories::ProjectDirs;
use lib::instruction::{self, Instruction};
use lib::register::Register;
use log::{error, info, warn};
use prettytable::*;
use rustyline::error::ReadlineError;
use rustyline::Editor;
use std::fs;
use std::io;
use std::net::TcpStream;
use std::path::Path;
use std::process;
use std::str::FromStr;

#[derive(Debug)]
enum MainError {
    ConnectionRefused,
    Other(io::Error),
}

#[derive(Debug)]
enum EvalInstructionError {
    Parse(instruction::Error),
}

struct RunArgs<'a> {
    port: u16,
    history_file_path: Option<&'a Path>,
}

/* narvie will use these as headers when displaying binary.
 */
fn format_headers(f: &instruction::Format) -> &'static [&'static str] {
    match f {
        instruction::Format::U => &["imm[31:12]", "rd", "opcode"],
        // instruction::Format::R =>
        // ["funct7", "rs2", "rs1", "funct3", "rd", "opcode"],
    }
}

/* narvie will split the instruction into blocks of binary.
 * These arrays indicate how wide each block should be.
 *
 * It is assumed in the code that these are positive integers
 * and that they sum to 32
 */
fn binary_block_widths(f: &instruction::Format) -> &'static [u32] {
    match f {
        instruction::Format::U => &[20, 5, 7],
        // instruction::Format::R =>
        //     [7, 5, 5, 3, 5, 7],
    }
}

fn format_binary_instruction(inst: &Instruction) -> Vec<String> {
    let widths = binary_block_widths(&inst.to_format());
    assert!(widths.into_iter().sum::<u32>() == 32);

    let binary_str = format!("{:032b}", inst.to_u32());

    widths
        .into_iter()
        .fold((vec![], binary_str.as_str()), |(mut p, string), w| {
            let (a, rest) = string.split_at(*w as usize);
            p.push(a.to_string());
            (p, rest)
        })
        .0
}

fn assembly_table(instruction: &Instruction) -> prettytable::Table {
    let mut table = prettytable::Table::new();
    table.set_format(*prettytable::format::consts::FORMAT_BOX_CHARS);

    let mut header_row = vec!["Mnemonic"];
    header_row.extend_from_slice(format_headers(&instruction.to_format()));

    let mut instruction_row = vec![instruction.to_string()];

    instruction_row.extend(format_binary_instruction(&instruction));

    table.add_row(prettytable::Row::new(
        header_row.into_iter().map(prettytable::Cell::new).collect(),
    ));
    table.add_row(prettytable::Row::new(
        instruction_row
            .into_iter()
            .map(|s| prettytable::Cell::new(s.as_str()))
            .collect(),
    ));
    table
}

fn reg_file_table(reg_file: &[u32; 32]) -> prettytable::Table {
    let mut table = prettytable::Table::new();
    table.set_format(*prettytable::format::consts::FORMAT_CLEAN);

    table.add_row(prettytable::Row::new(
        (0..2)
            .map(|i| {
                let mut side = prettytable::table!(["Name", "ABI", "Value"]);
                side.set_format(*prettytable::format::consts::FORMAT_BOX_CHARS);

                for j in 0..16 {
                    let reg_index = i * 16 + j;
                    let mut row = [
                        format!("x{}", reg_index),
                        Register::from_u32(reg_index).unwrap().abi_name(),
                        format!("0x{:08X}", reg_file[reg_index as usize]),
                    ];

                    side.add_row(prettytable::Row::new(
                        row.into_iter().map(|s| prettytable::cell!(s)).collect(),
                    ));
                }

                prettytable::cell!(side)
            })
            .collect::<Vec<prettytable::Cell>>(),
    ));

    table
}

fn eval_instruction<S>(mnemonic: &str, port: &mut S) -> Result<(), EvalInstructionError>
where
    S: io::Read + io::Write,
{
    let instruction = Instruction::from_str(mnemonic).map_err(EvalInstructionError::Parse)?;

    assembly_table(&instruction).printstd();

    port.write_u32::<LittleEndian>(instruction.to_u32())
        .unwrap();

    let mut reg_file = [0; 32];

    for i in 0..32 {
        reg_file[i] = port.read_u32::<LittleEndian>().unwrap();
    }

    reg_file_table(&reg_file).printstd();

    Ok(())
}

fn run(args: RunArgs) -> Result<(), MainError> {
    let RunArgs {
        port,
        history_file_path,
    } = args;

    let mut rl = Editor::<()>::new();

    if let Some(file) = history_file_path {
        if rl.load_history(&file).is_err() {
            info!("No existing history file");
        }
    }

    let mut stream = TcpStream::connect(("localhost", port)).map_err(|e| match e.kind() {
        io::ErrorKind::ConnectionRefused => MainError::ConnectionRefused,
        _ => MainError::Other(e),
    })?;

    stream.set_nodelay(true).map_err(MainError::Other)?;

    loop {
        match rl.readline("> ") {
            Ok(line) => {
                rl.add_history_entry(line.as_ref());
                if let Some(file) = history_file_path {
                    if rl.save_history(file).is_err() {
                        warn!("Error saving history to file");
                    }
                }
                eval_instruction(line.trim(), &mut stream).expect("error eval");
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

    let history_file = ProjectDirs::from("", "physical-computation", "narvie")
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
        .and_then(|p| p.parse::<u16>().ok())
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
            MainError::ConnectionRefused => error!(
                "Cannot connect to narvie processor!
    Check the processor is running and the that you are using the
    correct address. Then run the narvie CLI again."
            ),
            MainError::Other(error) => error!("Unrecognised error: {}", error),
        }
        process::exit(1)
    })
}

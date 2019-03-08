extern crate byteorder;
extern crate clap;
extern crate directories;
extern crate log;
extern crate prettytable;
extern crate rustyline;
extern crate serialport;
extern crate stderrlog;
extern crate time;

mod lib;

use byteorder::{LittleEndian, ReadBytesExt, WriteBytesExt};
use clap::{App, Arg};
use directories::ProjectDirs;
use lib::instruction::{self, Instruction};
use lib::register::Register;
use log::{debug, error, info, warn};
use prettytable::*;

use rustyline::error::ReadlineError;
use rustyline::Editor;
use std::fs::{self, File};
use std::io;
use std::path::Path;
use std::process;
use std::str::FromStr;
use std::time::Duration;

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
    address: &'a str,
    baud: u32,
    history_file_path: Option<&'a Path>,
    log_file_path: Option<&'a Path>,
}

struct SerialLogger<'a, S: io::Read + io::Write> {
    stream: &'a mut S,
    logger: Option<&'a mut io::Write>,
}

impl<'a, S: io::Read + io::Write> io::Read for SerialLogger<'a, S> {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        let res = self.stream.read(buf);
        if let Some(ref mut logger) = self.logger {
            logger.write_all(buf)?;
        }
        res
    }
}
impl<'a, S: io::Read + io::Write> io::Write for SerialLogger<'a, S> {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        self.stream.write(buf)
    }
    fn flush(&mut self) -> io::Result<()> {
        self.stream.flush()
    }
}

/* narvie will use these as headers when displaying binary.
 */
fn format_headers(f: &instruction::Format) -> &'static [&'static str] {
    match f {
        instruction::Format::U => &["imm[31:12]", "rd", "opcode"],
        instruction::Format::J => &["imm[20|10:1|11|19:12]", "rd", "opcode"],
        instruction::Format::I => &["imm[11:0]", "rs1", "funct3", "rd", "opcode"],
        instruction::Format::B => &[
            "imm[12|10:5]",
            "rs2",
            "rs1",
            "funct3",
            "imm[4:1|11]",
            "opcode",
        ],
        instruction::Format::R => &["funct7", "rs2", "rs1", "funct3", "rd", "opcode"],
        instruction::Format::S => &["imm[11:5]", "rs2", "rs1", "funct3", "imm[4:0]", "opcode"],
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
        instruction::Format::J => &[20, 5, 7],
        instruction::Format::I => &[12, 5, 3, 5, 7],
        instruction::Format::B => &[7, 5, 5, 3, 5, 7],
        instruction::Format::R => &[7, 5, 5, 3, 5, 7],
        instruction::Format::S => &[7, 5, 5, 3, 5, 7],
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
                        Register::<()>::from_u32(reg_index).unwrap().abi_name(),
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
        address,
        baud,
        history_file_path,
        log_file_path,
    } = args;

    let mut rl = Editor::<()>::new();

    if let Some(file) = history_file_path {
        if rl.load_history(&file).is_err() {
            info!("No existing history file");
        }
        debug!("Saving history to {}", file.to_string_lossy())
    }

    let mut logger = log_file_path.and_then(|p| {
        File::create(p)
            .map_err(|e| warn!("Could not open log file: {:?}", e))
            .map(|l| {
                debug!("Saving register logs to {}", p.to_string_lossy());
                l
            })
            .ok()
    });

    let mut serialport = serialport::open_with_settings(
        address,
        &serialport::SerialPortSettings {
            baud_rate: baud,
            data_bits: serialport::DataBits::Eight,
            flow_control: serialport::FlowControl::None,
            parity: serialport::Parity::None,
            stop_bits: serialport::StopBits::One,
            timeout: Duration::from_millis(500),
        },
    )
    .map_err(|_| MainError::ConnectionRefused)?;

    let mut stream = SerialLogger {
        stream: &mut serialport,
        logger: logger.as_mut().map(|f| (f as &mut io::Write)),
    };

    loop {
        match rl.readline("> ") {
            Ok(line) => {
                rl.add_history_entry(line.as_ref());
                if let Some(file) = history_file_path {
                    if rl.save_history(file).is_err() {
                        warn!("Error saving history to file");
                    }
                }
                let line = line.trim();
                if !line.is_empty() {
                    if let Err(error) = eval_instruction(line, &mut stream) {
                        println!("Error {} instruction:",  match error {
                            EvalInstructionError::Parse(_) =>
                                "parsing",
                        });

                        match error {
                            EvalInstructionError::Parse(parse_error) =>
                                println!("  {:?}", parse_error),
                        };

                    }
                }
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

    let (history_file, log_file) = ProjectDirs::from("", "physical-computation", "narvie")
        .map(|p| p.data_dir().to_owned())
        .ok_or_else(|| warn!("No project dir found"))
        .map(|dir| {
            if fs::create_dir_all(&dir).is_err() {
                warn!("Could not create project dir")
            }
            dir
        })
        .map(|dir| {
            (
                Some(dir.join("history.txt")),
                Some(dir.join(format!("log-{}", time::now_utc().rfc3339()))),
            )
        })
        .unwrap_or((None, None));

    let matches = App::new("narve CLI")
        .version("0.1.0")
        .author("Harry Sarson <harry.sarson@hotmail.co.uk>")
        .about("Native RISCV instruction evaluator")
        .arg(
            Arg::with_name("address")
                .value_name("address")
                .takes_value(true)
                .help("serial port port address"),
        )
        .arg(
            Arg::with_name("baud")
                .default_value("9600")
                .value_name("baud")
                .takes_value(true)
                .long("baud")
                .help("baud rate"),
        )
        .get_matches();

    let address = matches
        .value_of("address")
        .unwrap_or_else(|| {
            println!("Narvie requires use of a serial port!");
            if let Ok(ports) = serialport::available_ports() {
                if ports.is_empty() {
                    println!("No available ports could be found - make sure a narvie\nprocessor is plugged into your computer!");
                } else {
                    println!("Maybe you could try one of these available ports?");
                    for (i, info) in ports.iter().enumerate() {
                        println!("    {}: {}", i + 1, info.port_name);
                    }
                }
            }
            println!("\n{}", matches.usage());
            process::exit(1);
        });

    let baud = matches
        .value_of("baud")
        .and_then(|input| input.parse::<u32>().ok())
        .unwrap_or_else(|| {
            dbg!(address);
            error!("Parameter --baud must be an integer");
            process::exit(1);
        });

    run(RunArgs {
        address,
        baud,
        history_file_path: history_file.as_ref().map(|p| p.as_path()),
        log_file_path: log_file.as_ref().map(|p| p.as_path()),
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

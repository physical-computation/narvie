use lib::immediate::{self, GetImmediateError};
use lib::register::{GetRegisterError, Register};
use std::fmt;
use std::str::FromStr;
use std::string::String;

#[derive(Debug)]
pub enum Error {
    WrongNumberOfArgs { actual: usize, expected: usize },
    InvalidRegisterArg(GetRegisterError),
    InvalidImmediateArg(GetImmediateError),
    InvalidInstructionName(String),
}

struct Opcode(u32);

impl Opcode {
    pub fn from_u32(opcode: u32) -> Option<Opcode> {
        if opcode & !0x7F == 0 {
            Some(Opcode(opcode))
        } else {
            None
        }
    }
    pub fn to_u32(&self) -> u32 {
        self.0
    }
}

fn opcode_for(u: &Instruction) -> Opcode {
    match u {
        Instruction::Lui(_) => Opcode(0b0110111),
        Instruction::Auipc(_) => Opcode(0b0010111),
    }
}

#[derive(Debug)]
pub struct U {
    pub args: (Register, immediate::U),
}

#[derive(Debug)]
pub struct J {
    pub args: (Register, immediate::J),
}

#[derive(Debug)]
pub enum Instruction {
    Lui(U),
    Auipc(U),
}

#[derive(Debug)]
pub enum Format {
    U,
}

fn place_rd(rd: &Register) -> u32 {
    (rd.to_u32() & 0b11111) << 7
}
fn place_imm_u(imm: &immediate::U) -> u32 {
    (imm.to_u32() & 0xFFF) << 12
}
fn place_imm_j(imm: &immediate::J) -> u32 {
    let imm_ = imm.to_i32() as u32;
    ((imm_ & 0x100000) << 11) |     // imm[20], inst[31]
        ((imm_ & 0x0003FE) << 20) | // imm[10:1], inst[30:21]
        ((imm_ & 0x000800) << 9) |  // imm[11], inst[20]
        ((imm_ & 0x0FF000)) // imm[19:12], inst[19:12]
}
fn place_opcode(opcode: &Opcode) -> u32 {
    opcode.to_u32() & 0b1111111
}

impl U {
    fn from_args(args: &[&str]) -> Result<Self, Error> {
        if args.len() != 2 {
            Result::Err(Error::WrongNumberOfArgs {
                actual: args.len(),
                expected: 2,
            })
        } else {
            let rd_o = Register::from_str(args[0]).map_err(Error::InvalidRegisterArg);
            let imm_o = immediate::U::from_str(args[1]).map_err(Error::InvalidImmediateArg);

            rd_o.and_then(|rd| imm_o.map(|imm| U { args: (rd, imm) }))
        }
    }

    fn to_u32(&self, opcode: &Opcode) -> u32 {
        let (rd, imm) = &self.args;
        place_opcode(opcode) | place_rd(rd) | place_imm_u(imm)
    }
}

impl fmt::Display for U {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let (rd, imm) = &self.args;

        write!(
            f,
            "x{rd},0x{imm:x}", // TODO: limited to 12 bits?
            rd = rd.to_u32(),
            imm = imm.to_u32()
        )
    }
}

impl J {
    fn to_u32(&self, opcode: &Opcode) -> u32 {
        let (rd, imm) = &self.args;
        place_opcode(opcode) | place_rd(rd) | place_imm_j(imm)
    }
}

impl FromStr for Instruction {
    type Err = Error;

    fn from_str<'a>(mnemonic: &str) -> Result<Instruction, Error> {
        let mnemonic = mnemonic.trim();

        let first_space_index = mnemonic.find(' ').unwrap_or(mnemonic.len());

        let (name, args) = mnemonic.split_at(first_space_index);

        let args: Vec<&str> = args.split(',').map(str::trim).collect();

        match name.to_ascii_lowercase().as_str() {
            "lui" => U::from_args(&args).map(Instruction::Lui),
            "auipc" => U::from_args(&args).map(Instruction::Auipc),
            _ => Err(Error::InvalidInstructionName(name.to_string())),
        }
    }
}

impl fmt::Display for Instruction {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Instruction::Lui(u) => write!(f, "lui {}", u),
            Instruction::Auipc(u) => write!(f, "auipc {}", u),
        }
    }
}

impl Instruction {
    pub fn to_u32(&self) -> u32 {
        let opcode = opcode_for(&self);
        match self {
            Instruction::Lui(u) => u.to_u32(&opcode),
            Instruction::Auipc(u) => u.to_u32(&opcode),
        }
    }

    pub fn to_format(&self) -> Format {
        match self {
            Instruction::Lui(_) => Format::U,
            Instruction::Auipc(_) => Format::U,
        }
    }
}

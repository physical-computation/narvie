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

#[derive(Debug)]
struct Funct3(u32);

impl Funct3 {
    pub fn from_u32(funct3: u32) -> Option<Self> {
        if funct3 & !0x7 == 0 {
            Some(Funct3(funct3))
        } else {
            None
        }
    }
    pub fn to_u32(&self) -> u32 {
        self.0
    }
}

#[derive(Debug)]
struct Funct7(u32);

impl Funct7 {
    pub fn from_u32(funct7: u32) -> Option<Self> {
        if funct7 & !0x7F == 0 {
            Some(Funct7(funct7))
        } else {
            None
        }
    }
    pub fn to_u32(&self) -> u32 {
        self.0
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
pub struct I {
    pub args: (Register, Register, immediate::I),
}

#[derive(Debug)]
pub struct R {
    pub args: (Register, Register, Register),
}

#[derive(Debug)]
pub struct B {
    pub args: (Register, Register, immediate::B),
}

#[derive(Debug)]
pub enum Instruction {
    Lui(U),
    Auipc(U),
    Jal(J),
    Jalr(I),
    Beq(B),
    Bne(B),
    Blt(B),
    Bge(B),
    Bltu(B),
    Bgeu(B),
    Addi(I),
    Slti(I),
    Sltiu(I),
    Xori(I),
    Ori(I),
    Andi(I),
    Add(R),
    Sub(R),
    Sll(R),
    Slt(R),
    Sltu(R),
    Xor(R),
    Srl(R),
    Sra(R),
    Or(R),
    And(R),
}

#[derive(Debug)]
pub enum Format {
    U,
    J,
    I,
    B,
    R,
}

fn place_rd(rd: &Register) -> u32 {
    (rd.to_u32() & 0b11111) << 7
}

fn place_rs1(rs1: &Register) -> u32 {
    (rs1.to_u32() & 0b11111) << 15
}

fn place_rs2(rs2: &Register) -> u32 {
    (rs2.to_u32() & 0b11111) << 20
}

fn place_imm_u(imm: &immediate::U) -> u32 {
    (imm.to_u32() & 0xFFFFF) << 12
}

fn place_imm_i(imm: &immediate::I) -> u32 {
    ((imm.to_i32() as u32) & 0xFFF) << 20
}

fn place_imm_j(imm: &immediate::J) -> u32 {
    let imm_ = imm.to_i32() as u32;

    000 | ((imm_ & 0x100000) << 11) // imm[20], inst[31]
        | ((imm_ & 0x0003FE) << 20) // imm[10:1], inst[30:21]
        | ((imm_ & 0x000800) << 09) // imm[11], inst[20]
        | ((imm_ & 0x0FF000) << 00) // imm[19:12], inst[19:12]
}

fn place_imm_b(imm: &immediate::B) -> u32 {
    let imm_ = imm.to_i32() as u32;
    000 | ((imm_ & 0b1000000000000) << 19) // imm[12], inst[31]
        | ((imm_ & 0b0011111100000) << 20) // imm[10:5], inst[30:25]
        | ((imm_ & 0b0000000011110) << 07) // imm[4:1], inst[11:8]
        | ((imm_ & 0b0100000000000) >> 04) // imm[11], inst[7]
}

fn place_opcode(opcode: &Opcode) -> u32 {
    opcode.to_u32() & 0b1111111
}

fn place_funct3(funct3: &Funct3) -> u32 {
    (funct3.to_u32() & 0b111) << 12
}

fn place_funct7(funct7: &Funct7) -> u32 {
    (funct7.to_u32() & 0x3F) << 25
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
    fn from_args(args: &[&str]) -> Result<Self, Error> {
        if args.len() != 2 {
            Result::Err(Error::WrongNumberOfArgs {
                actual: args.len(),
                expected: 2,
            })
        } else {
            let rd_o = Register::from_str(args[0]).map_err(Error::InvalidRegisterArg);
            let imm_o = immediate::J::from_str(args[1]).map_err(Error::InvalidImmediateArg);

            rd_o.and_then(|rd| imm_o.map(|imm| J { args: (rd, imm) }))
        }
    }

    fn to_u32(&self, opcode: &Opcode) -> u32 {
        let (rd, imm) = &self.args;
        place_opcode(opcode) | place_rd(rd) | place_imm_j(imm)
    }
}

impl fmt::Display for J {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let (rd, imm) = &self.args;

        write!(
            f,
            "x{rd},{imm}", // TODO: limited to 12 bits?
            rd = rd.to_u32(),
            imm = imm.to_i32()
        )
    }
}

impl I {
    fn from_args(args: &[&str]) -> Result<Self, Error> {
        if args.len() != 3 {
            Result::Err(Error::WrongNumberOfArgs {
                actual: args.len(),
                expected: 3,
            })
        } else {
            let rd_o = Register::from_str(args[0]).map_err(Error::InvalidRegisterArg);
            let rs1_o = Register::from_str(args[1]).map_err(Error::InvalidRegisterArg);
            let imm_o = immediate::I::from_str(args[2]).map_err(Error::InvalidImmediateArg);

            rd_o.and_then(|rd| {
                rs1_o.and_then(|rs1| {
                    imm_o.map(|imm| I {
                        args: (rd, rs1, imm),
                    })
                })
            })
        }
    }

    fn to_u32(&self, opcode: &Opcode, funct3: &Funct3) -> u32 {
        let (rd, rs1, imm) = &self.args;
        000 | place_opcode(opcode)
            | place_rd(rd)
            | place_funct3(funct3)
            | place_rs1(rs1)
            | place_imm_i(imm)
    }
}

impl fmt::Display for I {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let (rd, rs1, imm) = &self.args;

        write!(
            f,
            "x{rd},x{rs1},{imm}", // TODO: limited to 12 bits?
            rd = rd.to_u32(),
            rs1 = rs1.to_u32(),
            imm = imm.to_i32()
        )
    }
}

impl R {
    fn from_args(args: &[&str]) -> Result<Self, Error> {
        if args.len() != 3 {
            Result::Err(Error::WrongNumberOfArgs {
                actual: args.len(),
                expected: 3,
            })
        } else {
            let rd_o = Register::from_str(args[0]).map_err(Error::InvalidRegisterArg);
            let rs1_o = Register::from_str(args[1]).map_err(Error::InvalidRegisterArg);
            let rs2_o = Register::from_str(args[2]).map_err(Error::InvalidRegisterArg);

            rd_o.and_then(|rd| {
                rs1_o.and_then(|rs1| {
                    rs2_o.map(|rs2| R {
                        args: (rd, rs1, rs2),
                    })
                })
            })
        }
    }

    fn to_u32(&self, opcode: &Opcode, funct3: &Funct3, funct7: &Funct7) -> u32 {
        let (rd, rs1, rs2) = &self.args;
        000 | place_opcode(opcode)
            | place_rd(rd)
            | place_funct3(funct3)
            | place_rs1(rs1)
            | place_rs2(rs2)
            | place_funct7(funct7)
    }
}

impl fmt::Display for R {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let (rd, rs1, rs2) = &self.args;

        write!(
            f,
            "x{rd},x{rs1},{rs2}",
            rd = rd.to_u32(),
            rs1 = rs1.to_u32(),
            rs2 = rs2.to_u32()
        )
    }
}

impl B {
    fn from_args(args: &[&str]) -> Result<Self, Error> {
        if args.len() != 3 {
            Result::Err(Error::WrongNumberOfArgs {
                actual: args.len(),
                expected: 3,
            })
        } else {
            let rs1_o = Register::from_str(args[0]).map_err(Error::InvalidRegisterArg);
            let rs2_o = Register::from_str(args[1]).map_err(Error::InvalidRegisterArg);
            let imm_o = immediate::B::from_str(args[2]).map_err(Error::InvalidImmediateArg);

            rs1_o.and_then(|rs1| {
                rs2_o.and_then(|rs2| {
                    imm_o.map(|imm| B {
                        args: (rs1, rs2, imm),
                    })
                })
            })
        }
    }

    fn to_u32(&self, opcode: &Opcode, funct3: &Funct3) -> u32 {
        let (rs1, rs2, imm) = &self.args;
        000 | place_opcode(opcode)
            | place_imm_b(imm)
            | place_funct3(funct3)
            | place_rs1(rs1)
            | place_rs2(rs2)
    }
}

impl fmt::Display for B {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let (rs1, rs2, imm) = &self.args;

        write!(
            f,
            "x{rs1},x{rs2},{imm}",
            rs1 = rs1.to_u32(),
            rs2 = rs2.to_u32(),
            imm = imm.to_i32()
        )
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
            "jal" => J::from_args(&args).map(Instruction::Jal),
            "jalr" => I::from_args(&args).map(Instruction::Jalr),
            "beq" => B::from_args(&args).map(Instruction::Beq),
            "bne" => B::from_args(&args).map(Instruction::Bne),
            "blt" => B::from_args(&args).map(Instruction::Blt),
            "bge" => B::from_args(&args).map(Instruction::Bge),
            "bltu" => B::from_args(&args).map(Instruction::Bltu),
            "bgeu" => B::from_args(&args).map(Instruction::Bgeu),
            "addi" => I::from_args(&args).map(Instruction::Addi),
            "slti" => I::from_args(&args).map(Instruction::Slti),
            "sltiu" => I::from_args(&args).map(Instruction::Sltiu),
            "xori" => I::from_args(&args).map(Instruction::Xori),
            "ori" => I::from_args(&args).map(Instruction::Ori),
            "andi" => I::from_args(&args).map(Instruction::Andi),
            "add" => R::from_args(&args).map(Instruction::Add),
            "sub" => R::from_args(&args).map(Instruction::Sub),
            "sll" => R::from_args(&args).map(Instruction::Sll),
            "slt" => R::from_args(&args).map(Instruction::Slt),
            "sltu" => R::from_args(&args).map(Instruction::Sltu),
            "xor" => R::from_args(&args).map(Instruction::Xor),
            "srl" => R::from_args(&args).map(Instruction::Srl),
            "sra" => R::from_args(&args).map(Instruction::Sra),
            "or" => R::from_args(&args).map(Instruction::Or),
            "and" => R::from_args(&args).map(Instruction::And),
            _ => Err(Error::InvalidInstructionName(name.to_string())),
        }
    }
}

impl fmt::Display for Instruction {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Instruction::Lui(u) => write!(f, "lui {}", u),
            Instruction::Auipc(u) => write!(f, "auipc {}", u),
            Instruction::Jal(j) => write!(f, "jal {}", j),
            Instruction::Jalr(i) => write!(f, "jalr {}", i),
            Instruction::Beq(b) => write!(f, "beq {}", b),
            Instruction::Bne(b) => write!(f, "bne {}", b),
            Instruction::Blt(b) => write!(f, "blt {}", b),
            Instruction::Bge(b) => write!(f, "bge {}", b),
            Instruction::Bltu(b) => write!(f, "bktu {}", b),
            Instruction::Bgeu(b) => write!(f, "bgeu {}", b),
            Instruction::Addi(i) => write!(f, "addi {}", i),
            Instruction::Slti(i) => write!(f, "slti {}", i),
            Instruction::Sltiu(i) => write!(f, "sltiu {}", i),
            Instruction::Xori(i) => write!(f, "xori {}", i),
            Instruction::Ori(i) => write!(f, "ori {}", i),
            Instruction::Andi(i) => write!(f, "andi {}", i),
            Instruction::Add(r) => write!(f, "add {}", r),
            Instruction::Sub(r) => write!(f, "sub {}", r),
            Instruction::Sll(r) => write!(f, "sll {}", r),
            Instruction::Slt(r) => write!(f, "slt {}", r),
            Instruction::Sltu(r) => write!(f, "sltu {}", r),
            Instruction::Xor(r) => write!(f, "xor {}", r),
            Instruction::Srl(r) => write!(f, "srl {}", r),
            Instruction::Sra(r) => write!(f, "sra {}", r),
            Instruction::Or(r) => write!(f, "or {}", r),
            Instruction::And(r) => write!(f, "and {}", r),
        }
    }
}

impl Instruction {
    pub fn to_u32(&self) -> u32 {
        match self {
            Instruction::Lui(u) => u.to_u32(&Opcode::from_u32(0b0110111).unwrap()),
            Instruction::Auipc(u) => u.to_u32(&Opcode::from_u32(0b0010111).unwrap()),
            Instruction::Jal(j) => j.to_u32(&Opcode::from_u32(0b1101111).unwrap()),
            Instruction::Jalr(i) => i.to_u32(
                &Opcode::from_u32(0b1100111).unwrap(),
                &Funct3::from_u32(0b000).unwrap(),
            ),
            Instruction::Beq(b) => b.to_u32(
                &Opcode::from_u32(0b1100011).unwrap(),
                &Funct3::from_u32(0b000).unwrap(),
            ),
            Instruction::Bne(b) => b.to_u32(
                &Opcode::from_u32(0b1100011).unwrap(),
                &Funct3::from_u32(0b001).unwrap(),
            ),
            Instruction::Blt(b) => b.to_u32(
                &Opcode::from_u32(0b1100011).unwrap(),
                &Funct3::from_u32(0b100).unwrap(),
            ),
            Instruction::Bge(b) => b.to_u32(
                &Opcode::from_u32(0b1100011).unwrap(),
                &Funct3::from_u32(0b101).unwrap(),
            ),
            Instruction::Bltu(b) => b.to_u32(
                &Opcode::from_u32(0b1100011).unwrap(),
                &Funct3::from_u32(0b110).unwrap(),
            ),
            Instruction::Bgeu(b) => b.to_u32(
                &Opcode::from_u32(0b1100011).unwrap(),
                &Funct3::from_u32(0b111).unwrap(),
            ),
            Instruction::Addi(i) => i.to_u32(
                &Opcode::from_u32(0b0010011).unwrap(),
                &Funct3::from_u32(0b000).unwrap(),
            ),
            Instruction::Slti(i) => i.to_u32(
                &Opcode::from_u32(0b0010011).unwrap(),
                &Funct3::from_u32(0b010).unwrap(),
            ),
            Instruction::Sltiu(i) => i.to_u32(
                &Opcode::from_u32(0b0010011).unwrap(),
                &Funct3::from_u32(0b011).unwrap(),
            ),
            Instruction::Xori(i) => i.to_u32(
                &Opcode::from_u32(0b0010011).unwrap(),
                &Funct3::from_u32(0b100).unwrap(),
            ),
            Instruction::Ori(i) => i.to_u32(
                &Opcode::from_u32(0b0010011).unwrap(),
                &Funct3::from_u32(0b110).unwrap(),
            ),
            Instruction::Andi(i) => i.to_u32(
                &Opcode::from_u32(0b0010011).unwrap(),
                &Funct3::from_u32(0b111).unwrap(),
            ),
            Instruction::Add(r) => r.to_u32(
                &Opcode::from_u32(0b0110011).unwrap(),
                &Funct3::from_u32(0b000).unwrap(),
                &Funct7::from_u32(0b0000000).unwrap(),
            ),
            Instruction::Sub(r) => r.to_u32(
                &Opcode::from_u32(0b0110011).unwrap(),
                &Funct3::from_u32(0b000).unwrap(),
                &Funct7::from_u32(0b0100000).unwrap(),
            ),
            Instruction::Sll(r) => r.to_u32(
                &Opcode::from_u32(0b0110011).unwrap(),
                &Funct3::from_u32(0b001).unwrap(),
                &Funct7::from_u32(0b0000000).unwrap(),
            ),
            Instruction::Slt(r) => r.to_u32(
                &Opcode::from_u32(0b0110011).unwrap(),
                &Funct3::from_u32(0b010).unwrap(),
                &Funct7::from_u32(0b0000000).unwrap(),
            ),
            Instruction::Sltu(r) => r.to_u32(
                &Opcode::from_u32(0b0110011).unwrap(),
                &Funct3::from_u32(0b011).unwrap(),
                &Funct7::from_u32(0b0000000).unwrap(),
            ),
            Instruction::Xor(r) => r.to_u32(
                &Opcode::from_u32(0b0110011).unwrap(),
                &Funct3::from_u32(0b100).unwrap(),
                &Funct7::from_u32(0b0000000).unwrap(),
            ),
            Instruction::Srl(r) => r.to_u32(
                &Opcode::from_u32(0b0110011).unwrap(),
                &Funct3::from_u32(0b101).unwrap(),
                &Funct7::from_u32(0b0000000).unwrap(),
            ),
            Instruction::Sra(r) => r.to_u32(
                &Opcode::from_u32(0b0110011).unwrap(),
                &Funct3::from_u32(0b101).unwrap(),
                &Funct7::from_u32(0b0100000).unwrap(),
            ),
            Instruction::Or(r) => r.to_u32(
                &Opcode::from_u32(0b0110011).unwrap(),
                &Funct3::from_u32(0b110).unwrap(),
                &Funct7::from_u32(0b0000000).unwrap(),
            ),
            Instruction::And(r) => r.to_u32(
                &Opcode::from_u32(0b0110011).unwrap(),
                &Funct3::from_u32(0b111).unwrap(),
                &Funct7::from_u32(0b0000000).unwrap(),
            ),
        }
    }

    pub fn to_format(&self) -> Format {
        match self {
            Instruction::Lui(_) => Format::U,
            Instruction::Auipc(_) => Format::U,
            Instruction::Jal(_) => Format::J,
            Instruction::Jalr(_) => Format::I,
            Instruction::Beq(_) => Format::B,
            Instruction::Bne(_) => Format::B,
            Instruction::Blt(_) => Format::B,
            Instruction::Bge(_) => Format::B,
            Instruction::Bltu(_) => Format::B,
            Instruction::Bgeu(_) => Format::B,
            Instruction::Addi(_) => Format::I,
            Instruction::Slti(_) => Format::I,
            Instruction::Sltiu(_) => Format::I,
            Instruction::Xori(_) => Format::I,
            Instruction::Ori(_) => Format::I,
            Instruction::Andi(_) => Format::I,
            Instruction::Add(_) => Format::R,
            Instruction::Sub(_) => Format::R,
            Instruction::Sll(_) => Format::R,
            Instruction::Slt(_) => Format::R,
            Instruction::Sltu(_) => Format::R,
            Instruction::Xor(_) => Format::R,
            Instruction::Srl(_) => Format::R,
            Instruction::Sra(_) => Format::R,
            Instruction::Or(_) => Format::R,
            Instruction::And(_) => Format::R,
        }
    }
}

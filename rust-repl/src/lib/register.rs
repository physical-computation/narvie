use std::num::ParseIntError;
use std::str::FromStr;

#[derive(Debug)]
pub struct Register(u32);

impl Register {
    pub fn from_u32(imm: u32) -> Option<Register> {
        if imm < (1 << 5) {
            Some(Register(imm))
        } else {
            None
        }
    }
    pub fn to_u32(&self) -> u32 {
        self.0
    }
}

#[derive(Debug)]
pub enum GetRegisterError {
    InvalidInt(ParseIntError),
    InvalidRegisterLiteral,
    OutsideRange { actual: i32, min: i32, max: u32 },
}

// fn check_range({
//         actual: i32,
//         min: i32,
//         max: u32,
//     }) -> bool -> {
//         x >= min && x <= max
//     }

impl FromStr for Register {
    type Err = GetRegisterError;

    fn from_str(string: &str) -> Result<Self, Self::Err> {
        match string {
            "zero" => Ok(Register(0)),
            "ra" => Ok(Register(1)),
            "sp" => Ok(Register(2)),
            "gp" => Ok(Register(3)),
            "tp" => Ok(Register(4)),
            _ => {
                let (first, rest) = string.split_at(1);
                match first {
                    "x" => rest
                        .parse::<u32>()
                        .map_err(GetRegisterError::InvalidInt)
                        .and_then(|reg| {
                            Register::from_u32(reg).ok_or(GetRegisterError::OutsideRange {
                                actual: reg as i32,
                                min: 0,
                                max: 31,
                            })
                        }),
                    "a" => rest
                        .parse::<u32>()
                        .map_err(GetRegisterError::InvalidInt)
                        .and_then(|a| {
                            if a < 8 {
                                Ok(a)
                            } else {
                                Err(GetRegisterError::OutsideRange {
                                    actual: a as i32,
                                    min: 0,
                                    max: 7,
                                })
                            }
                        })
                        .map(|a| a + 10)
                        .map(Register),
                    "s" => rest
                        .parse::<u32>()
                        .map_err(GetRegisterError::InvalidInt)
                        .and_then(|s| {
                            if s < 12 {
                                Ok(s)
                            } else {
                                Err(GetRegisterError::OutsideRange {
                                    actual: s as i32,
                                    min: 0,
                                    max: 11,
                                })
                            }
                        })
                        .map(|s| s + if s < 2 { 8 } else { 1 })
                        .map(Register),
                    "t" => rest
                        .parse::<u32>()
                        .map_err(GetRegisterError::InvalidInt)
                        .and_then(|t| {
                            if t < 8 {
                                Ok(t)
                            } else {
                                Err(GetRegisterError::OutsideRange {
                                    actual: t as i32,
                                    min: 0,
                                    max: 7,
                                })
                            }
                        })
                        .map(|t| t + if t < 3 { 5 } else { 25 })
                        .map(Register),
                    _ => Err(GetRegisterError::InvalidRegisterLiteral),
                }
            }
        }
    }
}

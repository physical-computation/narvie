use std::str::FromStr;
use std::string::String;

#[derive(Debug)]
pub struct U(u32);

#[derive(Debug)]
pub struct J(i32);

#[derive(Debug)]
pub enum GetImmediateError {
    InvalidLiteral(String),
    OutsideRange { actual: i32, min: i32, max: i32 },
    Odd,
}

fn get_immediate(string: &str) -> Option<i32> {
    let (first, rest) = string.split_at(1);
    if first == "-" {
        get_immediate(rest).map(|x| -x)
    } else {
        (if first == "0" {
            let (specifier, numeric) = rest.split_at(1);
            if specifier == "x" {
                Some((16, numeric))
            } else if specifier == "b" {
                Some((2, numeric))
            } else {
                None
            }
        } else {
            Some((10, string))
        })
        .and_then(|(radix, numeric)| i32::from_str_radix(numeric, radix).ok())
    }
}

impl U {
    pub fn from_u32(imm: u32) -> Option<U> {
        if imm < (1 << 20) {
            Some(U(imm))
        } else {
            None
        }
    }
    pub fn to_u32(&self) -> u32 {
        self.0
    }
}

impl FromStr for U {
    type Err = GetImmediateError;

    fn from_str(string: &str) -> Result<Self, Self::Err> {
        get_immediate(string)
            .ok_or(GetImmediateError::InvalidLiteral(string.to_string()))
            .and_then(|imm| {
                if imm > 0 {
                    U::from_u32(imm as u32)
                } else {
                    None
                }
                .ok_or(GetImmediateError::OutsideRange {
                    actual: imm,
                    min: 0,
                    max: (1 << 20) - 1,
                })
            })
    }
}

impl J {
    pub fn from_i32(imm: i32) -> Option<J> {
        if imm >= 0 && imm < (1 << 20) && imm & 1 == 0 {
            Some(J(imm))
        } else {
            None
        }
    }
    pub fn to_i32(&self) -> i32 {
        self.0
    }
}

impl FromStr for J {
    type Err = GetImmediateError;

    fn from_str(string: &str) -> Result<Self, Self::Err> {
        get_immediate(string)
            .ok_or(GetImmediateError::InvalidLiteral(string.to_string()))
            .and_then(|imm| {
                Self::from_i32(imm).ok_or_else(|| {
                    if imm & 1 == 1 {
                        GetImmediateError::Odd
                    } else {
                        GetImmediateError::OutsideRange {
                            actual: imm,
                            min: -1048576,
                            max: 1048574,
                        }
                    }
                })
            })
    }
}

use std::marker::PhantomData;
use std::str::FromStr;

#[derive(Debug)]
pub struct Register<R>(u32, PhantomData<R>);

#[derive(Debug)]
pub struct Rd;
#[derive(Debug)]
pub struct Rs1;
#[derive(Debug)]
pub struct Rs2;

impl<R> Register<R> {
    pub fn from_u32(imm: u32) -> Option<Register<R>> {
        if imm < GPR_COUNT {
            Some(Register(imm, PhantomData))
        } else {
            None
        }
    }
    pub fn to_u32(&self) -> u32 {
        self.0
    }
    pub const ZERO: Register<R> = Register(0, PhantomData);
}

pub const GPR_COUNT: u32 = 32;

#[derive(Debug)]
pub enum GetRegisterError {
    InvalidRegisterLiteral(String),
    OutsideRange { actual: i32, min: i32, max: i32 },
}

fn check_range(reg: u32, reg_count: u32) -> Result<u32, GetRegisterError> {
    if reg < reg_count {
        Ok(reg)
    } else {
        Err(GetRegisterError::OutsideRange {
            actual: reg as i32,
            min: 0,
            max: (reg_count as i32 - 1),
        })
    }
}

impl<R> FromStr for Register<R> {
    type Err = GetRegisterError;

    fn from_str(string: &str) -> Result<Self, Self::Err> {
        let err = || Err(GetRegisterError::InvalidRegisterLiteral(string.to_owned()));
        match string {
            "zero" => Ok(0),
            "ra" => Ok(1),
            "sp" => Ok(2),
            "gp" => Ok(3),
            "tp" => Ok(4),
            _ =>
            // Ok(0),
            {
                if string.is_empty() {
                    err()
                } else {
                    let (first, rest) = string.split_at(1);
                    let rest_u32 = rest.parse::<u32>().or_else(|_| err());

                    match first {
                        "x" => rest_u32.and_then(|reg| check_range(reg, 32)),
                        "a" => rest_u32.and_then(|a| check_range(a, 8)).map(|a| a + 10),
                        "s" => rest_u32
                            .and_then(|s| check_range(s, 12))
                            .map(|s| s + if s < 2 { 8 } else { 1 }),
                        "t" => rest_u32
                            .and_then(|t| check_range(t, 8))
                            .map(|t| t + if t < 3 { 5 } else { 25 }),
                        _ => err(),
                    }
                }
            }
        }
        .map(|x| Register/*::<R>*/(x, PhantomData))
    }
}

impl<R> Register<R> {
    pub fn abi_name(&self) -> String {
        let i = self.0;
        if i == 0 {
            "zero".to_string()
        } else if i == 1 {
            "ra".to_string()
        } else if i == 2 {
            "sp".to_string()
        } else if i == 3 {
            "gp".to_string()
        } else if i == 4 {
            "tp".to_string()
        } else if i >= 5 && i < 8 {
            format!("t{}", i - 5)
        } else if i >= 8 && i < 10 {
            format!("s{}", i - 8)
        } else if i >= 10 && i < 18 {
            format!("a{}", i - 10)
        } else if i >= 18 && i < 28 {
            format!("s{}", i - 16)
        } else if i >= 28 && i < 32 {
            format!("t{}", i - 25)
        } else {
            panic!("Register value outside bounds");
        }
    }
}

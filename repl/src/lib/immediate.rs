use std::marker::PhantomData;
use std::str::FromStr;
use std::string::String;

pub trait Constraints {
    const MAX: i32;
    const MIN: i32;
    const EVEN: bool;
}

#[derive(Debug)]
pub struct Immediate<I>(i32, PhantomData<I>);

#[derive(Debug)]
pub struct U;
#[derive(Debug)]
pub struct J;
#[derive(Debug)]
pub struct I;
#[derive(Debug)]
pub struct S;
#[derive(Debug)]
pub struct B;
#[derive(Debug)]
pub struct ShiftAmount;

impl Constraints for U {
    const MAX: i32 = (1 << 20) - 1;
    const MIN: i32 = 0;
    const EVEN: bool = false;
}

impl Constraints for J {
    const MAX: i32 = (1 << 20) - 1;
    const MIN: i32 = -(1 << 20);
    const EVEN: bool = true;
}

impl Constraints for I {
    const MAX: i32 = (1 << 11) - 1;
    const MIN: i32 = -(1 << 11);
    const EVEN: bool = false;
}

impl Constraints for S {
    const MAX: i32 = (1 << 11) - 1;
    const MIN: i32 = -(1 << 11);
    const EVEN: bool = false;
}

impl Constraints for B {
    const MAX: i32 = (1 << 12) - 1;
    const MIN: i32 = -(1 << 12);
    const EVEN: bool = true;
}

impl Constraints for ShiftAmount {
    const MAX: i32 = 31;
    const MIN: i32 = 0;
    const EVEN: bool = false;
}

#[derive(Debug)]
pub enum ConstraintViolation {
    LargerThan(i32),
    SmallerThan(i32),
    EvenNumberRequired,
}

#[derive(Debug)]
pub enum InvalidImmediate {
    Literal(String),
    NumericValue(ConstraintViolation),
}

fn constaint_violated<X: Constraints>(
    Immediate(imm, PhantomData): &Immediate<X>,
) -> Option<ConstraintViolation> {
    if imm > &X::MAX {
        Some(ConstraintViolation::LargerThan(X::MAX))
    } else if imm < &X::MIN {
        Some(ConstraintViolation::SmallerThan(X::MIN))
    } else if X::EVEN && (imm & 1 != 0) {
        Some(ConstraintViolation::EvenNumberRequired)
    } else {
        None
    }
}

impl<X: Constraints> Immediate<X> {
    pub fn from_i32(number: i32) -> Result<Self, ConstraintViolation> {
        let imm = Self(number, PhantomData);
        if let Some(violated) = constaint_violated(&imm) {
            Err(violated)
        } else {
            Ok(imm)
        }
    }

    pub fn to_i32(&self) -> i32 {
        self.0
    }
}

fn get_immediate(string: &str) -> Option<i32> {
    if string.is_empty() {
        None
    } else {
        let (first, rest) = string.split_at(1);
        if first == "-" {
            get_immediate(rest).map(|x| -x)
        } else if rest.is_empty() {
            i32::from_str(first).ok()
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
}

impl<X: Constraints> FromStr for Immediate<X> {
    type Err = InvalidImmediate;

    fn from_str(string: &str) -> Result<Self, Self::Err> {
        get_immediate(string)
            .ok_or(InvalidImmediate::Literal(string.to_string()))
            .and_then(|imm| Self::from_i32(imm).map_err(InvalidImmediate::NumericValue))
    }
}

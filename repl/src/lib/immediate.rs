use std::fmt;
use std::marker::PhantomData;
use std::marker::Sized;
use std::str::FromStr;
use std::string::String;

pub trait Constraints
where
    Self: Sized,
{
    const MAX: i32;
    const MIN: i32;
    const EVEN: bool;

    fn from_special_string(&str) -> Option<Immediate<Self>>;
    fn write_help(&Immediate<Self>, &mut fmt::Formatter) -> fmt::Result;
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
#[derive(Debug)]
pub struct CsrSpecifier;
#[derive(Debug)]
pub struct CsrImmediate;

impl Constraints for U {
    const MAX: i32 = (1 << 20) - 1;
    const MIN: i32 = 0;
    const EVEN: bool = false;
    fn from_special_string(_: &str) -> Option<Immediate<Self>> {
        None
    }
    fn write_help(value: &Immediate<Self>, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "0x{:X}", value.to_i32())
    }
}

impl Constraints for J {
    const MAX: i32 = (1 << 20) - 1;
    const MIN: i32 = -(1 << 20);
    const EVEN: bool = true;
    fn from_special_string(_: &str) -> Option<Immediate<Self>> {
        None
    }
    fn write_help(value: &Immediate<Self>, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", value.to_i32())
    }
}

impl Constraints for I {
    const MAX: i32 = (1 << 11) - 1;
    const MIN: i32 = -(1 << 11);
    const EVEN: bool = false;
    fn from_special_string(_: &str) -> Option<Immediate<Self>> {
        None
    }
    fn write_help(value: &Immediate<Self>, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", value.to_i32())
    }
}

impl Constraints for S {
    const MAX: i32 = (1 << 11) - 1;
    const MIN: i32 = -(1 << 11);
    const EVEN: bool = false;
    fn from_special_string(_: &str) -> Option<Immediate<Self>> {
        None
    }
    fn write_help(value: &Immediate<Self>, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", value.to_i32())
    }
}

impl Constraints for B {
    const MAX: i32 = (1 << 12) - 1;
    const MIN: i32 = -(1 << 12);
    const EVEN: bool = true;
    fn from_special_string(_: &str) -> Option<Immediate<Self>> {
        None
    }
    fn write_help(value: &Immediate<Self>, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", value.to_i32())
    }
}

impl Constraints for ShiftAmount {
    const MAX: i32 = 31;
    const MIN: i32 = 0;
    const EVEN: bool = false;
    fn from_special_string(_: &str) -> Option<Immediate<Self>> {
        None
    }
    fn write_help(value: &Immediate<Self>, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", value.to_i32())
    }
}

impl Constraints for CsrSpecifier {
    const MAX: i32 = (1 << 12) - 1;
    const MIN: i32 = 0;
    const EVEN: bool = false;
    fn from_special_string(string: &str) -> Option<Immediate<Self>> {
        Some(
            Immediate::from_i32(match string {
                "cycle" => 0xC00,
                "time" => 0xC01,
                "instret" => 0xC02,
                "cycleh" => 0xC80,
                "timeh" => 0xC81,
                "instreth" => 0xC82,
                _ => return None,
            })
            .unwrap(),
        )
    }
    fn write_help(value: &Immediate<Self>, f: &mut fmt::Formatter) -> fmt::Result {
        match value.to_i32() {
            0xC00 => write!(f, "{}", "cycle"),
            0xC01 => write!(f, "{}", "time"),
            0xC02 => write!(f, "{}", "instret"),
            0xC80 => write!(f, "{}", "cycleh"),
            0xC81 => write!(f, "{}", "timeh"),
            0xC82 => write!(f, "{}", "instreth"),
            other => write!(f, "0x{:X}", other),
        }
    }
}

impl Constraints for CsrImmediate {
    const MAX: i32 = 31;
    const MIN: i32 = 0;
    const EVEN: bool = false;
    fn from_special_string(_: &str) -> Option<Immediate<Self>> {
        None
    }
    fn write_help(value: &Immediate<Self>, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", value.to_i32())
    }
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

fn constraint_violated<X: Constraints>(
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
        if let Some(violated) = constraint_violated(&imm) {
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
        X::from_special_string(string).ok_or(()).or_else(|_| {
            get_immediate(string)
                .ok_or(InvalidImmediate::Literal(string.to_string()))
                .and_then(|imm| Self::from_i32(imm).map_err(InvalidImmediate::NumericValue))
        })
    }
}

impl<X: Constraints> fmt::Display for Immediate<X> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        X::write_help(self, f)
    }
}

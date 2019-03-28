use std::os::raw::{c_char, c_int};
use std::ffi::CString;

#[link(name = "vnarvie")]
#[link(name = "stdc++")]
extern {
    fn main_loop(argc: c_int, argv: *const *const c_char) -> ();
}

fn main() {
    let args = std::env::args().map(|arg| CString::new(arg).unwrap() ).collect::<Vec<CString>>();
    let c_args = args.iter().map(|arg| arg.as_ptr()).collect::<Vec<*const c_char>>();
    unsafe {
        main_loop(c_args.len() as c_int, c_args.as_ptr());
    };
}

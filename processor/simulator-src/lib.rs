use std::ffi::c_void;
use std::os::raw::c_int;
use std::sync::mpsc::{Receiver, Sender, TryRecvError};

#[link(name = "vnarvie")]
#[cfg_attr(target_os = "macos", link(name = "c++"))]
#[cfg_attr(not(target_os = "macos"), link(name = "stdc++"))]
extern "C" {
    fn main_loop(
        write: extern "C" fn(u8, *mut c_void) -> c_int,
        try_read: extern "C" fn(*mut u8, *mut c_void) -> c_int,
        read_write_state: *mut c_void,
    );
}

struct ReadWriteState {
    writer: Sender<u8>,
    reader: Receiver<u8>,
}

extern "C" fn write(byte: u8, state: *mut c_void) -> c_int {
    let state = state as *mut ReadWriteState;
    unsafe {
        match (*state).writer.send(byte) {
            Ok(()) => 0,
            Err(_) => -1,
        }
    }
}

extern "C" fn read(byte: *mut u8, state: *mut c_void) -> c_int {
    let state = state as *mut ReadWriteState;
    unsafe {
        match (*state).reader.try_recv() {
            Ok(value) => {
                *byte = value;
                0
            }
            Err(TryRecvError::Empty) => 1,

            Err(_) => -2,
        }
    }
}

pub fn run_narvie(sender: Sender<u8>, receiver: Receiver<u8>) {
    let mut state = ReadWriteState {
        writer: sender,
        reader: receiver,
    };
    unsafe {
        main_loop(
            write,
            read,
            &mut state as *mut ReadWriteState as *mut c_void,
        );
    };
}

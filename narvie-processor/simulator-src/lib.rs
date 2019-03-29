use std::ffi::c_void;
use std::os::raw::c_int;
use std::sync::mpsc::{Receiver, Sender, TryRecvError};

#[link(name = "vnarvie")]
#[link(name = "stdc++")]
extern "C" {
    fn main_loop(
        write: extern "C" fn(u8, *mut c_void) -> (),
        try_read: extern "C" fn(*mut u8, *mut c_void) -> c_int,
        read_write_state: *mut c_void,
    );
}

struct ReadWriteState {
    writer: Sender<u8>,
    reader: Receiver<u8>,
}

extern "C" fn write(byte: u8, state: *mut c_void) -> () {
    let state = state as *mut ReadWriteState;
    unsafe {
        (*state).writer.send(byte).unwrap();
    };
}

extern "C" fn read(byte: *mut u8, state: *mut c_void) -> c_int {
    let state = state as *mut ReadWriteState;
    unsafe {
        match (*state).reader.try_recv() {
            Ok(value) => {
                *byte = value;
                return 1;
            }
            Err(TryRecvError::Empty) => {
                return 0;
            }
            _ => panic!(),
        };
    };
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

use std::io::{Read, Write};
use std::net::TcpListener;
use std::sync::mpsc;
use std::thread;

mod lib;

enum Message {
    Uart(u8),
    Done,
}

fn main() {
    let (sender, receiver) = mpsc::channel();
    let (sender2, receiver2) = mpsc::channel();
    let master_channel = mpsc::channel();
    let master_sender1 = master_channel.0.clone();

    let listener = TcpListener::bind(("localhost", 8001)).unwrap();

    thread::spawn(move || {
        lib::run_narvie(sender2, receiver);
    });

    thread::spawn(move || {
        while let Ok(data) = receiver2.recv() {
            master_sender1.send(Message::Uart(data)).unwrap();
        }
    });

    for stream in listener.incoming() {
        let mut stream = stream.unwrap();
        stream.set_read_timeout(None).unwrap();

        let mut stream_clone = stream.try_clone().unwrap();
        let sender_copy = sender.clone();
        let master_sender2 = master_channel.0.clone();

        thread::spawn(move || {
            let mut buf = [0];
            while stream_clone
                .read(&mut buf)
                .map(|bytes_read| bytes_read == 1)
                .unwrap_or(false)
            {
                sender_copy.send(buf[0]).unwrap();
            }
            master_sender2.send(Message::Done).unwrap();
        });

        let mut buf = [0];
        while match master_channel.1.recv().unwrap() {
            Message::Uart(byte) => {
                buf[0] = byte;
                stream.write_all(&buf).unwrap();
                stream.flush().unwrap();
                true
            }
            Message::Done => false,
        } {}
    }
}

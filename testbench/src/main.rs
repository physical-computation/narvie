
#[link(name = "vnarvie")]
#[link(name = "stdc++")]
extern {
    fn main_loop() -> ();
}

fn main() {
    unsafe {
        main_loop();
    };
}

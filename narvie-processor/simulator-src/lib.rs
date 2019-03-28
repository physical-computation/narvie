
#[link(name = "vnarvie")]
#[link(name = "stdc++")]
extern {
    fn main_loop() -> ();
}

pub fn run_narvie() {
    unsafe {
        main_loop();
    };
}

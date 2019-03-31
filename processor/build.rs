use std::env;
use std::io::Write;
use std::process::{Command, Stdio};

fn main() {
    let current_dir = env::current_dir().unwrap();
    let out_dir = env::var("OUT_DIR").unwrap();
    let mut build = Command::new("bash").stdin(Stdio::piped()).spawn().unwrap();

    {
        let the_stdin_stream = build.stdin.as_mut().unwrap();
        write!(
            the_stdin_stream,
            r#"

set -e
set -v

OUT_DIR={}
NARVIE_ROOT={}
VERILATOR_SRC=$NARVIE_ROOT/simulator-src

cd $OUT_DIR

source $NARVIE_ROOT/module-list.sh

verilator \
-Wall \
--cc $VERILATOR_SRC/top_sim.v $MODULES $SAIL/config.vlt \
-I$UART_RX \
--prefix Vnarvie \
--cc $VERILATOR_SRC/main.c $VERILATOR_SRC/testbench.c $VERILATOR_SRC/uartsim.c \
--exe \
-Mdir $OUT_DIR \
-CFLAGS "-std=c++11 -g -O3"

make -j -f Vnarvie.mk
cp Vnarvie__ALL.a libvnarvie.a
ar -q libvnarvie.a testbench.o uartsim.o verilated.o

    "#,
            out_dir,
            current_dir.to_str().unwrap()
        )
        .unwrap();
    }

    assert!(build.wait().unwrap().success());

    println!(r"cargo:rustc-link-search={}", out_dir);
}

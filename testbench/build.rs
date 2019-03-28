
use std::process::{Command, Stdio};
use std::io::Write;
use std::env;

fn main() {
  let current_dir = env::current_dir().unwrap();
  let out_dir = env::var("OUT_DIR").unwrap();
  let mut build = Command::new("bash").stdin(Stdio::piped()).spawn().unwrap();

  {

    let the_stdin_stream = build.stdin.as_mut().unwrap();
    write!(the_stdin_stream, r#"

set -e
set -v

OUT_DIR={}
NARVIE_ROOT={}
TESTBENCH_DIR=$NARVIE_ROOT/testbench
VERILATOR_SRC=$TESTBENCH_DIR/verilator_src

cd $OUT_DIR

source $NARVIE_ROOT/module-list.sh

verilator \
-Wall \
--cc $VERILATOR_SRC/top_sim.v $MODULES $SAIL/config.vlt \
-I$UART_RX \
--prefix Vnarvie \
--cc $VERILATOR_SRC/main.cpp $VERILATOR_SRC/testbench.cpp $VERILATOR_SRC/uartsim.cpp \
--exe \
-Mdir $OUT_DIR \
-CFLAGS "-std=c++14 -g -O3"

make -j -f Vnarvie.mk
cp Vnarvie__ALL.a libvnarvie.a
ar -q libvnarvie.a testbench.o uartsim.o verilated.o

    "#, out_dir, current_dir.parent().unwrap().to_str().unwrap()).unwrap();
  }

  assert!(build.wait().unwrap().success());

  println!(r"cargo:rustc-link-search={}", out_dir);
}

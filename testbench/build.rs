
use std::process::{Command, Stdio};
use std::io::Write;

fn main() {

  let mut build = Command::new("bash").stdin(Stdio::piped()).spawn().unwrap();

  {

    let the_stdin_stream = build.stdin.as_mut().unwrap();
    write!(the_stdin_stream, r#"

set -e
set -v

cd ../sail
source ../module-list.sh

TESTBENCH_DIR=../testbench
VERILATOR_SRC=$TESTBENCH_DIR/verilator_src
BUILD_DIR=$TESTBENCH_DIR/verilator_built

verilator \
-Wall \
--cc $VERILATOR_SRC/top_sim.v $MODULES config.vlt \
-I$UART_RX \
--prefix Vnarvie \
--cc $VERILATOR_SRC/main.cpp $VERILATOR_SRC/testbench.cpp $VERILATOR_SRC/uartsim.cpp \
--exe \
-Mdir $BUILD_DIR \
-CFLAGS "-std=c++14 -g -O3"

cd -
cd verilator_built
make -j -f Vnarvie.mk
cp Vnarvie__ALL.a libvnarvie.a
ar -q libvnarvie.a testbench.o uartsim.o verilated.o


    "#).unwrap();
  }

  assert!(build.wait().unwrap().success());

  println!(r"cargo:rustc-link-search=verilator_built");
}

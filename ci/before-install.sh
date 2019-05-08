
#! /bin/bash

VERILATOR_VERSION=3.916
unset VERILATOR_ROOT

if [[ ! -d deps ]]; then mkdir deps ; fi

pushd deps

if [[ ! -d verilator-$VERILATOR_VERSION ]]; then
        wget https://www.veripool.org/ftp/verilator-$VERILATOR_VERSION.tgz
        tar xvzf verilator-$VERILATOR_VERSION.tgz
        pushd verilator-$VERILATOR_VERSION
        "./configure"
        make
else
        pushd verilator-$VERILATOR_VERSION
fi

sudo make install

popd
popd

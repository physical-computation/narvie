# Required FPGA Resources

## Standard RV32I processor

    IOs          8 / 21
      IO_I3Cs    0 / 2
      IO_ODs     0 / 3
    GBs          0 / 8
      GB_IOs     0 / 8
    LCs          2322 / 5280
      DFF        521
      CARRY      156
      CARRY, DFF 30
      DFF PASS   384
      CARRY PASS 4
    BRAMs        28 / 30

    final wire length = 9999

    After placement:
    PIOs       8 / 21
    PLBs       381 / 660
    BRAMs      28 / 30


## Standard RV32I processor with UART tx/rx

    IOs          10 / 21
      IO_I3Cs    0 / 2
      IO_ODs     0 / 3
    GBs          0 / 8
      GB_IOs     0 / 8
    LCs          2428 / 5280
      DFF        594
      CARRY      172
      CARRY, DFF 32
      DFF PASS   425
      CARRY PASS 8
    BRAMs        28 / 30

    final wire length = 11066

    After placement:
    PIOs       9 / 21
    PLBs       401 / 660
    BRAMs      28 / 30

## RV32I without instruction memory

    IOs          9 / 21
      IO_I3Cs    0 / 2
      IO_ODs     0 / 3
    GBs          0 / 8
      GB_IOs     0 / 8
    LCs          1302 / 5280
      DFF        304
      CARRY      105
      CARRY, DFF 58
      DFF PASS   228
      CARRY PASS 5
    BRAMs        20 / 30

    final wire length = 4757

    After placement:
    PIOs       8 / 21
    PLBs       249 / 660
    BRAMs      20 / 30

## RV32I without instruction memory with UART tx/rx

    IOs          10 / 21
      IO_I3Cs    0 / 2
      IO_ODs     0 / 3
    GBs          0 / 8
      GB_IOs     0 / 8
    LCs          1368 / 5280
      DFF        482
      CARRY      139
      CARRY, DFF 32
      DFF PASS   333
      CARRY PASS 5
    BRAMs        26 / 30

    final wire length = 5512

    After placement:
    PIOs       9 / 21
    PLBs       301 / 660
    BRAMs      26 / 30

## `narvie`

    IOs          10 / 21
      IO_I3Cs    0 / 2
      IO_ODs     0 / 3
    GBs          0 / 8
      GB_IOs     0 / 8
    LCs          2298 / 5280
      DFF        688
      CARRY      182
      CARRY, DFF 32
      DFF PASS   464
      CARRY PASS 10
    BRAMs        30 / 30

    final wire length = 10381

    After placement:
    PIOs       9 / 21
    PLBs       413 / 660
    BRAMs      30 / 30

## `narvie` with instruction memory

    IOs          10 / 21
      IO_I3Cs    0 / 2
      IO_ODs     0 / 3
    GBs          0 / 8
      GB_IOs     0 / 8
    LCs          2703 / 5280
      DFF        691
      CARRY      184
      CARRY, DFF 37
      DFF PASS   468
      CARRY PASS 11
    BRAMs        30 / 30

    final wire length = 11305

    After placement:
    PIOs       8 / 21
    PLBs       457 / 660
    BRAMs      30 / 30

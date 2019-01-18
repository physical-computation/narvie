const path = require('path');

const compilerFileDir = path.join(__dirname, 'compiler-files');

module.exports = Object.freeze({
    // Do not write or read from the serial port. Instead return a
    // random string of bytes for the register file.
    mockInstructionEvaluation: false,

    // Read TCP port instead of serial port, useful if the processor
    // is running in a simulation instead of on an FPGA.
    mockSerialPort: true,

    // TCP port to use if mocking serial port. Must match the port that
    // the testbed UART simulator is running on. See the argument used
    // to construct `m_uart` in `./testbench/testbench.cpp`.
    portForMockedSerialPort: 8001,

    // Serial port address. This is passed to the SerialPort constructor.
    // See https://serialport.io/docs/en/api-stream#path
    serialPortAddress: 'COM10',

    // Milliseconds to wait before retrying after error
    retryDelay: 3000,

    // Prompt for user input.
    prompt: '>',

    // Write over existing lines for a better UI. Disable if
    // logging is messing up the output.
    overwrite: true,

    // Make command (on windows try `wsl make`).
    makeCommand: 'make',

    // With of highlighted lines, set to Infinity to highlight
    // the width of the terminal.
    lineWidth: 80,

    // Set the file used to log bytes received by the serial port
    serialportLogPath: path.join(__dirname, 'logs', 'serialport'),

    // Set the files used to generate binary instructions, these
    // paths must match those set in `./Makefile`. See `./Makefile`
    // for explanations
    compilerFileDir,
    asPath: path.join(compilerFileDir, 'a.S'),
    machPath: path.join(compilerFileDir, 'machine-code'),
    disassemblyPath: path.join(compilerFileDir, 'd.S'),
});

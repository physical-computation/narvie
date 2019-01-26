const path = require('path');

const compilerFileDir = path.join(__dirname, 'compiler-files');

module.exports = Object.freeze({
	// Do not write or read from the serial port. Instead return a
	// random string of bytes for the register file.
	mockInstructionEvaluation: false,

	// TCP port to use if mocking serial port. Must match the port that
	// the testbed UART simulator is running on. See the argument used
	// to construct `m_uart` in `./testbench/testbench.cpp`.
	portForUart: 8001,

	// Milliseconds to wait before giving up reading registers
	readRegistersTimeout: 5000,

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
});

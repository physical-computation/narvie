'use strict';

const readline = require('readline');
const util = require('util');
const childProcess = require('child_process');
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const chalk = require('chalk');
const Table = require('@harrysarson/cli-table');
const config = require('./config');

const {portWrite, portReadRegisters} = require('./eval-instruction');
const {assemble} = require('./assemble');

const SerialPort = require('./serialport');

const writeFile = util.promisify(fs.writeFile);
const mkdir = util.promisify(fs.mkdir);

const getAbi = i => {
	if (i === 0) {
		return 'zero';
	}
	if (i === 1) {
		return 'ra';
	}
	if (i === 2) {
		return 'sp';
	}
	if (i === 3) {
		return 'gp';
	}
	if (i === 4) {
		return 'tp';
	}
	if (i >= 5 && i < 8) {
		return `t${i - 5}`;
	}
	if (i >= 8 && i < 10) {
		return `s${i - 8}`;
	}
	if (i >= 10 && i < 18) {
		return `a${i - 10}`;
	}
	if (i >= 18 && i < 28) {
		return `s${i - 16}`;
	}
	if (i >= 28 && i < 32) {
		return `t${i - 25}`;
	}
	throw new Error('register index is outside valid range');
};

const question = (rl, prompt) => new Promise(resolve => {
	rl.question(prompt, resolve);
});

const resetCursor = config.overwrite ?
	(tty => tty.cursorTo(0)) :
	(tty => tty.write('\n'));

const createAssembly = instruction => `
.globl _start

_start:
	${instruction}
`;

const highlightedLine = (tty, color, text) => {
	tty.write(color(' '.repeat(Math.min(tty.columns, config.lineWidth))));
	resetCursor(tty);
	tty.write(color(text));
};

const readEvalPrint = async ({instruction, serialport}) => {
	const messages = {
		compiling: inst => `Compiling ${chalk.bgWhite.black(` ${inst} `)} to riscv machine code:`,
		writing: inst => `Writing ${chalk.bgWhite.black(` ${inst} `)} to to riscv processor:`,
		reading: 'Reading updated registers from riscv processor:'
	};

	const logProcessorError = (message, error) => {
		highlightedLine(
			process.stdout,
			chalk.bgRed.white,
			`${message} Failed`,
		);
		process.stdout.write(`\n  ${`${`${error}`.trim()}`.replace(/\n/g, '\n  ')}\n`);

		highlightedLine(
			process.stdout,
			chalk.bgRed.white,
			'Fix the problem and try again.',
		);
		process.stdout.write('\n');
	};

	if (instruction === '') {
		return;
	}

	let machineCode;
	let disassembly;
	try {
		let {binary, disassembly: d} = assemble(instruction);
		const buffer = Buffer.alloc(4);
		buffer.writeInt32LE(binary);
		machineCode = [buffer];
		disassembly = [d];
	} catch (error) {
		if (error.assembleError) {
			const errorMessage = `Cannot assemble:
    ${instruction}

${error}

Expected: ${error.expected}
Actual:   ${error.actual}
`;
			logProcessorError(messages.compiling(instruction), errorMessage);
			return;
		} else {
			throw error;
		}
	}

	const binaryInstructions = machineCode.map(inst =>
		[...inst]
			.reverse()
			.map(x => x.toString(2).padStart(8, '0'))
			.join(' ')
	);

	const inputTable = new Table({
		head: ['Instruction', 'Binary'],
		style: {
			head: ['bgWhite', 'black']
		}
	});

	for (let i = 0; i < disassembly.length; ++i) {
		inputTable.push([disassembly[i], binaryInstructions[i]]);
	}

	process.stdout.write(`${inputTable}\n`);
	let regfile;

	for (let i = 0; i < machineCode.length; ++i) {
		highlightedLine(
			process.stdout,
			chalk.bgYellow.black,
			messages.writing,
		);
		resetCursor(process.stdout);

		try {
			portWrite(serialport, machineCode[i]);
		} catch (error) {
			logProcessorError(messages.writing(disassembly[i]), error);
			return;
		}

		highlightedLine(
			process.stdout,
			chalk.bgGreen.black,
			`${messages.writing(disassembly[i])} Success`,
		);
		process.stdout.write('\n\n');
		highlightedLine(
			process.stdout,
			chalk.bgYellow.black,
			messages.reading,
		);
		resetCursor(process.stdout);

		try {
			regfile = await portReadRegisters(serialport, {regCount: 32});
		} catch (error) {
			logProcessorError(messages.reading, error);
			return;
		}
		highlightedLine(
			process.stdout,
			chalk.bgGreen.black,
			`${messages.reading} Success`,
		);
		process.stdout.write('\n');
	}

	const options = {
		head: ['Name', 'ABI', 'Value'],
		style: {
			head: ['bgWhite', 'black']
		}
	};

	const registerTableLeft = new Table(options);
	const registerTableRight = new Table(options);
	const getRegHex = index =>
		`0x${regfile[index].toString(16).padStart(8, '0').toUpperCase()}`;

	for (let i = 0; i < 16; i++) {
		registerTableLeft.push([
			`x${i}`,
			getAbi(i),
			getRegHex(i)
		]);
		registerTableRight.push([
			`x${16 + i}`,
			getAbi(16 + i),
			getRegHex(16 + i)
		]);
	}
	const linesLeft = `${registerTableLeft}`.split('\n');
	const linesRight = `${registerTableRight}`.split('\n');
	const lines = [];
	assert.strictEqual(linesLeft.length, linesRight.length);
	for (let i = 0; i < linesLeft.length; i++) {
		lines.push(`${linesLeft[i]}    ${linesRight[i]}`);
	}

	process.stdout.write(`${lines.join('\n')}\n`);
};

const run = async rl => {
	const portAddress = `TCP port ${config.portForUart}`;
	const connectingMessage = `Connecting to processor at ${chalk.bgWhite.black(` ${portAddress} `)}:`;

	highlightedLine(
		process.stdout,
		chalk.bgYellow.black,
		connectingMessage,
	);
	resetCursor(process.stdout);

	let serialport;

	try {
		serialport = await SerialPort.connect();
	} catch (error) {
		highlightedLine(
			process.stdout,
			chalk.bgRed.white,
			`${connectingMessage} Error`,
		);

		process.stdout.write(`\n  ${`${`${error}`.trim()}`.replace(/\n/g, '\n  ')}\n`);

		highlightedLine(
			process.stdout,
			chalk.bgRed.white,
			'Check the riscv processor is connected.',
		);
		process.stdout.write('\n');
		return;
	}

	try {
		await mkdir(path.dirname(config.serialportLogPath));
	} catch (error) {}
	await writeFile(config.serialportLogPath, '');
	try {
		await mkdir(config.compilerFileDir);
	} catch (error) {}

	serialport.on('data', data => {
		writeFile(config.serialportLogPath, data, {
			flag: 'a+'
		});
	});
	serialport.pause();

	highlightedLine(
		process.stdout,
		chalk.bgGreen.black,
		`${connectingMessage} Success`,
	);
	process.stdout.write('\n');

	let portClosed = false;

	serialport.on('close', () => {
		portClosed = true;
	});

	try {
		// Await readEvalPrint({
		// 	instruction: 'nop',
		// 	serialport: serialport,
		// });
		while (!portClosed) {
			const input = await question(rl, `${config.prompt} `);
			if (portClosed) {
				break;
			}
			await readEvalPrint({
				instruction: input.trim(),
				serialport
			});
		}
		process.stdout.write('\n');
		highlightedLine(
			process.stdout,
			chalk.bgRed.white,
			`Connection to processor at ${chalk.bgWhite.black(` ${portAddress} `)} ended`,
		);
		process.stdout.write('\n');
	} catch (error) {
		process.stdout.write('\n');
		highlightedLine(
			process.stdout,
			chalk.bgRed.white,
			`${error} Failed`,
		);
		process.stdout.write('\n');
	}
};

(async () => {
	const rl = readline.createInterface({
		input: process.stdin,
		output: process.stdout
	});
	rl.on('SIGINT', () => {
		rl.close();
		process.stdout.write('\n');
		process.exit();
	});
	for (; ;) {
		await run(rl);
		process.stdout.write(`\nRetrying in ${config.retryDelay / 1000} seconds... \n\n`);
		await (new Promise(resolve => setTimeout(resolve, config.retryDelay)));
	}
})();

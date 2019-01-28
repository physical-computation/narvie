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

/* narvie will use these as headers when displaying binary.
 */
const formatHeaders = {
	R: ['funct7', 'rs2', 'rs1', 'funct3', 'rd', 'opcode'],
	I: ['imm[11:0]', 'rs1', 'funct3', 'rd', 'opcode'],
	'I-SHIFT': ['imm[11:5]', 'shamt', 'rs1', 'funct3', 'rd', 'opcode'],
	S: ['imm[15:5]', 'rs2', 'rs1', 'funct3', 'imm[4:0]', 'opcode'],
	B: ['imm[12|10:5]', 'rs2', 'rs1', 'funct3', 'imm[4:1|11]', 'opcode'],
	U: ['imm[31:12]', 'rd', 'opcode'],
	J: ['imm[20|10:1|11|19:12]', 'rd', 'opcode'],
};

/* narvie will split the instruction into blocks of binary.
 * These arrays indicate how wide each block should be.
 *
 * It is assumed in the code that these are positive integers.
 */
const binaryBlockWidths = {
	R: [7, 5, 5, 3, 5, 7],
	I: [12, 5, 3, 5, 7],
	'I-SHIFT': [7, 5, 5, 3, 5, 7],
	S: [7, 5, 5, 3, 5, 7],
	B: [7, 5, 5, 3, 5, 7],
	U: [20, 5, 7],
	J: [20, 5, 7],
}

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
	const res = {
		startTime: process.hrtime.bigint(),
		sendAssemblyTime: [],
		receiveRegfileTime: [],
		endTime: null,
	};

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
		return res;
	}

	let assembled = [];
	try {
		assembled = assemble(instruction);
	} catch (error) {
		if (error.assembleError) {
			const errorMessage = `Cannot assemble:
    ${instruction}

${error}

Expected: ${error.expected}
Actual:   ${error.actual}
`;
			logProcessorError(messages.compiling(instruction), errorMessage);
			return res;
		} else {
			throw error;
		}
	}

	if (assembled.length > 1) {
		throw new Error("Cannot support pseudo ops that expand to more than one instruction");
	}

	const inputTable = new Table({
		head: ['Instruction', ...formatHeaders[assembled[0].format]],
		style: {
			head: ['bgWhite', 'black']
		},
		colAligns: ['left', ...formatHeaders[assembled[0].format].map(_ => 'middle')],
	});


	for (const {binary, disassembly, format} of assembled) {
		const {binarySections} = [...binary]
			.reverse()
			.map(x => x.toString(2).padStart(8, '0'))
			.reduce((arr, byte) => {arr.push(...byte); return arr;}, [])
			.reduce(
				(acc, bit) => {
					acc.latestBinarySection.push(bit);
					acc.indexWithinSection += 1;

					if (acc.indexWithinSection === binaryBlockWidths[format][acc.sectionIndex]) {
						acc.binarySections.push(acc.latestBinarySection.join(''));
						acc.sectionIndex += 1;
						acc.indexWithinSection = 0;
						acc.latestBinarySection = [];
					}

					return acc;
				},
				{sectionIndex: 0, indexWithinSection: 0, binarySections: [], latestBinarySection: []}
			);
		inputTable.push([disassembly, ...binarySections]);
	}

	process.stdout.write(`${inputTable}\n`);
	let regfile;

	for (const {binary, disassembly} of assembled) {
		highlightedLine(
			process.stdout,
			chalk.bgYellow.black,
			messages.writing,
		);
		resetCursor(process.stdout);

		res.sendAssemblyTime.push(process.hrtime.bigint());
		try {
			portWrite(serialport, binary);
		} catch (error) {
			logProcessorError(messages.writing(disassembly), error);
			return res;
		}

		highlightedLine(
			process.stdout,
			chalk.bgGreen.black,
			`${messages.writing(disassembly)} Success`,
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
			res.receiveRegfileTime.push(process.hrtime.bigint());
		} catch (error) {
			logProcessorError(messages.reading, error);

			return res;
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
	res.endTime = process.hrtime.bigint();
	return res;
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
			const input = 'add x1, x2, x1'; // (await question(rl, `${config.prompt} `)).trim();
			if (portClosed) {
				break;
			}
			const {
				startTime,
				endTime,
				sendAssemblyTime,
				receiveRegfileTime
			} = await readEvalPrint({
				instruction: input,
				serialport
			});

			if (startTime !== null && endTime !== null) {
				highlightedLine(
					process.stdout,
					chalk.bgBlue.black,
					`Evaluation of ${chalk.bgWhite.black(` ${input} `)} took ${(Number(endTime - startTime) * 1.0e-9).toPrecision(4)} seconds.`,
				);
				process.stdout.write('\n');
			}
			if (receiveRegfileTime.length > 0 && sendAssemblyTime > 0) {
				highlightedLine(
					process.stdout,
					chalk.bgBlue.black,
					`Between sending the first instruction and receiving the register file were ${(Number(receiveRegfileTime[0] - sendAssemblyTime[0]) * 1.0e-9).toPrecision(4)} seconds.`,
				);
				process.stdout.write('\n');
			}
			await writeFile(__dirname + '/logs/timing.txt', `${receiveRegfileTime[0] - sendAssemblyTime[0]}\n`, {
				flag: 'a+'
			});
			await new Promise(resolve => setTimeout(resolve, 100));
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
		console.error(error);
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

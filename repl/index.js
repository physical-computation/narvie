'use strict';
const config = require('./config');

const readline = require('readline');
const util = require('util');
const childProcess = require('child_process');
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const Debug = require('debug');
const chalk = require('chalk');
const Table = require('@harrysarson/cli-table');

const { portWrite, portReadRegisters } = require('./eval-instruction');

const SerialPort = equire('./serialport');

const writeFile = util.promisify(fs.writeFile);
const readFile = util.promisify(fs.readFile);
const mkdir = util.promisify(fs.mkdir);

const debug = new Debug('process-repl');
const exec = util.promisify(childProcess.exec);


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

const resetCursor = config.overwrite
	? (tty => tty.cursorTo(0))
	: (tty => tty.write('\n'));

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

const readEvalPrint = async ({ instruction, serialport }) => {
	const messages = {
		compiling: inst => `Compiling ${chalk.bgWhite.black(` ${inst} `)} to riscv machine code:`,
		writing: inst => `Writing ${chalk.bgWhite.black(` ${inst} `)} to to riscv processor:`,
		reading: `Reading updated registers from riscv processor:`,
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

	// Create assembly file:
	try {
		await writeFile(config.asPath, createAssembly(instruction));
	} catch (error) {
		console.error('Failed to write assembly to temporary file: ');
		throw error;
	}

	highlightedLine(
		process.stdout,
		chalk.bgYellow.black,
		messages.compiling(instruction),
	);
	resetCursor(process.stdout);

	try {
		const { stdout, stderr } = await exec(
			config.makeCommand,
			{
				cwd: __dirname,
			}
		);

		debug(`stdout:\n${stdout}`);
		debug(`stderr:\n${stderr}`);

		if (stderr !== '') {
			process.error.write(`\n  Possible error in assembler:\n  ${stderr.replace(/\n/g, '\n  ')}\n`);
		}
	} catch (error) {
		highlightedLine(
			process.stdout,
			chalk.bgRed.white,
			`${messages.compiling(instruction)} Error`,
		);
		let errorString = `${error}`;
		if (error.stderr !== undefined) {
			errorString = error.stderr.trim();
		}
		process.stdout.write(`\n  ${errorString.replace(/\n/g, '\n  ')}\n`);

		highlightedLine(
			process.stdout,
			chalk.bgRed.white,
			'Fix the instruction and try again.',
		);
		process.stdout.write('\n');
		return;
	}

	highlightedLine(
		process.stdout,
		chalk.bgGreen.black,
		`${messages.compiling(instruction)} Success`,
	);
	process.stdout.write('\n');

	let machineCode = [];
	try {
		const binary = await readFile(config.machPath);
		let i = 0;
		while (i * 4 < binary.length) {
			machineCode.push(binary.slice(i * 4, (i + 1) * 4));
			i++;
		}
	} catch (error) {
		console.error('Failed to read machine code from temporary file:');
		throw error;
	}

	let disassembly = [];
	try {
		disassembly = await readFile(config.disassemblyPath, 'utf8');
		disassembly = disassembly
			.split('\n')
			.slice(0, -1)
			.map(text => text.replace('\t', ' '));
	} catch (error) {
		console.error('Failed to read disassembly temporary file:');
		throw error;
	}
	assert.strictEqual(disassembly.length, machineCode.length);
	assert.strictEqual(machineCode[machineCode.length - 1].length, 4);

	const binaryInstructions = machineCode.map(inst =>
		[...inst]
			.reverse()
			.map(x => x.toString(2).padStart(8, '0'))
			.join(' ')
	);

	const inputTable = new Table({
		head: ['Instruction', 'Binary'],
		style: {
			head: ['bgWhite', 'black'],
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
		process.stdout.write('\n');
		highlightedLine(
			process.stdout,
			chalk.bgYellow.black,
			messages.reading,
		);
		resetCursor(process.stdout);

		try {
			regfile = await portReadRegisters(serialport, { regCount: 32 });
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
			head: ['bgWhite', 'black'],
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
			getRegHex(i),
		]);
		registerTableRight.push([
			`x${16 + i}`,
			getAbi(16 + i),
			getRegHex(16 + i),
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
}


(async () => {
	const serialPortAddress = 'COM10';
	const connectingMessage = `Connecting to processor at ${chalk.bgWhite.black(` ${serialPortAddress} `)}:`;

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
			'Check the riscv processor is connected and run the program again.',
		);
		process.stdout.write('\n');
		// eslint-disable-next-line unicorn/no-process-exit
		process.exit(1);
	}

	try {
		await mkdir(path.dirname(config.serialportLogPath));
	} catch (error) { }
	await writeFile(config.serialportLogPath, '');
	try {
		await mkdir(config.compilerFileDir);
	} catch (error) { }

	serialport.on('data', data => {
		writeFile(config.serialportLogPath, data, {
			flag: 'a+',
		});
	});
	serialport.pause();

	highlightedLine(
		process.stdout,
		chalk.bgGreen.black,
		`${connectingMessage} Success`,
	);
	process.stdout.write('\n');

	const rl = readline.createInterface({
		input: process.stdin,
		output: process.stdout
	});

	try {
		// await readEvalPrint({
		// 	instruction: 'nop',
		// 	serialport: serialport,
		// });
		for (; ;) {
			// eslint-disable-next-line no-await-in-loop
			await readEvalPrint({
				instruction: await (async () => {
					const text = await question(rl, `${config.prompt} `);
					return text.trim();
				})(),
				serialport: serialport,
			});
		}
	} catch (error) {
		console.error(error);
		rl.close();
		// eslint-disable-next-line unicorn/no-process-exit
		process.exit(1);
	}

})();

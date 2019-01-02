'use strict';
const readline = require('readline');
const util = require('util');
const childProcess = require('child_process');
const fs = require('fs');
const path = require('path');
const tempy = require('tempy');
const Debug = require('debug');
const chalk = require('chalk');
const SerialPort = require('serialport');
const Table = require('@harrysarson/cli-table');

const { portWrite, portReadRegisters } = require('./eval-instruction.mock');

const writeFile = util.promisify(fs.writeFile);
const readFile = util.promisify(fs.readFile);

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

const asPath = './compiler-files/a.S'
const elfPath = './compiler-files/a.elf'
const machPath = './compiler-files/machine-code'

const config = Object.freeze({
	prompt: '>',
	overwrite: false,
	makeCommand: 'make', // do not allow user to configure at runtime!
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
	tty.write(color(' '.repeat(tty.columns)));
	resetCursor(tty);
	tty.write(color(text));
};

const readEvalPrint = async ({ rl, serialport }) => {
	const input = await question(rl, `${config.prompt} `);
	const instruction = input.trim();

	const messages = {
		compiling: `Compiling ${chalk.bgWhite.black(` ${instruction} `)} to riscv machine code:`,
		writing: `Writing ${chalk.bgWhite.black(` ${instruction} `)} to to riscv processor:`,
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

	if (input === '') {
		return;
	}

	// Create assembly file:
	try {
		await writeFile(asPath, createAssembly(instruction));
	} catch (error) {
		console.error('Failed to write assembly to temporary file: ');
		throw error;
	}

	highlightedLine(
		process.stdout,
		chalk.bgYellow.black,
		messages.compiling,
	);
	resetCursor(process.stdout);

	// Await (new Promise(r => setTimeout(r, 1000)));

	try {
		const { stdout, stderr } = await exec(
			config.makeCommand,
			{
				cwd: __dirname,
			}
		);

		debug(`stdout:\n${stdout}`);
		debug(`stderr:\n${stderr}`);
	} catch (error) {
		highlightedLine(
			process.stdout,
			chalk.bgRed.white,
			`${messages.compiling} Error`,
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
		`${messages.compiling} Success`,
	);
	process.stdout.write('\n');

	let machineCode = Buffer.from([]);
	try {
		machineCode = await readFile(machPath);
	} catch (error) {
		console.error('Failed to read machine code from temporary file:');
		throw error;
	}

	const binaryInstruction = [...machineCode]
		.reverse()
		.map(x => x.toString(2).padStart(8, '0'))
		.join(' ');

	const inputTable = new Table({
		head: ['Instruction', 'Binary'],
		colors: true
	});

	inputTable.push([instruction, binaryInstruction]);

	process.stdout.write(`${inputTable}\n`);

	highlightedLine(
		process.stdout,
		chalk.bgYellow.black,
		messages.writing,
	);
	resetCursor(process.stdout);

	try {
		console.log("start write");
		portWrite(serialport, machineCode);
		console.log("end write");
	} catch (error) {
		logProcessorError(messages.writing, error);
		return;
	}

	highlightedLine(
		process.stdout,
		chalk.bgGreen.black,
		`${messages.writing} Success`,
	);
	process.stdout.write('\n');
	highlightedLine(
		process.stdout,
		chalk.bgYellow.black,
		messages.reading,
	);
	resetCursor(process.stdout);

	let regfile;
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

	const headers = ['Name', 'ABI', 'Value'];
	const registerTable = new Table({
		head: [...headers, '    ', ...headers, '    ', ...headers, '    ', ...headers],
		colors: false
	});
	for (let i = 0; i < 8; i++) {
		registerTable.push([
			`x${i}`,
			getAbi(i),
			regfile[i].toString(16).padStart(8, '0').toUpperCase(),
			'',
			`x${8 + i}`,
			getAbi(8 + i),
			regfile[8 + i].toString(16).padStart(8, '0').toUpperCase(),
			'',
			`x${16 + i}`,
			getAbi(16 + i),
			regfile[16 + i].toString(16).padStart(8, '0').toUpperCase(),
			'',
			`x${24 + i}`,
			getAbi(24 + i),
			regfile[24 + i].toString(16).padStart(8, '0').toUpperCase()
		]);
	}
	process.stdout.write('Updated registers:\n');
	process.stdout.write(`${registerTable}\n`);
};

(async () => {
	const serialPortAddress = 'COM10';
	const connectingMessage = `Connecting to processor at ${chalk.bgWhite.black(` ${serialPortAddress} `)}:`;

	highlightedLine(
		process.stdout,
		chalk.bgYellow.black,
		connectingMessage,
	);
	resetCursor(process.stdout);

	const serialport = await new Promise(resolve => {
		const res = new SerialPort(
			'COM10',
			{
				baudRate: 112500,
				highWaterMark: 0,
			},
			error => {
				if (error !== null) {
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
					// Process.exit(1);
				}
				resolve(res);
			}
		);
	});

	highlightedLine(
		process.stdout,
		chalk.bgGreen.black,
		`${connectingMessage} Success`,
	);
	process.stdout.write('\n');

	const rl = readline.createInterface({
		input: process.stdin,
		output: process.stdout,
		path: path.join(__dirname, 'readline-history.txt')
	});

	for (; ;) {
		try {
			// eslint-disable-next-line no-await-in-loop
			await readEvalPrint({ rl, serialport: serialport });
		} catch (error) {
			console.error(error);
			rl.close();
			// eslint-disable-next-line unicorn/no-process-exit
			process.exit(1);
		}
	}
})();

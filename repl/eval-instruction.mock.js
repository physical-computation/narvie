const assert = require('assert');
const util = require('util');
const crypto = require('crypto');

const portWrite = util.promisify((port, buffer, cb) => {
	assert(Buffer.isBuffer(buffer));
	cb();
});

const portReadRegisters = (_, {regCount}) => new Promise(resolve => {
	const wordSize = 4;
	const expectedBytes = wordSize * regCount;
	const regfile = new Uint32Array(regCount);
	const byteBuffer = crypto.randomBytes(expectedBytes);
	for (let i = 0; i < regCount; ++i) {
		regfile[i] = byteBuffer.readInt32LE(i * wordSize);
	}
	resolve(regfile);
});

module.exports = {
	portWrite,
	portReadRegisters
};

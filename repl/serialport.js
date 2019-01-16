const net = require('net');
const SerialPort = require('serialport');
const config = require('./config');

const connect = config.mockSerialPort ?
	() => new Promise((resolve, reject) => {
		const client = net.createConnection(
			{
				port: config.portForMockedSerialPort,
				host: 'localhost',
				writableHighWaterMark: 0
			},
			() => resolve(client));
		client.on('error', reject);
	}) :
	() => new Promise((resolve, reject) => {
		const res = new SerialPort(
			config.serialPortAddress,
			{
				baudRate: 112500,
				highWaterMark: 0
			},
			error => {
				if (error !== null) {
					reject(error);
				}
				resolve(res);
			}
		);
	});

module.exports = {
	connect
};

const net = require('net');
const config = require('./config');

const connect = () => new Promise((resolve, reject) => {
	const client = net.createConnection(
		{
			port: config.portForUart,
			host: 'localhost',
			writableHighWaterMark: 0
		},
		() => resolve(client));
	client.on('error', reject);
});

module.exports = {
	connect
};

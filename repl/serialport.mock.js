const net = require('net');

const connect = () => new Promise((resolve, reject) => {
    const client = net.createConnection(
        {
            port: 8001,
            host: 'localhost',
            writableHighWaterMark: 0,
        },
        () => resolve(client));
    client.on('error', reject);
});

module.exports = {
    connect: async () => {
        const c = await connect();
        // c.write(Buffer.from([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]));
        return c;
    },
};

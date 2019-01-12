const SerialPort = require('serialport');

const connect = () => new Promise((resolve, reject) => {
    const res = new SerialPort(
        'COM10',
        {
            baudRate: 112500,
            highWaterMark: 0,
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
    connect,
};

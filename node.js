
const zlib = require('zlib');
const Buffer = require('buffer').Buffer;
var string = "";
process.argv.forEach(function (val, index, array) {
	if(index == 2) {
		console.log("0" + zlib.deflateSync(Buffer.from(val,'base64')).toString('base64'));
	}
});

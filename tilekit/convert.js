var fs = require('fs');

var filename = process.argv[2];
var mapObj = JSON.parse(fs.readFileSync(filename, 'utf8'));

var mapData2D = (x, y) => mapObj.map.data[x + (y * mapObj.map.w)];

var outputFileBaseName = filename.split(".").slice(0,-1).join(".");

function doSection(x, y, w, h, getter) {
	var ind = 0;
	var sectionArray = new Array(w * h);
	for(var k = 0; k < h; k ++) {
		for(var i = 0; i < w; i ++) {
			sectionArray[ind++] = (getter(i+x, k+y)+255)%256;
		}
	}
	return sectionArray;
}

function saveSection(arr, name) {
	var b = new Buffer(arr.length);
	arr.forEach((item, ind) => b[ind] = item);
	fs.writeFile(name, b, {}, ()=>{console.log("saved " + name)});
}

for(var r = 0; r < mapObj.map.h; r+= 16) {
	for(var c = 0; c < mapObj.map.w; c+= 16) {
		saveSection(doSection(c, r, 16, 16, mapData2D), outputFileBaseName + "." + (c / 16) + "_" + (r / 16) + ".map");
	}
}
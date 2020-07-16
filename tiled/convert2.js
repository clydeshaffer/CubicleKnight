var fs = require('fs');

var filename = process.argv[2];

var fileLines = fs.readFileSync(filename, 'utf8').split("\n");

var map_h = fileLines.length;
var map_w = fileLines[0].split(",").length;
console.log("Width " + map_w + " and height " + map_h + " detected");

var mapData = fileLines.join(",").split(",").map((st)=>(parseInt(st.trim()))).map((cell) => (cell==-1) ? 0xEF : cell);

var mapData2D = (x, y) => mapData[x + (y * map_w)];

var outputFileBaseName = filename.split(".").slice(0,-1).join(".");

function doSection(x, y, w, h, getter) {
	var ind = 0;
	var sectionArray = new Array(w * h);
	for(var k = 0; k < h; k ++) {
		for(var i = 0; i < w; i ++) {
			sectionArray[ind++] = (getter(i+x, k+y))%256;
		}
	}
	return sectionArray;
}

function saveSection(arr, name) {
	var b = new Buffer(arr.length);
	arr.forEach((item, ind) => b[ind] = item);
	fs.writeFile(name, b, {}, ()=>{console.log("saved " + name)});
}

var sections = [];
for(var r = 0; r < map_h; r+= 16) {
	for(var c = 0; c < map_w; c+= 16) {
		sections.push({
			x:c,
			y:r,
			w:16,
			h:16
		});
	}
}

var doneSections = sections.map((sect)=>doSection(sect.x, sect.y, sect.w, sect.h, mapData2D));
var mergedSections = [].concat.apply([], doneSections);
saveSection(mergedSections, outputFileBaseName + "_merged.map");
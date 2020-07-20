var fs = require("fs");
var parseMidi = require("midi-file").parseMidi;

var filename = process.argv[2];
var outputFileBaseName = filename.split(".").slice(0,-1).join(".");

var inputFile = fs.readFileSync(filename);
var parsedInput = parseMidi(inputFile);

class GTNote {
    constructor(frames, noteNumber) {
        this.frames = frames;
        this.noteNumber = noteNumber;
        if(noteNumber == 0) {
            this.noteCode = 0;
        } else {
            var octaveNum = Math.floor(noteNumber/12)-1;
            var noteInOctave = noteNumber % 12;
            this.noteCode = (octaveNum * 16) + noteInOctave;
        }
    }
}

console.log(parsedInput.header);
var ticksPerBeat = parsedInput.header.ticksPerBeat;
var framesPerBeat = 32;
var ch1 = parsedInput.tracks[1];
var ch2 = parsedInput.tracks[2];

var lastTrackLength = 0;

function processChannel(ch, outname) {
    var maxDelta = 0;
    var eventTypes = {};
    var noteTracker = {};
    var totalTicks = 0;
    var chNotes = [];
    var chLength = 0;
    var lastOff = 0;
    var biggestPause = 0;
    var notesOn = 0;
    ch.forEach(function(evt, ind) {
        totalTicks += evt.deltaTime;
        if(evt.type == "noteOn") {
            notesOn++;
            var sinceLastOff = totalTicks - lastOff - 1;
            if(sinceLastOff > 0) {
                var restFrames = framesPerBeat * sinceLastOff / ticksPerBeat;
                while(restFrames > 255) {
                    chNotes.push(new GTNote(255, 0)); //insert a max length rest
                    restFrames -= 255;
                }
                chNotes.push(new GTNote(restFrames, 0)); //insert a rest
            }
            noteTracker[evt.noteNumber] = totalTicks;
        } else if(evt.type == "noteOff") {
            notesOn--;
            lastOff = totalTicks;
            var noteTicks = 1 + totalTicks - noteTracker[evt.noteNumber];
            var noteFrames = framesPerBeat * noteTicks / ticksPerBeat;
            if(noteFrames > 255) {
                console.log("TODO: add rest after unsupportedly long notes");
            }
            chNotes.push(new GTNote(noteFrames, evt.noteNumber));
        } else if(evt.type == "endOfTrack") {
            chLength = Math.round(framesPerBeat * totalTicks / ticksPerBeat);
        }
        if(evt.deltaTime > maxDelta) {
            maxDelta = evt.deltaTime;
        }
        eventTypes[evt.type] = (eventTypes[evt.type] | 0) + 1;
        if(notesOn > 1) {
            console.log("note collision! " + JSON.stringify({
                eventNum : ind,
                time : totalTicks
            }));
        }
    });

    console.log(chNotes.length)
    console.log("0x" + chLength.toString(16));

    if(chLength > lastTrackLength) {
        lastTrackLength = chLength;
    }

    var b = new Buffer(chNotes.length * 2);
    chNotes.forEach((item, ind) => {
        b[ind*2] = item.frames % 256;
        b[ind*2 + 1] = item.noteCode;
    });
    //fs.writeFileSync(outputFileBaseName + "_" + outname + ".gtm", b);
    //console.log("saved " + outputFileBaseName + "_" + outname + ".gtm");
    return b;
}

var ch1b = processChannel(ch1, "ch1");
var ch2b = processChannel(ch2, "ch2");

var headerLen = 4; //header is two bytes for total song length in frames, then two bytes for offset of channel 2
var ch1Offset = headerLen; //redundant to include this, its immediately after the header of known size
var ch2Offset = 1 + ch1Offset + ch1b.length;

function highByte(num) {
    return (num & 0xFF00) >> 8;
}

function lowByte(num) {
    return num & 0xFF;
}

function bwrap(num) {
    var wrapperbuf = new Uint8Array(1);
    wrapperbuf[0] = num;
    return wrapperbuf;
}

var stream = fs.createWriteStream(outputFileBaseName + "_alltracks.gtm");
stream.on("error", console.error);
stream.write(bwrap(lowByte(lastTrackLength)));
stream.write(bwrap(highByte(lastTrackLength)));
stream.write(bwrap(lowByte(ch2Offset)));
stream.write(bwrap(highByte(ch2Offset)));
stream.write(bwrap(0));
stream.write(ch1b);
stream.write(bwrap(0));
stream.write(ch2b);
stream.end();

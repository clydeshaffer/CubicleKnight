#Makefile for Cubicle Knight that updates assets from source files and assembles the ROM image

cubicle.gtr: music mapdata
	vasm6502_oldstyle -dotdir -wdc02 -Fbin cubicle.asm -o cubicle.gtr

music: music/cubeknight.mid
	cd music ; node midiconvert.js cubeknight.mid

mapdata: tiled/testmap1.csv
	cd tiled ;\
	node convert2.js testmap1.csv ;\
	zopfli --deflate testmap1_merged.map

flash: cubicle.gtr
	cd ../eepromProgrammer ; node index.js /dev/ttyUSB0 ../CubicleKnight/cubicle.gtr

emulate: cubicle.gtr
	../GameTankEmulator/GameTankEmulator cubicle.gtr

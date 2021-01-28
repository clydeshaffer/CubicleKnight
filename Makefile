#Makefile for Cubicle Knight that updates assets from source files and assembles the ROM image

cubicle.gtr: music mapdata sprites
	vasm6502_oldstyle -dotdir -wdc02 -Fbin cubicle.asm -o cubicle.gtr

music: music/cubeknight.mid music/stroll.mid
	cd music ; node midiconvert.js cubeknight.mid ;\
	zopfli --deflate cubeknight_alltracks.gtm ;\
	node midiconvert.js stroll.mid ;\
	zopfli --deflate stroll_alltracks.gtm ;\

mapdata: tiled/testmap1.csv
	cd tiled ;\
	node convert2.js testmap1.csv ;\
	zopfli --deflate testmap1_merged.map ;\
	node convert2.js end.csv ;\
	zopfli --deflate end_merged.map ;\
	node convert2.js title.csv ;\
	zopfli --deflate title_merged.map

sprites: sprites/gamesprites.bmp
	cd sprites ;\
	tail -c 16384 gamesprites.bmp > gamesprites.gtg ;\
	zopfli --deflate gamesprites.gtg

cubicle.gtr.scrambled: cubicle.gtr
	cd ../eepromProgrammer/scrambler ;\
	./scrambler ../../CubicleKnight/cubicle.gtr ../../CubicleKnight/cubicle.gtr.scrambled

flash: cubicle.gtr
	cd ../eepromProgrammer ; node index.js COM8 ../CubicleKnight/cubicle.gtr

flash_smd: cubicle.gtr.scrambled
	cd ../eepromProgrammer ; node index.js COM8 ../CubicleKnight/cubicle.gtr.scrambled

emulate: cubicle.gtr
	../GameTankEmulator/GameTankEmulator cubicle.gtr

temp = $10

FrameFlag = $34
GuyFrame = $35
GuyFallTimer = $36
GuyGroundState = $37

MusicIndex = $38
MusicFrame = $39

GamePad1BufferA = $3A
GamePad1BufferB = $3B
Old_GamePad1BufferA = $3C
Old_GamePad1BufferB = $3D
Dif_GamePad1BufferA = $3E
Dif_GamePad1BufferB = $3F

MusicPtrLow = $7E
MusicPtrHigh = $7F
Square1Octave = $80
Square1Volume = $81
Square1Decay = $82
NoteLength = $83
Square2LastNote = $84
Square2LastCtrl = $85

DMA_Flags_buffer = $90

current_tilemap = $C0 ; C1

displaylist_zp = $E0 ; E1, E2, E3
gameobject = $E4 ; E5
gameobject_updater = $E6; E7

inflate_zp = $F0 ; F1, F2, F3

inflate_data = $0200 ; until $04FD

PlayerData = $0500
Items = $0510

LoadedMapsFirstPage = $1000 ; through $2000
StartMap = $1900

SquareNote1 = $2000
SquareCtrl1 = $2001
SquareNote2 = $2002
SquareCtrl2 = $2003
NoiseCtrl = $2004
WaveNote = $2005
WaveCtrl = $2006
DMA_Flags = $2007

GamePad1 = $2008
GamePad2 = $2009

Wavetable = $3000
Framebuffer = $4000
DMA_VX = $4000
DMA_VY = $4001
DMA_GX = $4002
DMA_GY = $4003
DMA_WIDTH = $4004
DMA_HEIGHT = $4005
DMA_Status = $4006
DMA_Color = $4007
NoteDecay = 4

INPUT_MASK_UP		= %00001000
INPUT_MASK_DOWN		= %00000100
INPUT_MASK_LEFT		= %00000010
INPUT_MASK_RIGHT	= %00000001
INPUT_MASK_A		= %00010000
INPUT_MASK_B		= %00010000
INPUT_MASK_C		= %00100000
INPUT_MASK_START	= %00100000

W  = 0
H  = 1
GX = 2
GY = 3
VX = 4
VY = 5
SX = 6
SY = 7
EntData = 7

GuyAnimRow = $20 ;use as number not as address
GuyStanding = $0
GuyJumping = $40

;DMA flags are as follows
; 1   ->   DMA enabled
; 2   ->   Video out page
; 4   ->   NMI enabled
; 8   ->   G.RAM frame select
; 16  ->   V.RAM frame select
; 32  ->   CPU access bank select (High for V, low for G)
; 64  ->   Enable copy completion IRQ
; 128 ->   Transparency copy enabled (skips zeroes)

	.org $E000
Inflate:
	.incbin "inflate_e000_0200.obx"
RESET:
	LDX #$FF
	TXS
	SEI
	LDX #0
	LDY #0
StartupWait:
	DEX
	BNE StartupWait
	DEY
	BNE StartupWait


	;init audio registers to do nothing
	LDA #0
	STA SquareNote1
	STA SquareNote2
	LDA #$24
	STA WaveNote
	LDA #63
	STA SquareCtrl1
	STA SquareCtrl2
	STA NoiseCtrl
	STA WaveCtrl

	STZ MusicIndex
	STZ GuyFrame
	STZ GuyGroundState
	LDA #1
	STA GuyFallTimer

	;extract graphics to graphics RAM
	LDA #%00000000	;Activate lower page of VRAM/GRAM, CPU accesses GRAM, no IRQ, no transparency
	STA DMA_Flags
	
	;run INFLATE to decompress graphics
	LDA #<Sprites
	STA inflate_zp
	LDA #>Sprites
	STA inflate_zp+1
	LDA #<Framebuffer
	STA inflate_zp+2
	LDA #>Framebuffer
	STA inflate_zp+3
	JSR Inflate

	;decomprss map data
	LDA #<Maps
	STA inflate_zp
	LDA #>Maps
	STA inflate_zp+1
	LDA #<LoadedMapsFirstPage
	STA inflate_zp+2
	LDA #>LoadedMapsFirstPage
	STA inflate_zp+3
	JSR Inflate

	LDA #<StartMap
	STA current_tilemap
	LDA #>StartMap
	STA current_tilemap+1
	
	;Copy movables data into RAM
	LDA #<Movables
	STA displaylist_zp
	LDA #>Movables
	STA displaylist_zp+1
	LDA #<PlayerData
	STA displaylist_zp+2
	LDA #>PlayerData
	STA displaylist_zp+3
	LDY #0
	JSR CopyPage

	LDA #%01110101
	STA DMA_Flags_buffer

Forever:
	JSR AwaitVSync
	INC MusicFrame
	JSR UpdateInputs

	;Swap video and draw target buffers
	LDA DMA_Flags_buffer
	EOR #%00010010
	STA DMA_Flags_buffer
	STA DMA_Flags

	;draw current tilemap
	LDA DMA_Flags_buffer
	AND #%01111111
	STA DMA_Flags_buffer
	STA DMA_Flags
	JSR DrawTilemap

	STZ PlayerData+SX ;zero out X speed
	LDA #GuyStanding
	STA PlayerData+GX
	LDA GamePad2
	LDA GamePad1
	EOR #$FF
	STA GamePad1BufferA
	LDA GamePad1
	EOR #$FF
	STA GamePad1BufferB
	AND #(INPUT_MASK_LEFT | INPUT_MASK_RIGHT)
	BEQ SkipInput
	LDY GuyFrame
	LDX GuyWalkCycle, y
	STX PlayerData+GX
	LDY #$01
	STY PlayerData+SX ;set X speed of first movable
	LDY #GuyAnimRow
	STY PlayerData+GY ;select right-facing row
	CMP #INPUT_MASK_RIGHT
	BEQ SkipInput
	LDY #$FF
	STY PlayerData+SX ;set X speed of first movable
	LDY #(GuyAnimRow + $10)
	STY PlayerData+GY ;select left-facing row
SkipInput:
	
	INC GuyFrame
	LDY GuyFrame
	LDA GuyWalkCycle, y
	BPL AnimLoop
	STZ GuyFrame
AnimLoop:


	LDA PlayerData+SX
	BNE SkipAnimReset
	STZ GuyFrame
SkipAnimReset:

	DEC GuyFallTimer
	BNE SkipFallDecel
	LDA #$8
	STA GuyFallTimer
	INC PlayerData+SY
SkipFallDecel:

	LDA PlayerData+SY ;grab Y velocity
	CLC
	BMI *+4
	ADC #$0F ;add 16 to check bottom of sprite
	CLC
	ADC PlayerData+VY ; add Y coordinate
	BMI NextScreenVert
	AND #%01111000
	ASL
	STA temp
	LDA PlayerData+VX ;grab X coordinate
	CLC
	ADC #2
	LSR
	LSR				;coordinates are two 7 bit numbers
	LSR				;tilemap grid index is (Y & %01111000) << 4 | (X >> 3)
	ORA temp
	TAY
	LDA (current_tilemap), y
	STA temp
	LDA	#%11110000
	BIT temp
	BEQ HitGround

	LDA PlayerData+SY ;grab Y velocity
	CLC
	BMI *+4
	ADC #$0F ;add 16 to check bottom of sprite
	CLC
	ADC PlayerData+VY ; add Y coordinate
	BMI NextScreenVert
	AND #%01111000
	ASL
	STA temp
	LDA PlayerData+VX ;grab X coordinate
	CLC
	ADC #14
	LSR
	LSR				;coordinates are two 7 bit numbers
	LSR				;tilemap grid index is (Y & %01111000) << 4 | (X >> 3)
	ORA temp
	TAY
	LDA (current_tilemap), y
	STA temp
	LDA	#%11110000
	BIT temp
	BNE SkipHitGround
HitGround:
	LDA PlayerData+SY
	BMI *+6
	LDA #1
	STA GuyGroundState
	STZ PlayerData+SY
	LDA #$01
	STA GuyFallTimer
SkipHitGround:

	LDA PlayerData+SY
	BEQ SkipFallAnim
	STZ GuyFrame
	STZ GuyGroundState
	LDA #GuyJumping
	STA PlayerData+GX
SkipFallAnim:

	LDA GuyGroundState
	BEQ SkipJumpInputCheck
	LDA #INPUT_MASK_A
	BIT GamePad1BufferA
	BEQ SkipJumpInputCheck
	LDA #$FE
	STA PlayerData+SY
	STZ GuyGroundState
	LDA #$08
	STA GuyFallTimer
SkipJumpInputCheck:

	JMP DontNextScreenVert
NextScreenVert:
	CMP #$C0	
	BCS PrevScreenVert
	CLC
	LDA current_tilemap+1
	ADC #4
	STA current_tilemap+1
	STZ PlayerData+VY
	JSR SpawnItems
	JMP DontNextScreenVert
PrevScreenVert:
	DEC current_tilemap+1
	DEC current_tilemap+1
	DEC current_tilemap+1
	DEC current_tilemap+1
	LDA #(128 - 16)
	AND #$7F
	STA PlayerData+VY
	JSR SpawnItems
DontNextScreenVert:

	LDA PlayerData+VY ;grab Y coordinate
	AND #%01111000
	ASL
	STA temp
	CLC
	LDA PlayerData+SX ;grab X velocity
	BMI *+4 ; check left side if velocity negative
	ADC #12 ;add 16 to check right side
	CLC
	ADC #2
	CLC
	ADC PlayerData+VX
	BMI NextScreen
	LSR
	LSR				;coordinates are two 7 bit numbers
	LSR				;tilemap grid index is (Y & %01111000) << 4 | (X >> 3)
	ORA temp
	TAY
	LDA (current_tilemap), y
	STA temp
	LDA	#%11110000
	BIT temp
	BEQ HitWall
	
	LDA PlayerData+VY ;grab Y coordinate
	CLC
	ADC #$07
	AND #%01111000
	ASL
	STA temp
	CLC
	LDA PlayerData+SX ;grab X velocity
	BMI *+4 ; check left side if velocity negative
	ADC #12 ;add 16 to check right side
	CLC
	ADC #2
	CLC
	ADC PlayerData+VX
	BMI NextScreen
	LSR
	LSR				;coordinates are two 7 bit numbers
	LSR				;tilemap grid index is (Y & %01111000) << 4 | (X >> 3)
	ORA temp
	TAY
	LDA (current_tilemap), y
	STA temp
	LDA	#%11110000
	BIT temp
	BEQ HitWall

	LDA PlayerData+VY ;grab Y coordinate
	CLC
	ADC #$0F
	AND #%01111000
	ASL
	STA temp
	CLC
	LDA PlayerData+SX ;grab X velocity
	BMI *+4 ; check left side if velocity negative
	ADC #12 ;add 16 to check right side
	CLC
	ADC #2
	CLC
	ADC PlayerData+VX
	BMI NextScreen
	LSR
	LSR				;coordinates are two 7 bit numbers
	LSR				;tilemap grid index is (Y & %01111000) << 4 | (X >> 3)
	ORA temp
	TAY
	LDA (current_tilemap), y
	STA temp
	LDA	#%11110000
	BIT temp
	BNE SkipHitWall

HitWall:
	STZ PlayerData+SX
SkipHitWall:

	JMP DontNextScreen
NextScreen:
	CMP #$C0	
	BCS PrevScreen
	INC current_tilemap+1
	STZ PlayerData+VX
	JSR SpawnItems
	JMP DontNextScreen
PrevScreen:
	DEC current_tilemap+1
	LDA #(128 - 16)
	AND #$7F
	STA PlayerData+VX
	JSR SpawnItems
DontNextScreen:


	CLC
	LDA PlayerData+SX
	ADC PlayerData+VX
	;AND #$7F
	STA PlayerData+VX

	CLC
	LDA PlayerData+SY
	ADC PlayerData+VY
	;AND #$7F
	STA PlayerData+VY

	;Draw player object
	LDA DMA_Flags_buffer
	ORA #%10000000
	STA DMA_Flags_buffer
	STA DMA_Flags
	LDA #<PlayerData
	STA displaylist_zp
	LDA #>PlayerData
	STA displaylist_zp+1
	JSR DrawMovables

	LDA #<Items
	STA displaylist_zp
	LDA #>Items
	STA displaylist_zp+1
	JSR UpdateItems

	;Draw Nonstatic Objects
	LDA DMA_Flags_buffer
	ORA #%10000000
	STA DMA_Flags_buffer
	STA DMA_Flags
	LDA #<Items
	STA displaylist_zp
	LDA #>Items
	STA displaylist_zp+1
	JSR DrawMovables

	;Set border pixels to black
	LDA DMA_Flags_buffer
	AND #%01111111
	STA DMA_Flags_buffer
	STA DMA_Flags
	LDA #0
	STA DMA_VX
	LDA #0
	STA DMA_VY
	LDA #%10000000
	STA DMA_GX
	LDA #%00000000
	STA DMA_GY
	LDA #1
	STA DMA_WIDTH
	LDA #128
	STA DMA_HEIGHT
	
	LDA #$FF
	STA DMA_Color

	;start a DMA transfer
	LDA #1
	STA DMA_Status
	WAI


	;;;;;;;;;handle sounds
	LDA MusicFrame
	AND #$0F
	BNE HoldNote
	LDY MusicIndex
	LDA MusicData, y
	BNE *+4
	LDY #0
	LDA MusicData, y
	JSR SetFreqAndOctave
	STA SquareNote1
	LDA Square1Octave
	AND #7
	ORA #$10
	STA SquareCtrl1
	INY
	LDA MusicData, y
	JSR SetFreqAndOctave
	STA Square2LastNote
	STA SquareNote2
	LDA Square1Octave
	AND #7
	ORA #$10
	STA Square2LastCtrl
	STA SquareCtrl2
	INY
	STY MusicIndex
HoldNote:


	LDY #$3F
	LDA GuyFrame
	CMP #1
	BNE *+4
	LDY #$53
	STY NoiseCtrl

	LDA PlayerData+SY
	BPL NoJumpSound
	BNE JumpSound
NoJumpSound:
	LDA Square2LastNote
	STA SquareNote2
	LDA Square2LastCtrl
	STA SquareCtrl2
	JMP Forever
JumpSound:
	LDA PlayerData+SY
	ASL
	ASL
	ASL
	ORA GuyFallTimer
	EOR #$FF
	STA SquareNote2
	LDA #$14
	STA SquareCtrl2

	JMP Forever

DrawMovables:
	LDY #$0
	LDA (displaylist_zp), y ;load width
	BNE *+3
	RTS
	STA DMA_WIDTH
	INY
	LDA (displaylist_zp), y ;load height
	STA DMA_HEIGHT
	INY
	LDA (displaylist_zp), y ;load GX
	STA DMA_GX
	INY
	LDA (displaylist_zp), y ;load GY
	STA DMA_GY
	STA DMA_Color
	INY
	LDA (displaylist_zp), y ;load VX
	STA DMA_VX
	INY
	LDA (displaylist_zp), y ;load VY
	STA DMA_VY
	INY
	INY
	INY
	LDA #1
	STA DMA_Status
	WAI
	JMP DrawMovables+2	

UpdateItems:
	LDY #$0
	LDA (displaylist_zp), y ;load width
	BNE *+3
	RTS
	TYA
	CLC
	ADC displaylist_zp
	STA gameobject
	LDA displaylist_zp+1
	STA gameobject+1
	INY
	INY
	INY
	INY
	INY
	INY
	LDA (displaylist_zp), y ;load SX
	TAX
	LDA UpdateFuncs, x
	STA gameobject_updater
	LDA UpdateFuncs+1, x
	STA gameobject_updater+1
	PHY
	JMP (gameobject_updater)
UpdateDone:
	PLY
	INY
	INY
	JMP UpdateItems+2	

SpawnItems:
	LDY #$0
	LDA #<Items
	STA temp
	LDA #>Items
	STA temp+1
	LDA #<ItemTemplates
	STA temp+2
	LDA #>ItemTemplates
	STA temp+3 
	LDA #0
	STA (temp), y
SpawnItemsLoop:
	LDA (current_tilemap), y
	CMP #$F0
	BCC SpawnItemsNextTile
	AND #$0F
	ASL
	ASL
	ASL
	CLC
	ADC #<ItemTemplates
	STA temp+2

	TYA
	AND #$0F
	ASL
	ASL
	ASL
	STA temp+4 ;calc X coord
	TYA
	AND #$F0
	LSR
	STA temp+5 ;calc Y coord

	PHY
	LDY #0
	LDA (temp+2), y ;copy width
	STA (temp), y
	INY
	LDA (temp+2), y ;copy height
	STA (temp), y
	INY
	LDA (temp+2), y ;copy GX
	STA (temp), y
	INY
	LDA (temp+2), y ;copy GY
	STA (temp), y
	INY
	LDA temp+4 ; copy from calculated VX
	STA (temp), y
	INY
	LDA temp+5 ; copy from calculated VY
	STA (temp), y
	INY
	LDA (temp+2), y ;copy Fn (update function number)
	STA (temp), y
	INY
	LDA (temp+2), y ;copy item state byte
	STA (temp), y

	LDA temp
	CLC
	ADC #8
	STA temp
	PLY
SpawnItemsNextTile:
	INY
	BNE SpawnItemsLoop
	LDA #0
	STA (temp), y
	RTS

DrawTilemap:
	LDA #$08
	STA DMA_WIDTH
	STA DMA_HEIGHT
	LDY #$0
TilemapLoop:
	TYA
	AND #$0F
	ASL
	ASL
	ASL
	STA DMA_VX
	TYA
	AND #$F0
	LSR
	STA DMA_VY
	LDA (current_tilemap), y
	AND #$0F
	ASL
	ASL
	ASL
	STA DMA_GX
	LDA (current_tilemap), y
	AND #$F0
	LSR
	STA DMA_GY
	LDA #1
	STA DMA_Status
	WAI
	INY
	BNE TilemapLoop
	RTS

CopyPage:
	LDA (displaylist_zp), y
	STA (displaylist_zp+2), y
	INY
	BNE CopyPage
	RTS

AwaitVSync:
	LDA FrameFlag
	BNE	AwaitVSync
	LDA #1
	STA FrameFlag
	RTS

UpdateInputs:
	LDA GamePad1BufferA
	STA Old_GamePad1BufferA
	LDA GamePad1BufferB
	STA Old_GamePad1BufferB
	LDA GamePad2
	LDA GamePad1
	EOR #$FF
	STA GamePad1BufferA
	LDA GamePad1
	EOR #$FF
	STA GamePad1BufferB
	LDA Old_GamePad1BufferA
	EOR #$FF
	AND GamePad1BufferA
	STA Dif_GamePad1BufferA
	LDA Old_GamePad1BufferB
	EOR #$FF
	AND GamePad1BufferB
	STA Dif_GamePad1BufferB
	RTS

SetFreqAndOctave:
	;This routine takes the command byte from the Accumulator and sets
	;the Accumulator to the pitch byte and the Square1Octave var to the corresponding octave (0-3)
	;Uses the X register
	TAX
	AND #112
	LSR
	LSR
	LSR
	LSR
	STA $0
	LDA #7
	CLC
	SBC $0
	AND #7
	STA Square1Octave
	TXA
	AND #15
	TAX
	LDA NoteFreqs, x;
	RTS

LizardUpdate:
	LDX #$01
	LDY #EntData
	LDA (gameobject), y
	CLC
	ADC #1
	STA (gameobject), y

	AND #%01000000
	BNE *+4
	LDX #$FF
	STX temp
	
	LDA (gameobject), y
	AND #%00000010
	BEQ *+4
	STZ temp

	LDA (gameobject), y
	AND #%00111111
	BNE LizardAnim
	LDY #GY
	LDA (gameobject), y
	EOR #$10
	STA (gameobject), y

LizardAnim:
	LDY #EntData
	LDA (gameobject), y
	AND #%00001111
	BNE LizardMove
	LDY #GX
	LDA (gameobject), y
	EOR #$10
	STA (gameobject), y

LizardMove:
	LDY #VX
	LDA (gameobject), y
	CLC
	ADC temp
	STA (gameobject), y

	JMP UpdateDone
BurgerUpdate:
	JMP UpdateDone
KeyUpdate:
	JMP UpdateDone
NullUpdate:
	JMP UpdateDone

DisplayList:
	.incbin "displaylist_test_1.dat"

Movables:
	.db $0F, $10, GuyStanding, GuyAnimRow, $01, $00, $00, $20
	.db $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $00, $00, $00, $00, $00

GuyWalkCycle:
	.db $10, $10, $10, $20, $20, $20, $30, $30, $30, $FF

UpdateFuncs:         ;id#
	.dw LizardUpdate ;0
	.dw BurgerUpdate ;2
	.dw KeyUpdate    ;4
	.dw NullUpdate   ;6

ItemTemplates:
	;     W,   H,  GX,  GY,  VX,  VY,  Fn, Data
	.db $0F, $10, $00, $40, $40, $40, $00, $00 ; Lizard
	.db $0F, $10, $40, $40, $40, $40, $02, $00 ; Burger
	.db $0F, $10, $20, $50, $40, $40, $04, $00 ; Key
	.db $0F, $10, $20, $10, $40, $40, $06, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $06, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $06, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $06, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $06, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $06, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $06, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $06, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $06, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $06, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $06, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $06, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $06, $00 ; Error

Sprites:
	.incbin "gamesprites.gtg.deflate"

NoteFreqs:
	.db $D4, $C8, $BD, $B2, $A8, $9E, $95, $8D, $85, $7D, $76, $70, $00, $00, $00, $00

	.align 8
MusicData:
	.incbin "koro.dat"
Maps:
	.incbin "tilekit\testmap3_merged.map.deflate"

NMI:
	STZ FrameFlag
	RTI

	.org $FFFA
	.dw NMI
	.dw RESET
	.dw 0
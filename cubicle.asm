temp = $10

gameobject = $20

FrameFlag = $34
GuyFrame = $35
GuyFallTimer = $36
GuyGroundState = $37

GamePad1BufferA = $3A
GamePad1BufferB = $3B
Old_GamePad1BufferA = $3C
Old_GamePad1BufferB = $3D
Dif_GamePad1BufferA = $3E
Dif_GamePad1BufferB = $3F


OctaveBuf      = $50
MusicPtr_Ch1   = $51 ; 52
MusicPtr_Ch2   = $53 ; 54
MusicPtr_Ch3   = $55 ; 56
MusicPtr_Ch4   = $57 ; 58
MusicNext_Ch1  = $59
MusicNext_Ch2  = $5A
MusicNext_Ch3  = $5B
MusicNext_Ch4  = $5C
MusicEnvI_Ch1   = $5D
MusicEnvI_Ch2   = $5E
MusicEnvI_Ch3   = $5F
MusicEnvI_Ch4   = $60
MusicEnvP_Ch1 = $61 ; 62
MusicEnvP_Ch2 = $63 ; 64
MusicEnvP_Ch3 = $65 ; 66
MusicEnvP_Ch4 = $67 ; 68
MusicStart_Ch1 = $69 ; 6A
MusicStart_Ch2 = $6B ; 6C
MusicStart_Ch3 = $6D ; 6E
MusicStart_Ch4 = $6F ; 70
MusicTicksTotal = $71 ; 72
MusicTicksLeft = $73 ; 74

DMA_Flags_buffer = $90

sfx_ch1 = $B0;B1
sfx_ch2 = sfx_ch1+2
sfx_ch3 = sfx_ch2+2
sfx_ch4 = sfx_ch3+2

current_tilemap = $C0 ; C1

displaylist_zp = $E0 ; E1, E2, E3
gameobject_updater = $E6; E7

inflate_zp = $F0 ; F1, F2, F3

inflate_data = $0200 ; until $04FD

PlayerData = $0500
Items = $0510

LoadedMapsFirstPage = $1000 ; through $2000
StartMap = $1C00

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
FuncNum = 6
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
	LDA #$00
	STA WaveNote
	LDA #63
	STA SquareCtrl1
	STA SquareCtrl2
	STA NoiseCtrl
	STA WaveCtrl

	STZ GuyFrame
	STZ GuyGroundState
	LDA #1
	STA GuyFallTimer

	LDA #<InstrumEnv1
	STA MusicEnvP_Ch1
	LDA #>InstrumEnv1
	STA MusicEnvP_Ch1+1
	LDA #$01
	STA MusicNext_Ch1

	LDA #<InstrumEnv2
	STA MusicEnvP_Ch2
	LDA #>InstrumEnv2
	STA MusicEnvP_Ch2+1
	LDA #$01
	STA MusicNext_Ch2

	LDA #<MusicData_Ch1
	STA MusicStart_Ch1
	LDA #>MusicData_Ch1
	STA MusicStart_Ch1+1

	LDA #<MusicData_Ch2
	STA MusicStart_Ch2
	LDA #>MusicData_Ch2
	STA MusicStart_Ch2+1

	LDA MusicLength
	STA MusicTicksTotal
	LDA MusicLength+1
	STA MusicTicksTotal+1

	STZ MusicTicksLeft
	STZ MusicTicksLeft+1

	;Fill wavetable with zero
	LDA #<AudioSamples
	STA inflate_zp
	LDA #>AudioSamples
	STA inflate_zp+1
	LDA #<Wavetable
	STA inflate_zp+2
	LDA #>Wavetable
	STA inflate_zp+3
	JSR Inflate

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
	LDA #<SFX_None
	STA sfx_ch2
	LDA #>SFX_None
	STA sfx_ch2+1
	
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
	BPL *+5
	JMP NextScreenVert
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
	AND #%01111000
	ASL
	STA temp
	LDA PlayerData+VX ;grab X coordinate
	CLC
	ADC #8
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
	LDA #<SFX_Jump
	STA sfx_ch2
	LDA #>SFX_Jump
	STA sfx_ch2+1
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


	;;;;Do music

	LDA MusicTicksLeft
	BNE DontLoopMusic
	LDA MusicTicksLeft+1
	BEQ RestartMusic
	DEC MusicTicksLeft+1
DontLoopMusic:
	DEC MusicTicksLeft
	JMP Music_SetCh1

RestartMusic:
	LDA MusicTicksTotal
	STA MusicTicksLeft
	LDA MusicTicksTotal+1
	STA MusicTicksLeft+1
	LDA MusicStart_Ch1
	STA MusicPtr_Ch1
	LDA MusicStart_Ch1+1
	STA MusicPtr_Ch1+1
	LDA #1
	STA MusicNext_Ch1
	LDA MusicStart_Ch2
	STA MusicPtr_Ch2
	LDA MusicStart_Ch2+1
	STA MusicPtr_Ch2+1
	LDA #1
	STA MusicNext_Ch2

Music_SetCh1:
	INC MusicEnvI_Ch1
	DEC MusicNext_Ch1
	BNE HoldNote_Ch1
	STZ MusicEnvI_Ch1
	INC MusicPtr_Ch1
	BNE *+4
	INC MusicPtr_Ch1+1
	LDY #0
	LDA (MusicPtr_Ch1), y
	STA MusicNext_Ch1
	INC MusicPtr_Ch1
	BNE *+4
	INC MusicPtr_Ch1+1
HoldNote_Ch1:
	LDY #0
	LDA (MusicPtr_Ch1), y
	JSR SetFreqAndOctave
	STA temp ; stash F number for note
	LDY MusicEnvI_Ch1
	LDA (MusicEnvP_Ch1), y
	PHA
	AND #$0F ;First four bits are pitch bend envelope
	CLC
	ADC #$F8 ;Midpoint is $08
	CLC
	ADC temp
	STA SquareNote1
	PLA
	AND #$70
	LSR
	ORA OctaveBuf
	STA SquareCtrl1

Music_SetCh2:
	INC MusicEnvI_Ch2
	DEC MusicNext_Ch2
	BNE HoldNote_Ch2
	STZ MusicEnvI_Ch2
	INC MusicPtr_Ch2
	BNE *+4
	INC MusicPtr_Ch2+1
	LDY #0
	LDA (MusicPtr_Ch2), y
	STA MusicNext_Ch2
	INC MusicPtr_Ch2
	BNE *+4
	INC MusicPtr_Ch2+1
HoldNote_Ch2:
	LDY #0
	LDA (MusicPtr_Ch2), y
	JSR SetFreqAndOctave
	STA temp ; stash F number for note
	LDY MusicEnvI_Ch2
	LDA (MusicEnvP_Ch2), y
	PHA
	AND #$0F ;First four bits are pitch bend envelope
	CLC
	ADC #$F8 ;Midpoint is $08
	CLC
	ADC temp
	STA SquareNote2
	PLA
	AND #$70
	LSR
	ORA OctaveBuf
	STA SquareCtrl2

	;;;Walking sound
	LDY #$3F
	LDA GuyFrame
	CMP #1
	BNE *+4
	LDY #$53
	STY NoiseCtrl


	;;;SFX, channel 2
	LDY #0
	LDA (sfx_ch2), y
	BEQ NoSFX2
	STA SquareNote2
	INC sfx_ch2
	BNE *+4
	INC sfx_ch2+1
	LDA (sfx_ch2), y
	STA SquareCtrl2
	INC sfx_ch2
	BNE *+4
	INC sfx_ch2+1
	JMP Forever
NoSFX2:
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
	
	PHY
	;copy item data struct into working area
	STA gameobject+W
	INY
	LDA (displaylist_zp), y
	STA gameobject+H
	INY
	LDA (displaylist_zp), y
	STA gameobject+GX
	INY
	LDA (displaylist_zp), y
	STA gameobject+GY
	INY
	LDA (displaylist_zp), y
	STA gameobject+VX
	INY
	LDA (displaylist_zp), y
	STA gameobject+VY
	INY
	LDA (displaylist_zp), y
	STA gameobject+FuncNum
	INY
	LDA (displaylist_zp), y
	STA gameobject+EntData
	INY
	;run this item's update func
	LDX gameobject+FuncNum
	LDA UpdateFuncs, x
	STA gameobject_updater
	LDA UpdateFuncs+1, x
	STA gameobject_updater+1
	JMP (gameobject_updater)
UpdateDone:
	PLY
	;copy item data struct back from working area
	LDA gameobject+W
	STA (displaylist_zp), y
	INY
	LDA gameobject+H
	STA (displaylist_zp), y
	INY
	LDA gameobject+GX
	STA (displaylist_zp), y
	INY
	LDA gameobject+GY
	STA (displaylist_zp), y
	INY
	LDA gameobject+VX
	STA (displaylist_zp), y
	INY
	LDA gameobject+VY
	STA (displaylist_zp), y
	INY
	LDA gameobject+FuncNum
	STA (displaylist_zp), y
	INY
	LDA gameobject+EntData
	STA (displaylist_zp), y
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
	;the Accumulator to the pitch byte and the OctaveBuf var to the corresponding octave (0-3)
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
	STA OctaveBuf
	TXA
	AND #15
	TAX
	LDA NoteFreqs, x;
	RTS

LizardUpdate:
	INC gameobject+EntData

	LDX #$01
	LDA #%01000000
	BIT gameobject+EntData
	BNE *+4
	LDX #$FF
	STX temp
	
	LDA #%00000010
	BIT gameobject+EntData
	BEQ *+4
	STZ temp

	LDA #%00111111
	BIT gameobject+EntData
	BNE LizardAnim
	LDA gameobject+GY
	EOR #$10
	STA gameobject+GY

LizardAnim:
	LDA #%00001111
	BIT gameobject+EntData
	BNE LizardMove
	LDA gameobject+GX
	EOR #$10
	STA gameobject+GX

LizardMove:
	LDA gameobject+VX
	CLC
	ADC temp
	STA gameobject+VX

	JMP UpdateDone

BurgerUpdate:
	INC gameobject+EntData
	LDA gameobject+EntData
	AND #$1F

	TAX
	LDA BounceAnim, x
	CLC
	ADC gameobject+VY
	STA gameobject+VY

	JSR CheckIntersectPlayer
	BNE *+5
	JMP UpdateDone
	STZ gameobject+FuncNum
	LDA gameobject+GX
	ORA #$80
	STA gameobject+GX
	LDA #$FF
	STA gameobject+GY
	JSR RemoveMe
	JMP UpdateDone

KeyUpdate:
	JSR CheckIntersectPlayer
	BEQ *+4
	INC gameobject+VX
	JMP UpdateDone

SpringUpdate:
	LDX #$FC
	JSR CheckIntersectPlayer
	BNE *+5
	JMP UpdateDone
	STX PlayerData+SY
	LDA #<SFX_Boing
	STA sfx_ch2
	LDA #>SFX_Boing
	STA sfx_ch2+1


NullUpdate:
	JMP UpdateDone

RemoveMe:
	LDA gameobject+VX
	CLC
	ADC #2
	AND #$7F
	LSR
	LSR
	LSR
	STA temp
	LDA gameobject+VY
	CLC
	ADC #2
	AND #$78
	ASL
	ORA temp
	TAY
	LDA #$EF
	STA (current_tilemap), y
	RTS

CheckIntersectPlayer:
	LDA gameobject+VX
	SEC
	SBC PlayerData+VX
	JSR ABS
	CMP #$10
	BCS ReturnNoIntersect
	LDA gameobject+VY
	SEC
	SBC PlayerData+VY
	JSR ABS
	CMP #$10
	BCS ReturnNoIntersect
	LDA #1
	RTS
ReturnNoIntersect:
	LDA #0
	RTS

ABS:
	BPL *+7
	EOR #$FF
	CLC
	ADC #1
	RTS

BounceAnim:
	.db $FF, $00, $00, $00, $00, $00, $00, $00, $FF, $00, $00, $00, $00, $00, $00, $00
	.db $01, $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00

SFX:
SFX_None:
	.db $00
	;jump sound 27 frames long
	;down from C to A over 9 frames, then back up to A2 over 18 frames
	;D604 is 130.07Hz
	;FD04 is 110.10Hz
	;7E04 is 220.20Hz
SFX_Boing:
	.db $D6, $03, $DA, $03, $DE, $03, $E3, $03, $E7, $03, $EB, $03, $F0, $03, $F4, $03, $F8, $03
	.db $FD, $0B, $F6, $0B, $EF, $0B, $E8, $13, $E1, $13, $DA, $13, $D3, $1B, $CC, $1B, $C5, $1B
	.db $BE, $23, $B7, $23, $B0, $23, $A9, $2B, $A2, $2B, $9B, $2B, $94, $33, $8D, $33, $86, $33
	.db $7F, $33, $7F, $3B, $00, $00
SFX_Jump:
	.db $FD, $0A, $F6, $0A, $EF, $0A, $E8, $12, $E1, $12, $DA, $12, $D3, $1A, $CC, $1A, $C5, $1A
	.db $BE, $22, $B7, $22, $B0, $22, $A9, $2A, $A2, $2A, $9B, $2A, $94, $32, $8D, $32, $86, $32
	.db $7F, $32, $7F, $3A, $00, $00

Movables:
	.db $0F, $10, GuyStanding, GuyAnimRow, $10, $40, $00, $20
	.db $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $00, $00, $00, $00, $00

GuyWalkCycle:
	.db $10, $10, $10, $20, $20, $20, $30, $30, $30, $FF

UpdateFuncs:         ;id#
	.dw NullUpdate   ;0
	.dw LizardUpdate ;2
	.dw BurgerUpdate ;4
	.dw KeyUpdate    ;6
	.dw SpringUpdate ;8

ItemTemplates:
	;     W,   H,  GX,  GY,  VX,  VY,  Fn, Data
	.db $0F, $10, $00, $40, $40, $40, $02, $00 ; Lizard
	.db $0F, $10, $40, $40, $40, $40, $04, $00 ; Burger
	.db $0F, $10, $20, $50, $40, $40, $04, $08 ; Key
	.db $0F, $08, $30, $40, $40, $40, $08, $00 ; Spring
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error

Sprites:
	.incbin "gamesprites.gtg.deflate"

AudioSamples:
	.incbin "oopsAllZeroes.bin.deflate"

NoteFreqs:
	.db $D4, $C8, $BD, $B2, $A8, $9E, $95, $8D, $85, $7D, $76, $70, $00, $00, $00, $00


InstrumEnv1:
	.db $08, $08, $08, $08, $28
	.db $48, $68, $18, $38, $58
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
InstrumEnv2:
	.db $6F, $3C, $08, $08, $08
	.db $08, $08, $08, $18, $28
	.db $38, $48, $58, $68, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78
	.db $78, $78, $78, $78, $78

MusicLength: .dw $0200

;;A 8 A 5 1 5 a
;;A 8 A 5 1 5 a
;+a 0 1 1 a 0 0 8 a a 5 a
MusicData_Ch1:
	.db $00
	.db $10,$5A, $10,$58, $10,$5A, $10,$55, $10,$51, $08,$55, $28,$4A ;length 80
	.db $10,$5A, $10,$58, $10,$5A, $10,$55, $10,$51, $08,$55, $28,$4A ;length 80
	.db $10,$5A, $10,$60, $20,$61, $10,$61, $10,$5A, $20,$60, $10,$60
	.db $10,$58, $20,$5A, $10,$5A, $10,$55, $20,$5A ;length 100
;;a A 5 a A 5 a A 5 a 1 5 A
;;8 3 _8
;;6 1 _6
MusicData_Ch2:
	.db $00
	.db $08,$2A, $08,$31, $08,$35, $08,$3A, $10,$2A, $08,$3A, $08,$35, $10,$2A, $08,$3A, $08,$35, $10,$2A, $08,$3A, $08,$35 ; length 80
	.db $08,$2A, $08,$31, $08,$35, $08,$3A, $10,$2A, $08,$3A, $08,$35, $10,$2A, $08,$3A, $08,$35, $10,$2A, $08,$3A, $08,$35 ; length 80
	.db $08,$2A, $08,$31, $08,$35, $08,$3A, $10,$28, $08,$38, $08,$33, $10,$28, $08,$38, $08,$33, $10,$26, $08,$36, $08,$31 ; length 80
	.db $10,$26, $08,$36, $08,$31, $10,$2A, $08,$3A, $08,$35, $10,$2A, $08,$3A, $08,$35, $10,$2A, $08,$3A, $08,$35 ; length 80

Maps:
	.incbin "tiled\testmap1_merged.map.deflate"

NMI:
	STZ FrameFlag
	RTI

	.org $FFFA
	.dw NMI
	.dw RESET
	.dw 0
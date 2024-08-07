temp = $10

gameobject = $20

FrameFlag = $30
BGColor = $31
SharedSpringState = $32
HP_Remaining = $33
Keys_Collected = $34
GuyFrame = $35
GuyFallTimer = $36
GuyGroundState = $37
GuyPainTimer = $38
GameStarted = $39

GamePad1BufferA = $3A
GamePad1BufferB = $3B
Old_GamePad1BufferA = $3C
Old_GamePad1BufferB = $3D
Dif_GamePad1BufferA = $3E
Dif_GamePad1BufferB = $3F

PrintNum_X = $40
PrintNum_Y = $41
PrintNum_N = $42

FrameCounter0 = $43
FrameCounter1 = $44
FrameCounter2 = $45
IsCountingFrames = $46

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
Banking_Register_buffer = $91

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
LoadedMusicFirstPage = $0600

LoadedMapsFirstPage = $1000 ; through $2000
StartMap = $1C00

Audio_Reset = $2000
Audio_NMI = $2001
Banking_Register = $2005
Audio_Rate = $2006
DMA_Flags = $2007

GamePad1 = $2008
GamePad2 = $2009

VIA = $2800
ORB = 0
ORA = 1
DDRB = 2
DDRA = 3
T1C = 5
ACR = $B
PCR = $C
IFR = $D
IER = $E

ARAM = $3000
LFSR = $04 ;$05
FreqsH = $10
FreqsL = $20
Amplitudes = $30

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

Ch1Offset = 4

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

	;This section initializes the banking and sets the GRAM "middle bits" to zero
	STZ Banking_Register
	LDA #$FF
	STA BGColor
	LDA #%11111101
	STA DMA_Flags
	LDA #$7F
	STA DMA_WIDTH
	STA DMA_HEIGHT
	STZ DMA_VX
	STZ DMA_VY
	STZ DMA_GX
	STZ DMA_GY
	LDA BGColor
	STA DMA_Color
	LDA #1
	STA DMA_Status
	WAI

	STZ FrameFlag

	;make sure audio coprocessor is stopped
	LDA #$7F
	STA Audio_Rate


	STZ GameStarted
	STZ HP_Remaining
	STZ Keys_Collected
	STZ GuyFrame
	STZ GuyGroundState
	STZ GuyPainTimer
	STZ SharedSpringState
	LDA #1
	STA GuyFallTimer

	STZ GamePad1BufferA
	STZ GamePad1BufferB

	STZ MusicEnvI_Ch1
	STZ MusicEnvI_Ch2
	STZ MusicEnvI_Ch3
	STZ MusicEnvI_Ch4

	LDA #<MusicPkg_Main
	STA inflate_zp
	LDA #>MusicPkg_Main
	STA inflate_zp+1
	JSR LoadMusic

	;Unpack Audio Coprocessor Program
	LDA #<ACProg
	STA inflate_zp
	LDA #>ACProg
	STA inflate_zp+1
	LDA #<ARAM
	STA inflate_zp+2
	LDA #>ARAM
	STA inflate_zp+3
	JSR Inflate
	STZ Audio_Reset

	;enable Audio RDY
	LDA #$FF
	STA Audio_Rate

	;extract graphics to graphics RAM
	LDA #%10000000	;Activate lower page of VRAM/GRAM, CPU accesses GRAM, no IRQ, no transparency
	STA DMA_Flags
	STZ Banking_Register
	
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

	LDA #<StartMap
	STA current_tilemap
	LDA #>StartMap
	STA current_tilemap+1
	LDA #<SFX_None
	STA sfx_ch1
	STA sfx_ch2
	STA sfx_ch3
	STA sfx_ch4
	LDA #>SFX_None
	STA sfx_ch1+1
	STA sfx_ch2+1
	STA sfx_ch3+1
	STA sfx_ch4+1

	LDA #<TitleScreen
	STA inflate_zp
	LDA #>TitleScreen
	STA inflate_zp+1
	LDA current_tilemap
	STA inflate_zp+2
	LDA current_tilemap+1
	STA inflate_zp+3
	JSR Inflate
	
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

	; DMA | VNMI | AUTOTILE | CPUVRAM | IRQ | OPAQUE
	LDA #%11110101
	STA DMA_Flags_buffer
	; HIGHVRAM
	LDA #%00001000
	STA Banking_Register_buffer

	STA IsCountingFrames

Forever:
	JSR AwaitVSync
	JSR UpdateInputs
	LDA IsCountingFrames
	BEQ SkipFrameCount
	SED
	CLC
	LDA #1
	ADC FrameCounter0
	STA FrameCounter0
	LDA #0
	ADC FrameCounter1
	STA FrameCounter1
	LDA #0
	ADC FrameCounter2
	STA FrameCounter2
	CLD
SkipFrameCount:

	LDA GameStarted
	BNE GameAlreadyStarted
	LDA #INPUT_MASK_START
	BIT GamePad1BufferA
	BEQ GameAlreadyStarted
	LDA #1
	STA GameStarted
	LDA #3
	STA HP_Remaining
	STZ FrameCounter0
	STZ FrameCounter1
	STZ FrameCounter2
	LDA #1
	STA IsCountingFrames
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
GameAlreadyStarted:

	;Swap video and draw target buffers
	LDA DMA_Flags_buffer
	EOR #%00000010 ; flip VIDOUT
	STA DMA_Flags_buffer
	STA DMA_Flags
	LDA Banking_Register_buffer
	EOR #%00001000 ; flip VRAM page
	STA Banking_Register_buffer
	STA Banking_Register

	LDA DMA_Flags_buffer
	ORA #%10001000 ;disable transparency, enable colorfill
	STA DMA_Flags_buffer
	STA DMA_Flags
	JSR ClearScreenBGColor

	;draw current tilemap
	LDA DMA_Flags_buffer
	AND #%01110111 ;enable transparency, disable colorfill
	STA DMA_Flags_buffer
	STA DMA_Flags
	JSR DrawTilemap

	LDA GameStarted
	BNE *+5
	JMP SkipDrawGuy
	LDA HP_Remaining
	BNE PostDeathExplosionSpawn
	LDA GuyPainTimer
	CMP #$FF
	BNE PostDeathExplosionSpawn
	JSR SpawnItems
PostDeathExplosionSpawn:

	LDA GuyPainTimer
	BNE SkipAnimReset
	STZ PlayerData+SX ;zero out X speed
	LDA #GuyStanding
	STA PlayerData+GX
	LDA GamePad1BufferB
	AND #(INPUT_MASK_LEFT | INPUT_MASK_RIGHT)
	BEQ SkipInput
	LDY GuyFrame
	LDX GuyWalkCycle, y
	STX PlayerData+GX
	LDY #$01
	STY PlayerData+SX ;set X speed of first movable
	LDY #GuyAnimRow
	STY PlayerData+GY ;select right-facing row
	LDY #$10
	STY PlayerData+W
	CMP #INPUT_MASK_RIGHT
	BEQ SkipInput
	LDY #$FF
	STY PlayerData+SX ;set X speed of first movable
	LDY #GuyAnimRow
	STY PlayerData+GY ;select left-facing row
	LDY #$90
	STY PlayerData+W
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

	LDA HP_Remaining
	BEQ SkipDrawGuy

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

	LDA GuyPainTimer
	AND #1
	BNE SkipDrawGuy
	;Draw player object
	LDA DMA_Flags_buffer
	AND #$7F ; Set Transparent
	STA DMA_Flags_buffer
	STA DMA_Flags
	LDA #<PlayerData
	STA displaylist_zp
	LDA #>PlayerData
	STA displaylist_zp+1
	JSR DrawMovables

SkipDrawGuy:
	LDA GuyPainTimer
	BEQ *+4
	DEC GuyPainTimer

	LDA #<Items
	STA displaylist_zp
	LDA #>Items
	STA displaylist_zp+1
	JSR UpdateItems

	;Draw Nonstatic Objects
	LDA DMA_Flags_buffer
	AND #$7F ; Set Transparent
	STA DMA_Flags_buffer
	STA DMA_Flags
	LDA #<Items
	STA displaylist_zp
	LDA #>Items
	STA displaylist_zp+1
	JSR DrawMovables

	JSR DrawUI

	;Set left border pixels to black
	LDA DMA_Flags_buffer
	ORA #%10001000 ;disable transparency, enable colorfill
	STA DMA_Flags_buffer
	STA DMA_Flags
	LDA #0
	STA DMA_VX
	LDA #0
	STA DMA_VY
	STZ DMA_GX
	STZ DMA_GY
	LDA #1
	STA DMA_WIDTH
	LDA #127
	STA DMA_HEIGHT
	
	LDA #$FF
	STA DMA_Color

	;start a DMA transfer
	LDA #1
	STA DMA_Status
	WAI

	;Set right border pixels to black
	LDA DMA_Flags_buffer
	ORA #%10001000 ;disable transparency, enable colorfill
	STA DMA_Flags_buffer
	STA DMA_Flags
	LDA #127
	STA DMA_VX
	LDA #0
	STA DMA_VY
	STZ DMA_GX
	STZ DMA_GY
	LDA #2
	STA DMA_WIDTH
	LDA #127
	STA DMA_HEIGHT
	
	LDA #$FF
	STA DMA_Color

	;start a DMA transfer
	LDA #1
	STA DMA_Status
	WAI

DoMusic:

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
	LDY MusicEnvI_Ch1
	LDA (MusicEnvP_Ch1), y
	AND #$80
	BNE *+4
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
	BEQ Rest_Ch1
	JSR SetFreqAndOctave
	STA temp ; stash pitch low byte
	LDY MusicEnvI_Ch1
	LDA (MusicEnvP_Ch1), y
	PHA
	AND #$0F ;First four bits are pitch bend envelope
	CLC
	ADC #$F8 ;Midpoint is $08
	CLC
	ADC temp
	STA ARAM+FreqsL+0
	LDA OctaveBuf
	STA ARAM+FreqsH+0
	PLA
	AND #$70
	LSR
	STA ARAM+Amplitudes+0

	JMP Music_SetCh2
Rest_Ch1:
	STZ ARAM+FreqsL+0
	STZ ARAM+FreqsH+0
	STZ ARAM+Amplitudes+0

Music_SetCh2:
	LDY MusicEnvI_Ch2
	LDA (MusicEnvP_Ch2), y
	AND #$80
	BNE *+4
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
	BEQ Rest_Ch2
	JSR SetFreqAndOctave
	STA temp ; stash pitch low byte
	LDY MusicEnvI_Ch2
	LDA (MusicEnvP_Ch2), y
	PHA
	AND #$0F ;First four bits are pitch bend envelope
	CLC
	ADC #$F8 ;Midpoint is $08
	CLC
	ADC temp
	STA ARAM+FreqsL+1
	LDA OctaveBuf
	STA ARAM+FreqsH+1
	PLA
	AND #$70
	LSR
	STA ARAM+Amplitudes+1

	JMP Music_SetCh3
Rest_Ch2:
	STZ ARAM+FreqsL+1
	STZ ARAM+FreqsH+1
	STZ ARAM+Amplitudes+1

;Add jump labels in case I implement 4ch music in this game
Music_SetCh3:
Music_SetCh4:
MusicDone:

	;;;Walking sound
	LDY #$FF
	LDA GuyFrame
	CMP #1
	BNE *+4
	LDY #$30
	STY ARAM+Amplitudes+2
	LDA MusicTicksLeft
	STA ARAM+FreqsL+2
	ORA #$80
	STA ARAM+FreqsH+2

	;not used, commenting out to save space for now
	;;;SFX, channel 1
	;LDY #0
	;LDA (sfx_ch1), y
	;BEQ NoSFX1
	;STA SquareNote1
	;INC sfx_ch1
	;BNE *+4
	;INC sfx_ch1+1
	;LDA (sfx_ch1), y
	;STA SquareCtrl1
	;INC sfx_ch1
	;BNE *+4
	;INC sfx_ch1+1
	;JMP Forever
NoSFX1:

	;;;SFX, channel 2
	LDY #0
	LDA (sfx_ch2), y
	BEQ NoSFX2
	EOR #$FF
	STA ARAM+FreqsL+1
	INC sfx_ch2
	BNE *+4
	INC sfx_ch2+1
	LDA (sfx_ch2), y
	AND #%00111000
	LSR
	LSR
	LSR
	STA ARAM+FreqsH+1
	LDA (sfx_ch2), y
	AND #%00000111
	ASL
	ASL
	ASL
	ASL
	ASL
	STA ARAM+Amplitudes+1
	INC sfx_ch2
	BNE *+4
	INC sfx_ch2+1
	JMP Forever
NoSFX2:

	;;;SFX, channel 3
	LDY #0
	LDA (sfx_ch3), y
	BEQ NoSFX3
	STZ ARAM+FreqsL+2
	AND #%00111000
	EOR #$3F
	STA ARAM+FreqsH+2
	LDA (sfx_ch3), y
	AND #%00000111
	ASL
	ASL
	ASL
	ASL
	ASL
	EOR #$FF
	STA ARAM+Amplitudes+2
	INC sfx_ch3
	BNE *+4
	INC sfx_ch3+1
	JMP Forever
NoSFX3:


	JMP Forever ;;;;;actual bottom of frame update loop

DrawUI:
	LDY HP_Remaining
	BEQ DrawKeys
DrawHP:
	LDA #$07
	STA DMA_WIDTH
	LDA #$08
	STA DMA_HEIGHT
	LDA #$60
	STA DMA_GX
	LDA #$70
	STA DMA_GY
	TYA
	ASL
	ASL
	ASL
	CLC
	ADC #252
	STA DMA_VX
	LDA #$08
	STA DMA_VY
	LDA #1
	STA DMA_Status
	WAI
	DEY
	BNE DrawHP

DrawKeys:
	LDY Keys_Collected
	BNE DrawKeys+5
	RTS

	LDA #$07
	STA DMA_WIDTH
	LDA #$08
	STA DMA_HEIGHT
	LDA #$68
	STA DMA_GX
	LDA #$70
	STA DMA_GY
	TYA
	ASL
	ASL
	ASL
	CLC
	ADC #252
	STA DMA_VX
	LDA #$10
	STA DMA_VY
	LDA #1
	STA DMA_Status
	WAI
	DEY
	BNE DrawKeys+5
	RTS


DrawMovables:
	LDY #$0
	LDA (displaylist_zp), y ;load width
	BNE *+3
	RTS
	STA DMA_WIDTH
	STA temp
	INY
	LDA (displaylist_zp), y ;load height
	STA DMA_HEIGHT
	INY
	LDA (displaylist_zp), y ;load GX
	LDX temp
	BPL SkipFlip
	CLC
	ADC temp
	SEC
	SBC #$1
	EOR #$7F
SkipFlip:
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


ClearScreenBGColor:
	LDA #$7F
	STA DMA_WIDTH
	STA DMA_HEIGHT
	STZ DMA_VX
	STZ DMA_VY
	STZ DMA_GX
	STZ DMA_GY
	LDA BGColor
	STA DMA_Color
	LDA #1
	STA DMA_Status
	WAI
	RTS

DrawTilemap:
	LDA #$08
	STA DMA_WIDTH
	LDA #$08
	STA DMA_HEIGHT
	LDY #$0
TilemapLoop:
	LDA (current_tilemap), y
	CMP #$EF
	BCS SkipTile
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
SkipTile:
	INY
	BNE TilemapLoop
	RTS

LoadMusic:

	LDA #<LoadedMusicFirstPage
	STA inflate_zp+2
	LDA #>LoadedMusicFirstPage
	STA inflate_zp+3
	JSR Inflate

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

	;;Music pack header goes
	;LByte HByte - song length
	;LByte HByte - add to LoadedMusicFirstPage to get ch2 data

	LDA #<(LoadedMusicFirstPage+4)
	STA MusicStart_Ch1
	LDA #>(LoadedMusicFirstPage+4)
	STA MusicStart_Ch1+1

	LDA #<LoadedMusicFirstPage
	CLC
	ADC LoadedMusicFirstPage+2 ;assuming here that the low byte of LoadedMusicFirstPage ptr is 00
	STA MusicStart_Ch2
	LDA #>LoadedMusicFirstPage
	CLC
	ADC LoadedMusicFirstPage+3
	STA MusicStart_Ch2+1

	LDA LoadedMusicFirstPage
	STA MusicTicksTotal
	LDA LoadedMusicFirstPage+1
	STA MusicTicksTotal+1

	STZ MusicTicksLeft
	STZ MusicTicksLeft+1
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
	;the Accumulator to the pitch low byte and the OctaveBuf var to the corresponding pitch high byte
	;Uses the X and Y registers
	STA temp
	AND #$70
	LSR
	LSR
	LSR
	LSR
	TAX
	LDA TwelveTimesTable, x
	STA temp+1
	LDA temp
	AND #$0F
	CLC
	ADC temp+1
	ASL
	TAX
	LDA Pitches+2, x
	STA OctaveBuf
	LDA Pitches+3, x
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
	LDA gameobject+W
	EOR #$80
	STA gameobject+W

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

	JSR DoObstacleCheck
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
	ORA #$70
	STA gameobject+GX
	LDA #$70
	STA gameobject+GY
	LDA #<SFX_Burger
	STA sfx_ch2
	LDA #>SFX_Burger
	STA sfx_ch2+1
	JSR RemoveMe
	INC HP_Remaining
	JMP UpdateDone

KeyUpdate:
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
	ORA #$70
	STA gameobject+GX
	LDA #$70
	STA gameobject+GY
	LDA #<SFX_Key
	STA sfx_ch2
	LDA #>SFX_Key
	STA sfx_ch2+1
	JSR RemoveMe
	INC Keys_Collected
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
	;set fractional part of bounce speed
	CLC
	LDA SharedSpringState
	ADC #$02
	AND #$07
	STA SharedSpringState
	ORA #$01
	STA GuyFallTimer
	JMP UpdateDone

SpikeUpdate:
	INC gameobject+EntData

	LDX #$FF
	LDA #%01000000
	BIT gameobject+EntData
	BNE *+4
	LDX #$01
	STX temp
	
	LDA #%00000010
	BIT gameobject+EntData
	BEQ *+4
	STZ temp
	LDA gameobject+VY
	CLC
	ADC temp
	STA gameobject+VY

	JSR DoObstacleCheck

	JMP UpdateDone

FireUpdate:
	INC gameobject+EntData

	LDX #$FF
	LDA #%00000100
	BIT gameobject+EntData
	BNE *+4
	LDX #$01
	STX temp
	
	LDA #%00000010
	BIT gameobject+EntData
	BEQ *+4
	STZ temp
	LDA gameobject+VX
	CLC
	ADC temp
	STA gameobject+VX

	JSR DoObstacleCheck
	BEQ *+7
	LDA #$FD
	STA PlayerData+SY

	JMP UpdateDone

DoorUpdate:
	LDA gameobject+EntData
	BNE DoorOnce
	CLC
	LDA gameobject+VX
	ADC #$08
	STA gameobject+VX
	INC gameobject+EntData
DoorOnce:

	LDA gameobject+VX
	CLC
	ADC #2
	AND #$7F
	LSR
	LSR
	LSR
	STA temp+2
	LDA gameobject+VY
	CLC
	ADC #2
	AND #$78
	ASL
	ORA temp+2
	STA temp+2

	
	JSR CheckIntersectPlayer
	BNE DoorDetect
	LDA #<Str_DoorBlank
	STA temp
	LDA #>Str_DoorBlank
	STA temp+1
	BRA NoDoorDetect
DoorDetect:
	LDA Keys_Collected
	BNE DoorHaveKey
	LDA #<Str_NeedKey
	STA temp
	LDA #>Str_NeedKey
	STA temp+1
	BRA NoDoorDetect
DoorHaveKey:
	STZ gameobject+FuncNum
	JSR LoadWinScreen
	JMP UpdateDone
NoDoorDetect:


	LDA current_tilemap
	CLC
	ADC #204
	CLC
	ADC temp+2
	STA temp+2
	LDA current_tilemap+1
	STA temp+3
	JSR PrintStr
	JMP UpdateDone
	
ExplosionUpdate:
	INC gameobject+EntData
	LDA gameobject+EntData
	CMP #15
	BEQ ExpFrame2
	CMP #30
	BEQ ExpFrame3
	CMP #45
	BEQ ExpDone
	JMP UpdateDone
ExpFrame2:
	LDA gameobject+VX
	SEC
	SBC #4
	STA gameobject+VX
	LDA gameobject+VY
	SEC
	SBC #4
	STA gameobject+VY
	LDA #88
	STA gameobject+GX

	LDA #15
	STA gameobject+W
	LDA #16
	STA gameobject+H
	JMP UpdateDone
ExpFrame3:
	LDA gameobject+VX
	SEC
	SBC #4
	STA gameobject+VX
	LDA gameobject+VY
	SEC
	SBC #4
	STA gameobject+VY
	LDA #104
	STA gameobject+GX
	LDA #23
	STA gameobject+W
	LDA #24
	STA gameobject+H
	JMP UpdateDone
ExpDone:
	LDA #$FF
	STA gameobject+GX
	STA gameobject+GY
	STZ gameobject+FuncNum
	LDA HP_Remaining
	BNE *+5
	JMP RESET
	JMP UpdateDone


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

DoObstacleCheck:
	LDA HP_Remaining
	BEQ DidntHitObstacle
	LDA GuyPainTimer
	BNE DidntHitObstacle
	JSR CheckIntersectPlayer
	BEQ DidntHitObstacle
	LDA #$10
	STA GuyPainTimer
	LDA #<SFX_Pain
	STA sfx_ch3
	LDA #>SFX_Pain
	STA sfx_ch3+1
	DEC HP_Remaining
	BNE *+5
	JSR MakeExplosion

	LDA PlayerData+VX
	CMP gameobject+VX
	BCC *+6;branch if PlayerVX < GameObjectVX
	LDA #$01
	BRA *+4
	LDA #$FF
	STA PlayerData+SX

	LDA PlayerData+VY
	CMP gameobject+VY
	BCC *+6;branch if PlayerVY < GameObjectVY
	LDA #$01
	BRA *+4
	LDA #$FF
	STA PlayerData+SY
	LDA #1
	RTS
DidntHitObstacle:
	LDA #0
	RTS

CheckIntersectPlayer:
	LDA gameobject+VX
	SEC
	SBC PlayerData+VX
	JSR ABS
	CMP #$0E
	BCS ReturnNoIntersect
	LDA gameobject+VY
	SEC
	SBC PlayerData+VY
	JSR ABS
	CMP #$0E
	BCS ReturnNoIntersect
	LDA #1
	RTS
ReturnNoIntersect:
	LDA #0
	RTS

MakeExplosion:
	LDA #<SFX_Explosion
	STA sfx_ch3
	LDA #>SFX_Explosion
	STA sfx_ch3+1
	LDA #$FF
	STA GuyPainTimer
	LDA PlayerData+VX
	CLC
	ADC #2
	AND #$7F
	LSR
	LSR
	LSR
	STA temp+2
	LDA PlayerData+VY
	CLC
	ADC #2
	AND #$78
	ASL
	ORA temp+2
	TAY
	LDA #$F6 ; explosion spawning tile
	STA (current_tilemap), y
	RTS

LoadWinScreen:
	STZ IsCountingFrames
	STZ HP_Remaining
	STZ Keys_Collected

	LDA #$22
	STA BGColor

	LDA #<WinScreen
	STA inflate_zp
	LDA #>WinScreen
	STA inflate_zp+1
	LDA current_tilemap
	STA inflate_zp+2
	LDA current_tilemap+1
	STA inflate_zp+3
	JSR Inflate

	LDA #<MusicPkg_Win
	STA inflate_zp
	LDA #>MusicPkg_Win
	STA inflate_zp+1
	JSR LoadMusic

	LDY #$E9
	LDX FrameCounter2
	JSR PutCounter
	LDX FrameCounter1
	JSR PutCounter
	LDX FrameCounter0
	JSR PutCounter

	RTS

PutCounter:
	CLC
	TXA
	BEQ SkipHighCountDigits
	LSR
	LSR
	LSR
	LSR
	ADC #192
	STA (current_tilemap), y
	INY
	TXA
	CLC
	AND #$0F
	ADC #192
	STA (current_tilemap), y
	INY
SkipHighCountDigits:
	RTS

;prints a null terminated bytestring (temp) to address (temp+2)
PrintStr:
	LDY #0
	LDA (temp), y
	BEQ StringDone
	STA (temp+2), y
	INY
	BRA PrintStr+2
StringDone:
	RTS

ABS:
	BPL *+7
	EOR #$FF
	CLC
	ADC #1
	RTS

UpdateFuncs:         ;id#
	.dw NullUpdate   ;0
	.dw LizardUpdate ;2
	.dw BurgerUpdate ;4
	.dw KeyUpdate    ;6
	.dw SpringUpdate ;8
	.dw SpikeUpdate  ;A
	.dw DoorUpdate	 ;C
	.dw ExplosionUpdate ;E
	.dw FireUpdate ;10
	
	.align 8
ItemTemplates:
	;     W,   H,  GX,  GY,  VX,  VY,  Fn, Data
	.db $10, $10, $00, $40, $40, $40, $02, $00 ; Lizard
	.db $10, $10, $40, $40, $40, $40, $04, $00 ; Burger
	.db $10, $10, $20, $50, $40, $40, $06, $08 ; Key
	.db $10, $08, $30, $40, $40, $40, $08, $00 ; Spring
	.db $10, $10, $20, $40, $40, $40, $0A, $00 ; Spikeball
	.db $10, $10, $70, $70, $40, $40, $0C, $00 ; Door
	.db $08, $08, $50, $40, $40, $40, $0E, $00 ; Explosion
	.db $10, $10, $40, $50, $40, $40, $10, $00 ; Fire
	.db $10, $10, $50, $50, $40, $40, $10, $00 ; GroundSpikes
	.db $90, $10, $00, $50, $40, $40, $02, $40 ; Lizard2
	.db $10, $10, $60, $20, $40, $40, $02, $40 ; Cat?
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error
	.db $0F, $10, $20, $10, $40, $40, $00, $00 ; Error

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
SFX_Burger:
	.db $D6, $53, $DA, $33, $DE, $13, $E3, $43, $E7, $23, $EB, $13, $F0, $33, $F4, $13, $F8, $03, $00
SFX_Key:
	.db $3F,$01, $3F,$11, $3F,$21, $3F,$2B, $40,$01, $40,$11, $3F,$01, $3F,$11, $3F,$21, $3F,$2B, $3F,$31, $3F,$3B, $00, $00
SFX_Explosion:
	.db $C1, $C2, $C3, $C4, $C5, $C6, $C7, $C8, $C9, $CA, $CB, $CC, $CD, $CE, $CF
	.db $D1, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $DA, $DB, $DC, $DD, $DE, $DF
	.db $E1, $E2, $E3, $E4, $E5, $E6, $E7, $E8, $E9, $EA, $EB, $EC, $ED, $EE, $EF
	.db $00, $00
SFX_Pain:
	.db $C0, $C2, $C3, $C4, $C5, $C6, $C7, $C8, $00

Movables:
	.db $10, $10, GuyStanding, GuyAnimRow, $10, $40, $00, $20
	.db $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $00, $00, $00, $00, $00
	.db $00, $00, $00, $00, $00, $00, $00, $00

GuyWalkCycle:
	.db $10, $10, $10, $20, $20, $20, $30, $30, $30, $FF

Str_NeedKey:
	.db $D7, $CE, $CE, $CD, $DC, $EF, $D4, $CE, $E2, $E6, $00
Str_DoorBlank:
	.db $EF, $EF, $EF, $EF, $EF, $EF, $EF, $EF, $EF, $EF, $00

Sprites:
	.incbin "sprites/gamesprites.gtg.deflate"

InstrumEnv1:
	.db $58, $58, $58, $58, $48
	.db $48, $38, $38, $28, $08
	.db $88
InstrumEnv2:
	.db $5F, $5C, $48, $38, $38
	.db $38, $38, $38, $38, $38
	.db $28, $28, $28, $28, $28
	.db $18, $18, $18, $18, $18
	.db $88

MusicPkg_Main:
	.incbin "music\cubeknight_alltracks.gtm.deflate"
MusicPkg_Win:
	.incbin "music\stroll_alltracks.gtm.deflate"	

Maps:
	.incbin "tiled\testmap1_merged.map.deflate"
TitleScreen:
	.incbin "tiled\title_merged.map.deflate"
WinScreen:
	.incbin "tiled\end_merged.map.deflate"

ACProg:
	.incbin "acp/dynawave_nosine.acp.deflate"

TwelveTimesTable:
	.db 0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120
Pitches:
	.incbin "pitches.dat"

NMI:
	STZ FrameFlag
	RTI

	.org $FFFA
	.dw NMI
	.dw RESET
	.dw 0

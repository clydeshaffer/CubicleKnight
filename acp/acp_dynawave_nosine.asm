DAC = $8000

AccBuf = $00
LFSR = $04 ;$05
FreqsH = $10
FreqsL = $20
Amplitudes = $30
WaveStatesH = $50
WaveStatesL = $60

	.org $0000
	.db 0, 0, 0, 0, 2

	.org $0050
	.db $FF, $FF, $FF, $FF

	.org $0200
RESET:
	CLI
Forever:
	JMP Forever

IRQ:
	;Clear sum buffer
	STZ AccBuf ;3?

	;Channel 1 wavestate
	CLC ;2
	LDA WaveStatesL+0 ;3
	ADC FreqsL+0 ;3
	STA WaveStatesL+0
	LDA WaveStatesH+0
	ADC FreqsH+0
	STA WaveStatesH+0 ;3
	ROL ;2
	LDA #$FF ;2
	ADC #$00 ;2
	AND Amplitudes+0 ;3
	CLC ;2
	ADC AccBuf ;3
	STA AccBuf ;3

	;Channel 2 wavestate
	CLC ;2
	LDA WaveStatesL+1 ;3
	ADC FreqsL+1 ;3
	STA WaveStatesL+1
	LDA WaveStatesH+1
	ADC FreqsH+1
	STA WaveStatesH+1 ;3
	ROL ;2
	LDA #$FF ;2
	ADC #$00 ;2
	AND Amplitudes+1 ;3
	CLC ;2
	ADC AccBuf ;3
	STA AccBuf ;3

	;LFSR noise channel
	CLC ;2
	LDA WaveStatesL+2 ;3
	ADC FreqsL+2 ;3
	STA WaveStatesL+2
	LDA WaveStatesH+2
	ADC FreqsH+2
	STA WaveStatesH+2 ;3
	BCC AddNoise

	LDA LFSR
	ASL
	ROL LFSR+1
	BCC *+4
	EOR #$39
	STA LFSR
	LDA LFSR
	ASL
	ROL LFSR+1
	BCC *+4
	EOR #$39
	STA LFSR
	LDA LFSR
	ASL
	ROL LFSR+1
	BCC *+4
	EOR #$39
	STA LFSR
	LDA LFSR
	ASL
	ROL LFSR+1
	BCC *+4
	EOR #$39
	STA LFSR
	LDA LFSR
	ASL
	ROL LFSR+1
	BCC *+4
	EOR #$39
	STA LFSR
	LDA LFSR
	ASL
	ROL LFSR+1
	BCC *+4
	EOR #$39
	STA LFSR
	LDA LFSR
	ASL
	ROL LFSR+1
	BCC *+4
	EOR #$39
	STA LFSR
	LDA LFSR
	ASL
	ROL LFSR+1
	BCC *+4
	EOR #$39
	STA LFSR

AddNoise:
	LDA Amplitudes+2
	LSR
	LSR
	LSR
	LSR
	LSR
	BEQ SkipNoiseAttenuation
	TAX
	LDA LFSR
ShiftLoop:
	LSR
	DEX
	BNE ShiftLoop
SkipNoiseAttenuation:
	CLC ;2
	ADC AccBuf ;3
	STA AccBuf ;3

	;Move sum buffer to DAC
	;assuming final channel math ends with AccBuf in register A
	STA DAC ;3
	RTI ;6

NMI:
	RTI

	.org $0FFA
	.dw NMI
	.dw RESET
	.dw IRQ
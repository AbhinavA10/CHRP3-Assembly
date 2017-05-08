;ANALOGUE INPUT			v3.1	May 4th, 2017
;===============================================================================
;Description:	Output test program. Initializes the PIC18F25K50 I/O pins for LED
;output on the CHRP 3.0 based on an analogue potentiometer.

;Configure MPLAB and the microcontroller

    include	"p18f25k50.inc"		;Include processor definitions

	config	PLLSEL = PLL3X, CFGPLLEN = ON, CPUDIV = CLKDIV3, LS48MHZ = SYS48X8, FOSC = INTOSCIO, PCLKEN = ON, FCMEN = OFF, IESO = OFF
	config	nPWRTEN = OFF, BOREN = SBORDIS, BORV = 190, nLPBOR = OFF, WDTEN = SWON, WDTPS = 32768
	config	CCP2MX = RC1, PBADEN = OFF, T3CMX = RC0, SDOMX = RC7, MCLRE = ON, STVREN = ON, LVP = ON, XINST = OFF
	config	CP0 = OFF, CP1 = OFF, CP2 = OFF, CP3 = OFF, CPB = OFF, CPD = OFF
	config	WRT0 = OFF, WRT1 = OFF, WRT2 = OFF, WRT3 = OFF, WRTC = OFF, WRTB = OFF, WRTD = OFF
	config	EBTR0 = OFF, EBTR1 = OFF, EBTR2 = OFF, EBTR3 = OFF, EBTRB = OFF
   
;Set hardware equates.
S1			equ	3			;PORTE position of pushbutton S1

;Set A-D converter channel constants.

adQ1			equ	00000000b		;A-D channel 0 (Q1 phototransistor)
adQ2			equ	00000100b		;A-D channel 1 (Q2 phototransistor)
adVR1			equ	00001000b		;A-D channel 2 (VR1 potentiometer)
adT1			equ	00001100b		;A-D channel 3 (T1 temperature sensor)
adVM			equ	00010000b		;A-D channel 4 (+VM power supply voltage divider)
	
;Start the program at the reset vector

    org	2000h		;Reset vector - start of program memory    
    goto initOsc	;Jump to initialize routine
    org	2018h		;Continue program after the interrupt vector
    

adConvert		
    ;First, selects A-D channel by non-destructively writing the
    ;channel code from W into ADCON0 (see channel constants, above).
    ;Then, initiates A-D conversion on the selected A-D channel.
    ;Repeatedly polls the Go_Done bit until conversion finishes.

    bsf		ADCON0,ADON	;Turn A-D converter on
    movwf	ADRESH		;Use ADRES for temporary channel storage
    movlw	11000011b	;Clear CHS3-0 bits by logical ANDing with 0
    andwf	ADCON0,F
    movf	ADRESH,W	;Get stored channel select bits from ADRES
    iorwf	ADCON0,F	;and set channel bits by logical ORing
    nop				;Allow input to settle after channel switch
    nop				
    nop				
    nop				
    bsf		ADCON0,GO	;Start the A/D conversion

adConvLoop		
    btfsc	ADCON0,GO	;Check GO_DONE bit for end of conversion
    goto	adConvLoop	;Repeat until until conversion is done
    bcf		ADCON0,ADON	;Turn A-D converter off
    return

timeDelay		
    movlw	61		;Preload TMR0 for ~50ms time period
    movwf	TMR0

checkTimer		
    movf	TMR0,W		;Check if the TMR0 value is zero by
    btfss	STATUS,Z	;testing the Z bit
    goto	checkTimer	;Repeat check until TMR0 = 0
    return			;Return to the calling routine when done
 
initOsc
    banksel OSCTUNE
    movlw   0x80		;3X PLL ratio mode selected
    movwf   OSCTUNE
    
    banksel OSCCON
    movlw   0x70		;Switch to 16MHz HFINTOSC
    movwf   OSCCON
      
    banksel OSCCON2
    movlw   0x10		; Enable PLL, SOSC, PRI OSC drivers turned off
    movwf   OSCCON2
    
    banksel ACTCON
    movlw   0x90	    	; Enable active clock tuning for USB operation
    movwf   ACTCON
    
initOscWhile			; wait until !PLLRDY
    btfsc   OSCCON2, PLLRDY
    goto initOscWhile
	
initPorts			;Configures PORTA and PORTB for digital I/O
    banksel	LATA
    clrf	LATA		;Clear Port A latches before configuring PORTA
    banksel	ANSELA		
    clrf	ANSELA		;Make all Port A pins digital
    banksel	TRISA		
    movlw	00101111b	;Set runLED, IR LEDs as outputs in PORTA
    movwf	TRISA		
        
    banksel	LATB		
    clrf	LATB		;Clear Port B latches before configuring PORTB
    banksel	ANSELB		
    clrf	ANSELB		;Make all Port B pins digital
    banksel	TRISB
    clrf	TRISB		;Set PORTB LEDS as outputs
    
    banksel INTCON2
    bcf	    INTCON2, RBPU	;RBPU = 0  enable PORTB pullup resistors
    
    banksel	LATC
    clrf	LATC    
    banksel	ANSELC		
    clrf	ANSELC		
    banksel	TRISC
    movlw	10110000b	;Set piezo and LED pins as outputs and
    movwf	TRISC
    
    banksel	T0CON
    movlw	10000001b	;Enable TMR0 as 16-bit, internal clock, /2
    movwf	T0CON
    
    banksel	PORTA		
    clrf	PORTA		;Clear all PORTA outputs and turn on Run LED
    banksel	PORTB		
    clrf	PORTB
    banksel	PORTC
    clrf	PORTC
    
initANA				;Configures PORTA for analogue Input
    banksel	LATA
    clrf	LATA		;Clear Port A latches before configuring PORTA
        
    banksel	ANSELA		
    clrf	ANSELA
    movlw	00011111b	;Make RA0-4 analogue inputs
    movwf	ANSELA		;and the others as digital I/O
    
    banksel	ADCON0		;VDD reference voltage
    clrf	ADCON0		;Analogue channel AN0, A/D converter
    banksel	ADCON1		
    clrf	ADCON1		;Set A-D for left justified result,
    banksel	ADCON2		
    movlw	00001110b
    movwf	ADCON2		;2TAD acquisition time, FOSC/64 conversion clock
    banksel	TRISA		
    movlw	00101111b	;Set runLED, IR LEDs as outputs in PORTA
    movwf	TRISA	
     
main
    movlw	11000011b	;Send this pattern to the
    movwf	LATB		;Port B LEDs 
    
checkS1
    btfsc	PORTE,S1	;Check if S1 is pressed
    goto	adTest		;If S1 is not pressed, convert analogue
    goto	001Ch		;If S1 is pressed, go to booloader
       
adTest				;Display analogue value on Port B LEDs.
    movlw	adVR1		;Set A-D input channel to potentiometer
    call	adConvert	;Start A-D conversion
    movf	ADRESH,W	;Copy finished A-D result into W and
    movwf	LATB		;display it on the LEDs
    call	timeDelay	;Pause to display current result
    goto	checkS1		;Check if bootloader button is pressed
    
    end
;SERVO OUTPUT		v3.1	May 8th, 2017
;===============================================================================
;Description:	Servo Output test program. Initializes the PIC18F25K50 I/O pins 
;for servo output on the CHRP 3.0. Note: this is an work in progress file.
    
    
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

;Start the program at the reset vector

    org	2000h		;Reset vector - start of program memory    
    goto initOsc	;Jump to initialize routine
    org	2018h		;Continue program after the interrupt vector


timeDelay		
    movlw	61		;Preload TMR0 for ~50ms time period
    movwf	TMR0

checkTimer		
    movf	TMR0,W		;Check if the TMR0 value is zero by
    btfss	STATUS,Z	;testing the Z bit
    goto	checkTimer	;Repeat check until TMR0 = 0
    return			;Return to the calling routine when done
 
initOsc
    banksel	OSCTUNE
    movlw	0x80		;3X PLL ratio mode selected
    movwf	OSCTUNE
    
    banksel	OSCCON
    movlw	0x70		;Switch to 16MHz HFINTOSC
    movwf	OSCCON
      
    banksel	OSCCON2
    movlw	0x10		; Enable PLL, SOSC, PRI OSC drivers turned off
    movwf	OSCCON2
    
    banksel	ACTCON
    movlw	0x90	    	; Enable active clock tuning for USB operation
    movwf	ACTCON
    
initOscWhile			; wait until !PLLRDY
    btfsc	OSCCON2, PLLRDY
    goto	initOscWhile
	
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
    
    banksel	INTCON2
    bcf		INTCON2, RBPU	;RBPU = 0  enable PORTB pullup resistors
    
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
  
main
    movlw	11000011b	;Send this pattern to the
    movwf	LATB		;Port B LEDs 
    
checkS1
    btfsc	PORTE,S1	;Check if S1 is pressed
    goto	checkS1		;If S1 is not pressed, convert analogue
    goto	001Ch		;If S1 is pressed, go to bootloader
    end
    
;1 clock cycle seems to be 21ns
; so 48 is around 1us
;http://siriusmicro.com/projects/i2servo.html
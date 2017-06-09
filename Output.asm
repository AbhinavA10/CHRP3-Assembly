;OUTPUT			v3.1	April 27th, 2017
;===============================================================================
;Description:	Output test program. Initializes the PIC16F886 I/O pins for LED
;output on the CHRP 3.0, and demonstrates port output.

;Configure MPLAB and the microcongtroller

    include	"p18f25k50.inc"		;Include processor definitions

	config	PLLSEL = PLL3X, CFGPLLEN = ON, CPUDIV = CLKDIV3, LS48MHZ = SYS48X8, FOSC = INTOSCIO, PCLKEN = ON, FCMEN = OFF, IESO = OFF
	config	nPWRTEN = OFF, BOREN = SBORDIS, BORV = 190, nLPBOR = OFF, WDTEN = SWON, WDTPS = 32768
	config	CCP2MX = RC1, PBADEN = OFF, T3CMX = RC0, SDOMX = RC7, MCLRE = ON, STVREN = ON, LVP = ON, XINST = OFF
	config	CP0 = OFF, CP1 = OFF, CP2 = OFF, CP3 = OFF, CPB = OFF, CPD = OFF
	config	WRT0 = OFF, WRT1 = OFF, WRT2 = OFF, WRT3 = OFF, WRTC = OFF, WRTB = OFF, WRTD = OFF
	config	EBTR0 = OFF, EBTR1 = OFF, EBTR2 = OFF, EBTR3 = OFF, EBTRB = OFF

;Start the program at the reset vector

    org	2000h		;Reset vector - start of program memory
    goto initOsc	;Jump to initialize routine
    org	2018h		;Continue program after the interrupt vector

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
    ;btfss PLLRDY, 1 ;why 1???
    btfsc   OSCCON2, PLLRDY
    goto initOscWhile
	
initPorts
    ;Configures PORTA and PORTB for digital I/O
       
    banksel	LATA
    clrf	LATA
    banksel	ANSELA		
    clrf	ANSELA		;Make all Port A pins digital
    banksel	TRISA		
    movlw	00101111b	;Set runLED, IR LEDs as outputs in PORTA
    movwf	TRISA		
    banksel	PORTA		
    clrf	PORTA		;Clear all PORTA outputs and turn on Run LED
    
    ;next 2 lines are for the old processor
    ;movlw	01010111b	;Enable Port B pull-ups, TMR0 internal
    ;movwf	OPTION_REG	;clock, and 256 prescaler
    
    banksel	LATB		
    clrf	LATB		;Clear Port B latches before configuring PORTB
    banksel	ANSELB		
    clrf	ANSELB		;Make all Port B pins digital
    banksel	TRISB
    clrf	TRISB
    banksel	PORTB		
    clrf	PORTB
    ;RBPU = 0			; something about PORTB pullup resistors?
    banksel	LATC
    clrf	LATC    
    banksel	ANSELC		;Switch register banks
    clrf	ANSELC		
    banksel	TRISC
    movlw	10110000b	;Set piezo and LED pins as outputs and
    movwf	TRISC
    banksel	PORTC
    clrf	PORTC
    
    banksel	T0CON
    movlw	10000001b	;Enable TMR0 as 16-bit, internal clock, /2
    movwf	T0CON

main				
    movlw	11000011b	;Send this pattern to the
    movwf	LATB		;Port B LEDs
    sleep			;Done - shut down microcontroller core

    end
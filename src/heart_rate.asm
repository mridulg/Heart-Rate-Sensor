; Heart Rate Monitor
; Group Members:
; Aditya Adhikary (2015007)
; Ajay Balasubramanian (2015008)
; Mridul Gupta (2015061)
; Nambiar Pranav (2015063)
; Sanidhya Singal (2015085)


RS EQU P1.0 ; lcd pins being declared as constants
RW EQU P1.1
EN EQU P1.2

ORG 000H
  ACALL INIT
  ACALL TEXT1
  ACALL LINE2
  ACALL TEXT3

  MOV DPTR, #LUT ;move the contents of lookup table to dataptr
  MOV P1, #00000000B ;set P1 as output port
  MOV P2, #00000000B ;set P2 as output port

MAIN: 
  MOV R6, #230D
  
  SETB P3.5 ;Timer 1 connection, sets it as an input port
  
  MOV TMOD, #01100001B ; sets Timer 1 as Mode 2 counter ( 8-bit auto-reload mode ) and Timer 0 as Mode 1 ( 16-bit timer mode )
  MOV TL1, #00000000B  ; reload value of High bits of Timer 1 
  MOV TH1, #00000000B  ; initial value of Low bits of Timer 1 ( this is reloaded into the Tl bits after tl1 rolls over and Tf1 is set to 1 )
  SETB TR1  ;starts Timer 1

  ; ----Timer1 is set as an 8 bit auto reload counter for counting the the number of pulses (indicating the heart beat)  
  ; ----Timer0 is set as a 16 bit timer which generates a 65536 microsec delay. 
  ; ----When looped 230 times it will produce a 15 second time span (230 x 65536 microsec = 15 sec)  for the Timer 1 to count. 
  ; ----The number of counts obtained in 15 seconds is multiplied by 4 to obtain the heart rate in beats per minute.

  BACK: 
    MOV TH0, #00000000B ; initial value of higher bits of Timer 0
    MOV TL0, #00000000B ; initial value of lower bits of Timer 0
    SETB TR0 ; start timer 0

  HERE: 
    JNB TF0, HERE ; checks for Timer 0 roll over 
    CLR TR0 ; stops the timer 
    CLR TF0 ; clear the timer flag 
    DJNZ R6, BACK ; do the Back function 230 times

    CLR TR1  ; stops timer 1
    CLR TF0  ; clears timer flag 0
    CLR TF1  ; clears timer flag 1
    MOV A, TL1 ; move counted number of beats ( stored in TL1 ) to A
    MOV B, #4D 
    MUL AB ; multiply the number of beats by 4
    
    ACALL SPLIT ; split the digits of the number obtained into 3 digits
    ACALL INIT  ; repeat the intial lcd printing
    ACALL TEXT1
    ACALL LINE2
    ACALL TEXT2
    ACALL BPM ; print the beats per minute
  SJMP MAIN

  INIT: ; initialises lcd 
    ACALL CMD ; sets up lcd in command mode and enables it
    MOV A, #0FH; lcd on, cursor on, cursor blinking on
    ACALL CMD ; 

    MOV A, #01H ; clear screen
    ACALL CMD
    
    MOV A, #06H ;increment cursor
    ACALL CMD

    MOV A, #83H ;cursor line 1 position 3
    ACALL CMD

    MOV A, #3CH ;activate second line 
    ACALL CMD
  RET

  TEXT1: ;some text to be displayed at lcd
    MOV A, #48H ; 'H'
    ACALL DISPLAY ; displays whatever is there in A 
    
    MOV A, #65H ; 'e'
    ACALL DISPLAY
    
    MOV A, #61H ; 'a'
    ACALL DISPLAY
    
    MOV A, #72H ; 'r'
    ACALL DISPLAY
 
    MOV A, #74H ; 't'
    ACALL DISPLAY
    
    MOV A, #20H ; ' '
    ACALL DISPLAY
    
    MOV A, #52H ; 'R'
    ACALL DISPLAY
    
    MOV A, #61H ; 'a'
    ACALL DISPLAY
    
    MOV A, #74H ; 't'
    ACALL DISPLAY
    
    MOV A, #65H ; 'e'
    ACALL DISPLAY
  RET

  LINE2:
    MOV A, #0C0H ; display on, cursor off
    ACALL CMD
  RET

  TEXT2:
    MOV A, #62H ; 'b'
    ACALL DISPLAY
    
    MOV A, #70H ; 'p'
    ACALL DISPLAY
    
    MOV A, #6DH ; 'm'
    ACALL DISPLAY
    
    MOV A, #20H ; ' '
    ACALL DISPLAY
  RET

  TEXT3:
    MOV A, #63H ; 'c'
    ACALL DISPLAY
    
    MOV A, #6FH ; 'o'
    ACALL DISPLAY
    
    MOV A, #75H ; 'u'
    ACALL DISPLAY
    
    MOV A, #6EH ; 'n'
    ACALL DISPLAY
    
    MOV A, #74H ; 't'
    ACALL DISPLAY
    
    MOV A, #69H ; 'i'
    ACALL DISPLAY
    
    MOV A, #6EH ; 'n'
    ACALL DISPLAY
    
    MOV A, #67H ; 'g'
    ACALL DISPLAY
    
    MOV A, #2EH ; '.'
    ACALL DISPLAY
    
    MOV A, #2EH ; '.'
    ACALL DISPLAY
    
    MOV A, #2EH ; '.'
    ACALL DISPLAY
  RET

  BPM:
    MOV A, R1 ; move the calculated 1st digit of the bpm to A
    ACALL ASCII ; moves a byte from the program memory to the accumulator
    ACALL DISPLAY
    
    MOV A, R2 ; move the calculated 2nd digit of the bpm to A
    ACALL ASCII
    ACALL DISPLAY
    
    MOV A, R3 ; move the calculated 3rd digit of the bpm to A
    ACALL ASCII
    ACALL DISPLAY
  RET

  CMD:  ;used again and again to setup lcd 
    MOV P2, A ;move contents of A to P2 (Lcd is connected to Port 2)
    CLR RS ; selects the command register for sending a command to the LCD
    CLR RW ; write mode at RW pin
    SETB EN
    CLR EN ; high to low transition at this pin will enable the lcd module
    ACALL DELAY
  RET

  DISPLAY:
    MOV P2, A ; move the contents of A to P2
    SETB RS ; selects data register for sending a data to Lcd
    CLR RW ; write mode at RW pin
    SETB EN 
    CLR EN ;high to low transition at this pin will enable the lcd module
    ACALL DELAY
  RET

  DELAY: 
    CLR EN ; disable lcd temporarily while we do other stuff
    CLR RS ; selects the command register for sending a command to the LCD
    SETB RW ; read mode
    MOV P2, #0FFh ; move 255 to P2
    SETB EN 
    MOV A, P2 ; move 255 to A
    JB ACC.7, DELAY ; until the 7th bit of accumulator remains 1, keep repeating

    CLR EN ; enable lcd again ( it was given a high pulse earlier )
    CLR RW ; enable write mode
  RET

  DELAY1: ; general delay function
    MOV R5, #255D 
    HERE2: DJNZ R5, HERE2
  RET

  SPLIT: ; divides the result into 3 digits
    MOV B, #10D 
    DIV AB ; divides the result stored in A by 10, A stores the quotient, B stores the remainder
    MOV R3, B ; stores the remainder in R3
    
    MOV B, #10D
    DIV AB ; divide the quotient by 10 again
    MOV R2, B ; stores the remainder in R2
    
    MOV R1, A ; stores the quotient in R1
  RET

  ASCII:
    MOVC A,@A+DPTR ; moves a byte from the program memory to the accumulator
  RET

  LUT:  ;Look Up Table
    DB 48D  ; DB0 of LCD
    DB 49D  ; DB1
    DB 50D  ; DB2
    DB 51D  ; DB3
    DB 52D  ; DB4
    DB 53D  ; DB5
    DB 54D  ; DB6
    DB 55D  ; DB7
    DB 56D  
    DB 57D  
END
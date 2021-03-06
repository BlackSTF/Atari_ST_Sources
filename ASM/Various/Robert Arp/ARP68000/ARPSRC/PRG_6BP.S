 ; Program Name: PRG_6BP.S
 ;      Version: 1.002

 ; Assembly Instructions:

 ;     Assemble in PC-relative mode and save with a TOS extension.

 ; Execution Instructions:

 ;     Before this program is executed, trap 11 must be installed via the
 ; execution of program PRG_6AP.TOS.  In addition, this program uses traps
 ; installed by CUSTOM.PRG.  Execute from the desktop or via SPAWN.TTP.

 ; Program Function:

 ;     Prints the content of register A7 during various stages of execution
 ; while the state of the processor is varied from user mode to supervisor
 ; mode, from supervisor mode back to user mode, from user mode to supervisor
 ; mode a second time and from supervisor mode back to user mode a second time.

 ;     In this program, custom trap #11 is used to toggle the state of the
 ; processor.

calculate_program_size:
 lea        -$102(pc), a1       ; Fetch basepage start address.
 lea        program_end, a0     ; Fetch program end address.
 trap       #6                  ; Return unused memory to op system.

print_heading:
 lea        heading, a0
 bsr.s      print_string

 ; NOTE: During this section of the program, no user stack has yet been
 ;       assigned, therefore, the user stack address is that of the default
 ;       user stack assigned by the system when execution commences.

print_address_of_default_user_stack:
 lea        header_1, a0
 bsr.s      print_string
 move.l     a7, d1              ; Convert address to ASCII hexadecimal.
 trap       #5
 bsr.s      print_string
 bsr.s      print_newline

invoke_custom_super_mode_trap:
 trap       #11                 ; Sets bit 13 of SR to 1 and prints SSP.

print_current_SSP:              ; SSP = address of supervisor stack.
 lea        header_2, a0        ; Did invocation of trap #11 alter the address
 bsr.s      print_string        ; in the supervisor stack pointer?
 move.l     a7, d1              ; Convert to ASCII hexadecimal.
 trap       #5
 bsr.s      print_string
 bsr.s      print_newline
 bsr.s      print_newline

enter_user_mode:
 andi.w     #$DFFF, SR          ; Sets bit 13 of status register to zero.

 ; NOTE: During this section of the program, a user stack is assigned.  The
 ;       user stack address is that of the label "stack".

print_address_of_assigned_user_stack:
 lea        header_3, a0
 bsr.s      print_string
 lea        stack, a7
 move.l     a7, d1              ; Convert to ASCII hexadecimal.
 trap       #5
 bsr.s      print_string
 bsr.s      print_newline

invoke_custom_super_mode_trap_again:
 trap       #11                 ; Sets bit 13 of SR to 1 and prints SSP.

print_current_SSP_again:        ; Did invocation of trap #11 alter the address
 lea        header_4, a0        ; in the supervisor stack pointer?
 bsr.s      print_string
 move.l     a7, d1              ; Convert to ASCII hexadecimal.
 trap       #5
 bsr.s      print_string
 bsr.s      print_newline

enter_user_mode_again:
 andi.w     #$DFFF, SR          ; Sets bit 13 of status register to zero.

print_address_of_assigned_user_stack_again:
 lea        header_5, a0
 bsr.s      print_string
 move.l     a7, d1              ; Convert to ASCII hexadecimal.
 trap       #5
 bsr.s      print_string
 bsr.s      print_newline

terminate:
 trap       #8

 ;
 ; SUBROUTINES
 ;

print_string:         
 pea        (a0)
 move.w     #9, -(sp) 
 trap       #1        
 addq.l     #6, sp    
 rts

print_newline:
 lea        newline, a0
 bsr.s      print_string
 rts

 data
newline:   dc.b $D,$A,0
heading:   dc.b 'PRG_6BP Execution Results => Content of A7:',$D,$A,$D,$A,0
header_1:  dc.b   '  NO USER STACK ASSIGNED',$D,$A
           dc.b   '    Start of program:          ',0
header_2:  dc.b   '    After trap 11 invocation:   ',0
header_3:  dc.b   '  USER STACK ASSIGNED',$D,$A
           dc.b   '    After force to user mode:  ',0
header_4:  dc.b   '    After trap 11 invocation:   ',0
header_5:  dc.b   '    After force to user mode:  ',0
 bss
 align 
               ds.l   96
stack:         ds.l    0
program_end:   ds.l    0
 end
 
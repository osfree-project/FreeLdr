;
; modesw.asm:
; real <-> protected
; mode switching
;

name modesw

.386p

;public  base
extrn    base        :dword

;extrn   set_pm_idt  :near
;extrn   set_rm_idt  :near

;public  idtr
;public  idtr_old

public  gdtsrc
public  gdtdesc
public  gdtaddr
public  call_rm

ifndef  NO_PROT
public  call_pm
ifndef STAGE1_5
extrn   idt_init     :near
extrn   idt_initted  :byte
endif
endif

public  __CHK
public  __I8LS
public  __U8RS

include fsd.inc
include struc.inc

include mb_etc.inc


;ifdef NO_PROT
;
;ifdef BLACKBOX
;
;if 1 ; term blackbox
;  BASE    equ TERMLO_BASE
;else
;     ; other blackboxes
;endif
;  
;else
;  BASE    equ REAL_BASE
;endif
;
;else
;
;  BASE    equ STAGE0_BASE
;
;endif

_TEXT16  segment dword public 'CODE'  use16

start1   label byte

ifndef NO_PROT

;
; void __cdecl call_pm(unsigned long func);
;
; (Call 32-bit protected mode function
; with entry point address func)
;

call_pm proc near
        ; Save stack frame
        push bp
        mov  bp, sp
        ; Disable interrupts
        cli
        ; Load GDTR
        mov  eax, offset _TEXT:gdtdesc
        sub  eax, base
        lgdt fword ptr [eax]
        ; Enable protected mode
        mov  eax, cr0
        or   eax, 1
        mov  cr0, eax
        ; Do a far jump to 16-bit segment
        ; to switch to protected mode
        mov  ax, PSEUDO_RM_CSEG
        push ax
        push protmode
        retf
protmode:
        ; set selectors
        mov  ax, PSEUDO_RM_DSEG
        mov  ds, ax
        mov  es, ax
        mov  fs, ax
        mov  gs, ax

	mov  ax, PSEUDO_RM_SSEG
        mov  ss, ax
        ; do a far call to a 32-bit segment
        push esi
        mov  esi, offset _TEXT:address
        sub  esi, base
        mov  ax,  PROT_MODE_CSEG
        mov  word ptr  [esi + 4], ax
        mov  eax, offset _TEXT:pmode
        mov  dword ptr [esi], eax
        mov  ebp,  dword ptr [bp + 4]
        mov  eax, esi
        pop  esi

        call fword ptr [eax]

        ; Clear PE bit in CR0 register
        mov  eax, cr0
        and  al,  0feh
        mov  cr0, eax
        ; long jump to 16-bits entry point
        mov  eax, base
        shr  eax, 4
        push ax
        push realmode
        retf
realmode:
        ; Set up segments
        mov  ds,  ax
        mov  es,  ax
        mov  fs,  ax
        mov  gs,  ax

	mov  eax, STAGE0_BASE
	shr  eax, 4 
        mov  ss,  ax
        ; Restore interrupts
        sti
        ; Restore stack frame
        pop  bp
        ; Return
        ret
call_pm endp

endif

;
; This function gets called from
; 32-bit segment and it switches
; machine to real mode and calls
; a real mode function with address
; specified in ebp register.
;

rmode_switch proc far
        ; switch to real mode
        mov  eax, cr0
        and  al,  0feh
        mov  cr0, eax
        ; set segment registers
        mov  eax, base
        shr  eax, 4
        mov  ds, ax
        mov  es, ax
        mov  fs, ax
        mov  gs, ax

	mov  eax, STAGE0_BASE
	shr  eax, 4
        mov  ss, ax

        ; do a far jump to reload a
        ; real mode CS
        push ds
        push rmode1
        retf
rmode1:
	; enable interrupts
	sti

        ; Now we are in a real mode
        ; call a function with address in ebp
        mov  eax, ebp
        shr  eax, 16
        push ax
        push bp
        mov  bp, sp
        call dword ptr [bp]
        add  sp, 4

	; disable interrupts
	cli

        ; Switcch back to protected mode
        mov  eax, cr0
        or   al, 1
        mov  cr0, eax
        ; load segment registers
        mov  ax, PSEUDO_RM_DSEG
        mov  ds, ax
        mov  es, ax
        mov  fs, ax
        mov  gs, ax

	mov  ax, PSEUDO_RM_SSEG
        mov  ss, ax
        ; do a far jump to load a
        ; protected mode 16-bit CS
        mov  ax, PSEUDO_RM_CSEG
        push ax
        push pmode1
        retf
pmode1:
        ; return to 32-bit segment
        ; use jmp instead of retf
        ; because retf uses 16-bit offset,
        ; not 32-bit one
        ;retf
        mov bp, sp
        jmp fword ptr ss:[bp]
rmode_switch endp

ifdef NO_PROT

;base        dd   BASE
MODESW_SZ   equ  0x100
padsize     equ  MODESW_SZ - ($ - start1)
pad         db   padsize dup (0)

endif

_TEXT16 ends


_TEXT   segment dword public 'CODE' use32

ifndef NO_PROT

;
; pmode:
; A wrapper for 32-bit function call,
; gets called from 16-bit protmode
; function, sets selectors and calls
; function; takes function entry point
; flat address in ebp.
;

pmode   proc far
        ; Load segment registers
        mov  ax, PROT_MODE_DSEG
        mov  ds, ax
        mov  es, ax
        mov  fs, ax
        mov  gs, ax

	mov  ax, ss
	mov  word ptr ds:[RMSTACK + 2], ax

        mov  ax, PROT_MODE_DSEG
        mov  ss, ax

        ; Get protected mode stack
        mov  word ptr ds:[RMSTACK], sp

        mov  eax, dword ptr ds:[PROTSTACK]
        mov  esp, eax

ifndef STAGE1_5
	mov  al, byte ptr idt_initted
	cmp  al, 0
	jz   not_initted

	call set_pm_idt
	;mov  byte ptr idt_initted, 1
	jmp  call_func

not_initted:
	call idt_init
endif

call_func:
        ; Call protected mode func
        push  cs
        push  ebp
        call  fword ptr ss:[esp]
        add   esp, 6
	;add   esp, 14

ifndef STAGE1_5
	call set_rm_idt
endif

        ; Save protected mode stack
        mov  eax, esp
        mov  dword ptr ds:[PROTSTACK], eax

	mov  ax, word ptr ds:[RMSTACK + 2]
	mov  ss, ax
	xor  eax, eax
        mov  ax, word ptr ds:[RMSTACK]
        mov  esp, eax

        ; Set up selectors
        mov  ax, PSEUDO_RM_DSEG
        mov  ds, ax
        mov  es, ax
        mov  fs, ax
        mov  gs, ax

	;mov  ax, PSEUDO_RM_SSEG
        ;mov  ss, ax

        xor  eax, eax

        retf
pmode   endp

endif

;
; void __cdecl call_rm(fp_t func);
;
; Call real-mode function with address func
; from protected mode
;

call_rm proc near
        push ebp
        mov  ebp, esp

        mov  ebp, dword ptr [ebp + 8]

ifndef STAGE1_5
	call set_rm_idt
endif

        ; set segment registers
        ; and switch stack to 16-bit
        mov  eax, esp
        mov  dword ptr ds:[PROTSTACK], eax

	mov  ax, word ptr ds:[RMSTACK + 2]
	mov  ss, ax
	xor  eax, eax
	mov  ax, word ptr ds:[RMSTACK]
        mov  esp, eax

        mov  ax, PSEUDO_RM_DSEG
        mov  ds, ax
        mov  es, ax
        mov  fs, ax
        mov  gs, ax

	;mov  ax, PSEUDO_RM_SSEG
        ;mov  ss, ax
        ; call 16-bit function
        mov  ax, PSEUDO_RM_CSEG
        push ax
        mov  eax, offset _TEXT16:rmode_switch
        push eax
        call fword ptr ss:[esp]
        add  esp, 14      ; 6 bytes are the called function address and 8
                          ; bytes are the return address.

        mov  ax, PROT_MODE_DSEG
        mov  ds, ax
        mov  es, ax
        mov  fs, ax
        mov  gs, ax

	mov  ax, ss
	mov  word ptr ds:[RMSTACK + 2], ax
        mov  ax, sp
        mov  word ptr ds:[RMSTACK], ax

        mov  ax, PROT_MODE_DSEG
        mov  ss, ax

        mov  esp, dword ptr ds:[PROTSTACK]

ifndef STAGE1_5
	call set_pm_idt
endif
        pop  ebp

        ret
call_rm endp

;
; set protect mode IDT
;
set_pm_idt:
	; store realmode idt
	;mov   eax, IDTR_OLD
	;sidt  fword ptr [eax]

	mov   eax, IDTR
	lidt  fword ptr [eax]

	ret

;
; set realmode IDT
;
set_rm_idt:
	; store protmode idt
	;mov   eax, IDTR
	;sidt  fword ptr [eax]

	; set realmode idt
	mov   eax, IDTR_OLD
	lidt  fword ptr [eax]

	ret

__CHK:
        ret  4
__I8LS:
        ret

__U8RS:
        ret

_TEXT   ends

_DATA   segment dword public 'DATA' use32

CR0_PE_ON       equ 01h
CR0_PE_OFF      equ 0fffffffeh

; flat selectors
PROT_MODE_CSEG  equ 08h
PROT_MODE_DSEG  equ 10h

; 16-bit selectors
PSEUDO_RM_SSEG  equ 28h
ifndef NO_PROT
; selectors for real-mode part of pre-loader
PSEUDO_RM_CSEG  equ 18h
PSEUDO_RM_DSEG  equ 20h
else
ifdef BLACKBOX
; selectors for real-mode part of blackboxes
PSEUDO_RM_CSEG  equ 30h
PSEUDO_RM_DSEG  equ 38h
else
; selectors for real-mode part of multiboot kernels
PSEUDO_RM_CSEG  equ 40h
PSEUDO_RM_DSEG  equ 48h
endif
endif

;align 4

boot_drive        dd   0

;align 4

;/*
; * This is the Global Descriptor Table
; *
; *  An entry, a "Segment Descriptor", looks like this:
; *
; * 31          24         19   16                 7           0
; * ------------------------------------------------------------
; * |             | |B| |A|       | |   |1|0|E|W|A|            |
; * | BASE 31..24 |G|/|0|V| LIMIT |P|DPL|  TYPE   | BASE 23:16 |
; * |             | |D| |L| 19..16| |   |1|1|C|R|A|            |
; * ------------------------------------------------------------
; * |                             |                            |
; * |        BASE 15..0           |       LIMIT 15..0          |
; * |                             |                            |
; * ------------------------------------------------------------
; *
; *  Note the ordering of the data items is reversed from the above
; *  description.
; */


gdtaddr dd    GDT_ADDR

gdtsrc  desc  <0,0,0,0,0,0>                  ;
        desc  <0FFFFh,0,0,09Ah,0CFh,0>       ; flat DS
        desc  <0FFFFh,0,0,092h,0CFh,0>       ; flat CS
        desc  <0FFFFh,?,?,09Eh,0h,?>         ; 16-bit real mode CS
        desc  <0FFFFh,?,?,092h,0h,?>         ; 16-bit real mode DS
        desc  <0FFFFh,?,?,092h,0h,?>         ; 16-bit real mode SS
;ifdef NO_PROT
        desc  <0FFFFh,?,?,09Eh,0h,?>         ; 16-bit real mode CS \--|
        desc  <0FFFFh,?,?,092h,0h,?>         ; 16-bit real mode DS /----for blackboxes
        desc  <0FFFFh,?,?,09Eh,0h,?>         ; 16-bit real mode CS \----for multiboot kernels
        desc  <0FFFFh,?,?,092h,0h,?>         ; 16-bit real mode DS /--|
;endif

gdtsize equ   ($ - gdtsrc)                   ; GDT size

gdtdesc gdtr  <gdtsize - 1, ?>

address dd    ?
        dw    ?

;; A flag which defines, that IDT is initted or not
;idt_initted	db	0

;idtr		gdtr	<>
;idtr_old	gdtr	<>

_DATA   ends

        end

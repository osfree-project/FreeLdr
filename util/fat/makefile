#
# A Makefile for ufat.dll
# (c) osFree project
#

PROJ     = ujfs
DESC     = FAT utility filesystem library
srcfiles   = $(p)func32$(e)
srcfiles16 = $(p)sys$(e) $(p)dummies$(e)
ADD_COPT = -d2 -db -i=$(%WATCOM)$(SEP)h -i=$(%WATCOM)$(SEP)h$(SEP)os2
ADD_LINKOPT  = debug all lib os2386.lib lib clib3r.lib segment   type DATA shared
DLL     = 1
DLLOPT  = initinstance terminstance
EXPORTS = &
	CHKDSK,    &
	SYS,       &
	FORMAT,    &
	RECOVER

DEST    = os2$(SEP)dll

!include $(%ROOT)tools/mk/appsos2.mk
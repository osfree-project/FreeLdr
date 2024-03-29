#
# A Makefile for minifsd
# (c) osFree project,
# author, date
#

PROJ        = mbi
TRGT        = $(PROJ).dll
DESC        = A multiboot info mini-FSD
srcfiles    = $(p)mfs$(e) $(p)fs_stubs$(e) $(p)fs_all$(e) $(p)serial$(e) $(p)vsprintf$(e) &
              $(p)istable$(e) $(p)div$(e) $(p)libc$(e) $(p)cmdline$(e) $(p)os2bird$(e) $(p)end$(e)
ADD_COPT    = -dOS2 -dMINIFSD -2 -mc -zu -ecc -r -s -zdp -ze -zq -oe -i=$(MYDIR)..$(SEP)..$(SEP)include
ADD_LINKOPT = option nod segment type DATA preload segment type CODE preload
# linking dll file
DLL         = 1
32_BITS     = 0
DLLOPT      = initglobal
OPTIONS     = manyautodata
IMPORTS     = &
    FSH_SEGALLOC FSHELPER.1, &
    FSH_SEGFREE FSHELPER.2, &
    FSH_SEGREALLOC FSHELPER.3, &
    FSH_FORCENOSWAP FSHELPER.4, &
    FSH_INTERR FSHELPER.5, &
    FSH_SEMREQUEST FSHELPER.6, &
    FSH_SEMCLEAR FSHELPER.7, &
    FSH_PROBEBUF FSHELPER.8, &
    FSH_GETPRIORITY FSHELPER.9, &
    FSH_IOSEMCLEAR FSHELPER.10, &
    FSH_FLUSHBUF FSHELPER.11, &
    FSH_CRITERROR FSHELPER.12, &
    FSH_DEVIOCTL FSHELPER.13, &
    FSH_GETVOLPARM FSHELPER.14, &
    FSH_FINDDUPHVPB FSHELPER.15, &
    FSH_DOVOLIO FSHELPER.16, &
    FSH_ADDSHARE FSHELPER.17, &
    FSH_REMOVESHARE FSHELPER.18, &
    FSH_GETOVERLAPBUF FSHELPER.19, &
    FSH_ISCURDIRPREFIX FSHELPER.20, &
    FSH_LOADCHAR FSHELPER.21, &
    FSH_PREVCHAR FSHELPER.22, &
    FSH_STORECHAR FSHELPER.23, &
    FSH_SEMSET FSHELPER.24, &
    FSH_SEMSETWAIT FSHELPER.25, &
    FSH_SEMWAIT FSHELPER.26, &
    FSH_WILDMATCH FSHELPER.27, &
    FSH_YIELD FSHELPER.28, &
    FSH_DOVOLIO2 FSHELPER.29, &
    FSH_FINDCHAR FSHELPER.30, &
    MFSH_SETBOOTDRIVE FSHELPER.31, &
    FSH_CANONICALIZE FSHELPER.32, &
    MFSH_DOVOLIO FSHELPER.33, &
    MFSH_INTERR  FSHELPER.34, &
    MFSH_SEGALLOC FSHELPER.35, &
    MFSH_SEGFREE FSHELPER.36, &
    MFSH_SEGREALLOC FSHELPER.37, &
    MFSH_CALLRM FSHELPER.38, &
    MFSH_LOCK FSHELPER.39, &
    MFSH_PHYSTOVIRT FSHELPER.40, &
    MFSH_UNLOCK FSHELPER.41, &
    MFSH_UNPHYSTOVIRT FSHELPER.42, &
    MFSH_VIRT2PHYS FSHELPER.43, &
    FSH_QSYSINFO FSHELPER.44, &
    FSH_NAMEFROMSFN FSHELPER.45, &
    FSH_UPPERCASE FSHELPER.46, &
    FSH_CHECKEANAME FSHELPER.47, &
    FSH_CALLDRIVER FSHELPER.48, &
    FSH_SETVOLUME FSHELPER.49, &
    FSH_STACKSPACE FSHELPER.50, &
    FSH_REGISTERPERFCTRS FSHELPER.51, &
    FSH_IOBOOST FSHELPER.52, &
    FSH_QUERYSERVERTHREAD FSHELPER.53, &
    FSH_QUERYOPLOCK FSHELPER.54, &
    FSH_EXTENDTIMESLICE FSHELPER.55, &
    MFSH_SYSCTL FSHELPER.56
EXPORTS     = &
# Optional
#   FS_ALLOCATEPAGESPACE, &
    FS_ATTACH, &
    FS_CHDIR, &
    FS_CHGFILEPTR, &
    FS_CLOSE, &
    FS_COMMIT, &
    FS_COPY, &
    FS_DELETE, &
    FS_EXIT, &
    FS_FILEATTRIBUTE, &
    FS_FILEINFO, &
# Optional
    FS_FILEIO, &
    FS_FINDCLOSE, &
    FS_FINDFIRST, &
    FS_FINDFROMNAME, &
    FS_FINDNEXT, &
# Obsolete in OS/2 WARP
    FS_FINDNOTIFYCLOSE, &
    FS_FINDNOTIFYFIRST, &
    FS_FINDNOTIFYNEXT, &
######
    FS_FLUSHBUF, &
    FS_FSCTL, &
    FS_FSINFO, &
    FS_INIT, &
    FS_IOCTL, &
    FS_MKDIR, &
    FS_MOUNT, &
    FS_MOVE, &
    FS_NEWSIZE, &
    FS_NMPIPE, &
    FS_OPENCREATE, &
# Optional
#   FS_OPENPAGEFILE, &
    FS_PATHINFO, &
    FS_PROCESSNAME, &
    FS_READ, &
    FS_RMDIR, &
    FS_SETSWAP, &
    FS_SHUTDOWN, &
    FS_WRITE, &
    FS_ATTRIBUTE, &
    FS_NAME, &
    FS_MPSAFEFLAGS2, &
#
# MINI FSD entry points
#
    MFS_CHGFILEPTR, &
    MFS_CLOSE, &
    MFS_INIT, &
    MFS_OPEN, &
    MFS_READ, &
    MFS_TERM

DEST        = none

!include $(%ROOT)tools/mk/appsos2v1.mk

.c: $(MYDIR)..
.c: $(MYDIR)..$(SEP)..

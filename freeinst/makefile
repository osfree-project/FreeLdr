#
# A Makefile for freeinst
# (c) osFree project,
# valerius, 2010/07/14
#
# $Id: makefile,v 1.1 2004/08/16 06:27:30 prokushev Exp $
#

PROJ  = freeinst
TRGT  = $(PROJ).exe
!ifeq ENV OS/2
defs = -dOS2
!endif
!ifeq ENV WIN32
defs = -dWIN32
!endif
!ifeq ENV DOS
defs = -dDPMI32
!endif
!ifeq ENV LINUX
defs = -dLINUX
!endif
ADD_PCOPT =  -B -Fccp437 -Futpro $(defs)
DESC  = FreeLDR installer by Yoda
DEST  = boot
!include $(%ROOT)tools/mk/toolspas.mk

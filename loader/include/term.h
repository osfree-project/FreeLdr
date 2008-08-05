/* term.h - definitions for terminal handling */
/*
 *  GRUB  --  GRand Unified Bootloader
 *  Copyright (C) 2002  Free Software Foundation, Inc.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef GRUB_TERM_HEADER
#define GRUB_TERM_HEADER	1

/* These are used to represent the various color states we use */
typedef enum
{
  /* represents the color used to display all text that does not use the user
   * defined colors below
   */
  COLOR_STATE_STANDARD,
  /* represents the user defined colors for normal text */
  COLOR_STATE_NORMAL,
  /* represents the user defined colors for highlighted text */
  COLOR_STATE_HIGHLIGHT
} color_state;

#ifndef STAGE1_5

/* Flags for representing the capabilities of a terminal.  */
/* Some notes about the flags:
   - These flags are used by higher-level functions but not terminals
   themselves.
   - If a terminal is dumb, you may assume that only putchar, getkey and
   checkkey are called.
   - Some fancy features (nocursor, setcolor, and highlight) can be set to
   NULL.  */

/* Set when input characters shouldn't be echoed back.  */
#define TERM_NO_ECHO		(1 << 0)
/* Set when the editing feature should be disabled.  */
#define TERM_NO_EDIT		(1 << 1)
/* Set when the terminal cannot do fancy things.  */
#define TERM_DUMB		(1 << 2)
/* Set when the terminal needs to be initialized.  */
#define TERM_NEED_INIT		(1 << 16)

struct term_entry
{
  /* The name of a terminal.  */
  const char *name;
  /* The feature flags defined above.  */
  unsigned long flags;
  /* Put a character.  */
  void __cdecl (*putchar) (int c);
  /* Check if any input character is available.  */
  int __cdecl (*checkkey) (void);
  /* Get a character.  */
  int __cdecl (*getkey) (void);
  /* Get the cursor position. The return value is ((X << 8) | Y).  */
  int __cdecl (*getxy) (void);
  /* Go to the position (X, Y).  */
  void __cdecl (*gotoxy) (int x, int y);
  /* Clear the screen.  */
  void __cdecl (*cls) (void);
  /* Set the current color to be used */
  void __cdecl (*setcolorstate) (color_state state);
  /* Set the normal color and the highlight color. The format of each
     color is VGA's.  */
  void __cdecl (*setcolor) (int normal_color, int highlight_color);
  /* Turn on/off the cursor.  */
  int __cdecl (*setcursor) (int on);
};

/* This lists up available terminals.  */
extern struct term_entry term_table[];
/* This points to the current terminal. This is useful, because only
   a single terminal is enabled normally.  */
extern struct term_entry *current_term;

#endif /* ! STAGE1_5 */

#ifdef  TERM_CONSOLE
/* The console stuff.  */
extern int __cdecl console_current_color;
void __cdecl console_putchar (int c);
#pragma aux console_current_color "*"
int __cdecl console_checkkey (void);
int __cdecl console_getkey (void);
int __cdecl console_getxy (void);
void __cdecl console_gotoxy (int x, int y);
void __cdecl console_cls (void);
void __cdecl console_setcolorstate (color_state state);
void __cdecl console_setcolor (int normal_color, int highlight_color);
int __cdecl console_setcursor (int on);
#pragma aux console_putchar       "*"
#pragma aux console_checkkey      "*"
#pragma aux console_getkey        "*"
#pragma aux console_getxy         "*"
#pragma aux console_gotoxy        "*"
#pragma aux console_cls           "*"
#pragma aux console_setcolorstate "*"
#pragma aux console_setcolor      "*"
#pragma aux console_setcursor     "*"
#endif

#ifdef TERM_SERIAL
void __cdecl serial_putchar (int c);
int __cdecl serial_checkkey (void);
int __cdecl serial_getkey (void);
int __cdecl serial_getxy (void);
void __cdecl serial_gotoxy (int x, int y);
void __cdecl serial_cls (void);
void __cdecl serial_setcolorstate (color_state state);
//#pragma aux serial_putchar       "*"
//#pragma aux serial_checkkey      "*"
//#pragma aux serial_getkey        "*"
//#pragma aux serial_getxy         "*"
//#pragma aux serial_gotoxy        "*"
//#pragma aux serial_cls           "*"
//#pragma aux serial_setcolorstate "*"
#endif

#ifdef TERM_HERCULES
void __cdecl hercules_putchar (int c);
int __cdecl console_checkkey (void);
int __cdecl console_getkey (void);
int __cdecl hercules_getxy (void);
void __cdecl hercules_gotoxy (int x, int y);
void __cdecl hercules_cls (void);
void __cdecl hercules_setcolorstate (color_state state);
void __cdecl hercules_setcolor (int normal_color, int highlight_color);
int __cdecl hercules_setcursor (int on);
//#pragma aux hercules_putchar       "*"
#pragma aux console_checkkey       "*"
#pragma aux console_getkey         "*"
//#pragma aux hercules_getxy         "*"
//#pragma aux hercules_gotoxy        "*"
//#pragma aux hercules_cls           "*"
//#pragma aux hercules_setcolorstate "*"
//#pragma aux hercules_setcolor      "*"
//#pragma aux hercules_setcursor     "*"
#endif

#endif /* ! GRUB_TERM_HEADER */

/*!
 * @file putchar.c
 * @brief Mini-libc: single-character output.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"
#include "term.h"

/*!
 * @brief Terminal driver used by grub_putchar when @c use_term is non-zero.
 */
extern struct term_entry *t;
/*!
 * @brief Non-zero while the terminal driver should be used.
 *
 * Cleared during early boot before the terminal is available, so
 * output falls back to the firmware console via u_msg().
 */
unsigned char use_term = 1;

/*!
 * @brief Display one ASCII character.
 * @param[in] c Character to display.
 */
void
grub_putchar (int c)
{
  char buf[2];

  if (!use_term)
  {
    buf[0] = (char)c;
    buf[1] = '\0';
    u_msg(buf);
  }
  else
  {
    t->putchar(c);
  }
}

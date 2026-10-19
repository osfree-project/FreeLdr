/*!
 * @file putstr.c
 * @brief Mini-libc: NUL-terminated string output.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Display a NUL-terminated string via grub_putchar().
 * @param[in] str String to display. Not NULL.
 */
void
grub_putstr (const char *str)
{
  while (*str)
    grub_putchar (*str++);
}

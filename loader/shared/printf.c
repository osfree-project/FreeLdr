/*!
 * @file printf.c
 * @brief Mini-libc: formatted console output.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Format and print to the console.
 *
 * Supports the format specifiers `%u` in all builds, plus `%d`, `%x`,
 * `%X`, `%c` and `%s` on non-STAGE1_5 builds. The variadic arguments
 * are read from the stack via a raw pointer, which is the convention
 * used by the original GRUB mini-libc.
 *
 * @param[in] format NUL-terminated format string. Not NULL.
 * @param[in] ...    Format arguments.
 */
void
grub_printf (const char *format,...)
{
  int *dataptr = (int *) &format;
  char c, str[16];

  dataptr++;

  while ((c = *(format++)) != 0)
    {
      if (c != '%')
        grub_putchar (c);
      else
        switch (c = *(format++))
          {
#ifndef STAGE1_5
          case 'd':
          case 'x':
          case 'X':
#endif
          case 'u':
            *convert_to_ascii (str, c, *((unsigned long *) dataptr++)) = 0;
            grub_putstr (str);
            break;

#ifndef STAGE1_5
          case 'c':
            grub_putchar ((*(dataptr++)) & 0xff);
            break;

          case 's':
            grub_putstr ((char *) *(dataptr++));
            break;
#endif
          }
    }
}

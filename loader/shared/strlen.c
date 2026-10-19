/*!
 * @file strlen.c
 * @brief Mini-libc: string length.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Compute the length of a NUL-terminated string.
 * @param[in] str String. Not NULL.
 * @return Number of bytes before the terminating NUL.
 */
int
grub_strlen (const char *str)
{
   int len = 0;

  while (*str++)
    len++;

  return len;
}

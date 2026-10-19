/*!
 * @file aton.c
 * @brief Mini-libc: ASCII to integer conversion.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Convert a decimal or 0x-prefixed hexadecimal string to an int.
 *
 * Digits are processed left-to-right with positional weight.
 *
 * @param[in] h NUL-terminated input. Not NULL.
 * @retval 0  Input contains a non-digit, or base is 10 but a hex
 *            letter was found.
 * @return The parsed value.
 */
int
grub_aton(char *h)
{
  char *s = h;
  int  i = 0;
  int  j, k, l;
  char c;
  int  base;

  if (s[0] == '0' && s[1] == 'x') {
    base = 16;
    s += 2; // Delete "0x"
  } else {
    base = 10;
  }

  l = grub_strlen(s) - 1;

  while (*s) {
    c = grub_tolower(*s);

    if ('a' <= c && c <= 'f') {
      if (base == 16) {
        c = c - 'a' + 10;
      } else {
        return 0;
      }
    } else if ('0' <= c && c <= '9') {
      c -= '0';
    } else {
      return 0;
    }

    for (j = 0, k = c; j < l; j++)
      k *= base;

    i += k;
    s++;
    l--;
  }

  return i;
}

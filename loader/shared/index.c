/*!
 * @file index.c
 * @brief Mini-libc: character search in a string.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Return the 1-based position of @a c in @a s.
 * @param[in] c Character to find.
 * @param[in] s NUL-terminated string. Not NULL.
 * @retval 0  Not found.
 * @return 1-based position, or 0 if not found.
 */
int grub_index(char c, char *s)
{
  int  i  = 0;
  char *p = s;

  for (;*p != '\0' && *p != c; p++) i++;
  if (!*p) return 0;

  return i + 1;
}

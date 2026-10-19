/*!
 * @file strcmp.c
 * @brief Mini-libc: string comparison.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Compare two NUL-terminated strings.
 * @param[in] s1 First string. Not NULL.
 * @param[in] s2 Second string. Not NULL.
 * @retval -1  @a s1 sorts before @a s2.
 * @retval  0  Strings are equal.
 * @retval  1  @a s1 sorts after @a s2.
 * @return Comparison result.
 */
int
grub_strcmp (const char *s1, const char *s2)
{
  while (*s1 || *s2)
    {
      if (*s1 < *s2)
        return -1;
      else if (*s1 > *s2)
        return 1;
      s1 ++;
      s2 ++;
    }

  return 0;
}

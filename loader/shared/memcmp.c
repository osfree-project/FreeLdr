/*!
 * @file memcmp.c
 * @brief Mini-libc: memory comparison.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Compare two memory regions byte-by-byte.
 * @param[in] s1 First region. Not NULL.
 * @param[in] s2 Second region. Not NULL.
 * @param[in] n  Number of bytes to compare.
 * @retval -1  @a s1 sorts before @a s2.
 * @retval  0  Regions are equal.
 * @retval  1  @a s1 sorts after @a s2.
 * @return Comparison result.
 */
int
grub_memcmp (const char *s1, const char *s2, int n)
{
  while (n)
    {
      if (*s1 < *s2)
        return -1;
      else if (*s1 > *s2)
        return 1;
      s1++;
      s2++;
      n--;
    }

  return 0;
}

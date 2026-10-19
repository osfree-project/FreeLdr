/*!
 * @file strstr.c
 * @brief Mini-libc: substring search.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Find the first occurrence of @a s2 inside @a s1.
 * @param[in] s1 Haystack. Not NULL.
 * @param[in] s2 Needle. Not NULL.
 * @retval 0  @a s2 was not found.
 * @return Pointer to the first occurrence, or NULL.
 */
char *
grub_strstr (const char *s1, const char *s2)
{
  while (*s1)
    {
      const char *ptr, *tmp;

      ptr = s1;
      tmp = s2;

      while (*tmp && *ptr == *tmp)
        ptr++, tmp++;

      if (tmp > s2 && ! *tmp)
        return (char *) s1;

      s1++;
    }

  return 0;
}

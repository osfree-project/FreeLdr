/*!
 * @file substr.c
 * @brief Mini-libc: substring test.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Test whether @a s1 is a prefix of @a s2.
 * @param[in] s1 Candidate prefix. Not NULL.
 * @param[in] s2 String to compare against. Not NULL.
 * @retval  0  Strings are identical.
 * @retval -1  @a s1 is a proper prefix of @a s2.
 * @retval  1  @a s1 is not a prefix of @a s2.
 * @return Comparison result.
 */
int
substring (const char *s1, const char *s2)
{
  while (*s1 == *s2)
    {
      /* The strings match exactly. */
      if (! *(s1++))
        return 0;
      s2 ++;
    }

  /* S1 is a substring of S2. */
  if (*s1 == 0)
    return -1;

  /* S1 isn't a substring. */
  return 1;

}

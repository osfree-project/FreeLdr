/*!
 * @file isspace.c
 * @brief Mini-libc: whitespace classification.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Test whether @a c is a whitespace character.
 * @param[in] c Character to test.
 * @retval 1  @a c is ' ', '\\t', '\\r' or '\\n'.
 * @retval 0  Otherwise.
 * @return Non-zero if @a c is whitespace.
 */
int
grub_isspace (int c)
{
  switch (c)
    {
    case ' ':
    case '\t':
    case '\r':
    case '\n':
      return 1;
    default:
      break;
    }

  return 0;
}

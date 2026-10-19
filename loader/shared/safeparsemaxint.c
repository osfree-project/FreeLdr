/*!
 * @file safeparsemaxint.c
 * @brief Mini-libc: overflow-checked integer parsing.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Parse a decimal or 0x-prefixed hexadecimal integer safely.
 *
 * Advances @p str_ptr past the parsed digits and stores the value in
 * @p myint_ptr. Returns 0 if no digits were found, or if the value
 * would overflow @c MAXINT.
 *
 * @param[in,out] str_ptr   Pointer to the input cursor. Not NULL.
 * @param[out]    myint_ptr Receiver for the parsed value. Not NULL.
 * @retval 0  No digits found, or overflow.
 * @retval 1  Parsed successfully.
 * @return 1 on success.
 */
int
safe_parse_maxint (char **str_ptr, long *myint_ptr)
{
  char *ptr = *str_ptr;
  long myint = 0;
  long mult = 10, found = 0;

  /*
   *  Is this a hex number?
   */
  if (*ptr == '0' && tolower (*(ptr + 1)) == 'x')
    {
      ptr += 2;
      mult = 16;
    }

  while (1)
    {
      /* A bit tricky. This below makes use of the equivalence:
         (A >= B && A <= C) <=> ((A - B) <= (C - B))
         when C > B and A is unsigned.  */
      unsigned int digit;

      digit = tolower (*ptr) - '0';
      if (digit > 9)
        {
          digit -= 'a' - '0';
          if (mult == 10 || digit > 5)
            break;
          digit += 10;
        }

      found = 1;
      if (myint > ((MAXINT - digit) / mult))
        {
          // = ERR_NUMBER_OVERFLOW;
#ifndef STAGE1_5
          //u_parm(PARM_ERRNUM, ACT_SET, (unsigned int *)&errnum);
#endif
          return 0;
        }
      myint = (myint * mult) + digit;
      ptr++;
    }

  if (!found)
    {
      //errnum = ERR_NUMBER_PARSING;
#ifndef STAGE1_5
      //u_parm(PARM_ERRNUM, ACT_SET, (unsigned int *)&errnum);
#endif
      return 0;
    }

  *str_ptr = ptr;
  *myint_ptr = myint;

  return 1;
}

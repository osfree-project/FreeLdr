/*!
 * @file memset.c
 * @brief Mini-libc: memory fill.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Fill @a len bytes at @a start with the byte value @a c.
 * @param[out] start Destination region. Not NULL.
 * @param[in]  c     Fill byte (only the low 8 bits are used).
 * @param[in]  len   Number of bytes to fill.
 * @return @a start.
 */
void *
grub_memset (void *start, int c, int len)
{
  char *p = start;

  //if (grub_memcheck ((int) start, len))
    {
      while (len -- > 0)
        *p ++ = c;
    }
#ifndef STAGE1_5
  //u_parm(PARM_ERRNUM, ACT_GET, (unsigned int *)&errnum);
#endif
  //return errnum ? NULL : start;
  return start;
}

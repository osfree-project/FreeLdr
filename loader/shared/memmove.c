/*!
 * @file memmove.c
 * @brief Mini-libc: overlap-safe memory copy.
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Copy @a _len bytes from @a _from to @a _to, handling overlap.
 * @param[out] _to   Destination region. Not NULL.
 * @param[in]  _from Source region. Not NULL.
 * @param[in]  _len  Number of bytes to copy.
 * @return @a _to.
 */
void *
grub_memmove (void *_to, const void *_from, int _len)
{

    char *from = (char *)_from;
    char *to   = _to;

    //if (grub_memcheck ((unsigned long)(_to), _len))
    //{
        if ( from == to )
        {
            return( to );
        }
        if ( from < to  &&  from + _len > to )
        {
            to += _len;
            from += _len;
            while( _len != 0 )
            {
                *--to = *--from;
                _len--;
            }
        }
        else
        {
            while( _len != 0 )
            {
                *to++ = *from++;
                _len--;
            }
        }
    //}

    return( to );
}

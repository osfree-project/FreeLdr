/*!
 * @file memcheck.c
 * @brief Mini-libc: address-range sanity check (stub).
 */

#include <shared.h>
#include "libc.h"
#include "fsys.h"

/*!
 * @brief Stub range check for a memory region.
 *
 * The real bounds-checking logic is currently disabled; the function
 * always succeeds.
 *
 * @param[in] addr Base address to check.
 * @param[in] len  Region length in bytes.
 * @retval 1  Always (checking is currently disabled).
 * @return 1.
 */
long
grub_memcheck (unsigned long addr, long len)
{
    // Physical address:
    //if ( (addr < RAW_ADDR (0x1000))
    //if ( (addr < RAW_ADDR (0x600)) )
    //    || ((addr <  RAW_ADDR (0x100000)) && (RAW_ADDR(mem_lower * 1024) < (addr + len)))
    //    || ((addr >= RAW_ADDR (0x100000)) && (RAW_ADDR(mem_upper * 1024) < ((addr - 0x100000) + len))) )
    //{
    //    errnum = ERR_WONT_FIT;
    //    //printk("freeldr_memcheck: ERR_WONT_FIT");
    //    //printk("freeldr_memcheck(): addr = 0x%08lx, len = %u", addr, len);
    //    return 0;
    //}

    return 1;
}

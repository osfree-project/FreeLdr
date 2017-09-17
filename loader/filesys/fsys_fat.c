/*
 *  GRUB  --  GRand Unified Bootloader
 *  Copyright (C) 2000,2001,2005   Free Software Foundation, Inc.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#if defined(fsys_fat) || defined(FSYS_FAT)

#include "shared.h"
#include "filesys.h"
#include "fat.h"

#include "fsys.h"
#include "misc.h"
#include "fsd.h"

char fs_name[] = "fat";

/* struct fat_superblock 
{
  unsigned long fat_offset;
  unsigned long fat_length;
  int fat_size;
  int fat_type;
  unsigned long root_offset;
  int root_max;
  unsigned long data_offset;
  
  unsigned long long num_sectors;
  unsigned long num_clust;
  unsigned long clust_eof_marker;
  unsigned long sects_per_clust;
  int sectsize_bits;
  int clustsize_bits;
  unsigned long root_cluster;
  
  long long cached_fat;
  unsigned long file_cluster;
  unsigned long long contig_size;
  unsigned long current_cluster_num;
  unsigned long current_cluster;
}; */

struct fat_superblock 
{
  int fat_offset;
  int fat_length;
  int fat_size;
  int fat_type;
  int root_offset;
  int root_max;
  int data_offset;
  
  int num_sectors;
  int num_clust;
  int clust_eof_marker;
  int sects_per_clust;
  int sectsize_bits;
  int clustsize_bits;
  int root_cluster;
  
  int cached_fat;
  int file_cluster;
  int contig_size;
  int current_cluster_num;
  int current_cluster;
};

/* pointer(s) into filesystem info buffer for DOS stuff */
#define FAT_SUPER ((struct fat_superblock *)(FSYS_BUF + 32256))/* 512 bytes long */
#define FAT_BUF   (FSYS_BUF + 30208)	/* 4 sector FAT buffer(2048 bytes) */
#define NAME_BUF  (FSYS_BUF + 28160)	/* unicode name buffer(833*2 bytes)*/
#define UTF8_BUF  (FSYS_BUF + 25600)	/* UTF8 name buffer (833*3 bytes)*/

#define FAT_CACHE_SIZE 2048

static inline unsigned long
log2_tmp (unsigned long word)
{
  unsigned long l;

  l = word;

  __asm {
     bsf   eax, l
     mov   l,   eax
  }
  return l;
}

/* Convert unicode filename to UTF-8 filename. N is the max UTF-16 characters
 * to be converted. The caller should asure there is enough room in the UTF8
 * buffer. Return the length of the converted UTF8 string.
 */
unsigned long
unicode_to_utf8 (unsigned short *filename, unsigned char *utf8, unsigned long n)
{
	unsigned short uni;
	unsigned long j, k;

	for (j = 0, k = 0; j < n && (uni = filename[j]); j++)
	{
		if (uni <= 0x007F)
		{
			if (uni != ' ')
				utf8[k++] = uni;
			else
			{
				/* quote the SPACE with a backslash */
				utf8[k++] = '\\';
				utf8[k++] = uni;
			}
		}
		else if (uni <= 0x07FF)
		{
			utf8[k++] = 0xC0 | (uni >> 6);
			utf8[k++] = 0x80 | (uni & 0x003F);
		}
		else
		{
			utf8[k++] = 0xE0 | (uni >> 12);
			utf8[k++] = 0x80 | ((uni >> 6) & 0x003F);
			utf8[k++] = 0x80 | (uni & 0x003F);
		}
	}
	utf8[k] = 0;
	return k;
}

int
fat_mount (void)
{
  struct fat_bpb bpb;
  __u32  first_fat;
  __u32  magic;
  
  /* Check partition type for harddisk */
//  if (((current_drive & 0x80) || (current_slice != 0))
//      && ! IS_PC_SLICE_TYPE_FAT (current_slice)
//      && (! IS_PC_SLICE_TYPE_BSD_WITH_FS (current_slice, FS_MSDOS)))
//    return 0;
  
  /* Read bpb */
  if (! (*pdevread) (0, 0, sizeof (bpb), (char *) &bpb))
    return 0;

  if (! bpb.fat_length && ! bpb.fat32_length)
	goto label_exfat;
  /* Check if the number of sectors per cluster is zero here, to avoid
     zero division.  */
  if (bpb.sects_per_clust == 0)
    return 0;
  
  /*  Sectors per cluster. Valid values are 1, 2, 4, 8, 16, 32, 64 and 128.
   *  But a cluster size larger than 32K should not occur.
   */
  if (128 % bpb.sects_per_clust)
    return 0;

  FAT_SUPER->sectsize_bits = log2_tmp (FAT_CVT_U16 (bpb.bytes_per_sect));

  /* sector size must be 512 */
  if (FAT_SUPER->sectsize_bits != 9)
    return 0;

  FAT_SUPER->clustsize_bits
    = FAT_SUPER->sectsize_bits + log2_tmp (bpb.sects_per_clust);
  
  /* cluster size must be <= 32768 */
  if (FAT_SUPER->clustsize_bits > 15)
  {
    //if (debug > 0)
    //   printf_warning ("Warning! FAT cluster size(=%d) larger than 32K!\n", (1 << (FAT_SUPER->clustsize_bits)));
    //return 0;
  }

  /* reserved sectors should not be 0 for fat_fs */
  if (FAT_CVT_U16 (bpb.reserved_sects) == 0)
    return 0;

  /* Number of FATs(nearly always 2).  */
  if ((unsigned char)(bpb.num_fats - 1) > 1)
    return 0;
  
  /* sectors per track(between 1 and 63).  */
  if ((unsigned short)(bpb.secs_track - 1) > 62)
    return 0;
  
  /* number of heads(between 1 and 256).  */
  if ((unsigned short)(bpb.heads - 1) > 255)
    return 0;
  
  /* Fill in info about super block */
  FAT_SUPER->num_sectors = FAT_CVT_U16 (bpb.short_sectors) 
    ? FAT_CVT_U16 (bpb.short_sectors) : bpb.long_sectors;
  
  /* FAT offset and length */
  FAT_SUPER->fat_offset = FAT_CVT_U16 (bpb.reserved_sects);
  FAT_SUPER->fat_length = 
    bpb.fat_length ? bpb.fat_length : bpb.fat32_length;
  
  /* Rootdir offset and length for FAT12/16 */
  FAT_SUPER->root_offset = 
    FAT_SUPER->fat_offset + bpb.num_fats * FAT_SUPER->fat_length;
  FAT_SUPER->root_max = FAT_DIRENTRY_LENGTH * FAT_CVT_U16(bpb.dir_entries);
  
  /* Data offset and number of clusters */
  FAT_SUPER->data_offset = 
    FAT_SUPER->root_offset
    + ((FAT_SUPER->root_max + SECTOR_SIZE - 1) >> FAT_SUPER->sectsize_bits);
  FAT_SUPER->num_clust = 
    2 + (((unsigned long)FAT_SUPER->num_sectors - FAT_SUPER->data_offset) 
	 / bpb.sects_per_clust);
  FAT_SUPER->sects_per_clust = bpb.sects_per_clust;
  
  if (!bpb.fat_length)
    {
      /* This is a FAT32 */
      if (FAT_CVT_U16(bpb.dir_entries))
 	return 0;
      
      if (bpb.flags & 0x0080)
	{
	  /* FAT mirroring is disabled, get active FAT */
	  int active_fat = bpb.flags & 0x000f;
	  if (active_fat >= bpb.num_fats)
	    return 0;
	  FAT_SUPER->fat_offset += active_fat * FAT_SUPER->fat_length;
	}
      
      FAT_SUPER->fat_type = 32;
      FAT_SUPER->fat_size = 8;
      FAT_SUPER->root_cluster = bpb.root_cluster;

      /* Yes the following is correct.  FAT32 should be called FAT28 :) */
      FAT_SUPER->clust_eof_marker = 0xffffff8;
    } 
  else 
    {
      if (!FAT_SUPER->root_max)
 	return 0;
      
      FAT_SUPER->root_cluster = -1;
      if (FAT_SUPER->num_clust > FAT_MAX_12BIT_CLUST) 
	{
	  FAT_SUPER->fat_type = 16;
	  FAT_SUPER->fat_size = 4;
	  FAT_SUPER->clust_eof_marker = 0xfff8;
	} 
      else
	{
    	  FAT_SUPER->fat_type = 12;
	  FAT_SUPER->fat_size = 3;
	  FAT_SUPER->clust_eof_marker = 0xff8;
	}
    }

  /* Now do some sanity checks */
  
  if (FAT_CVT_U16(bpb.bytes_per_sect) != (1 << FAT_SUPER->sectsize_bits)
      || FAT_CVT_U16(bpb.bytes_per_sect) != SECTOR_SIZE
      || bpb.sects_per_clust != (1 << (FAT_SUPER->clustsize_bits
 				       - FAT_SUPER->sectsize_bits))
      || FAT_SUPER->num_clust <= 2
      || (FAT_SUPER->fat_size * FAT_SUPER->num_clust / (2 * SECTOR_SIZE)
 	  > FAT_SUPER->fat_length))
    return 0;
  
  /* kbs: Media check on first FAT entry [ported from PUPA] */

  if (!(*pdevread)(FAT_SUPER->fat_offset, 0,
               sizeof(first_fat), (char *)&first_fat))
    return 0;

  if (FAT_SUPER->fat_size == 8)
    {
      first_fat &= 0x0fffffff;
      magic = 0x0fffff00;
    }
  else if (FAT_SUPER->fat_size == 4)
    {
      first_fat &= 0x0000ffff;
      magic = 0xff00;
    }
  else
    {
      first_fat &= 0x00000fff;
      magic = 0x0f00;
    }

  /* Ignore the 3rd bit, because some BIOSes assigns 0xF0 to the media
     descriptor, even if it is a so-called superfloppy (e.g. an USB key).
     The check may be too strict for this kind of stupid BIOSes, as
     they overwrite the media descriptor.  */
//  if ((first_fat | 0x8) != (magic | bpb.media | 0x8))
//  if ((first_fat | 0x8) != (magic | 0xF8))
  if ((first_fat | 0xF) != (magic | 0xFF))
  {
    //if (debug > 0)
    //   printf_warning ("Warning! Invalid first FAT entry(=0x%X)!\n", first_fat);
    //return 0;
  }

  FAT_SUPER->cached_fat = - 2 * FAT_CACHE_SIZE;
  return 1;

label_exfat:
    /*  bytes per sector for exFAT must be 0 */
    if (FAT_CVT_U16 (bpb.bytes_per_sect))  
      return 0;

    /* sector_bits - Power of 2. Minimum 9 (512 bytes per sector), 
    maximum 12 (4096 bytes per sector) */
    FAT_SUPER->sectsize_bits = bpb.sector_bits;

//    if ((FAT_SUPER->sectsize_bits < 9) || (FAT_SUPER->sectsize_bits > 12))
//      return 0;

    /* sector size must be 512 */
    if (FAT_SUPER->sectsize_bits != 9)
      return 0;

    /* spc_bits - Power of 2. Minimum 0 (1 sector per cluster), 
    maximum 25 – BytesPerSectorShift, so max cluster size is 32 MB */
    FAT_SUPER->clustsize_bits
      = FAT_SUPER->sectsize_bits + bpb.spc_bits;

    if (FAT_SUPER->clustsize_bits > 25)
      return 0;

    /* cluster size must be <= 32768 */
    //if (FAT_SUPER->clustsize_bits > 15)
    //{
    //  if (debug > 0)
    //	printf_warning ("Warning! FAT cluster size(=%d) larger than 32K!\n", (1 << (FAT_SUPER->clustsize_bits)));
    //  //return 0;
    //}

    /* Number of FATs(nearly always 1, 2 is for TexFAT only).  */
    if ((unsigned char)(bpb.fat_count - 1) > 1)
      return 0;

    /* Fill in info about super block */
    FAT_SUPER->num_sectors = bpb.sector_count;
  
    /* FAT offset and length */
    FAT_SUPER->fat_offset = bpb.fat_sector_start;
    FAT_SUPER->fat_length = bpb.fat_sector_count;
    
    FAT_SUPER->fat_type = 64;
    FAT_SUPER->fat_size = 8;
  
    /* Data offset and number of clusters */
    FAT_SUPER->data_offset = bpb.cluster_sector_start;

    /* Rootdir offset and length for FAT12/16 */
    FAT_SUPER->root_offset = FAT_SUPER->data_offset;
    FAT_SUPER->root_max = 0;
  
    /* Test data offset */
//    if (FAT_SUPER->data_offset != FAT_SUPER->fat_offset + bpb.fat_count * FAT_SUPER->fat_length)
//      return 0;

    FAT_SUPER->num_clust = bpb.cluster_count;
    
    FAT_SUPER->sects_per_clust = (unsigned long)1 << bpb.spc_bits;

    if (FAT_CVT_U16(bpb.dir_entries))
 	  return 0;

    /* ActiveFat 0 - First FAT and Allocation Bitmap are active, 1- Second. */ 
    if (bpb.volume_state & 0x0001)
    {
	if (bpb.fat_count<2)
 	    return 0;
	FAT_SUPER->fat_offset += FAT_SUPER->fat_length;
    }


    FAT_SUPER->root_cluster = bpb.rootdir_cluster;

    FAT_SUPER->clust_eof_marker = EXFAT_CLUSTER_END;


    /* Now do some sanity checks */

    if (FAT_SUPER->num_clust <= 2
        || (FAT_SUPER->fat_size * FAT_SUPER->num_clust / (2 * SECTOR_SIZE)
   	  > FAT_SUPER->fat_length))
      return 0;
  
    /* check first FAT entry */

    if (!(*pdevread)(FAT_SUPER->fat_offset, 0, sizeof(first_fat),
	(char *)&first_fat))
      return 0;
    
    //if (first_fat != 0xfffffff8)
    //{
    //  if (debug > 0)
    //	printf_warning ("Warning! Invalid first FAT entry(=0x%X)!\n", first_fat);
    //  //return 0;
    //}

  FAT_SUPER->cached_fat = - 2 * FAT_CACHE_SIZE;
  return 1;
}

int
fat_read (char *buf, int len)
//unsigned long long
//fat_read (unsigned long long buf, unsigned long long len, unsigned long write)
{
  unsigned long logical_clust;
  unsigned long offset;
  unsigned long ret = 0;
  unsigned long size;

  if (! len)
    return 0;
  
  if (FAT_SUPER->file_cluster == MAXINT)
    {
      if (! FAT_SUPER->root_max)
	return 0;
      if (FAT_SUPER->root_max <= *pfilepos)
	return 0;
      if (FAT_SUPER->fat_type > 16)
	return 0;
      /* root directory for FAT12/FAT16 */
      size = FAT_SUPER->root_max - *pfilepos;
      if (size > len)
 	size = len;
      if (!(*pdevread)(FAT_SUPER->root_offset, *pfilepos, size, buf))
 	return 0;
      *pfilepos += size;
      return size;
    }
  
  
  if  ((FAT_SUPER->fat_type == 64) && (FAT_SUPER->contig_size))
  {
      unsigned long sector;
      sector = FAT_SUPER->data_offset + ((FAT_SUPER->file_cluster - 2)
		<< (FAT_SUPER->clustsize_bits - FAT_SUPER->sectsize_bits));

      if ( *pfilepos >= FAT_SUPER->contig_size )
        return 0; 
      else
        if ( *pfilepos + len > FAT_SUPER->contig_size ) 
    	    size = FAT_SUPER->contig_size - *pfilepos;
        else 
    	    size = len;
        
      *pdisk_read_func = *pdisk_read_hook;
      
      (*pdevread)(sector, *pfilepos, size, buf);
      //(*pdevread)(sector, *pfilepos, size, buf, write);
      
      *pdisk_read_func = NULL;
      
      if (buf)
	buf += size;
      ret = size;
      *pfilepos += size;
      FAT_SUPER->current_cluster_num = 0;
      FAT_SUPER->current_cluster = FAT_SUPER->file_cluster;
      return *perrnum ? 0 : ret;
  }
  logical_clust = *pfilepos >> FAT_SUPER->clustsize_bits;
  offset = (*pfilepos & ((1 << FAT_SUPER->clustsize_bits) - 1));
  if (logical_clust < FAT_SUPER->current_cluster_num)
    {
      FAT_SUPER->current_cluster_num = 0;
      FAT_SUPER->current_cluster = FAT_SUPER->file_cluster;
    }
  
  while (len > 0)
    {
      unsigned long sector;
      while (logical_clust > FAT_SUPER->current_cluster_num)
	{
	  /* calculate next cluster */
	  unsigned long fat_entry = 
	    FAT_SUPER->current_cluster * FAT_SUPER->fat_size;
	  unsigned long next_cluster;
	  unsigned long cached_pos = (fat_entry - FAT_SUPER->cached_fat);
	  
	  if (fat_entry < FAT_SUPER->cached_fat || 
	      (cached_pos + FAT_SUPER->fat_size) > 2*FAT_CACHE_SIZE)
	    {
	      FAT_SUPER->cached_fat = (fat_entry & ~(2*SECTOR_SIZE - 1));
	      cached_pos = (fat_entry - FAT_SUPER->cached_fat);
	      sector = FAT_SUPER->fat_offset
		+ FAT_SUPER->cached_fat / (2*SECTOR_SIZE);
	      if (!(*pdevread) (sector, 0, FAT_CACHE_SIZE, (char*) FAT_BUF))
		return 0;
	    }
	  next_cluster = * (unsigned long *) (FAT_BUF + (cached_pos >> 1));
	  if (FAT_SUPER->fat_size == 3)
	    {
	      if (cached_pos & 1)
		next_cluster >>= 4;
	      next_cluster &= 0xFFF;
	    }
	  else if (FAT_SUPER->fat_size == 4)
	    next_cluster &= 0xFFFF;
	  
	  if (next_cluster >= FAT_SUPER->clust_eof_marker)
	    return ret;
	  if (next_cluster < 2 || next_cluster >= FAT_SUPER->num_clust)
	    {
	      *perrnum = ERR_FSYS_CORRUPT;
	      return 0;
	    }
	  
	  FAT_SUPER->current_cluster = next_cluster;
	  FAT_SUPER->current_cluster_num++;
	}
      
      sector = FAT_SUPER->data_offset + ((FAT_SUPER->current_cluster - 2)
		<< (FAT_SUPER->clustsize_bits - FAT_SUPER->sectsize_bits));
      
      size = (1 << FAT_SUPER->clustsize_bits) - offset;
      
      if (size > len)
	  size = len;
      
      *pdisk_read_func = *pdisk_read_hook;
      
      (*pdevread)(sector, offset, size, buf);
      //(*pdevread)(sector, offset, size, buf, write);
      
      *pdisk_read_func = NULL;
      
      len -= size;	/* len always >= 0 */
      if (buf)
	buf += size;
      ret += size;
      *pfilepos += size;
      logical_clust++;
      offset = 0;
    }
  return *perrnum ? 0 : ret;
}

int
fat_dir (char *dirname)
{
  char *rest, ch, dir_buf[FAT_DIRENTRY_LENGTH];
  unsigned short *filename = (unsigned short *) NAME_BUF; /* unicode */
  unsigned char *utf8 = (unsigned char *) UTF8_BUF; /* utf8 filename */
  int attrib = FAT_ATTRIB_DIR;
  int exfat_attrib = FAT_ATTRIB_DIR;
  int exfat_flags = 0;
  int exfat_secondarycount = 0;
  int exfat_namecount = 0;
  int exfat_nextentry =  EXFAT_ENTRY_FILE;
  unsigned long long exfat_filemax = 0;
  unsigned long exfat_file_cluster = 0;
  
//  int do_possibilities = 0;
  
  /* XXX I18N:
   * the positions 2,4,6 etc are high bytes of a 16 bit unicode char 
   */
  static unsigned char longdir_pos[] = 
  { 1, 3, 5, 7, 9, 14, 16, 18, 20, 22, 24, 28, 30 };
  int slot = -2;
  int alias_checksum = -1;
  
  FAT_SUPER->file_cluster = FAT_SUPER->root_cluster;
  
  if (FAT_SUPER->fat_type == 64)
	FAT_SUPER->contig_size = 0;/* root directory always not contiguous */

  /* main loop to find desired directory entry */
 loop:
  *pfilepos = 0;
  FAT_SUPER->current_cluster_num = MAXINT;
  
  /* if we have a real file (and we're not just printing possibilities),
     then this is where we want to exit */
  
  if (!*dirname || (*pgrub_isspace) (*dirname))
    {
      if (attrib & FAT_ATTRIB_DIR)
	{
	  *perrnum = ERR_BAD_FILETYPE;
	  return 0;
	}
      
      return 1;
    }
  
  /* continue with the file/directory name interpretation */
  
  /* skip over slashes */
  while (*dirname == '/')
    dirname++;
  
  if (!(attrib & FAT_ATTRIB_DIR))
    {
      *perrnum = ERR_BAD_FILETYPE;
      return 0;
    }
  /* Directories don't have a file size */
  *pfilemax = MAXINT;
  
  /* check if the dirname ends in a slash(saved in CH) and end it in a NULL */
  //for (rest = dirname; (ch = *rest) && !isspace (ch) && ch != '/'; rest++);
  for (rest = dirname; (ch = *rest) && !(*pgrub_isspace) (ch) && ch != '/'; rest++)
  {
	if (ch == '\\')
	{
		rest++;
		if (! (ch = *rest))
			break;
	}
  }
  
  *rest = 0;
  
//  if (print_possibilities && ch != '/')
//    do_possibilities = 1;
  
  while (1)
    {
      /* read the dir entry */
      if (fat_read (dir_buf, FAT_DIRENTRY_LENGTH) != FAT_DIRENTRY_LENGTH
		/* read failure */
	  || dir_buf[0] == 0 /* end of dir entry */)
	{
	  if (*perrnum == 0)
	    {
	      if (*pprint_possibilities < 0)
		{
		  /* previously succeeded, so return success */
		  *rest = ch;	/* XXX: Should restore the byte? */
		  return 1;
		}
	      
	      *perrnum = ERR_FILE_NOT_FOUND;
	    }
	  
	  *rest = ch;
	  return 0;
	}
      
      if (FAT_SUPER->fat_type == 64)
      {
	if (EXFAT_DIRENTRY_ATTRIB (dir_buf) != exfat_nextentry)
	{
	  exfat_nextentry = EXFAT_ENTRY_FILE;
	  continue;
	}
	{
	  int i;
	  switch (EXFAT_DIRENTRY_ATTRIB (dir_buf))
	  {
	    case EXFAT_ENTRY_FILE:
		    exfat_attrib = (*(unsigned short *)(dir_buf+4));
		    exfat_secondarycount = (*(unsigned char *)(dir_buf+1));
		    if ((exfat_secondarycount<2)||(exfat_secondarycount>18))
			/* invalid */
			exfat_nextentry = EXFAT_ENTRY_FILE;
		    else 
			exfat_secondarycount --;        		
		    exfat_namecount = 0;
		    exfat_nextentry = EXFAT_ENTRY_FILE_INFO;
		    continue;
	    case EXFAT_ENTRY_FILE_INFO:
		    exfat_filemax = (*(unsigned long long *)(dir_buf+8));
		    exfat_file_cluster = (*(unsigned long *)(dir_buf+20));
		    exfat_flags = (*(unsigned short *)(dir_buf+1));
		    exfat_nextentry = EXFAT_ENTRY_FILE_NAME;
		    continue;
	    case EXFAT_ENTRY_FILE_NAME:
		    for (i=0; i < 15; i++)
			filename[i+(15*exfat_namecount)]
				= *(unsigned short *)(dir_buf+2+(i<<1));
		    exfat_namecount++;
		    filename[15*exfat_namecount] = 0;
		    if (exfat_namecount < exfat_secondarycount)
		    {
			exfat_nextentry = EXFAT_ENTRY_FILE_NAME;
			continue;
		    }
		    exfat_nextentry = EXFAT_ENTRY_FILE;
		    goto valid_filename;
	    default:
		    exfat_nextentry = EXFAT_ENTRY_FILE;
		    continue;
	  }
	}
      }

      if (FAT_DIRENTRY_ATTRIB (dir_buf) == FAT_ATTRIB_LONGNAME)
	{
	  /* This is a long filename.  The filename is build from back
	   * to front and may span multiple entries.  To bind these
	   * entries together they all contain the same checksum over
	   * the short alias.
	   *
	   * The id field tells if this is the first entry (the last
	   * part) of the long filename, and also at which offset this
	   * belongs.
	   *
	   * We just write the part of the long filename this entry
	   * describes and continue with the next dir entry.
	   */
	  int i, offset;
	  unsigned char id = FAT_LONGDIR_ID(dir_buf);
	  
	  if ((id & 0x40)) 
	    {
	      id &= 0x3f;
	      slot = id;
	      filename[slot * 13] = 0;
	      alias_checksum = FAT_LONGDIR_ALIASCHECKSUM(dir_buf);
	    } 
	  
	  if (id != slot || slot == 0
	      || alias_checksum != FAT_LONGDIR_ALIASCHECKSUM(dir_buf))
	    {
	      alias_checksum = -1;
	      continue;
	    }
	  
	  slot--;
	  offset = slot * 13;
	  
	  for (i=0; i < 13; i++)
	    filename[offset+i] = *(unsigned short *)(dir_buf+longdir_pos[i]);
	  continue;
	}
      
      if (!FAT_DIRENTRY_VALID (dir_buf))
	continue;

      if (alias_checksum != -1 && slot == 0)
	{
	  int i;
	  unsigned char sum;
	  
	  slot = -2;
	  for (sum = 0, i = 0; i< 11; i++)
	    sum = ((sum >> 1) | (sum << 7)) + dir_buf[i];
	  
	  if (sum == alias_checksum)
	    {
	      goto valid_filename;
//	      if (do_possibilities)
//		goto print_filename;
//	      
//	      if (substring (dirname, filename, 1) == 0)
//		break;
	    }
	}
short_name:
      /* XXX convert to 8.3 filename format here */
      {
	unsigned int i, j, c, y;
#define TOLOWER(c,y) (((y) && ((unsigned)((c) - 'A') < 26)) ? ((c)|0x20) : (c))
	
	y = (dir_buf[12] & 0x08);	// filename base in lower case
	for (i = 0; i < 8 && (c = filename[i] = TOLOWER (dir_buf[i], y))
	       && /*!isspace (c)*/ c != ' '; i++);
	
	filename[i++] = '.';
	
	y = (dir_buf[12] & 0x10);	// filename extension in lower case
	for (j = 0; j < 3 && (c = filename[i+j] = TOLOWER (dir_buf[8+j], y))
	       && /*!isspace (c)*/ c != ' '; j++);
	
	if (j == 0)
	  i--;
	
	filename[i + j] = 0;
      }
      
valid_filename:
      unicode_to_utf8 (filename, utf8, 832);

      if (*pprint_possibilities && ch != '/')
	{
//	print_filename:
	  if ((*psubstring) (dirname, (char *)utf8) <= 0)
	    {
	      if (*pprint_possibilities > 0)
		*pprint_possibilities = -*pprint_possibilities;
	      (*pprint_a_completion) ((char *)utf8);
	    }
	  continue;
	}
      
      if ((*psubstring) (dirname, (char *)utf8) == 0)
	break;
	 if (alias_checksum != -1)
	  {
 		alias_checksum = -1;
		goto short_name;
	  }
    }
  
  *(dirname = rest) = ch;
  
  if (FAT_SUPER->fat_type == 64)
  {
    attrib = exfat_attrib;
    *pfilemax = exfat_filemax;
    FAT_SUPER->file_cluster = exfat_file_cluster;
    if (exfat_flags & EXFAT_FLAG_CONTIGUOUS) /* NoFatChain */
	FAT_SUPER->contig_size = (*pfilemax + ((1 << FAT_SUPER->clustsize_bits) - 1)) & ~((1 << FAT_SUPER->clustsize_bits) - 1);
    else 
	FAT_SUPER->contig_size = 0;
    goto loop;
  }

  attrib = FAT_DIRENTRY_ATTRIB (dir_buf);
  *pfilemax = FAT_DIRENTRY_FILELENGTH (dir_buf);
  FAT_SUPER->file_cluster = FAT_DIRENTRY_FIRST_CLUSTER (dir_buf);
  
  /* go back to main loop at top of function */
  goto loop;
}

#endif /* FSYS_FAT */

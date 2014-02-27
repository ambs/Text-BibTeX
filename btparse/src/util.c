/* ------------------------------------------------------------------------
@NAME       : util.c
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Miscellaneous utility functions.  So far, just:
                 strlwr
                 strupr
@CREATED    : Summer 1996, Greg Ward
@MODIFIED   : 
@VERSION    : $Id$
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#include "bt_config.h"
#include <string.h>
#include <ctype.h>
#include "prototypes.h"
#include "my_dmalloc.h"

/* ------------------------------------------------------------------------
@NAME       : strlwr()
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Converts a string to lowercase in place.
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1996/01/06, GPW
@MODIFIED   : 
@COMMENTS   : This should work the same as strlwr() in DOS compilers --
              why this isn't mandated by ANSI is a mystery to me...
-------------------------------------------------------------------------- */
#if !HAVE_STRLWR
char *strlwr (char *s)
{
   int  len, i;

   len = strlen (s);
   for (i = 0; i < len; i++)
      s[i] = tolower (s[i]);

   return s;
}
#endif



/* ------------------------------------------------------------------------
@NAME       : strupr()
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Converts a string to uppercase in place.
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1996/01/06, GPW
@MODIFIED   : 
@COMMENTS   : This should work the same as strupr() in DOS compilers --
              why this isn't mandated by ANSI is a mystery to me...
-------------------------------------------------------------------------- */
#if !HAVE_STRUPR
char *strupr (char *s)
{
   int  len, i;

   len = strlen (s);
   for (i = 0; i < len; i++)
      s[i] = toupper (s[i]);

   return s;
}
#endif

/* ------------------------------------------------------------------------
@NAME       : get_uchar()
@INPUT      : string
              offset in string
@OUTPUT     : number of bytes required to gobble the next unicode character, including any combining marks
@RETURNS    : 
@DESCRIPTION: In order to deal with unicode chars when calculating abbreviations,
              we need to know how many bytes the next character is.
@CALLS      : 
@CALLERS    : count_virtual_char()
@CREATED    : 2010/03/14, PK
@MODIFIED   : 
-------------------------------------------------------------------------- */
int
get_uchar(char * string, int offset)
{
  unsigned char * bytes = (unsigned char *)string;
  int init;
  unsigned int c = 0; // Without unsigned, for some reason Solaris coredumps

  if(!string)
    return 0;

  if (     (// ASCII
            bytes[offset] == 0x09 ||
            bytes[offset] == 0x0A ||
            bytes[offset] == 0x0D ||
            (0x20 <= bytes[offset] && bytes[offset] <= 0x7E)
            )
           )
    {
      init = 1;
    }

  if(     (// non-overlong 2-byte
           (0xC2 <= bytes[offset] && bytes[offset] <= 0xDF) &&
           (0x80 <= bytes[offset+1] && bytes[offset+1] <= 0xBF)
           )
          )
    {
      init = 2;
    }

  if(     (// excluding overlongs
           bytes[offset] == 0xE0 &&
           (0xA0 <= bytes[offset+1] && bytes[offset+1] <= 0xBF) &&
           (0x80 <= bytes[offset+2] && bytes[offset+2] <= 0xBF)
           ) ||
          (// straight 3-byte
           ((0xE1 <= bytes[offset] && bytes[offset] <= 0xEC) ||
            bytes[offset] == 0xEE ||
            bytes[offset] == 0xEF) &&
           (0x80 <= bytes[offset+1] && bytes[offset+1] <= 0xBF) &&
           (0x80 <= bytes[offset+2] && bytes[offset+2] <= 0xBF)
           ) ||
          (// excluding surrogates
           bytes[offset] == 0xED &&
           (0x80 <= bytes[offset+1] && bytes[offset+1] <= 0x9F) &&
           (0x80 <= bytes[offset+2] && bytes[offset+2] <= 0xBF)
           )
          )
    {
      init = 3;
    }

  if(     (// planes 1-3
           bytes[offset] == 0xF0 &&
           (0x90 <= bytes[offset+1] && bytes[offset+1] <= 0xBF) &&
           (0x80 <= bytes[offset+2] && bytes[offset+2] <= 0xBF) &&
           (0x80 <= bytes[offset+3] && bytes[offset+3] <= 0xBF)
           ) ||
          (// planes 4-15
           (0xF1 <= bytes[offset] && bytes[offset] <= 0xF3) &&
           (0x80 <= bytes[offset+1] && bytes[offset+1] <= 0xBF) &&
           (0x80 <= bytes[offset+2] && bytes[offset+2] <= 0xBF) &&
           (0x80 <= bytes[offset+3] && bytes[offset+3] <= 0xBF)
           ) ||
          (// plane 16
           bytes[offset] == 0xF4 &&
           (0x80 <= bytes[offset+1] && bytes[offset+1] <= 0x8F) &&
           (0x80 <= bytes[offset+2] && bytes[offset+2] <= 0xBF) &&
           (0x80 <= bytes[offset+3] && bytes[offset+3] <= 0xBF)
           )
          )
    {
      init = 4;
    }

  /* Now check for combining marks which are separate even in NFC */
  while (bytes[offset+init+c]) {
    /* 0300–036F - Combining Diacritical Marks */
    if (  bytes[offset+init+c] == 0xCC &&
          (0x80 <= bytes[offset+init+1+c] && bytes[offset+init+1+c] <= 0xAF)
          )
      {
        c = c + 2; /* Skip to next possible combining mark */
      }
    /* 1DC0–1DFF - Combining Diacritical Marks Supplement */
    else if (  bytes[offset+init+c] == 0xE1 &&
               bytes[offset+init+1+c] == 0xB7 &&
               (0x80 <= bytes[offset+init+2+c] && bytes[offset+init+2+c] <= 0xBF)
               )
      {
        c = c + 3; /* Skip to next possible combining mark */
      }
    /* FE20–FE2F - Combining Half Marks */
    else if (  bytes[offset+init+c] == 0xEF &&
               bytes[offset+init+1+c] == 0xB8 &&
               (0xA0 <= bytes[offset+init+2+c] && bytes[offset+init+2+c] <= 0xAF)
               )
      {
        c = c + 3; /* Skip to next possible combining mark */
      }
    else {
      break;
    }
  }
  return init+c;
}

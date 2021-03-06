/* ------------------------------------------------------------------------
@NAME       : parse_auxiliary.c
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Anything needed by the parser that's too hairy to go in the
              grammar itself.  Currently, just stuff needed for generating
              syntax errors. (See error.c for how they're actually
              printed.)
@GLOBALS    : 
@CALLS      : 
@CALLERS    : 
@CREATED    : 1996/08/07, Greg Ward
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
#include "stdpccts.h"
#include "error.h"
#include "lex_auxiliary.h"
#include "parse_auxiliary.h"
#include "my_dmalloc.h"

extern char * InputFilename;            /* from input.c */

GEN_PRIVATE_ERRFUNC (syntax_error, (char * fmt, ...),
                     BTERR_SYNTAX, InputFilename, zzline, NULL, -1, fmt)


/* this is stolen from PCCTS' err.h */
static SetWordType bitmask[] = 
{
    0x00000001, 0x00000002, 0x00000004, 0x00000008,
    0x00000010, 0x00000020, 0x00000040, 0x00000080
};

static struct 
{
   int    token;
   char  *new_name;
} new_tokens[] = 
{
   { AT,         "\"@\"" },
   { NAME,       "name (entry type, key, field, or macro name)" },
   { LBRACE,     "left brace (\"{\")" },
   { RBRACE,     "right brace (\"}\")" },
   { ENTRY_OPEN, "start of entry (\"{\" or \"(\")" },
   { ENTRY_CLOSE,"end of entry (\"}\" or \")\")" },
   { EQUALS,     "\"=\"" },
   { HASH,       "\"#\"" },
   { COMMA,      "\",\"" },
   { NUMBER,     "number" },
   { STRING,     "quoted string ({...} or \"...\")" }
};


#ifdef CLEVER_TOKEN_STUFF
char **token_names;
#endif


#ifndef HAVE_STRLCAT
/********************************* AMBS **********************/
/*
 * Appends src to string dst of size dsize (unlike strlcat, dsize is the
 * full size of dst, not space left).  At most dsize-1 characters
 * will be copied.  Always NUL terminates (unless dsize <= strlen(dst)).
 * Returns strlen(src) + MIN(dsize, strlen(initial dst)).
 * If retval >= dsize, truncation occurred.
 */
static size_t
strlcat(char *dst, const char *src, size_t dsize)
{
        const char *odst = dst;
        const char *osrc = src;
        size_t n = dsize;
        size_t dlen;

        /* Find the end of dst and adjust bytes left but don't go past end. */
        while (n-- != 0 && *dst != '\0')
                dst++;
        dlen = dst - odst;
        n = dsize - dlen;

        if (n-- == 0)
                return(dlen + strlen(src));
        while (*src != '\0') {
                if (n != 0) {
                        *dst++ = *src;
                        n--;
                }
                src++;
        }
        *dst = '\0';

        return(dlen + (src - osrc));    /* count does not include NUL */
}
/********************************* AMBS **********************/
#endif
















void
fix_token_names (void)
{
   int    i;
   int    num_replace;

#ifdef CLEVER_TOKEN_STUFF               /* clever, but it doesn't work... */
   /* arg! this doesn't work because I don't know how to find out the
    * number of tokens
    */

   int    num_tok;

   num_tok = (sizeof(zztokens) / sizeof(*zztokens));
   sizeof (zztokens);
   sizeof (*zztokens);
   token_names = (char **) malloc (sizeof (char *) * num_tok);

   for (i = 0; i < num_tok; i++)
   {
      token_names[i] = zztokens[i];
   }
#endif

   num_replace = (sizeof(new_tokens) / sizeof(*new_tokens));
   for (i = 0; i < num_replace; i++)
   {
      char  *new = new_tokens[i].new_name;
      char **old = zztokens + new_tokens[i].token;

      *old = new;
   }
}


#ifdef USER_ZZSYN

static void
append_token_set (char *msg, SetWordType *a)
{
   SetWordType *p = a;
   SetWordType *endp = &(p[zzSET_SIZE]);
   unsigned e = 0;
   int      tokens_printed = 0;
   
   do 
   {
      SetWordType t = *p;
      SetWordType *b = &(bitmask[0]);
      do
      {
         if (t & *b)
         {
            strlcat (msg, zztokens[e], MAX_ERROR);
            tokens_printed++;
            if (tokens_printed < zzset_deg (a) - 1)
               strlcat (msg, ", ", MAX_ERROR);
            else if (tokens_printed == zzset_deg (a) - 1)
               strlcat (msg, " or ", MAX_ERROR);
         }
         e++;
      } while (++b < &(bitmask[sizeof(SetWordType)*8]));
   } while (++p < endp);
}


void
zzsyn(char *        text,
      int           tok, 
      char *        egroup,
      SetWordType * eset,
      int           etok,
      int           k,
      char *        bad_text)
{
   static char    msg [MAX_ERROR];
   int            len;

#ifndef ALLOW_WARNINGS
   text = NULL;                         /* avoid "unused parameter" warning */
#endif

   /* Initial message: give location of error */

   msg[0] = (char) 0;           /* make sure string is empty to start! */
   if (tok == zzEOF_TOKEN)
      strlcat (msg, "at end of input", MAX_ERROR);
   else
     snprintf (msg, MAX_ERROR - 1, "found \"%s\"", bad_text);

   len = strlen (msg);

   
   /* Caller supplied neither a single token nor set of tokens expected... */

   if (!etok && !eset)
   {
      syntax_error (msg);
      return;
   }
   else
   {
      strlcat (msg, ", ", MAX_ERROR);
      len += 2;
   }

   
   /* I'm not quite sure what this is all about, or where k would be != 1... */
   
   if (k != 1)
   {
      snprintf (msg+len, MAX_ERROR - len - 1, "; \"%s\" not", bad_text);
      if (zzset_deg (eset) > 1) strcat (msg, " in");
      len = strlen (msg);
   }


   /* This is the code that usually gets run */
   
   if (zzset_deg (eset) > 0) 
   {
      if (zzset_deg (eset) == 1)
         strlcat (msg, "expected ", MAX_ERROR);
      else
         strlcat (msg, "expected one of: ", MAX_ERROR);

      append_token_set (msg, eset);
   }
   else
   {
      if (MAX_ERROR - len > 0)  // Check if we have space for more info...
         snprintf (msg+len, MAX_ERROR - len - 1, "expected %s", zztokens[etok]);
      if (etok == ENTRY_CLOSE)
      {
         strlcat (msg, " (skipping to next \"@\")", MAX_ERROR);
         initialize_lexer_state ();
      }
   }

   len = strlen (msg);
   if (egroup && strlen (egroup) > 0) 
      snprintf (msg+len, MAX_ERROR - len - 1, " in %s", egroup);

   syntax_error (msg);

}
#endif /* USER_ZZSYN */


void
check_field_name (AST * field)
{
   char * name;

   if (! field || field->nodetype != BTAST_FIELD)
      return;

   name = field->text;
   if (strchr ("0123456789", name[0]))
      syntax_error ("invalid field name \"%s\": cannot start with digit",
                    name);
}


#ifdef STACK_DUMP_CODE

static void
show_ast_stack_elem (int num)
{
   extern char *nodetype_names[];       /* nicked from bibtex_ast.c */
   /*   bt_nodetype    nodetype;
   bt_metatype    metatype; */
   AST   *elem;

   elem = zzastStack[num];
   printf ("zzastStack[%3d] = ", num);
   if (elem)
   {
      /*      get_node_type (elem, &nodetype, &metatype); */
      if (elem->nodetype <= BTAST_MACRO)
      {
         printf ("{ %s: \"%s\" (line %d, char %d) }\n",
                 nodetype_names[elem->nodetype], 
                 elem->text, elem->line, elem->offset);
      }
      else
      {
         printf ("bogus node (uninitialized?)\n");
      }
   }
   else
   {
      printf ("NULL\n");
   }
}


static void
show_ast_stack_top (char *label)
{
   if (label)
      printf ("%s: ast stack top: ", label);
   else
      printf ("ast stack top: ");
   show_ast_stack_elem (zzast_sp);
}


static void
dump_ast_stack (char *label)
{
   int   i;

   if (label)
      printf ("%s: complete ast stack:\n", label);
   else
      printf ("complete ast stack:\n");

   for (i = zzast_sp; i < ZZAST_STACKSIZE; i++)
   {
      printf ("  ");
      show_ast_stack_elem (i);
   }   
}


static void
show_attrib_stack_elem (int num)
{
   Attrib   elem;

   elem = zzaStack[num];
   printf ("zzaStack[%3d] = ", num);
   printf ("{ \"%s\" (token %d (%s), line %d, char %d) }\n",
           elem.text, elem.token, zztokens[elem.token],
           elem.line, elem.offset);
}


static void
show_attrib_stack_top (char *label)
{
   if (label)
      printf ("%s: attrib stack top: ", label);
   else
      printf ("attrib stack top: ");
   show_attrib_stack_elem (zzasp);
}


static void
dump_attrib_stack (char *label)
{
   int   i;

   if (label)
      printf ("%s: complete attrib stack:\n", label);
   else
      printf ("complete attrib stack:\n");

   for (i = zzasp; i < ZZA_STACKSIZE; i++)
   {
      printf ("  ");
      show_attrib_stack_elem (i);
   }   
}

#endif /* STACK_DUMP_CODE */

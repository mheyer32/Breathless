//*****************************************************************************
//***
//***		Support.h
//***
//***		Include per Support.c
//***
//***
//***
//*****************************************************************************

#ifndef	SUPPORT_H
#define	SUPPORT_H

struct Node *FindNode(struct List *list, long num);
struct Node *FindNodePos(struct List *list, char *name);
long FindPosNum(struct List *list, struct Node *node);

short BitPos(long n);

long strnscpy(char *dest, char *src, long n, char c);
short strisempty(char *str);
void strrtrim(char *str);
char *strstr_nocase(char *str1, char *str2);

int MakeFileName(char *strdest, char *path, char *name1, char *name2, char *name3, ULONG len);
void RemExtension(char *str, char *ext);

#endif	/*	SUPPORT_H	*/

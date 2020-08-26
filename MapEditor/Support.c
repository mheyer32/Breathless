//*****************************************************************************
//***
//***		Support.c
//***
//***		Routine varie di supporto
//***
//***
//***
//*****************************************************************************

#include	"Support.h"

#include <proto/dos.h>

#include <string.h>


//********************************************
//********** Exec support functions **********
//********************************************



//*** Cerca il nodo numero num, nella lista list
//*** I nodi sono numerati a partire da 0.

struct Node *FindNode(struct List *list, long num) {

	register long	i;
	struct Node		*node, *nnode;

	nnode = list->lh_Head;
	for(i=0; i<=num; i++) {
		node=nnode;
		if(!(nnode=node->ln_Succ)) return(NULL);
	}

	return(node);
}


//*** Cerca nella lista list la posizione in cui inserire il nodo
//*** di nome name. Restituisce il pun. nella lista al nodo con nome
//*** minore a name.

struct Node *FindNodePos(struct List *list, char *name) {

	register long	i;
	struct Node		*node, *nnode;

	nnode = list->lh_Head;
	node=nnode;
	for(nnode=list->lh_Head; nnode->ln_Succ; nnode=nnode->ln_Succ) {
		if(strcmp(nnode->ln_Name, name)>=0) break;
		node=nnode;
	}

	return(node);
}


//*** Cerca nella lista list la posizione in cui si trova il nodo node.
//*** Restituisce il numero della posizione del nodo, numerata a partire
//*** da zero.
//*** Se il nodo non è presente nella lista, restituisce -1.

long FindPosNum(struct List *list, struct Node *node) {

	register long	i;
	struct Node		*nnode;

	for(nnode=list->lh_Head, i=0; nnode->ln_Succ; nnode=nnode->ln_Succ, i++)
		if(nnode==node) return(i);

	return(-1);
}



//*********************************************
//********* numeric support functions *********
//*********************************************


//*** Restituisce la posizione del primo bit settato di n.
//*** Ad es.:  BitPos(128)=7     oppure    BitPos(65)=0

short BitPos(long n) {

	register short	i;

	for(i=0; !(n & 1); i++)
		n >>= 1;

	return(i);
}


//********************************************
//********* string support functions *********
//********************************************


//*** Copia i primi n caratteri della stringa src nella stringa dest.
//*** Si ferma nel caso in cui incontra il carattere c nella stringa src.
//*** Restituisce il numero di caratteri copiati, escluso il '\0'.

long strnscpy(char *dest, char *src, long n, char c) {

	register long	count;

	count=0;
	while((*src!='\0') && (*src!=c) && n--) {
		*dest++=*src++;
		count++;
	}
	*dest='\0';

	return(count);
}



//*** Testa se la stringa str e' vuota, oppure se contiene solo spazi.
//*** In tal caso ritorna TRUE. Se la stringa non e' vuota, ritorna FALSE.

short strisempty(char *str) {

	register	char	*p;

	p=str;
	while(*p!='\0')
		if(*p++!=' ') return(FALSE);

	return(TRUE);
}



//*** Rimuove gli spazi a destra della stringa str.
//*** La stringa DEVE essere null terminated.

void strrtrim(char *str) {

	register	char	*p;

	p=str;
	while(*p++!='\0');
	p-=2;
	while(p>=str && *p==' ')
		*p--='\0';
}



//*** Restituisce il puntatore alla prima occorrenza di str2 in str1.
//*** Non tiene conto del case delle stringhe.
//*** Se non trova nessuna occorrenza, restituisce NULL.

char *strstr_nocase(char *str1, char *str2) {

	register char	a, b;
	char			*s1, *s2;

	if(*str2=='\0') return(NULL);

	while(*str1!='\0') {
		for(s1=str1, s2=str2; (*s1!='\0') && (*s2!='\0'); s2++, s1++) {
			a = *s1;
			b = *s2;
			if((a>='a') && (a<='z')) a-=32;
			if((b>='a') && (b<='z')) b-=32;
			if(a!=b) break;
		}
		if(*s2=='\0') return(str1);
		str1++;
	}

	return(NULL);
}



//********************************************
//********** I/O  support functions **********
//********************************************


//*** Fonde insieme la path, e 3 parti di nome file.
//*** Si assume che strdest possa contenere almeno len caratteri.
//*** name1, name2 e name3 possono valere NULL. In tal caso non vengono
//*** considerati.
//*** Restituisce FALSE, se c'e' stato qualche problema.

int MakeFileName(char *strdest, char *path, char *name1, char *name2, char *name3, ULONG len) {

	strdest[0]='\0';

	if(!AddPart((STRPTR)strdest,(STRPTR)path,len)) return(FALSE);

	if(name1) {
		if(!AddPart((STRPTR)strdest,(STRPTR)name1,len)) return(FALSE);
		if(name2) {
			if((strlen(name2) + strlen(strdest)) < len)
				strcat(strdest,name2);
		}
		if(name3) {
			if((strlen(name3) + strlen(strdest)) < len)
				strcat(strdest,name3);
		}

	} else if(name2) {
		if(!AddPart((STRPTR)strdest,(STRPTR)name2,len)) return(FALSE);
		if(name3) {
			if((strlen(name3) + strlen(strdest)) < len)
				strcat(strdest,name3);
		}

	} else if(name3) {
		if(!AddPart((STRPTR)strdest,(STRPTR)name3,len)) return(FALSE);
	}

	return(TRUE);
}



//*** Cerca nella stringa str, la stringa ext e, se presente,
//*** la elimina.
//*** Usata per eliminare da un nome file l'estensione con il punto

void RemExtension(char *str, char *ext) {

	char	*p, *pn;

	if(*ext=='\0' || *str=='\0') return;

	pn = NULL;

	do {
		p = pn;
		pn = strstr_nocase(str, ext);
		str = pn + 1;
	} while(pn);

	if(p == NULL) return;

	*p = '\0';
}

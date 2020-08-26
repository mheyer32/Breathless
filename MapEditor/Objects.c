//*****************************************************************************
//***
//***		Objects.c
//***
//***	Gestione oggetti
//***
//***
//***
//*****************************************************************************

#include	"MapEditor3d.h"
#include	"Definitions.h"

#include <proto/dos.h>

#include <stdio.h>
//*****************************************************************************


struct IntuiText MapObjWinIText[]={
	 1,0, JAM2, 8,68, NULL, (UBYTE *)"Trigger", NULL
};


//*****************************************************************************

//*** Seleziona dalla ObjectsList gli oggetti utilizzati nella mappa corrente.
//*** Gli oggetti vengono poi numerati a partire da uno.
//*** Ritorna l'occupazione di memoria in byte degli oggetti.

long ArrangeObjectsList() {

	register short		i;
	long				len;
	char				tag[256];
	struct Node			*node;
	struct MapObject	*mopun;


	//*** Azzera odn_num di tutti gli oggetti

	for(node=ObjectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
		((struct ObjDirNode *)node)->odn_num = 0;
	}

	//*** Scorre MapObjectList per segnare tutti gli oggetti usati

	for(mopun=MapObjectList; mopun; mopun=mopun->Next)
		(mopun->Object)->odn_num = 1;


	//*** Azzera array tag[]

	for(i=0; i<256; i++)	tag[i]=0;

	//*** Scorre la ObjectsList per segnare tutti gli oggetti di tipo Shot
	//*** e per segnare in tag[] tutte le esplosioni utilizzate

	for(node=ObjectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
		switch(((struct ObjDirNode *)node)->odn_objtype) {
			case OBJTYPE_ENEMY:
				tag[((struct ObjDirNode *)node)->odn_param4]=1;
				break;
			case OBJTYPE_SHOT:
				((struct ObjDirNode *)node)->odn_num = 1;
				tag[((struct ObjDirNode *)node)->odn_param9]=1;
				break;
			default:
				break;
		}
	}


	//*** Scorre la ObjectsList per controllare nell'array tag se
	//*** gli oggetti di tipo explosion sono usati

	for(node=ObjectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
		if(((struct ObjDirNode *)node)->odn_objtype == OBJTYPE_EXPLOSION) {
			if(tag[((struct ObjDirNode *)node)->odn_param1])
				((struct ObjDirNode *)node)->odn_num = 1;
		}
	}


	//*** Scorre la ObjectsList per numerare tutti gli oggetti usati

	len=0;
	i=0;
	for(node=ObjectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
		if(((struct ObjDirNode *)node)->odn_numframes) {
			if(((struct ObjDirNode *)node)->odn_num) {
				((struct ObjDirNode *)node)->odn_num = ++i;
				len+=((struct ObjDirNode *)node)->odn_length;
			}
		} else {
			((struct ObjDirNode *)node)->odn_num = 0;
		}
	}
	NumUsedObjects=i;

	return(len);
}


//******************************************************************************

//*** Restituisce il numero di oggetti in mappa.
//*** Inoltre restituisce, nei parametri passati per indirizzo,
//*** il numero di oggetti dei vari tipi.

long CountObjects(long *enemies, long *things) {

	struct MapObject	*obj;
	long				num;

	num=0;
	*enemies=0;
	*things=0;

	if(MapObjectList) {
		for(obj=MapObjectList; obj->Next; obj=obj->Next) {
			num++;
			switch(obj->Object->odn_objtype) {
				case OBJTYPE_THING:
				case OBJTYPE_PICKTHING:
					(*things)++;
					break;
				case OBJTYPE_ENEMY:
					(*enemies)++;
					break;
				default:
					(*things)++;
					break;
			}
		}
	}

	return(num);
}


//*** Aggiunge un oggetto alla lista di oggetti in mappa
//*** Se tutto ok, ritorna il pun. all'oggetto creato

struct MapObject *AddMapObject(long x, long y, struct ObjDirNode *object) {

	struct MapObject	*newobj, *lastobj;

	if(MapObjectList) {
		for(lastobj=MapObjectList; lastobj->Next; lastobj=lastobj->Next) {
			if((x==(lastobj->x>>6)) && (y==(lastobj->y>>6))) {
				ShowMessage("Only one object per block !",0);
				return(NULL);
			}
		}
		if((x==(lastobj->x>>6)) && (y==(lastobj->y>>6))) {
			ShowMessage("Only one object per block !",0);
			return(NULL);
		}
	}

	if(!(newobj = (struct MapObject *)AllocMem(sizeof(struct MapObject),MEMF_CLEAR))) {
		error=NO_MEMORY;
		return(NULL);
	}

	newobj->Object		= object;
	newobj->x 			= (x<<6)+32;
	newobj->y 			= (y<<6)+32;
	newobj->Heading		= 0;
	newobj->PlayerType	= 0;
	newobj->Effect		= (struct EffectDirNode *)EffectsList.lh_Head;
	newobj->Next		= NULL;

	if(MapObjectList) {
		lastobj->Next = newobj;
	} else {
		MapObjectList = newobj;
	}

	printf("Alloca oggetto\n");

	NumObjects++;

	ModifiedMap_fl=TRUE;

	return(newobj);
}


//*** Controlla se sul blocco di posizione x,y e' presente un oggetto.
//*** Se si, ne ritorna il puntatore, altrimenti ritorna NULL.

struct MapObject *CheckMapObject(long x, long y) {

	struct MapObject	*obj;

	if(MapObjectList) {
		for(obj=MapObjectList; obj; obj=obj->Next) {
			if((x==(obj->x>>6)) && (y==(obj->y>>6))) {
				return(obj);
			}
		}
	}

	return(NULL);
}


//******************************************************************************


//*** Conversione degli oggetti nel formato grafico usato dal motore
//*** Restituisce la lunghezza della struttura dati generata
//*** La lunghezza è sempre allineata a long.

long ConvertObj(struct PictureHeader *PicHead) {

	register long	i,j,w,h;
	register UBYTE	c,*pun,*punnum,np;
	ULONG			*puncol;
	long			ll;
	WORD			xoffset,yoffset,my;
	UWORD			*punw,*punheight,*punyoffset;

	rp.BitMap = &(PicHead->BitMap);

	w=(long)(PicHead->Header.Width);
	h=(long)(PicHead->Header.Height);

	xoffset=-1;
	for(i=0; i<w && xoffset<0; i++)
		if(ReadPixel(&rp,i,0)==KeyColor) xoffset=i;

	my=0;
	yoffset=0;
	pun=(UBYTE *)GfxBuffer;
	pun+=8;
	puncol=(ULONG *)pun;
	pun+=((w+4)<<2);
	for(i=0; i<w; i++) {
		np=0;
		*puncol++=(ULONG)(pun-GfxBuffer);
		for(j=1; j<h; j++) {
			c=(UBYTE)ReadPixel(&rp,i,j);
			if(c != KeyColor) {
				if(!np++) {
					*pun++=(char)j;
					punnum=pun++;
				}
				my=(WORD)j;
				*pun++=c;
				*punnum=np;
			} else {
				np=0;
			}
		}
		*pun++=255;
		yoffset = (my>yoffset) ? my : yoffset;
	}
	*puncol++=(ULONG)(pun-GfxBuffer-1);
	*puncol++=(ULONG)(pun-GfxBuffer-1);
	*puncol++=(ULONG)(pun-GfxBuffer-1);
	*puncol++=(ULONG)(pun-GfxBuffer-1);

	punw=(UWORD *)GfxBuffer;
	*punw++=(UWORD)w;
	*punw++=(UWORD)yoffset;
	*punw++=(UWORD)xoffset;
	*punw++=(UWORD)((WORD)h-yoffset-1);

	ll=(((long)(pun-GfxBuffer))+4) & 0xfffffffc;

	return(ll);
}



//*** Legge dalla directory temporanea, l'oggetto di nome name,
//*** di lunghezza length.
//*** Se delflag=TRUE, il file viene cancellato dopo essere stato letto.
//*** Se non ci sono errori restituisce FALSE.

int	ReadTempObjFile(char *name, long length, int delflag) {

	struct FileHandle	*file;
	long				err;
	char				nname[9];

	strncpy(nname, name, 4);
	nname[4]='\0';
	if(!MakeFileName(filename, TempDir_Pref, nname, NULL, NULL, FILENAME_LEN)) {
		error=BADFILENAME;
		return(TRUE);
	}

	if ((file = (struct FileHandle *)Open((STRPTR)filename, MODE_OLDFILE)) != 0) {
		do {
			err=0;
			if(Read((BPTR)file,GfxBuffer,length)<length) {
				if(err=IoErr())
					if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) err=0;
			}
		} while(err);
		Close((BPTR)file);
		if(delflag) DeleteFile((STRPTR)filename);
	} else {
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) return(TRUE);
	}
	return(FALSE);
}



//*** Scrive il file temporaneo dell'oggetto
//*** mode =	MODE_NEWFILE
//***			MODE_OLDFILE
//***
//*** offset =	OFFSET_BEGINNING
//***			OFFSET_END
//***
//*** Il parametro offset e' usato solo se mode=MODE_OLDFILE e serve
//*** per indicare se scrivere alla fine del file (nuovo frame) o
//*** all'inizio del file (testata oggetto).
//*** Se non ci sono errori restituisce FALSE.

int	WriteTempObjFile(char *name, long len, long mode, long offset) {

	struct FileHandle	*file;
	long				l, err;
	char				nname[9];

	strncpy(nname, name, 8);
	nname[8]='\0';
	if(!MakeFileName(filename, TempDir_Pref, nname, NULL, NULL, FILENAME_LEN)) {
		error=BADFILENAME;
		return(TRUE);
	}

	if ((file = (struct FileHandle *)Open((STRPTR)filename, mode)) != NULL) {
		l=len;

		if(mode==MODE_OLDFILE) {
			Seek((BPTR)file,0,offset);
		}

		do {
			err=0;
			if(Write((BPTR)file,GfxBuffer,l)<l) {
				if(err=IoErr())
					if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) err=0;
			}
		} while(err);
		Close((BPTR)file);
	} else {
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) return(TRUE);
	}

	return(FALSE);
}



//*** Legge dal file Objects GLD l'oggetto puntato da *object
//*** Se non ci sono errori restituisce FALSE.

int ReadGLDObjFile(struct ObjDirNode *object) {

	BPTR		file;
	long		err,l1;

	if(!MakeFileName(filename, ProjectDir, ProjectPrefix, ProjectObjFileName, ".gld", FILENAME_LEN)) return(1);

	err=0;

	if((file = Open((STRPTR)filename, MODE_OLDFILE)) != 0) {
		Read(file,&l1,4);
		if(l1 != OGLD_ID) {		// La ID è corretta ?
			ShowErrorMessage(BADGLDFILE, filename);
			err=1;
			goto RGOFesci;
		}

		if(Seek(file, object->odn_offset, OFFSET_BEGINNING) == -1) {
			if(err=IoErr())
				if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) {
					err=1;
					goto RGOFesci;
				}
		}
		if(Read(file, GfxBuffer, object->odn_length) < object->odn_length) {
			if(err=IoErr())
				if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) {
					err=1;
					goto RGOFesci;
				}
		}

	} else {
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) return(TRUE);
	}

RGOFesci:
	if(file)	Close(file);
	return(err);
}



//*** Rimuove un oggetto dalla lista

void RemoveObject(struct ObjDirNode *object) {

	if(object && (object!=(struct ObjDirNode *)ObjectsList.lh_Head)) {
		GT_SetGadgetAttrs(ObjListWinGadgets[OBJLISTWINGAD_LIST],
							ObjListWin,NULL,
							GTLV_Labels, NULL,
							TAG_DONE, NULL);

		Remove((struct Node *)object);
		FreeMem(object,sizeof(struct ObjDirNode));
		ModifiedObjList_fl=TRUE;

		GT_SetGadgetAttrs(ObjListWinGadgets[OBJLISTWINGAD_LIST],
							ObjListWin,NULL,
							GTLV_Labels, &ObjectsList,
							TAG_DONE, NULL);
	}
}



//*** Modifica i soli parametri dell'oggetto puntato da *object

void ModifyObjectParam(struct ObjDirNode *object) {

	struct FObject		fobject;
	char				*str, *str2, objname[9];
	long				l1;

	GT_GetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAME], ObjectsWin,NULL, GTST_String,&str, TAG_DONE,0);
	GT_GetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_DESCR], ObjectsWin,NULL, GTST_String,&str2, TAG_DONE,0);
	sprintf(object->odn_name,"%-4s     %-30s",str,str2);
	strcpy(objname,str);

	object->odn_radius = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_RADIUS]->SpecialInfo)->LongInt);
	object->odn_height = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_HEIGHT]->SpecialInfo)->LongInt);

	object->odn_param1 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM1]->SpecialInfo)->LongInt);
	object->odn_param2 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM2]->SpecialInfo)->LongInt);
	object->odn_param3 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM3]->SpecialInfo)->LongInt);
	object->odn_param4 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM4]->SpecialInfo)->LongInt);
	object->odn_param5 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM5]->SpecialInfo)->LongInt);
	object->odn_param6 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM6]->SpecialInfo)->LongInt);
	object->odn_param7 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM7]->SpecialInfo)->LongInt);
	object->odn_param8 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM8]->SpecialInfo)->LongInt);
	object->odn_param9 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM9]->SpecialInfo)->LongInt);
	object->odn_param10= (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM10]->SpecialInfo)->LongInt);
	object->odn_param11= (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM11]->SpecialInfo)->LongInt);
	object->odn_param12= (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM12]->SpecialInfo)->LongInt);

	strncpy((char *)&(object->odn_sound1),n_ObjSound1,4);
	strncpy((char *)&(object->odn_sound2),n_ObjSound2,4);
	strncpy((char *)&(object->odn_sound3),n_ObjSound3,4);

	fobject.numframes = object->odn_numframes;
	fobject.radius = object->odn_radius;
	fobject.height = object->odn_height;
	fobject.animtype = (BYTE)(object->odn_animtype-1);
	fobject.objtype = (BYTE)object->odn_objtype;
	fobject.param1 = object->odn_param1;
	fobject.param2 = object->odn_param2;
	fobject.param3 = object->odn_param3;
	fobject.param4 = object->odn_param4;
	fobject.param5 = object->odn_param5;
	fobject.param6 = object->odn_param6;
	fobject.param7 = object->odn_param7;
	fobject.param8 = object->odn_param8;
	fobject.param9 = object->odn_param9;
	fobject.param10= object->odn_param10;
	fobject.param11= object->odn_param11;
	fobject.param12= object->odn_param12;
	fobject.sound1= object->odn_sound1;
	fobject.sound2= object->odn_sound2;
	fobject.sound3= object->odn_sound3;

	if(fobject.sound1==0x20202020) fobject.sound1=0;
	if(fobject.sound2==0x20202020) fobject.sound2=0;
	if(fobject.sound3==0x20202020) fobject.sound3=0;

	if(object->odn_location) {	// L'oggetto è su file temporaneo

		memcpy(GfxBuffer,&fobject,36);
		WriteTempObjFile(objname,36,MODE_OLDFILE,OFFSET_BEGINNING);	// Scrive testata

	} else {					// L'oggetto è sul file .gld

		ReadGLDObjFile(object);
		memcpy(GfxBuffer,&fobject,36);
		WriteTempObjFile(objname,object->odn_length,MODE_NEWFILE,0);

	}

	object->odn_offset = 	0;
	object->odn_location = 	1;

	ModifiedObjList_fl=TRUE;
}



//*** Se object==NULL , aggiunge un nuovo oggetto alla lista
//*** Se object!=NULL , modifica oggetto

void AddModifyObject(struct ObjDirNode *object) {

	static struct ObjDirNode	onode;
	static struct FObject		fobject;

	long				l1, len, headlen, offset;
	int					err,frame,flagskip;
	char				*str, *str2, objname[9], objext[5];
	char				f, d;
	struct ObjDirNode	*nonode;
	struct Node			savenode;



	GT_GetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAME], ObjectsWin,NULL, GTST_String,&str, TAG_DONE,0);
	GT_GetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_DESCR], ObjectsWin,NULL, GTST_String,&str2, TAG_DONE,0);
	sprintf(onode.odn_name,"%-4s     %-30s",str,str2);
	strcpy(objname,str);

	if(strisempty(str)) {
		ShowMessage("You MUST specify object name !",0);
		return;
	}

	onode.odn_numframes = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_NUMFRAMES]->SpecialInfo)->LongInt);
	onode.odn_radius = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_RADIUS]->SpecialInfo)->LongInt);
	onode.odn_height = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_HEIGHT]->SpecialInfo)->LongInt);

	GT_GetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_OBJTYPE],ObjectsWin, NULL, GTCY_Active,&l1, TAG_DONE,0);
	onode.odn_objtype = l1;

	GT_GetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_ANIMTYPE],ObjectsWin, NULL, GTCY_Active,&l1, TAG_DONE,0);
	onode.odn_animtype = l1;

	onode.odn_param1 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM1]->SpecialInfo)->LongInt);
	onode.odn_param2 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM2]->SpecialInfo)->LongInt);
	onode.odn_param3 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM3]->SpecialInfo)->LongInt);
	onode.odn_param4 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM4]->SpecialInfo)->LongInt);
	onode.odn_param5 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM5]->SpecialInfo)->LongInt);
	onode.odn_param6 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM6]->SpecialInfo)->LongInt);
	onode.odn_param7 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM7]->SpecialInfo)->LongInt);
	onode.odn_param8 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM8]->SpecialInfo)->LongInt);
	onode.odn_param9 = (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM9]->SpecialInfo)->LongInt);
	onode.odn_param10= (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM10]->SpecialInfo)->LongInt);
	onode.odn_param11= (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM11]->SpecialInfo)->LongInt);
	onode.odn_param12= (((struct StringInfo *)ObjectsWinGadgets[OBJWINGAD_PARAM12]->SpecialInfo)->LongInt);

	strncpy((char *)&(onode.odn_sound1),n_ObjSound1,4);
	strncpy((char *)&(onode.odn_sound2),n_ObjSound2,4);
	strncpy((char *)&(onode.odn_sound3),n_ObjSound3,4);

	onode.odn_offset = 		0;
	onode.odn_length = 		0;
	onode.odn_location = 	1;

	if(rtFileRequest(ObjFileReq, filename, "Pick a directory", RTFI_Flags,FREQF_NOFILES, TAG_END,NULL)) {
		strcpy(ObjectsDir, ObjFileReq->Dir);

		headlen = 48L + (long)(onode.odn_numframes<<2);
		offset=headlen;

		fobject.numframes = onode.odn_numframes;
		fobject.radius = onode.odn_radius;
		fobject.height = onode.odn_height;
		fobject.animtype = (BYTE)(onode.odn_animtype-1);
		fobject.objtype = (BYTE)onode.odn_objtype;
		fobject.param1 = onode.odn_param1;
		fobject.param2 = onode.odn_param2;
		fobject.param3 = onode.odn_param3;
		fobject.param4 = onode.odn_param4;
		fobject.param5 = onode.odn_param5;
		fobject.param6 = onode.odn_param6;
		fobject.param7 = onode.odn_param7;
		fobject.param8 = onode.odn_param8;
		fobject.param9 = onode.odn_param9;
		fobject.param10= onode.odn_param10;
		fobject.param11= onode.odn_param11;
		fobject.param12= onode.odn_param12;
		fobject.sound1 = onode.odn_sound1;
		fobject.sound2 = onode.odn_sound2;
		fobject.sound3 = onode.odn_sound3;
		fobject.frame = offset;
		fobject.zero = 0;
		fobject.framelist[onode.odn_numframes] = 0;

		if(fobject.sound1==0x20202020) fobject.sound1=0;
		if(fobject.sound2==0x20202020) fobject.sound2=0;
		if(fobject.sound3==0x20202020) fobject.sound3=0;

		d='1';
		f='A';
		objext[1] = '\0';
		objext[2] = '\0';

		frame=0;

		while(frame<onode.odn_numframes) {

			ShowProgress(frame, (long)onode.odn_numframes, "Processing object ...");

			if(onode.odn_animtype==ANIMTYPE_DIRECTIONAL) {
				if(frame<128) {
					objext[0] = f++;
					objext[1] = d;
					if(f > 'P') {	f='A';	d++; }
				} else {
					if(frame==128) f='Q';
					objext[0] = f++;
					objext[1] = '0';
				}
			} else {
				objext[0] = f++;
			}

			if(!MakeFileName(filename, ObjectsDir, objname, objext, ".pic", FILENAME_LEN)) {
				ShowErrorMessage(BADFILENAME,filename);
				goto AMOexit;
			}

			flagskip=0;
			if(err=LoadIFFPic(filename,&ObjectPicHead)) {
				if(onode.odn_animtype==ANIMTYPE_DIRECTIONAL) {
					flagskip=1;
					if(objext[0]!='A') err=0;	// C'e' errore solo se non trova il primo frame di ogni direzione
				}
				if(err) {
					ShowErrorMessage(err,filename);
					goto AMOexit;
				}
			}

			if(!flagskip) {
				printf("frame %ld) width=%ld - height=%ld\n",frame, ObjectPicHead.Header.Width, ObjectPicHead.Header.Height);

				len=ConvertObj(&ObjectPicHead);

				err=IFFFree(&ObjectPicHead);

				fobject.framelist[frame] = offset;	// offset al frame corrente
				offset+=len;
				frame++;

				if(frame==1) {
					WriteTempObjFile(objname,headlen,MODE_NEWFILE,0);	// Lascia spazio per la testata
					WriteTempObjFile(objname,len,MODE_OLDFILE,OFFSET_END);		// Scrive primo frame
				} else {
					WriteTempObjFile(objname,len,MODE_OLDFILE,OFFSET_END);		// Scrive frame
				}

			} else {

				fobject.framelist[frame] = fobject.framelist[frame-1];
				frame++;
			}
		}

		memcpy(GfxBuffer,&fobject,headlen);
		WriteTempObjFile(objname,headlen,MODE_OLDFILE,OFFSET_BEGINNING);	// Scrive testata

		//*** Aggiunge entry nella lista

		GT_SetGadgetAttrs(ObjListWinGadgets[OBJLISTWINGAD_LIST],
							ObjListWin,NULL,
							GTLV_Labels, NULL,
							TAG_DONE, NULL);

		if(object==NULL) {
			if(!(nonode = (struct ObjDirNode *)AllocMem(sizeof(struct ObjDirNode),MEMF_CLEAR))) {
				error=NO_MEMORY;
				goto AMOexit;
			}
		} else {
			nonode = object;
			savenode = object->odn_node;
		}

		onode.odn_length = offset;
		*nonode = onode;

		if(object==NULL) {
			nonode->odn_node.ln_Type=0;
			nonode->odn_node.ln_Pri	=0;
			nonode->odn_node.ln_Name=nonode->odn_name;
			AddTail(&ObjectsList,&(nonode->odn_node));
		} else {
			nonode->odn_node = savenode;
		}

		GT_SetGadgetAttrs(ObjListWinGadgets[OBJLISTWINGAD_LIST],
							ObjListWin,NULL,
							GTLV_Labels, &ObjectsList,
							TAG_DONE, NULL);

		ModifiedObjList_fl=TRUE;
	}

AMOexit:;

	//*** Si assicura che venga chiusa la progress window

	ShowProgress(100L, 100L, "Processing object ...");
}



//*** In base al valore di object->odn_objtype, setta
//*** i gadget della finestra ObjectsWin

void ProcessObjType(struct ObjDirNode *object) {

	register long	i;

	switch(object->odn_objtype) {
		case OBJTYPE_THING:
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_ANIMTYPE],ObjectsWin, NULL, GTCY_Active,ANIMTYPE_NONE, GA_DISABLED,FALSE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NUMFRAMES],ObjectsWin, NULL, GTIN_Number,1, GA_DISABLED,TRUE, TAG_DONE,0);
			for(i=OBJWINGAD_PARAM1; i<=OBJWINGAD_PARAM12; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
			for(i=OBJWINGAD_NAMEPARAM1; i<=OBJWINGAD_NAMEPARAM12; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);

			for(i=OBJWINGAD_SOUND1; i<=OBJWINGAD_SOUND3; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			for(i=OBJWINGAD_NAMESOUND1; i<=OBJWINGAD_NAMESOUND3; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			break;

		case OBJTYPE_PLAYER:
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_ANIMTYPE],ObjectsWin, NULL, GTCY_Active,ANIMTYPE_DIRECTIONAL, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NUMFRAMES],ObjectsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
			for(i=OBJWINGAD_PARAM1; i<=OBJWINGAD_PARAM12; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
			for(i=OBJWINGAD_NAMEPARAM1; i<=OBJWINGAD_NAMEPARAM12; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);

			for(i=OBJWINGAD_SOUND1; i<=OBJWINGAD_SOUND3; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			for(i=OBJWINGAD_NAMESOUND1; i<=OBJWINGAD_NAMESOUND3; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			break;

		case OBJTYPE_ENEMY:
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_ANIMTYPE],ObjectsWin, NULL, GTCY_Active,ANIMTYPE_DIRECTIONAL, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NUMFRAMES],ObjectsWin, NULL, GTIN_Number,130, GA_DISABLED,TRUE, TAG_DONE,0);
			for(i=OBJWINGAD_PARAM1; i<=OBJWINGAD_PARAM12; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GTIN_Number,0, GA_DISABLED,FALSE, TAG_DONE,0);

			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM6],ObjectsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM11],ObjectsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);

			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM1],ObjectsWin, NULL, GTTX_Text,"Attack dist.", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM2],ObjectsWin, NULL, GTTX_Text,"Score", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM3],ObjectsWin, NULL, GTTX_Text,"Strength", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM4],ObjectsWin, NULL, GTTX_Text,"Explosion code", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM5],ObjectsWin, NULL, GTTX_Text,"Gun", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM6],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM7],ObjectsWin, NULL, GTTX_Text,"Power", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM8],ObjectsWin, NULL, GTTX_Text,"Speed", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM9],ObjectsWin, NULL, GTTX_Text,"Attack prob.(>0)", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM10],ObjectsWin, NULL, GTTX_Text,"Behaviour", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM11],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM12],ObjectsWin, NULL, GTTX_Text,"Gun Y offset", TAG_DONE,0);

			for(i=OBJWINGAD_SOUND1; i<=OBJWINGAD_SOUND3; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMESOUND1],ObjectsWin, NULL, GTTX_Text,"Howl", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMESOUND2],ObjectsWin, NULL, GTTX_Text,"Hit", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMESOUND3],ObjectsWin, NULL, GTTX_Text,"Death", TAG_DONE,0);
			break;

		case OBJTYPE_PICKTHING:
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_ANIMTYPE],ObjectsWin, NULL, GTCY_Active,ANIMTYPE_NONE, GA_DISABLED,FALSE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NUMFRAMES],ObjectsWin, NULL, GTIN_Number,1, GA_DISABLED,TRUE, TAG_DONE,0);
			for(i=OBJWINGAD_PARAM1; i<=OBJWINGAD_PARAM2; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GTIN_Number,0, GA_DISABLED,FALSE, TAG_DONE,0);
			for(i=OBJWINGAD_PARAM3; i<=OBJWINGAD_PARAM12; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM1],ObjectsWin, NULL, GTTX_Text,"Type (0-3)", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM2],ObjectsWin, NULL, GTTX_Text,"Value", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM3],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM4],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM5],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM6],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM7],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM8],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM9],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM10],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM11],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM12],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);

			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_SOUND1],ObjectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_SOUND2],ObjectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_SOUND3],ObjectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMESOUND1],ObjectsWin, NULL, GTTX_Text,"Pick sound", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMESOUND2],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMESOUND3],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			break;

		case OBJTYPE_SHOT:
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_ANIMTYPE],ObjectsWin, NULL, GTCY_Active,ANIMTYPE_NONE, GA_DISABLED,FALSE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NUMFRAMES],ObjectsWin, NULL, GTIN_Number,1, GA_DISABLED,TRUE, TAG_DONE,0);
			for(i=OBJWINGAD_PARAM1; i<=OBJWINGAD_PARAM12; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GTIN_Number,0, GA_DISABLED,FALSE, TAG_DONE,0);

			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM11],ObjectsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);

			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM1],ObjectsWin, NULL, GTTX_Text,"Power", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM2],ObjectsWin, NULL, GTTX_Text,"Speed", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM3],ObjectsWin, NULL, GTTX_Text,"Energy loss", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM4],ObjectsWin, NULL, GTTX_Text,"Max distance(0-8192)", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM5],ObjectsWin, NULL, GTTX_Text,"Accel", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM6],ObjectsWin, NULL, GTTX_Text,"Max speed", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM7],ObjectsWin, NULL, GTTX_Text,"Code", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM8],ObjectsWin, NULL, GTTX_Text,"Type", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM9],ObjectsWin, NULL, GTTX_Text,"Expl. code", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM10],ObjectsWin, NULL, GTTX_Text,"Autofire (0/1)", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM11],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM12],ObjectsWin, NULL, GTTX_Text,"Player Y offset", TAG_DONE,0);

			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_SOUND1],ObjectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_SOUND2],ObjectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_SOUND3],ObjectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMESOUND1],ObjectsWin, NULL, GTTX_Text,"Gun shot", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMESOUND2],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMESOUND3],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			break;

		case OBJTYPE_EXPLOSION:
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_ANIMTYPE],ObjectsWin, NULL, GTCY_Active,ANIMTYPE_NONE, GA_DISABLED,FALSE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NUMFRAMES],ObjectsWin, NULL, GTIN_Number,1, GA_DISABLED,TRUE, TAG_DONE,0);
			for(i=OBJWINGAD_PARAM1; i<=OBJWINGAD_PARAM2; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GTIN_Number,0, GA_DISABLED,FALSE, TAG_DONE,0);
			for(i=OBJWINGAD_PARAM3; i<=OBJWINGAD_PARAM12; i++)
				GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM1],ObjectsWin, NULL, GTTX_Text,"Code", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM2],ObjectsWin, NULL, GTTX_Text,"Type", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM3],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM4],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM5],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM6],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM7],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM8],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM9],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM10],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM11],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMEPARAM12],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);

			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_SOUND1],ObjectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_SOUND2],ObjectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_SOUND3],ObjectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMESOUND1],ObjectsWin, NULL, GTTX_Text,"Explosion", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMESOUND2],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAMESOUND3],ObjectsWin, NULL, GTTX_Text,"", TAG_DONE,0);
			break;
	}
}



//*** Apre finestra Objects
//*** Se object==NULL : inserimento nuovo oggetto
//*** Se object!=NULL : modifica dell'oggetto puntato da object in base
//***                   al valore di modflag: 
//***					se modflag=0 : modifica solo parametri
//***                   se modflag=1 : modifica anche immagine

void OpenObjectsWindow(struct ObjDirNode *object, short modflag) {

	register long		i;
	int					cont;
	long				l1;
	ULONG				signals;
	ULONG				imsgClass;
	UWORD				imsgCode;
	char				str[31];
	struct Gadget		*gad;
	struct ObjDirNode	objnode;


	if(object==NULL) {
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_OBJTYPE],ObjectsWin, NULL, GTCY_Active,OBJTYPE_THING, GA_DISABLED,FALSE, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_ANIMTYPE],ObjectsWin, NULL, GTCY_Active,ANIMTYPE_NONE, GA_DISABLED,FALSE, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NUMFRAMES],ObjectsWin, NULL, GTIN_Number,1, GA_DISABLED,TRUE, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAME],ObjectsWin, NULL, GTST_String,"", GA_DISABLED,FALSE, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_RADIUS],ObjectsWin, NULL, GTIN_Number,0, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_HEIGHT],ObjectsWin, NULL, GTIN_Number,0, TAG_DONE,0);
		for(i=OBJWINGAD_PARAM1; i<=OBJWINGAD_PARAM12; i++)
			GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_DESCR],ObjectsWin, NULL, GTST_String,"", TAG_DONE,0);
		strncpy(n_ObjSound1,"    ",4);
		strncpy(n_ObjSound2,"    ",4);
		strncpy(n_ObjSound3,"    ",4);
	} else {
		ProcessObjType(object);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_OBJTYPE],ObjectsWin, NULL, GTCY_Active,(long)object->odn_objtype, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_ANIMTYPE],ObjectsWin, NULL, GTCY_Active,(long)object->odn_animtype, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NUMFRAMES],ObjectsWin, NULL, GTIN_Number,(long)object->odn_numframes, TAG_DONE,0);
		strncpy(str,object->odn_name,4);
		str[4]='\0';
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAME],ObjectsWin, NULL, GTST_String,str, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_RADIUS],ObjectsWin, NULL, GTIN_Number,(long)object->odn_radius, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_HEIGHT],ObjectsWin, NULL, GTIN_Number,(long)object->odn_height, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM1],ObjectsWin, NULL, GTIN_Number,(long)object->odn_param1, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM2],ObjectsWin, NULL, GTIN_Number,(long)object->odn_param2, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM3],ObjectsWin, NULL, GTIN_Number,(long)object->odn_param3, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM4],ObjectsWin, NULL, GTIN_Number,(long)object->odn_param4, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM5],ObjectsWin, NULL, GTIN_Number,(long)object->odn_param5, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM6],ObjectsWin, NULL, GTIN_Number,(long)object->odn_param6, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM7],ObjectsWin, NULL, GTIN_Number,(long)object->odn_param7, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM8],ObjectsWin, NULL, GTIN_Number,(long)object->odn_param8, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM9],ObjectsWin, NULL, GTIN_Number,(long)object->odn_param9, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM10],ObjectsWin, NULL, GTIN_Number,(long)object->odn_param10, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM11],ObjectsWin, NULL, GTIN_Number,(long)object->odn_param11, TAG_DONE,0);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_PARAM12],ObjectsWin, NULL, GTIN_Number,(long)object->odn_param12, TAG_DONE,0);
		strncpy(str,&(object->odn_name[9]),30);
		str[30]='\0';
		strrtrim(str);
		GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_DESCR],ObjectsWin, NULL, GTST_String,str, TAG_DONE,0);
		strncpy(n_ObjSound1,(char *)&(object->odn_sound1),4);
		strncpy(n_ObjSound2,(char *)&(object->odn_sound2),4);
		strncpy(n_ObjSound3,(char *)&(object->odn_sound3),4);
		if(modflag==0) {
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_OBJTYPE],ObjectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_ANIMTYPE],ObjectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NUMFRAMES],ObjectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NAME],ObjectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
		}
	}

	ObjectsWin = OpenWindowTags(NULL,
						WA_Left,	58,
						WA_Top,		22,
						WA_Width,	524,
						WA_Height,	211,
						WA_Flags,	WFLG_DRAGBAR|WFLG_DEPTHGADGET|
									WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|
									WFLG_ACTIVATE|WFLG_NEWLOOKMENUS,
						WA_IDCMP,	IDCMP_CLOSEWINDOW|
									IDCMP_GADGETUP|IDCMP_INTUITICKS,
						WA_Title,	"Objects",
						WA_Gadgets,	ObjectsWinGadList,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

	if(!ObjectsWin) {
		ShowMessage("Problems opening Objects window !",0);
		error=GENERIC_ERROR;
		return;
	}

	DrawBevelBox(ObjectsWin->RPort,8,58,508,101, GT_VisualInfo,VInfo, TAG_DONE,0);
	DrawBevelBox(ObjectsWin->RPort,8,162,508,21, GT_VisualInfo,VInfo, TAG_DONE,0);

	GT_RefreshWindow(ObjectsWin,NULL);

	ObjectsWinSigBit = 1 << ObjectsWin->UserPort->mp_SigBit;
	OpenedWindow |= ObjectsWinSigBit;

	TurnOffIDCMP(0xffffffff ^ ObjectsWinSigBit);

	cont=TRUE;

	while(cont && !error) {
		if(signals = Wait(ObjectsWinSigBit)) {
			while(!error && (imsg = GT_GetIMsg(ObjectsWin->UserPort))) {
				imsgClass = imsg->Class;
				imsgCode = imsg->Code;

				gad = (struct Gadget *)imsg->IAddress;

				GT_ReplyIMsg(imsg);

				switch(imsgClass) {
					case IDCMP_CLOSEWINDOW:
						cont=FALSE;
						break;
					case IDCMP_GADGETUP:
						switch(gad->GadgetID) {
							case OBJWINGAD_OBJTYPE:
								GT_GetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_OBJTYPE],ObjectsWin, NULL, GTCY_Active,&l1, TAG_DONE,0);
								objnode.odn_objtype=(WORD)l1;
								ProcessObjType(&objnode);
								break;

							case OBJWINGAD_ANIMTYPE:
								GT_GetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_ANIMTYPE],ObjectsWin, NULL, GTCY_Active,&l1, TAG_DONE,0);
								objnode.odn_animtype=(WORD)l1;
								switch(objnode.odn_animtype) {
									case ANIMTYPE_DIRECTIONAL:
										GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NUMFRAMES],ObjectsWin, NULL, GTIN_Number,1, GA_DISABLED,TRUE, TAG_DONE,0);
										break;
									case ANIMTYPE_NONE:
										GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NUMFRAMES],ObjectsWin, NULL, GTIN_Number,1, GA_DISABLED,TRUE, TAG_DONE,0);
										break;
									case ANIMTYPE_SIMPLE:
										GT_SetGadgetAttrs(ObjectsWinGadgets[OBJWINGAD_NUMFRAMES],ObjectsWin, NULL, GTIN_Number,1, GA_DISABLED,FALSE, TAG_DONE,0);
										break;
								}
								break;

							case OBJWINGAD_SOUND1:
							case OBJWINGAD_SOUND2:
							case OBJWINGAD_SOUND3:
								SoundSelectWin = ObjectsWin;
								SoundSelect = gad->GadgetID;
								OpenSndListWindow();
								TurnOnIDCMP(SndListWinSigBit);
								TurnOffIDCMP(0xffffffff ^ SndListWinSigBit ^ ObjectsWinSigBit);
								GT_SetGadgetAttrs(ObjectsWinGadgets[gad->GadgetID],ObjectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
								ProcessSndListWindow();
								GT_SetGadgetAttrs(ObjectsWinGadgets[gad->GadgetID],ObjectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
								TurnOnIDCMP(0xffffffff ^ SndListWinSigBit ^ ObjectsWinSigBit);
								break;

							case OBJWINGAD_OK:
								if(!modflag)
									ModifyObjectParam(object);
								else
									AddModifyObject(object);
								cont=FALSE;
								break;

							case OBJWINGAD_CANCEL:
								cont=FALSE;
								break;
						}
						break;
				}
			}
		}
	}

	CloseObjectsWindow();

	TurnOnIDCMP(0xffffffff);
}


//*****************************************************************************


//*** Processa l'input sulla listview degli oggetti

void ProcessObjList(UWORD imsgCode, ULONG seconds, ULONG micros) {

	static ULONG		startsecs=0, startmicros=0;
	char				*str;
	struct ObjDirNode	*nnode;

	SelectedObj = (struct ObjDirNode *)FindNode(&ObjectsList,imsgCode);

	if(DoubleClick(startsecs, startmicros, seconds, micros)) {
		CurrObjPun = SelectedObj;
		DrawWhat = 2;
	}
	startsecs=seconds;
	startmicros=micros;
}


//*****************************************************************************




//*** Apre finestra MapObjWin

void OpenMapObjWindow(struct MapObject *object) {

	register long		i;
	ULONG				signals;
	ULONG				imsgClass;
	UWORD				imsgCode;


	strncpy(n_MapObjName,object->Object->odn_name,4);
	GT_SetGadgetAttrs(MapObjWinGadgets[MAPOBJWINGAD_OBJ],MapObjWin, NULL, GTTX_Text,n_MapObjName, TAG_DONE,0);
	GT_SetGadgetAttrs(MapObjWinGadgets[MAPOBJWINGAD_X],MapObjWin, NULL, GTNM_Number,(long)object->x, TAG_DONE,0);
	GT_SetGadgetAttrs(MapObjWinGadgets[MAPOBJWINGAD_Y],MapObjWin, NULL, GTNM_Number,(long)object->y, TAG_DONE,0);
	GT_SetGadgetAttrs(MapObjWinGadgets[MAPOBJWINGAD_HEADING],MapObjWin, NULL, GTCY_Active,(long)object->Heading, TAG_DONE,0);

	MapObjEffect=object->Effect;

	if(object->Effect->eff_trigger>0)
		sprintf(n_MapObjTriggerNum,"%3ld",object->Effect->eff_trigger);
	else
		strcpy(n_MapObjTriggerNum,"---");

	if(object->Object->odn_objtype==OBJTYPE_ENEMY)
		GT_SetGadgetAttrs(MapObjWinGadgets[MAPOBJWINGAD_TRIGGER],MapObjWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
	else
		GT_SetGadgetAttrs(MapObjWinGadgets[MAPOBJWINGAD_TRIGGER],MapObjWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);


	if(MapObjWin) {		// Se già aperta, la porta di fronte e ritorna subito
		WindowToFront(MapObjWin);
		ActivateWindow(MapObjWin);
		RefreshGadgets(MapObjWinGadgets[0],MapObjWin,NULL);
		GT_RefreshWindow(MapObjWin,NULL);
		return;
	}


	MapObjWin = OpenWindowTags(NULL,
						WA_Left,	227,
						WA_Top,		64,
						WA_Width,	186,
						WA_Height,	128,
						WA_Flags,	WFLG_DRAGBAR|WFLG_CLOSEGADGET|
									WFLG_SMART_REFRESH|	WFLG_ACTIVATE,
						WA_IDCMP,	IDCMP_CLOSEWINDOW|
									IDCMP_GADGETUP|IDCMP_INTUITICKS,
						WA_Title,	"Edit obj",
						WA_Gadgets,	MapObjWinGadList,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

	if(!MapObjWin) {
		ShowMessage("Problems opening MapObj window !",0);
		error=GENERIC_ERROR;
		return;
	}

	PrintIText(MapObjWin->RPort, MapObjWinIText, MapObjWin->BorderLeft, MapObjWin->BorderTop);

	GT_RefreshWindow(MapObjWin,NULL);

	MapObjWinSigBit = 1 << MapObjWin->UserPort->mp_SigBit;
	OpenedWindow |= MapObjWinSigBit;

	if(!SetMenuStrip(MapObjWin, myMenu)) {
		ShowMessage("Problems with MapObj window SetMenuStrip !",0);
		error=GENERIC_ERROR;
		return;
	}
}



//*** Gestione dell'input dai gadget della finestra MapObjWin

void ProcessMapObjWinGad(struct Gadget *gad, UWORD imsgCode) {

	long				l1;
	struct MapObject	*obj,*preobj;


	switch(gad->GadgetID) {
		case MAPOBJWINGAD_DEL:
			preobj=NULL;
			for(obj=MapObjectList; obj && (obj!=SelectedMapObj); obj=obj->Next)
				preobj=obj;
			if(preobj)
				preobj->Next=SelectedMapObj->Next;
			else
				MapObjectList=SelectedMapObj->Next;
			DelMapObject(SelectedMapObj);
			FreeMem(SelectedMapObj,sizeof(struct MapObject));
			NumObjects--;
			ModifiedMap_fl=TRUE;
			CloseMapObjWindow();
			break;

		case MAPOBJWINGAD_TRIGGER:
			TriggerSelect = 3;
			OpenEffectsWindow();
			TurnOffIDCMP(0xffffffff ^ EffectsWinSigBit);
			break;

		case MAPOBJWINGAD_OK:
			GT_GetGadgetAttrs(MapObjWinGadgets[MAPOBJWINGAD_HEADING],MapObjWin, NULL, GTCY_Active,&l1, TAG_DONE,0);
			SelectedMapObj->Heading = (WORD)l1;
			SelectedMapObj->Effect = MapObjEffect;
			ModifiedMap_fl=TRUE;
			CloseMapObjWindow();
			break;

		case MAPOBJWINGAD_CANCEL:
			CloseMapObjWindow();
			break;
	}
}

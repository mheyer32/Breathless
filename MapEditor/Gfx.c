//*****************************************************************************
//***
//***		Gfx.c
//***
//***	Gestione gfx
//***
//***
//***
//*****************************************************************************

#include	"MapEditor3d.h"
#include	"Definitions.h"


//*****************************************************************************



//*** Processa l'input sulla listview dei gfx

void ProcessGfxList(UWORD imsgCode, ULONG seconds, ULONG micros) {

	static ULONG		startsecs=0, startmicros=0, oldsel=0xffff;
	char				*str;
	struct GfxNode		*nnode;

	SelectedGfx = (struct GfxNode *)FindNode(&GfxList,imsgCode);

	if((oldsel == imsgCode) && DoubleClick(startsecs, startmicros, seconds, micros)) {
		if(GfxSelect) {
			if((GfxSelectWin==LevelWin) && (OpenedWindow & LevelWinSigBit)) {
				strncpy(n_LevelLoadPic,SelectedGfx->gfx_name,4);
				ModifiedMap_fl=TRUE;
			}
			GfxSelect=FALSE;
			TurnOnIDCMP(0xffffffff ^ GfxListWinSigBit);
			CloseGfxListWindow();
		}
		oldsel=0xffff;
	} else {
		oldsel=imsgCode;
	}
	startsecs=seconds;
	startmicros=micros;
}


//*****************************************************************************

//*** Conversione pics da planar a chunky

void PlanarToChunky2(struct PictureHeader *PicHead, UBYTE *punbuf) {

	register long	i,j,w,h;
	register UBYTE	*pun;

	rp.BitMap = &(PicHead->BitMap);

	pun=punbuf;
	w=(long)(PicHead->Header.Width);
	h=(long)(PicHead->Header.Height);
	for(j=0; j<h; j++) {
		for(i=0; i<w; i++) {
			*pun++=(UBYTE)ReadPixel(&rp,i,j);
		}
	}

}



//*** Legge dalla directory temporanea, la pic di nome name,
//*** di lunghezza length.
//*** Se delflag=TRUE, il file viene cancellato dopo essere stato letto.
//*** Se non ci sono errori restituisce FALSE.

int	ReadTempGfxFile(char *name, long length, int delflag) {

	struct FileHandle	*file;
	long				err;
	char				nname[9];

	strncpy(nname, name, 4);
	nname[4]='\0';
	if(!MakeFileName(filename, TempDir_Pref, nname, NULL, NULL, FILENAME_LEN)) {
		error=BADFILENAME;
		return(TRUE);
	}

	if ((file = (struct FileHandle *)Open((STRPTR)filename, MODE_OLDFILE)) != NULL) {
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




//*** Legge dalla directory temporanea, la pic di nome name,
//*** e ne restituisce la lunghezza.
//*** Se ci sono errori restituisce FALSE

long ReadTempGfxFile2(char *name) {

	struct FileHandle	*file;
	long				err, length;
	char				nname[9];

	strncpy(nname, name, 4);
	nname[4]='\0';
	if(!MakeFileName(filename, TempDir_Pref, nname, NULL, NULL, FILENAME_LEN)) {
		error=BADFILENAME;
		return(TRUE);
	}

	if ((file = (struct FileHandle *)Open((STRPTR)filename, MODE_OLDFILE)) != NULL) {
		if((length=Read((BPTR)file,GfxBuffer,81920L))==0) return(FALSE);
		Close((BPTR)file);
	} else {
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) return(TRUE);
	}
	return(length);
}




//*** Scrive il file temporaneo della pic
//*** mode =	MODE_NEWFILE
//***			MODE_OLDFILE
//*** Se non ci sono errori restituisce FALSE.

int	WriteTempGfxFile(char *name, long l, long mode) {

	struct FileHandle	*file;
	long				err;
	char				nname[9];

	strncpy(nname, name, 4);
	nname[4]='\0';
	if(!MakeFileName(filename, TempDir_Pref, nname, NULL, NULL, FILENAME_LEN)) {
		error=BADFILENAME;
		return(TRUE);
	}

	if ((file = (struct FileHandle *)Open((STRPTR)filename, mode)) != NULL) {

		if(mode==MODE_OLDFILE) {
			Seek((BPTR)file,0,OFFSET_END);
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



//*** Rimuove una pic dalla lista

void RemovePic(struct GfxNode *gfx) {

	if(gfx && (gfx->gfx_type!=GFXTYPE_EMPTY)) {
		GT_SetGadgetAttrs(GfxListWinGadgets[GFXLISTWINGAD_LIST],
							GfxListWin,NULL,
							GTLV_Labels, NULL,
							TAG_DONE, NULL);

		Remove((struct Node *)gfx);
		FreeMem(gfx,sizeof(struct GfxNode));

		GT_SetGadgetAttrs(GfxListWinGadgets[GFXLISTWINGAD_LIST],
							GfxListWin,NULL,
							GTLV_Labels, &GfxList,
							TAG_DONE, NULL);

		ModifiedGfx_fl=TRUE;
	}
}



//*** Aggiunge una nuova pic alla GfxList
//*** !!! ATTENZIONE !!!
//***     Questa routine è stata momentaneamente sostituita da
//***     una versione che carica direttamente le immagini
//***     in formato chunky


void AddNewPic() {

	int				err;
	long			len, i;
	UBYTE			*pun;
	char			picname[64];
	struct GfxNode	*gnode;

	filename[0]='\0';
	if(rtFileRequest(GfxFileReq, filename, "Add new pic", TAG_END,NULL)) {
		strcpy(GfxDir, GfxFileReq->Dir);
		strcpy(picname, filename);

		if(!MakeFileName(filename, GfxDir, picname, NULL, NULL, FILENAME_LEN)) {
			ShowErrorMessage(BADFILENAME,filename);
			goto ANPexit;
		}

		if(err=LoadIFFPic(filename,&GfxPicHead)) {
			ShowErrorMessage(err,filename);
			goto ANPexit;
		}

		len = GfxPicHead.Header.Width * GfxPicHead.Header.Height + 3*256;

	printf("width=%ld - height=%ld - depth=%ld\n",GfxPicHead.Header.Width,
												  GfxPicHead.Header.Height,
												  GfxPicHead.Header.Depth);

		PlanarToChunky2(&GfxPicHead,&(GfxBuffer[3*256]));

		for(i=0; i<3*256; i++)				// Copia palette
			GfxBuffer[i] = GfxPicHead.Palette[i];

		if(WriteTempGfxFile(picname, len, MODE_NEWFILE)) goto ANPexit;

		GT_SetGadgetAttrs(GfxListWinGadgets[GFXLISTWINGAD_LIST],
							GfxListWin,NULL,
							GTLV_Labels, NULL,
							TAG_DONE, NULL);


		if(!(gnode = (struct GfxNode *)AllocMem(sizeof(struct GfxNode),MEMF_CLEAR))) {
			error=NO_MEMORY;
			goto ANPexit;
		}

		picname[4]='\0';
		sprintf(gnode->gfx_name,"%-4s     ",picname);
		memset(&(gnode->gfx_name[9]),' ',30);

		gnode->gfx_type = GFXTYPE_PIC;
		gnode->gfx_noused = 0;
		gnode->gfx_x = (320 - GfxPicHead.Header.Width)>>1;
		gnode->gfx_y = (240 - GfxPicHead.Header.Height)>>1;
		gnode->gfx_width = GfxPicHead.Header.Width;
		gnode->gfx_height = GfxPicHead.Header.Height;
		gnode->gfx_offset = 0;
		gnode->gfx_length = len + sizeof(struct FGfx);
		gnode->gfx_location = 1;

		gnode->gfx_node.ln_Type=0;
		gnode->gfx_node.ln_Pri	=0;
		gnode->gfx_node.ln_Name=gnode->gfx_name;
		AddTail(&GfxList,&(gnode->gfx_node));

		GT_SetGadgetAttrs(GfxListWinGadgets[GFXLISTWINGAD_LIST],
							GfxListWin,NULL,
							GTLV_Labels, &GfxList,
							TAG_DONE, NULL);

		ModifiedGfx_fl=TRUE;
	}

ANPexit: ;

	err=IFFFree(&GfxPicHead);

}




/*
//*** Aggiunge una nuova pic alla GfxList
//*** !!! ATTENZIONE !!!
//***     Questa routine è solo momentanea e sostituisce la precedente
//***     Il file da caricare e' compresso con slz

void AddNewPic() {

	int				err;
	long			len, i;
	UBYTE			*pun;
	char			picname[64];

	filename[0]='\0';
	if(rtFileRequest(GfxFileReq, filename, "Add new pic", TAG_END,NULL)) {
		strcpy(GfxDir, GfxFileReq->Dir);
		strcpy(picname, filename);

		if(!MakeFileName(filename, GfxDir, picname, NULL, NULL, FILENAME_LEN)) {
			ShowErrorMessage(BADFILENAME,filename);
			goto ANPexit;
		}

		if ((file = (struct FileHandle *)Open((STRPTR)filename, MODE_OLDFILE)) != NULL) {
			len=Read(file,GfxBuffer,80000);
	
		printf("gfx len=%ld\n",len);
		
			if(WriteTempGfxFile(picname, len, MODE_NEWFILE)) goto ANPexit;

			GT_SetGadgetAttrs(GfxListWinGadgets[GFXLISTWINGAD_LIST],
								GfxListWin,NULL,
								GTLV_Labels, NULL,
								TAG_DONE, NULL);


			if(!(gnode = (struct GfxNode *)AllocMem(sizeof(struct GfxNode),MEMF_CLEAR))) {
				error=NO_MEMORY;
				goto ANPexit;
			}

			picname[4]='\0';
			sprintf(gnode->gfx_name,"%-4s     ",picname);
			memset(&(gnode->gfx_name[9]),' ',30);

			gnode->gfx_type = GFXTYPE_PIC;
			gnode->gfx_noused = 0;
			gnode->gfx_x = 0;
			gnode->gfx_y = 0;
			gnode->gfx_width = 0;
			gnode->gfx_height = 0;
			gnode->gfx_offset = 0;
			gnode->gfx_length = len;
			gnode->gfx_location = 1;

			gnode->gfx_node.ln_Type=0;
			gnode->gfx_node.ln_Pri	=0;
			gnode->gfx_node.ln_Name=gnode->gfx_name;
			AddTail(&GfxList,&(gnode->gfx_node));

			GT_SetGadgetAttrs(GfxListWinGadgets[GFXLISTWINGAD_LIST],
								GfxListWin,NULL,
								GTLV_Labels, &GfxList,
								TAG_DONE, NULL);

			ModifiedGfx_fl=TRUE;
		}
	}

ANPexit: ;
}

*/

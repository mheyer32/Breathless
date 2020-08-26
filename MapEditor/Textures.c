//*****************************************************************************
//***
//***		Textures.c
//***
//***		Gestione textures
//***
//***
//***
//*****************************************************************************

#include	"MapEditor3d.h"
#include	"Definitions.h"

#include <proto/dos.h>
#include <proto/intuition.h>

#include <string.h>
#include <stdio.h>

//*****************************************************************************




//*** Conversione texture da planar a chunky

void PlanarToChunky(struct PictureHeader *PicHead, UBYTE *punbuf) {

	register long	i,j,w,h;
	register UBYTE	*pun;

	rp.BitMap = &(PicHead->BitMap);

	pun=punbuf;
	w=(long)(PicHead->Header.Width);
	h=(long)(PicHead->Header.Height);
	for(i=0; i<w; i++) {
		for(j=0; j<h; j++) {
			*pun++=(UBYTE)ReadPixel(&rp,i,j);
		}
	}

}


//*** Conversione texture da chunky a planar

void ChunkyToPlanar(int width, int height) {

	register long	i,j,w,h;
	register UBYTE	*pun;

	w = GRAPHSCR_W;
	h = height;
	pun=GfxBuffer;
	for(i=GRAPHSCR_W-width; i<w; i++) {
		for(j=0; j<h; j++) {
			SetAPen(GraphScrRP,*pun++);
			WritePixel(GraphScrRP,i,j);
		}
	}
}


//*** Legge dal file Textures GLD la texture indicata dal nodo tnode
//*** Se non ci sono errori restituisce FALSE.

int ReadGLDTextFile(struct TextDirNode *tnode) {

	BPTR		file;
	long		err,l1;

	if(!MakeFileName(filename, ProjectDir, ProjectPrefix, ProjectTextFileName, ".gld", FILENAME_LEN)) return(1);

	err=0;

	if(tnode->tdn_type==0) return(0);

	if((file = Open((STRPTR)filename, MODE_OLDFILE)) != 0) {
		Read(file,&l1,4);
		if(l1 != TGLD_ID) {		// La ID è corretta ?
			ShowErrorMessage(BADGLDFILE, filename);
			err=1;
			goto RGTFesci;
		}

		if(tnode->tdn_type>1)
			l1 = tnode->tdn_offset + 20 + (tnode->tdn_type<<2);
		else
			l1 = tnode->tdn_offset + 20;

		if(Seek(file, l1, OFFSET_BEGINNING) == -1) {
			if(err=IoErr())
				if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) {
					err=1;
					goto RGTFesci;
				}
		}

		l1=tnode->tdn_width * tnode->tdn_height;
		do {
			err=0;
			if(Read(file,GfxBuffer,l1) < l1) {
				if(err=IoErr())
					if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) err=0;
			}
		} while(err);

	} else {
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) return(TRUE);
	}

RGTFesci:
	if(file)	Close(file);
	return(err);
}


//*** Legge dalla directory temporanea, la texture di nome name,
//*** di dimensioni l.
//*** Il parametro l indica il numero di byte da leggere dal file,
//*** quindi, presumibilmente, avra' valore:
//*** (width * height * numframes) + eventuali byte aggiuntivi
//*** Se delflag=TRUE, il file viene cancellato dopo essere stato letto.
//*** Se non ci sono errori restituisce FALSE.

int	ReadTempTextFile(long l, char *name, int delflag) {

	struct FileHandle	*file;
	long				err;
	char				nname[9];

	strncpy(nname, name, 8);
	nname[8]='\0';
	if(!MakeFileName(filename, TempDir_Pref, nname, NULL, NULL, FILENAME_LEN)) {
		error=BADFILENAME;
		return(TRUE);
	}

	if ((file = (struct FileHandle *)Open((STRPTR)filename, MODE_OLDFILE)) != NULL) {
		do {
			err=0;
			if(Read((BPTR)file,GfxBuffer,l)<l) {
				if(err=IoErr())
					if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) err=0;
			}
		} while(err);
		Close((BPTR)file);
		DeleteFile((STRPTR)filename);
	} else {
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) return(TRUE);
	}
	return(FALSE);
}


//*** Scrive il file temporaneo della texture
//*** mode =	MODE_NEWFILE
//***			MODE_OLDFILE
//*** Se non ci sono errori restituisce FALSE.

int	WriteTempTextFile(long l, char *name, long mode) {

	struct FileHandle	*file;
	long				err;
	char				nname[9];

	strncpy(nname, name, 8);
	nname[8]='\0';
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



//*** Mostra la texture n dalla lista

void ShowTexture(long n) {

	struct TextDirNode	*tnode;

	tnode=(struct TextDirNode *)FindNode(&TexturesList,n);

	if(tnode) {
		SetAPen(GraphScrRP,0);
		RectFill(GraphScrRP,0,0,319,255);	// Clear Graph screen

		if(!tnode->tdn_type) return;	// Se non è una texture, esce

		if(tnode->tdn_location) {		// La texture è su un file temporaneo ?
			if(ReadTempTextFile((tnode->tdn_width * tnode->tdn_height), tnode->tdn_name, FALSE)) return;
		} else {
			if(ReadGLDTextFile(tnode)) return;
		}

		ScreenToFront(GraphScr);

		ChunkyToPlanar(tnode->tdn_width, tnode->tdn_height);

		ShowMessageW(GraphWin,"Ok ?",0);
		ScreenToFront(MainScr);
	}
}



//*** Aggiunge una nuova texture alla lista
//*** type =	0 : normal texture
//***			1 : anim texture

void AddNewTexture(short type) {

	int					err, accept, i, l, frame, cont;
	char				*tname, msg[40];
	struct TextDirNode	*tnode;

	frame=0;
	cont=TRUE;

	while(cont) {
		strcpy(filename, TextureName);
		if(rtFileRequest(TextFileReq, filename, "Add new texture", TAG_END,NULL)) {
			strcpy(TexturesDir, TextFileReq->Dir);
			strcpy(TextureName, filename);

			if(!MakeFileName(filename, TexturesDir, TextureName, NULL, NULL, FILENAME_LEN)) {
				ShowErrorMessage(BADFILENAME,filename);
				goto ANTcont;
			}

			if(err=LoadIFFPic(filename,&TexturePicHead)) {
				ShowErrorMessage(err,filename);
				goto ANTcont;
			}

		printf("width=%ld - height=%ld - depth=%ld\n",TexturePicHead.Header.Width,
													  TexturePicHead.Header.Height,
													  TexturePicHead.Header.Depth);

			PlanarToChunky(&TexturePicHead,GfxBuffer);

			SetAPen(GraphScrRP,0);
			RectFill(GraphScrRP,0,0,319,255);	// Clear Graph screen

			MakeRGB32Table(&(TexturePicHead.Palette[0]));
			LoadRGB32(GraphScrVP,ColorTable);

			for(i=0; i<3*256; i++)				// Copia nella palette corrente
				Palette[i] = TexturePicHead.Palette[i];

			BltBitMapRastPort(&(TexturePicHead.BitMap),0,0,GraphScrRP,
										GRAPHSCR_W-TexturePicHead.Header.Width,0,
										TexturePicHead.Header.Width,
										TexturePicHead.Header.Height,0xc0);

			if(ShowText_fl) {
				ScreenToFront(GraphScr);
				sprintf(msg,"Accept this texture ?\n(%3ldx%3ld)",TexturePicHead.Header.Width,TexturePicHead.Header.Height);
				accept=ShowMessageW(GraphWin,msg,1);
				ScreenToFront(MainScr);
			} else {
				accept=TRUE;
			}

			if(accept) {

				frame++;

				if(frame==1) {
					if(!(tnode = (struct TextDirNode *)AllocMem(sizeof(struct TextDirNode),MEMF_CLEAR))) {
						error=NO_MEMORY;
						err=IFFFree(&TexturePicHead);
						return;
					}
				}

				// Forma il nome della texture per la list box nel formato: "abcdefgh  128x128"

				if(frame==1) {
					l=strnscpy(tnode->tdn_name, TextureName, 8, '.');
					for(i=l; i<8; i++) tnode->tdn_name[i]=' ';
					tnode->tdn_name[8]=' ';
					tnode->tdn_name[9]=' ';
				} else {
					tnode->tdn_name[9]='A';
				}
				sprintf(&(tnode->tdn_name[10]),"%3ld",TexturePicHead.Header.Width);
				tnode->tdn_name[13]='x';
				sprintf(&(tnode->tdn_name[14]),"%3ld",TexturePicHead.Header.Height);
				tnode->tdn_name[17]='\0';

				tnode->tdn_width=TexturePicHead.Header.Width;
				tnode->tdn_height=TexturePicHead.Header.Height;
				tnode->tdn_location=1;			// Segnala che la texture è su un file nella directory temporanea
				tnode->tdn_type=frame;			// Segnala che è una texture

				GT_SetGadgetAttrs(TexturesWinGadgets[TEXTWINGAD_LIST],
									TexturesWin,NULL,
									GTLV_Labels, NULL,
									TAG_DONE, NULL);

				if(frame==1) {
					tnode->tdn_node.ln_Type	=0;
					tnode->tdn_node.ln_Pri	=0;
					tnode->tdn_node.ln_Name	=tnode->tdn_name;
					nodo=FindNodePos(&TexturesList,tnode->tdn_name);
					Insert(&TexturesList,&(tnode->tdn_node),nodo);
				}

				GT_SetGadgetAttrs(TexturesWinGadgets[TEXTWINGAD_LIST],
									TexturesWin,NULL,
									GTLV_Labels, &TexturesList,
									TAG_DONE, NULL);

				ModifiedTextList_fl=TRUE;

				l=TexturePicHead.Header.Width * TexturePicHead.Header.Height;
				if(frame==1)
					WriteTempTextFile(l, tnode->tdn_name,MODE_NEWFILE);
				else
					WriteTempTextFile(l, tnode->tdn_name,MODE_OLDFILE);
			}
			err=IFFFree(&TexturePicHead);

			if(type) {
				if(!ShowMessage("Add another frame ?",2)) cont=FALSE;
			} else {
				cont=FALSE;
			}

		} else {

			cont=FALSE;

		}

ANTcont:;

	}
}


//*** Aggiunge una texture switch alla lista

void AddSwitchTexture() {

	int					err, accept, i, l, frame, cont;
	char				*tname, msg[40];
	struct TextDirNode	*tnode;
	struct FTexture		*ftpun;

	frame=0;
	cont=TRUE;

	while(cont) {
		strcpy(filename, TextureName);
		if(!frame)
			strcpy(msg,"Add switch : OFF frame");
		else
			strcpy(msg,"Add switch : ON frame");

		if(rtFileRequest(TextFileReq, filename, msg, TAG_END,NULL)) {
			strcpy(TexturesDir, TextFileReq->Dir);
			strcpy(TextureName, filename);

			if(!MakeFileName(filename, TexturesDir, TextureName, NULL, NULL, FILENAME_LEN)) {
				ShowErrorMessage(BADFILENAME,filename);
				goto ASTcont;
			}

			if(err=LoadIFFPic(filename,&TexturePicHead)) {
				ShowErrorMessage(err,filename);
				goto ASTcont;
			}

			if(frame) {
				ftpun=(struct FTexture *)GfxBuffer;
				ftpun->Width = TexturePicHead.Header.Width;
				ftpun->Animation = 1;
				ftpun->Height = TexturePicHead.Header.Height;
				ftpun->HShift = BitPos(TexturePicHead.Header.Height);
				ftpun->Frame = 16;
				ftpun->zero = 0;
				ftpun->FrameList[0] = 0;
				PlanarToChunky(&TexturePicHead,(UBYTE *)&(ftpun->FrameList[1]));
			} else {
				PlanarToChunky(&TexturePicHead,GfxBuffer);
			}

			SetAPen(GraphScrRP,0);
			RectFill(GraphScrRP,0,0,319,255);	// Clear Graph screen

			MakeRGB32Table(&(TexturePicHead.Palette[0]));
			LoadRGB32(GraphScrVP,ColorTable);

			for(i=0; i<3*256; i++)				// Copia nella palette corrente
				Palette[i] = TexturePicHead.Palette[i];

			BltBitMapRastPort(&(TexturePicHead.BitMap),0,0,GraphScrRP,
										GRAPHSCR_W-TexturePicHead.Header.Width,0,
										TexturePicHead.Header.Width,
										TexturePicHead.Header.Height,0xc0);

			if(ShowText_fl) {
				ScreenToFront(GraphScr);
				sprintf(msg,"Accept this texture ?\n(%3ldx%3ld)",TexturePicHead.Header.Width,TexturePicHead.Header.Height);
				accept=ShowMessageW(GraphWin,msg,1);
				ScreenToFront(MainScr);
			} else {
				accept=TRUE;
			}

			if(accept) {

				frame++;

				if(frame==1) {
					if(!(tnode = (struct TextDirNode *)AllocMem(sizeof(struct TextDirNode),MEMF_CLEAR))) {
						error=NO_MEMORY;
						err=IFFFree(&TexturePicHead);
						return;
					}
				}

				// Forma il nome della texture per la list box nel formato: "abcdefgh  128x128"

				if(frame==1) {
					l=strnscpy(tnode->tdn_name, TextureName, 8, '.');
					for(i=l; i<8; i++) tnode->tdn_name[i]=' ';
					tnode->tdn_name[8]=' ';
					tnode->tdn_name[9]=' ';
					sprintf(&(tnode->tdn_name[10]),"%3ld",TexturePicHead.Header.Width);
					tnode->tdn_name[13]='x';
					sprintf(&(tnode->tdn_name[14]),"%3ld",TexturePicHead.Header.Height);
					tnode->tdn_name[17]='\0';

					tnode->tdn_width=TexturePicHead.Header.Width;
					tnode->tdn_height=TexturePicHead.Header.Height;
					tnode->tdn_location=1;			// Segnala che la texture è su un file nella directory temporanea
					tnode->tdn_type=1;				// Segnala che è una texture
					tnode->tdn_switch=1;			// Segnala che è uno switch
				} else {
					tnode->tdn_name[9]='S';
				}

				GT_SetGadgetAttrs(TexturesWinGadgets[TEXTWINGAD_LIST],
									TexturesWin,NULL,
									GTLV_Labels, NULL,
									TAG_DONE, NULL);

				if(frame==1) {
					tnode->tdn_node.ln_Type	=0;
					tnode->tdn_node.ln_Pri	=0;
					tnode->tdn_node.ln_Name	=tnode->tdn_name;
					nodo=FindNodePos(&TexturesList,tnode->tdn_name);
					Insert(&TexturesList,&(tnode->tdn_node),nodo);
				}

				GT_SetGadgetAttrs(TexturesWinGadgets[TEXTWINGAD_LIST],
									TexturesWin,NULL,
									GTLV_Labels, &TexturesList,
									TAG_DONE, NULL);

				ModifiedTextList_fl=TRUE;

				l=TexturePicHead.Header.Width * TexturePicHead.Header.Height;
				if(frame==1)
					WriteTempTextFile(l,tnode->tdn_name,MODE_NEWFILE);
				else
					WriteTempTextFile(l+20,tnode->tdn_name,MODE_OLDFILE);
			}
			err=IFFFree(&TexturePicHead);

			if(frame<=1) {
				if(!ShowMessage("Add another frame ?",2)) cont=FALSE;
			} else {
				cont=FALSE;
			}

		} else {

			cont=FALSE;

		}

ASTcont:;

	}
}


//*** Modifica una texture già esistente

void ModifyTexture() {

	ShowMessage("Non implementato.",0);
}


//*** Rimuove una texture
//*** Ritorna TRUE se è tutto ok

int RemoveTexture(UWORD ntext) {

	struct TextDirNode	*tnode;
	struct Block		*bpun;

	tnode=(struct TextDirNode *)FindNode(&TexturesList,ntext);

	if(tnode) {
		if(tnode->tdn_type<1) return(FALSE);

		if((bpun=FindBlockTexture(tnode)) != NULL) {
			HilightBlock(bpun->BlockNumber);
			if(!ShowMessage("Texture already used!\nAre you sure you want\nto delete this texture ?",1)) {
				DrawMap();
				return(FALSE);
			}
		}

		GT_SetGadgetAttrs(TexturesWinGadgets[TEXTWINGAD_LIST],
							TexturesWin,NULL,
							GTLV_Labels, NULL,
							TAG_DONE, NULL);

		Remove((struct Node *)tnode);
		FreeMem(tnode,sizeof(struct TextDirNode));
		ModifiedTextList_fl=TRUE;

		GT_SetGadgetAttrs(TexturesWinGadgets[TEXTWINGAD_LIST],
							TexturesWin,NULL,
							GTLV_Labels, &TexturesList,
							TAG_DONE, NULL);

		return(TRUE);

	} else {

		return(FALSE);
	}
}



//*** Processa l'input sulla listview delle textures

void ProcessTextureList(UWORD imsgCode, ULONG seconds, ULONG micros) {

	static ULONG		startsecs=0, startmicros=0, oldsel=0xffff;
	char				*str;
	struct TextDirNode	*nnode;

	SelectedTexture = imsgCode;

	if(TextureSelect) {
		if(DoubleClick(startsecs, startmicros, seconds, micros)) {
			if(oldsel == SelectedTexture) {
				nnode=(struct TextDirNode *)FindNode(&TexturesList,imsgCode);
				switch(TextureSelect) {
					case BLOCKWINGAD_FLOORTEXT:		FloorTexture=nnode;		str=n_FloorTexture;		break;
					case BLOCKWINGAD_CEILTEXT:		CeilTexture=nnode;		str=n_CeilTexture;		break;
					case BLOCKWINGAD_E1_UPTEXT:		UpTextureE1=nnode;		str=n_UpTextureE1;		break;
					case BLOCKWINGAD_E1_NORMTEXT:	NormTextureE1=nnode;	str=n_NormTextureE1;	break;
					case BLOCKWINGAD_E1_LOWTEXT:	LowTextureE1=nnode;		str=n_LowTextureE1;		break;
					case BLOCKWINGAD_E2_UPTEXT:		UpTextureE2=nnode;		str=n_UpTextureE2;		break;
					case BLOCKWINGAD_E2_NORMTEXT:	NormTextureE2=nnode;	str=n_NormTextureE2;	break;
					case BLOCKWINGAD_E2_LOWTEXT:	LowTextureE2=nnode;		str=n_LowTextureE2;		break;
					case BLOCKWINGAD_E3_UPTEXT:		UpTextureE3=nnode;		str=n_UpTextureE3;		break;
					case BLOCKWINGAD_E3_NORMTEXT:	NormTextureE3=nnode;	str=n_NormTextureE3;	break;
					case BLOCKWINGAD_E3_LOWTEXT:	LowTextureE3=nnode;		str=n_LowTextureE3;		break;
					case BLOCKWINGAD_E4_UPTEXT:		UpTextureE4=nnode;		str=n_UpTextureE4;		break;
					case BLOCKWINGAD_E4_NORMTEXT:	NormTextureE4=nnode;	str=n_NormTextureE4;	break;
					case BLOCKWINGAD_E4_LOWTEXT:	LowTextureE4=nnode;		str=n_LowTextureE4;		break;
				}
				strncpy(str,((struct Node *)nnode)->ln_Name,8);
				GT_RefreshWindow(BlockWin,NULL);
				TextureSelect=FALSE;
				TurnOnIDCMP(0xffffffff ^ TexturesWinSigBit);
				oldsel=0xffff;
				CloseTexturesWindow();
			}
		}
	} else {
		if(DoubleClick(startsecs, startmicros, seconds, micros)) {
			if(oldsel == SelectedTexture) {
				ShowTexture(imsgCode);
				oldsel=0xffff;
			}
		}
	}
	startsecs=seconds;
	startmicros=micros;
	oldsel=SelectedTexture;
}


//*****************************************************************************

//*** Seleziona dalla TextureList le texture utilizzate nella mappa corrente.
//*** Le texture usate vengono numerate a partire da uno.
//*** Ritorna l'occupazione di memoria in byte delle texture.

long ArrangeTextureList() {

	register short	i;
	long			len;
	struct Node		*node;
	struct Block	*bpun;
	struct Edge		*epun;


 // Azzera tdn_num di tutte le texture

	for(node=TexturesList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
		((struct TextDirNode *)node)->tdn_num = 0;
	}

 // Scorre la BlockList per segnare tutte le texture effettivamente usate

	bpun = BlockList;
	while(bpun!=NULL) {
		(bpun->FloorTexture)->tdn_num = 1;
		(bpun->CeilTexture)->tdn_num = 1;
		epun = bpun->Edge1;
		(epun->NormTexture)->tdn_num = 1;
		(epun->UpTexture)->tdn_num = 1;
		(epun->LowTexture)->tdn_num = 1;
		epun = bpun->Edge2;
		(epun->NormTexture)->tdn_num = 1;
		(epun->UpTexture)->tdn_num = 1;
		(epun->LowTexture)->tdn_num = 1;
		epun = bpun->Edge3;
		(epun->NormTexture)->tdn_num = 1;
		(epun->UpTexture)->tdn_num = 1;
		(epun->LowTexture)->tdn_num = 1;
		epun = bpun->Edge4;
		(epun->NormTexture)->tdn_num = 1;
		(epun->UpTexture)->tdn_num = 1;
		(epun->LowTexture)->tdn_num = 1;

		bpun = bpun->Next;
	}

 // Scorre la TexturesList per numerare tutte le texture effettivamente usate

	len=0;
	i=0;
	for(node=TexturesList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
		if(((struct TextDirNode *)node)->tdn_type) {
			if(((struct TextDirNode *)node)->tdn_num) {
				((struct TextDirNode *)node)->tdn_num = ++i;
				len+=((struct TextDirNode *)node)->tdn_length;
			}
		} else {
			((struct TextDirNode *)node)->tdn_num = 0;	// Se è la texture vuota, il suo numero è zero.
		}
	}
	NumUsedTexture=i;

	return(len);
}


//*****************************************************************************


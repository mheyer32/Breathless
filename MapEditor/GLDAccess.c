//*****************************************************************************
//***
//***		GLDAccess.c
//***
//***		Gestione file .GLD
//***
//***
//***
//*****************************************************************************

#include	"MapEditor3d.h"
#include	"Definitions.h"



//*** Legge il file GLD relativo ad un livello
//*** Se non ci sono errori restituisce FALSE.

int ReadMapGLD(struct GLNode *level) {

	BPTR						file;
	long						err, l1, i, el;
	WORD						w1;
	short						trig, eff;
	UBYTE						b1;
	char						nometext[9], filename[FILENAME_LEN], ss[5];
	struct Block				*bpun, *bpunlast;
	struct FBlock				fblock;
	struct Edge					*epun, *epunlast, fedge;
	struct Node					*node;
	struct TextDirNode			*tnode;
//	static struct TextDirNode	*tdarray[2048];
	static void					*tdarray[2048];
	static struct Edge			*edarray[5000];
	struct EffectDirNode		*effnode;
	struct FxNode				*fxnode;
	struct MapObject			*mapobj, *lastobj;
	struct FMapObject			fmapobj;
	struct SoundNode			*snode;

	memcpy(ss,level->gln_filename,4);
	ss[4] = '\0';
	if(!MakeFileName(filename, ProjectDir, ProjectPrefix, ss, ".gld", FILENAME_LEN)) return(1);

	printf("ReadMapGLD(%ls)  ",filename);

	err=0;

	if ((file = Open((STRPTR)filename, MODE_OLDFILE)) != NULL) {
		printf("OK\n");

		Read(file,&l1,4);
		if(l1 != LGLD_ID) {		// La ID è corretta ?
			ShowErrorMessage(BADGLDFILE, filename);
			err=1;
			goto RLesci;
		}

		Read(file,&w1,2);		// Num. livelli nel file
		Read(file,&l1,4);		// Offset alla directory

		Read(file,&b1,1);		// Flag compressione

		Read(file,&l1,4);		// Lunghezza mappa

		//*** Legge blocks

		Read(file,&LastBlock,4);	// Num. blocchi

		BlockList = (struct Block *)NULL;

		for(i=0; i<LastBlock; i++) {
			Read(file,&fblock,32);

			if(!(bpun = (struct Block *)AllocMem(sizeof(struct Block),MEMF_CLEAR))) {
				error=NO_MEMORY;
				err=1;
				goto RLesci;
			}

			bpun->FloorHeight = fblock.FloorHeight;
			bpun->CeilHeight = fblock.CeilHeight;

			bpun->FloorTexture = (struct TextDirNode *)fblock.FloorTexture;
			if(fblock.CeilTexture<0) {
				bpun->CeilTexture = (struct TextDirNode *)(-fblock.CeilTexture);
				bpun->SkyCeil = 1;
			} else {
				bpun->CeilTexture = (struct TextDirNode *)fblock.CeilTexture;
				bpun->SkyCeil = 0;
			}
			bpun->BlockNumber = i;
			bpun->Illumination = fblock.Illumination>>8;
			bpun->FogLighting = (fblock.Illumination & 0x80) ? 1 : 0;
			bpun->Edge1 = (struct Edge *)fblock.Edge1;
			bpun->Edge2 = (struct Edge *)fblock.Edge2;
			bpun->Edge3 = (struct Edge *)fblock.Edge3;
			bpun->Edge4 = (struct Edge *)fblock.Edge4;
			bpun->Effect = (struct EffectDirNode *)fblock.Effect;
			bpun->Attributes = fblock.Attributes;
			bpun->Trigger = (struct EffectDirNode *)fblock.Trigger;
			bpun->Trigger2 = (struct EffectDirNode *)fblock.Trigger2;

			bpun->Next = (struct Block *)NULL;

			if(BlockList)		// E' il primo blocco della lista ?
				bpunlast->Next = bpun;
			else
				BlockList = bpun;

			bpunlast = bpun;
		}

		//*** Legge edges

		Read(file,&LastEdge,4);		// Num. edges

		EdgeList = (struct Edge *)NULL;

		for(i=0; i<LastEdge; i++) {
			Read(file,&fedge,16);

			if(!(epun = (struct Edge *)AllocMem(sizeof(struct Edge),MEMF_CLEAR))) {
				error=NO_MEMORY;
				err=1;
				goto RLesci;
			}

			edarray[i] = epun;

			epun->NormTexture = (struct TextDirNode *)fedge.NormTexture;
			epun->UpTexture = (struct TextDirNode *)fedge.UpTexture;
			epun->LowTexture = (struct TextDirNode *)fedge.LowTexture;
			epun->Attribute = fedge.Attribute;
			epun->EdgeNumber = (WORD)i;

			epun->Next = (struct Edge *)NULL;

			if(EdgeList)		// E' il primo edge della lista ?
				epunlast->Next = epun;
			else
				EdgeList = epun;

			epunlast = epun;
		}

		//*** Read Effects

			GT_SetGadgetAttrs(EffectsWinGadgets[PRJWINGAD_LIST], EffectsWin,NULL, GTLV_Labels, NULL, TAG_DONE, NULL);

			LastEffectList=0;
			LastTrigger=0;

			Read(file,&el,4);
			while(el>=0) {
				if(!(effnode = (struct EffectDirNode *)AllocMem(sizeof(struct EffectDirNode),MEMF_CLEAR))) {
					error=NO_MEMORY;
					err=1;
					goto RLesci;
				}
				LastEffectList++;

				sprintf(effnode->eff_name,"%3ld",LastEffectList);
				strcat(effnode->eff_name, " ------------------------------------");

				effnode->eff_listnum = LastEffectList;
				effnode->eff_trigger = 0;
				effnode->eff_fx = (struct FxNode *)NULL;
				effnode->eff_effect = 0;
				effnode->eff_param1 = 0;
				effnode->eff_param2 = 0;
				effnode->eff_key = 0;
				effnode->eff_noused = 0;

				effnode->eff_node.ln_Type	=0;
				effnode->eff_node.ln_Pri	=0;
				effnode->eff_node.ln_Name	=effnode->eff_name;
				AddTail(&EffectsList,&(effnode->eff_node));

				while(el) {
					if(!(effnode = (struct EffectDirNode *)AllocMem(sizeof(struct EffectDirNode),MEMF_CLEAR))) {
						error=NO_MEMORY;
						err=1;
						goto RLesci;
					}

					trig=(short)(el>>16);
					eff=(short)(el & 0xffff);

					LastTrigger = (trig>LastTrigger) ? trig : LastTrigger;

					for(node=FxList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
						fxnode=(struct FxNode *)node;
						if(eff==fxnode->fx_code) break;
					}

					effnode->eff_listnum = LastEffectList;
					effnode->eff_trigger = trig;
					effnode->eff_fx = fxnode;
					effnode->eff_effect = eff;

					Read(file,&el,4);
					effnode->eff_param1 = (short)(el>>16);
					effnode->eff_param2 = (short)(el & 0xffff);

					Read(file,&w1,2);
					effnode->eff_key = (char)(w1>>8);
					effnode->eff_noused = 0;

					sprintf(effnode->eff_name,"    %3ld %20s %5ld %5ld",trig,&(fxnode->fx_name[6]),effnode->eff_param1,effnode->eff_param2);

					effnode->eff_node.ln_Type	=0;
					effnode->eff_node.ln_Pri	=0;
					effnode->eff_node.ln_Name	=effnode->eff_name;
					AddTail(&EffectsList,&(effnode->eff_node));

					Read(file,&el,4);
				}
				Read(file,&el,4);
			}

			GT_SetGadgetAttrs(EffectsWinGadgets[PRJWINGAD_LIST], EffectsWin,NULL, GTLV_Labels, &EffectsList, TAG_DONE, NULL);


		//*** Read Map

			Read(file,MapBuffer,MAP_WIDTH*MAP_HEIGHT*2);

		//*** Read textures usate

		Read(file,&NumUsedTexture,4);		// Numero textures
		nometext[8] = '\0';
		tdarray[0] = TexturesList.lh_Head;

		for(i=1; i<=NumUsedTexture; i++) {
			Read(file,nometext,8);
			w1=1;
			for(node=TexturesList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
				if((w1=strncmp(node->ln_Name,nometext,8)) == 0) break;
			}
			if(!w1)
				tdarray[i] = node;
			else
				tdarray[i] = TexturesList.lh_Head;
		}


		//*** Assegna ai blocks e agli edges i pun. alle textures e agli effects

		bpun = BlockList;
		for(i=1; i<=LastBlock; i++) {
			bpun->FloorTexture = tdarray[(long)bpun->FloorTexture];
			bpun->CeilTexture = tdarray[(long)bpun->CeilTexture];
			bpun->Edge1 = edarray[(long)bpun->Edge1];
			bpun->Edge2 = edarray[(long)bpun->Edge2];
			bpun->Edge3 = edarray[(long)bpun->Edge3];
			bpun->Edge4 = edarray[(long)bpun->Edge4];
			if(bpun->Effect) {
				for(node=EffectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
					effnode=(struct EffectDirNode *)node;
					if(effnode->eff_listnum == (long)bpun->Effect) {
						bpun->Effect = effnode;
						break;
					}
				}
			} else {
				bpun->Effect = (struct EffectDirNode *)EffectsList.lh_Head;
			}
			if(bpun->Trigger) {
				for(node=EffectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
					effnode=(struct EffectDirNode *)node;
					if(effnode->eff_trigger == (long)bpun->Trigger) {
						bpun->Trigger = effnode;
						break;
					}
				}
			} else {
				bpun->Trigger = (struct EffectDirNode *)((EffectsList.lh_Head)->ln_Succ);
			}
			if(bpun->Trigger2) {
				for(node=EffectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
					effnode=(struct EffectDirNode *)node;
					if(effnode->eff_trigger == (long)bpun->Trigger2) {
						bpun->Trigger2 = effnode;
						break;
					}
				}
			} else {
				bpun->Trigger2 = (struct EffectDirNode *)((EffectsList.lh_Head)->ln_Succ);
			}
			bpun = bpun->Next;
		}
		epun = EdgeList;
		for(i=1; i<=LastEdge; i++) {
			epun->NormTexture = tdarray[(long)epun->NormTexture];
			epun->UpTexture = tdarray[(long)epun->UpTexture];
			epun->LowTexture = tdarray[(long)epun->LowTexture];
			epun = epun->Next;
		}


		//*** Read oggetti usati

		Read(file,&NumUsedObjects,4);		// Numero oggetti
		nometext[4] = '\0';
		tdarray[0] = ObjectsList.lh_Head;

		for(i=1; i<=NumUsedObjects; i++) {
			Read(file,nometext,4);
			w1=1;
			for(node=ObjectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
				if((w1=strncmp(node->ln_Name,nometext,4)) == 0) break;
			}
			if(!w1)
				tdarray[i] = node;
			else
				tdarray[i] = NULL;
		}


		//*** Read oggetti in mappa

		MapObjectList = NULL;

		Read(file,&NumObjects,4);		// Numero oggetti in mappa
		for(i=1; i<=NumObjects; i++) {
			Read(file,&fmapobj,sizeof(struct FMapObject));
			if(!(mapobj = (struct MapObject *)AllocMem(sizeof(struct MapObject),MEMF_CLEAR))) {
				error=NO_MEMORY;
				err=1;
				goto RLesci;
			}
			mapobj->Object		= tdarray[fmapobj.Object];
			mapobj->x			= fmapobj.x;
			mapobj->y			= fmapobj.y;
			mapobj->Heading		= (fmapobj.Heading)>>8;
			mapobj->PlayerType	= 0;
			mapobj->Effect		= (struct EffectDirNode *)fmapobj.Effect;
			mapobj->Next		= NULL;

				//*** Cerca pun. all'effetto
			l1=(long)mapobj->Effect;
			mapobj->Effect = (struct EffectDirNode *)EffectsList.lh_Head;
			if(l1) {
				for(node=EffectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
					effnode=(struct EffectDirNode *)node;
					if(effnode->eff_trigger == l1) {
						mapobj->Effect = effnode;
						break;
					}
				}
			}

			if(MapObjectList) {
				lastobj->Next = mapobj;
			} else {
				MapObjectList = mapobj;
			}

			lastobj = mapobj;
		}


		//*** Non legge i suoni usati perchè non servono al mapeditor
		//*** ma cerca solo il modulo PT del livello

		memset(n_LevelMod,' ',4);
		nometext[4] = '\0';

		Read(file,&l1,4);		// Numero suoni
		for(i=1; i<=l1; i++) {
			Read(file,nometext,4);
			if((snode=SearchSound(nometext))!=NULL) {
				if(snode->snd_type==SOUNDTYPE_MOD) {
					strcpy(n_LevelMod,nometext);
				}
			}
		}

	//*** Read loading pic name

		Read(file,n_LevelLoadPic,4);


	} else {
		printf("FAILED\n");
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) err=1;
	}

RLesci:
	if(file)	Close(file);
	return(err);
}



//*** Legge il Textures GLD
//*** Restituisce zero se non ci sono errori

int ReadTexturesGLD() {

	BPTR					file;
	long					err, i;
	long					l1, offset, numtext;
	char					filename[FILENAME_LEN];
	struct Node				*node;
	struct TextDirNode		*tnode;
	struct FTexture			ftext;
	struct FTextDirEntry	ftentry;


	if(!MakeFileName(filename, ProjectDir, ProjectPrefix, ProjectTextFileName, ".gld", FILENAME_LEN)) return(1);

	err=0;

	if((file = Open((STRPTR)filename, MODE_OLDFILE)) != NULL) {
		Read(file,&l1,4);
		if(l1 != TGLD_ID) {		// La ID è corretta ?
			ShowErrorMessage(BADGLDFILE, filename);
			err=1;
			goto RTesci;
		}

		Read(file,&l1,4);		// Legge offset della directory

		if(Seek(file, l1, OFFSET_BEGINNING) == -1) {
			if(err=IoErr())
				if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) {
					err=1;
					goto RTesci;
				}
		}

		Read(file,&numtext,4);		// Legge numero textures

		//*** Legge la directory

		for(i=0; i<numtext; i++) {
			if(!(tnode = (struct TextDirNode *)AllocMem(sizeof(struct TextDirNode),MEMF_CLEAR))) {
				error=NO_MEMORY;
				err=1;
				goto RTesci;
			}
			Read(file,tnode->tdn_name,8);		// Nome texture
			Read(file,&(tnode->tdn_offset),4);	// Offset
			Read(file,&(tnode->tdn_length),4);	// Length
			tnode->tdn_type = 1;
			tnode->tdn_location = 0;

			tnode->tdn_node.ln_Type	=0;
			tnode->tdn_node.ln_Pri	=0;
			tnode->tdn_node.ln_Name	=tnode->tdn_name;
			AddTail(&TexturesList,&(tnode->tdn_node));
		}

		//*** Legge la testata delle textures

		for(node=TexturesList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			tnode=(struct TextDirNode *)node;

			if(tnode->tdn_type) {
				if(Seek(file, tnode->tdn_offset, OFFSET_BEGINNING) == -1) {
					if(err=IoErr())
						if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) {
							err=1;
							goto RTesci;
						}
				}

				Read(file,&ftext,16);
				tnode->tdn_width =	ftext.Width;
				tnode->tdn_type =	ftext.Animation;
				tnode->tdn_height =	ftext.Height;

				tnode->tdn_name[8]=' ';
				if(tnode->tdn_type>1) {
					tnode->tdn_name[9]='A';
				} else {
					if(ftext.zero) {			// E' uno switch ?
						tnode->tdn_switch=1;
						tnode->tdn_name[9]='S';
					} else {
						tnode->tdn_name[9]=' ';
					}
				}
				sprintf(&(tnode->tdn_name[10]),"%3ld",tnode->tdn_width);
				tnode->tdn_name[13]='x';
				sprintf(&(tnode->tdn_name[14]),"%3ld",tnode->tdn_height);
				tnode->tdn_name[17]='\0';
			}
		}

	} else {
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) err=1;
	}

RTesci:

	if(file) Close(file);
	return(err);
}




//*** Legge l' Objects GLD
//*** Restituisce FALSE se non ci sono errori

int ReadObjectsGLD() {

	BPTR					file;
	long					err, i;
	long					l1, offset, numobj;
	char					filename[FILENAME_LEN];
	struct Node				*node;
	struct ObjDirNode		*onode;
	struct FObject			fobj;
	struct FObjDirEntry		foentry;


	if(!MakeFileName(filename, ProjectDir, ProjectPrefix, ProjectObjFileName, ".gld", FILENAME_LEN)) return(1);

	printf("ReadObjectsGLD(%ls)  ",filename);

	err=0;

	if((file = Open((STRPTR)filename, MODE_OLDFILE)) != NULL) {
		Read(file,&l1,4);
		if(l1 != OGLD_ID) {		// La ID è corretta ?
			ShowErrorMessage(BADGLDFILE, filename);
			err=1;
			goto ROesci;
		}

		Read(file,&l1,4);		// Legge offset della directory

		if(Seek(file, l1, OFFSET_BEGINNING) == -1) {
			if(err=IoErr())
				if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) {
					err=1;
					goto ROesci;
				}
		}

		Read(file,&numobj,4);		// Legge numero oggetti

		//*** Legge la directory

		for(i=0; i<numobj; i++) {
			if(!(onode = (struct ObjDirNode *)AllocMem(sizeof(struct ObjDirNode),MEMF_CLEAR))) {
				error=NO_MEMORY;
				err=1;
				goto ROesci;
			}
			Read(file,&foentry,sizeof(struct FObjDirEntry));
			memcpy(onode->odn_name,foentry.name,4);
			memset(&(onode->odn_name[4]),' ',5);
			onode->odn_name[40]='\0';
			onode->odn_offset = foentry.offset;
			onode->odn_length = foentry.length;
			onode->odn_location = 0;

			onode->odn_numframes = 1;

			onode->odn_node.ln_Type	= 0;
			onode->odn_node.ln_Pri	= 0;
			onode->odn_node.ln_Name	= onode->odn_name;
			AddTail(&ObjectsList,&(onode->odn_node));
		}

		//*** Legge descrizione oggetti

		for(node=ObjectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			onode=(struct ObjDirNode *)node;
			if(onode->odn_numframes) {
				Read(file,&(onode->odn_name[9]),30);
			}
		}

		//*** Legge la testata degli oggetti

		for(node=ObjectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			onode=(struct ObjDirNode *)node;

			if(onode->odn_numframes) {
				if(Seek(file, onode->odn_offset, OFFSET_BEGINNING) == -1) {
					if(err=IoErr())
						if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) {
							err=1;
							goto ROesci;
						}
				}

				Read(file,&fobj,36);	// Legge parte della struttura FObject

				onode->odn_numframes = fobj.numframes;
				onode->odn_radius = fobj.radius;
				onode->odn_height = fobj.height;
				onode->odn_animtype = fobj.animtype+1;
				onode->odn_objtype = fobj.objtype;
				onode->odn_param1 = fobj.param1;
				onode->odn_param2 = fobj.param2;
				onode->odn_param3 = fobj.param3;
				onode->odn_param4 = fobj.param4;
				onode->odn_param5 = fobj.param5;
				onode->odn_param6 = fobj.param6;
				onode->odn_param7 = fobj.param7;
				onode->odn_param8 = fobj.param8;
				onode->odn_param9 = fobj.param9;
				onode->odn_param10= fobj.param10;
				onode->odn_param11= fobj.param11;
				onode->odn_param12= fobj.param12;
				onode->odn_sound1 = fobj.sound1;
				onode->odn_sound2 = fobj.sound2;
				onode->odn_sound3 = fobj.sound3;
			}
		}

	} else {
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) err=1;
	}

ROesci:

	if(file) Close(file);
	return(err);
}



//*** Legge il file Gfx GLD
//*** Se non ci sono errori restituisce FALSE.

int ReadGfxGLD() {

	BPTR					file;
	long					err, i;
	long					l1, offset, numpic;
	WORD					w1;
	char					filename[FILENAME_LEN];
	struct Node				*node;
	struct GfxNode			*gnode;
	struct FGfx				fgfx;
	struct FGfxDirEntry		fgentry;


	if(!MakeFileName(filename, ProjectDir, ProjectPrefix, ProjectGfxFileName, ".gld", FILENAME_LEN)) return(1);

	err=0;

	if((file = Open((STRPTR)filename, MODE_OLDFILE)) != NULL) {
		Read(file,&l1,4);
		if(l1 != GGLD_ID) {		// La ID è corretta ?
			ShowErrorMessage(BADGLDFILE, filename);
			err=1;
			goto RGesci;
		}

		Read(file,&l1,4);		// offset directory

		Read(file,&w1,2);		// Numero palette di colori

		Read(file,Palette,3*256);	//*** Legge prima palette

		if(Seek(file, l1, OFFSET_BEGINNING) == -1) {
			if(err=IoErr())
				if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) {
					err=1;
					goto RGesci;
				}
		}

		Read(file,&numpic,4);		// Legge numero entry

		//*** Legge la directory

		for(i=0; i<numpic; i++) {
			if(!(gnode = (struct GfxNode *)AllocMem(sizeof(struct GfxNode),MEMF_CLEAR))) {
				error=NO_MEMORY;
				err=1;
				goto RGesci;
			}
			Read(file,&fgentry,sizeof(struct FGfxDirEntry));
			memcpy(gnode->gfx_name,fgentry.name,4);
			memset(&(gnode->gfx_name[4]),' ',5);
			gnode->gfx_name[40]='\0';
			gnode->gfx_offset = fgentry.offset;
			gnode->gfx_length = fgentry.length;
			gnode->gfx_location = 0;

			gnode->gfx_node.ln_Type	= 0;
			gnode->gfx_node.ln_Pri	= 0;
			gnode->gfx_node.ln_Name	= gnode->gfx_name;
			AddTail(&GfxList,&(gnode->gfx_node));
		}

		//*** Legge descrizioni

		for(node=GfxList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			gnode=(struct GfxNode *)node;
			if(gnode->gfx_type!=GFXTYPE_EMPTY)
				Read(file,&(gnode->gfx_name[9]),30);
		}

		//*** Legge la testata delle pic

		for(node=GfxList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			gnode=(struct GfxNode *)node;
			if(gnode->gfx_type!=GFXTYPE_EMPTY) {

				if(Seek(file, gnode->gfx_offset, OFFSET_BEGINNING) == -1) {
					if(err=IoErr())
						if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) {
							err=1;
							goto RGesci;
						}
				}

				Read(file,&fgfx,sizeof(struct FGfx));

				gnode->gfx_type 	= fgfx.type;
				gnode->gfx_x		= fgfx.x;
				gnode->gfx_y		= fgfx.y;
				gnode->gfx_width	= fgfx.width;
				gnode->gfx_height	= fgfx.height;
			}
		}

	} else {
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) err=1;
	}

RGesci:
	if(file)	Close(file);
	return(err);
}




//*** Legge ill Sounds GLD
//*** Restituisce FALSE se non ci sono errori

int ReadSoundsGLD() {

	BPTR					file;
	long					err, i;
	long					l1, offset, numsnd;
	char					filename[FILENAME_LEN];
	struct Node				*node;
	struct SoundNode		*snode;
	struct FSound			fsound;
	struct FSoundDirEntry	fsentry;


	if(!MakeFileName(filename, ProjectDir, ProjectPrefix, ProjectSoundFileName, ".gld", FILENAME_LEN)) return(1);

	printf("ReadSoundsGLD(%ls)  ",filename);

	err=0;

	if((file = Open((STRPTR)filename, MODE_OLDFILE)) != NULL) {
		Read(file,&l1,4);
		if(l1 != SGLD_ID) {		// La ID è corretta ?
			ShowErrorMessage(BADGLDFILE, filename);
			err=1;
			goto RSesci;
		}

		Read(file,&l1,4);		// Legge offset della directory

		if(Seek(file, l1, OFFSET_BEGINNING) == -1) {
			if(err=IoErr())
				if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) {
					err=1;
					goto RSesci;
				}
		}

		Read(file,&numsnd,4);		// Legge numero entry

		//*** Legge la directory

		for(i=0; i<numsnd; i++) {
			if(!(snode = (struct SoundNode *)AllocMem(sizeof(struct SoundNode),MEMF_CLEAR))) {
				error=NO_MEMORY;
				err=1;
				goto RSesci;
			}
			Read(file,&fsentry,sizeof(struct FSoundDirEntry));
			memcpy(snode->snd_name,fsentry.name,4);
			memset(&(snode->snd_name[4]),' ',5);
			snode->snd_name[40]='\0';
			snode->snd_offset = fsentry.offset;
			snode->snd_flength = fsentry.length;
			snode->snd_location = 0;

			snode->snd_node.ln_Type	= 0;
			snode->snd_node.ln_Pri	= 0;
			snode->snd_node.ln_Name	= snode->snd_name;
			AddTail(&SoundsList,&(snode->snd_node));
		}

		//*** Legge descrizioni

		for(node=SoundsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			snode=(struct SoundNode *)node;
			if(snode->snd_type!=SOUNDTYPE_EMPTY)
				Read(file,&(snode->snd_name[9]),30);
		}

		//*** Legge la testata dei suoni

		for(node=SoundsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			snode=(struct SoundNode *)node;
			if(snode->snd_type!=SOUNDTYPE_EMPTY) {

				if(Seek(file, snode->snd_offset, OFFSET_BEGINNING) == -1) {
					if(err=IoErr())
						if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) {
							err=1;
							goto RSesci;
						}
				}

				Read(file,&fsound,sizeof(struct FSound));

				snode->snd_type = ((fsound.type>=0) ? fsound.type : SOUNDTYPE_RND);
				if(snode->snd_type!=SOUNDTYPE_RND) {
					snode->snd_code = fsound.code;
					snode->snd_length = fsound.length<<1;
					snode->snd_period = fsound.period;
					snode->snd_volume = fsound.volume;
					snode->snd_loop = fsound.loop;
					snode->snd_priority = fsound.priority;
					snode->snd_mask = fsound.mask & 0x7f;
					snode->snd_alone = fsound.mask & 0x80;
				} else {
					snode->snd_code = 0;
					snode->snd_length = 0;
					snode->snd_period = 0;
					snode->snd_volume = 0;
					snode->snd_loop = 0;
					snode->snd_priority = 0;
					snode->snd_mask = 0;
				}
				switch(snode->snd_type) {
					case SOUNDTYPE_MOD:
						snode->snd_sample[0] = '\0';
						snode->snd_sound1[0] = '\0';
						snode->snd_sound2[0] = '\0';
						snode->snd_sound3[0] = '\0';
						break;
					case SOUNDTYPE_GLOBAL:
					case SOUNDTYPE_OBJECT:
						if(fsound.sample) {
							snode->snd_sample[0] = (fsound.sample & 0xff000000)>>24;
							snode->snd_sample[1] = (fsound.sample & 0xff0000)>>16;
							snode->snd_sample[2] = (fsound.sample & 0xff00)>>8;
							snode->snd_sample[3] = fsound.sample & 0xff;
							snode->snd_sample[4] = '\0';
						} else {
							snode->snd_sample[0] = '\0';
						}
						break;
					case SOUNDTYPE_RND:
						if(fsound.sample) {
							snode->snd_sound1[0] = (fsound.sample & 0xff000000)>>24;
							snode->snd_sound1[1] = (fsound.sample & 0xff0000)>>16;
							snode->snd_sound1[2] = (fsound.sample & 0xff00)>>8;
							snode->snd_sound1[3] = fsound.sample & 0xff;
							snode->snd_sound1[4] = '\0';
						} else {
							snode->snd_sound1[0] = '\0';
						}
						if(fsound.length+fsound.period) {
							snode->snd_sound2[0] = (fsound.length & 0xff00)>>8;
							snode->snd_sound2[1] = fsound.length & 0xff;
							snode->snd_sound2[2] = (fsound.period & 0xff00)>>8;
							snode->snd_sound2[3] = fsound.period & 0xff;
							snode->snd_sound2[4] = '\0';
						} else {
							snode->snd_sound2[0] = '\0';
						}
						if(fsound.volume+fsound.loop) {
							snode->snd_sound3[0] = (fsound.volume & 0xff00)>>8;
							snode->snd_sound3[1] = fsound.volume & 0xff;
							snode->snd_sound3[2] = (fsound.loop & 0xff00)>>8;
							snode->snd_sound3[3] = fsound.loop & 0xff;
							snode->snd_sound3[4] = '\0';
						} else {
							snode->snd_sound3[0] = '\0';
						}
						break;
				}
			}
		}
	} else {
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) err=1;
	}

RSesci:

	if(file) Close(file);
	return(err);
}




//*** Legge il file GLD principale
//*** Se non ci sono errori restituisce FALSE.

int ReadMainGLD() {

	BPTR			file;
	long			err, l1, i, j, nl;
	WORD			w1;
	char			str[30], filename[FILENAME_LEN];
	struct Node		*node;
	struct GLNode	*glnode;

	if(!MakeFileName(filename, ProjectDir, ProjectName, NULL, NULL, FILENAME_LEN)) return(1);

	printf("ReadMainGLD(%ls)  ",filename);

	err=0;

	if((file = Open((STRPTR)filename, MODE_OLDFILE)) != NULL) {
		printf("OK\n");

		Read(file,&l1,4);
		if(l1 != MGLD_ID) {		// La ID è corretta ?
			ShowErrorMessage(BADGLDFILE, filename);
			err=1;
			goto RMesci;
		}

		Read(file,ProjectNotes,32);

		Read(file,str,28);		// Filler

		Read(file,ProjectPrefix,4);				// Filenames prefix
		Read(file,ProjectGfxFileName,4);
		Read(file,ProjectTextFileName,4);
		Read(file,ProjectObjFileName,4);
		Read(file,ProjectSoundFileName,4);
		Read(file,str,4);		// Filler

		Read(file,&w1,2);		// Numero di games del project
		NumGame=w1;

		for(i=1; i<=NumGame; i++) {

			if(!(glnode = (struct GLNode *)AllocMem(sizeof(struct GLNode),MEMF_CLEAR))) {
				error=NO_MEMORY;
				err=1;
				goto RMesci;
			}

			Read(file,&(glnode->gln_num),2);
			sprintf(glnode->gln_gamenum,"%3ld ", i);
			Read(file,glnode->gln_gamename,20);
			glnode->gln_pad1=' ';
			memset(glnode->gln_levelnum,' ',4);
			memset(glnode->gln_levelname,' ',20);
			glnode->gln_pad2=' ';
			memset(glnode->gln_filename,' ',4);

			glnode->gln_type = 0;

			glnode->gln_node.ln_Type=0;
			glnode->gln_node.ln_Pri	=0;
			glnode->gln_node.ln_Name=glnode->gln_gamenum;
			AddTail(&GLList,&(glnode->gln_node));

			nl=glnode->gln_num;
			for(j=1; j<=nl; j++) {

				if(!(glnode = (struct GLNode *)AllocMem(sizeof(struct GLNode),MEMF_CLEAR))) {
					error=NO_MEMORY;
					err=1;
					goto RMesci;
				}

				Read(file,glnode->gln_filename,4);
				memset(glnode->gln_gamenum,' ',4);
				memset(glnode->gln_gamename,' ',20);
				glnode->gln_pad1=' ';
				sprintf(glnode->gln_levelnum,"%3ld ", j);
				Read(file,glnode->gln_levelname,20);
				glnode->gln_pad2=' ';
				glnode->gln_num = 0;

				glnode->gln_type = 1;

				glnode->gln_node.ln_Type=0;
				glnode->gln_node.ln_Pri	=0;
				glnode->gln_node.ln_Name=glnode->gln_gamenum;
				AddTail(&GLList,&(glnode->gln_node));
			}
		}
	} else {
		printf("FAILED\n");
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) err=1;
	}

RMesci:
	if(file)	Close(file);
	return(err);
}






//*** Scrive il file GLD relativo ad un livello
//*** Se non ci sono errori restituisce FALSE.

int WriteMapGLD(struct GLNode *level) {

	BPTR					file;
	long					err, t1, currpos, length;
	WORD					w1;
	short					lnum;
	UBYTE					b1;
	char					nometext[9], filename[FILENAME_LEN], ss[5];
	struct Block			*bpun;
	struct FBlock			fblock;
	struct Edge				*epun, fedge;
	struct EffectDirNode	*effnode;
	struct Node				*node;
	struct MapObject		*mapobj;
	struct FMapObject		fmapobj;

	memcpy(ss,level->gln_filename,4);
	ss[4] = '\0';
	if(!MakeFileName(filename, ProjectDir, ProjectPrefix, ss, ".gld", FILENAME_LEN)) return(1);

	printf("WriteMapGLD(%ls)  ",filename);

	err=0;

	if ((file = Open((STRPTR)filename, MODE_NEWFILE)) != NULL) {
		printf("OK\n");

		t1=LGLD_ID;
		Write(file,&t1,4);

		w1=1;
		Write(file,&w1,2);		// Num. livelli
		t1=0;
		Write(file,&t1,4);		// offset alla directory

	//*** Write compression type

		b1=0;
		Write(file,&b1,1);		// No compression

	//*** Write map length

		t1=0;
		Write(file,&t1,4);

	//*** Read current position

		currpos = Seek(file,0,OFFSET_CURRENT);

	//*** Write Blocks

		t1=LastBlock;
		Write(file,&t1,4);		// Num. of blocks 
		bpun = BlockList;
		while(bpun!=NULL) {
			fblock.FloorHeight =	bpun->FloorHeight;
			fblock.CeilHeight = 	bpun->CeilHeight;
			fblock.FloorTexture = 	(WORD)(bpun->FloorTexture->tdn_num);
			if(bpun->SkyCeil)
				fblock.CeilTexture = 	-((WORD)(bpun->CeilTexture->tdn_num));
			else
				fblock.CeilTexture = 	(WORD)(bpun->CeilTexture->tdn_num);
			fblock.BlockNumber = 	0;
			fblock.Illumination = 	(bpun->Illumination<<8) | (bpun->FogLighting ? 0x80 : 0);
			fblock.Edge1 = 			(LONG)(bpun->Edge1->EdgeNumber);
			fblock.Edge2 = 			(LONG)(bpun->Edge2->EdgeNumber);
			fblock.Edge3 = 			(LONG)(bpun->Edge3->EdgeNumber);
			fblock.Edge4 = 			(LONG)(bpun->Edge4->EdgeNumber);
			fblock.Effect = 		bpun->Effect->eff_listnum;
			fblock.Attributes = 	bpun->Attributes;
			fblock.Trigger = 		bpun->Trigger->eff_trigger;
			fblock.Trigger2 = 		bpun->Trigger2->eff_trigger;
			Write(file,&fblock,32);
			bpun = bpun->Next;
		}

	//*** Write Edges

		t1=LastEdge;
		Write(file,&t1,4);		// Num. of edges
		epun = EdgeList;
		while(epun!=NULL) {
			fedge.NormTexture =	(struct TextDirNode *)(epun->NormTexture->tdn_num);
			fedge.UpTexture =	(struct TextDirNode *)(epun->UpTexture->tdn_num);
			fedge.LowTexture =	(struct TextDirNode *)(epun->LowTexture->tdn_num);
			fedge.Attribute =	epun->Attribute;
			fedge.noused =		0;
			Write(file,&fedge,16);
			epun = epun->Next;
		}

	//*** Write Effects

		lnum=0;
		for(node=EffectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			effnode=(struct EffectDirNode *)node;
			if(effnode->eff_trigger) {				// E' un effetto
				Write(file,&(effnode->eff_trigger),10);
			} else {								// E' un separatore di lista
				if(lnum) {
					if(lnum!=effnode->eff_listnum) {
						t1=0;
						Write(file,&t1,4);		// Effect list end
					}
				}
				lnum=effnode->eff_listnum;
			}
		}

		t1=0;
		Write(file,&t1,4);		// Last effect list end
		t1=-1;
		Write(file,&t1,4);		// End

	//*** Write Map

		Write(file,MapBuffer,MAP_WIDTH*MAP_HEIGHT*2);

	//*** Read final position

		length = Seek(file,0,OFFSET_CURRENT) - currpos;

	//*** Write textures names

		Write(file,&NumUsedTexture,4);		// Numero textures
		for(node=TexturesList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			if(((struct TextDirNode *)node)->tdn_num) {
				strncpy(nometext,node->ln_Name,8);
				Write(file,nometext,8);
			}
		}

	//*** Write objects names

		Write(file,&NumUsedObjects,4);		// Numero oggetti usati
		for(node=ObjectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			if(((struct ObjDirNode *)node)->odn_num) {
				strncpy(nometext,node->ln_Name,4);
				Write(file,nometext,4);
			}
		}

	//*** Write oggetti in mappa

		Write(file,&NumObjects,4);		// Numero oggetti in mappa
		for(mapobj=MapObjectList; mapobj; mapobj=mapobj->Next) {
			fmapobj.Object	= (mapobj->Object)->odn_num;
			fmapobj.x		= mapobj->x;
			fmapobj.y		= mapobj->y;
			fmapobj.Heading	= (mapobj->Heading)<<8;
			fmapobj.Flags	= 0;
			fmapobj.Effect	= (UBYTE)mapobj->Effect->eff_trigger;

			Write(file,&fmapobj,sizeof(struct FMapObject));
		}


	//*** Write sounds names

		Write(file,&NumUsedSounds,4);		// Numero suoni usati
		for(node=SoundsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			if(((struct SoundNode *)node)->snd_num) {
				strncpy(nometext,node->ln_Name,4);
				Write(file,nometext,4);
			}
		}


	//*** Write loading pic name

		Write(file,n_LevelLoadPic,4);


	//*** Write length of map

		Seek(file, currpos-4, OFFSET_BEGINNING);
		Write(file,&length,4);

	} else {
		printf("FAILED\n");
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) err=1;
	}

	if(file)	Close(file);
	return(err);
}



//*** Scrive il Textures GLD
//*** Se non ci sono errori restituisce FALSE.

int WriteTexturesGLD() {

	BPTR					oldfile, newfile;
	long					err;
	long					l1, l2, offset, numtext, nframes;
	long					i, broffs, brlen, hdlen, swoffs;
	char					filename1[FILENAME_LEN], filename2[FILENAME_LEN];
	struct Node				*node;
	struct TextDirNode		*tnode;
	struct FTexture			ftext;
	struct FTextDirEntry	ftentry;

	if(!ModifiedTextList_fl) return(0);

	if(!MakeFileName(filename1, ProjectDir, ProjectPrefix, ProjectTextFileName, ".gld", FILENAME_LEN)) return(1);
	if(!MakeFileName(filename2, ProjectDir, ProjectPrefix, ProjectTextFileName, ".newgld", FILENAME_LEN)) return(1);

	if((oldfile = Open((STRPTR)filename1, MODE_OLDFILE)) == NULL) {
		err=IoErr();
		if(err!=0 && err!=ERROR_OBJECT_NOT_FOUND)
			if(ErrorReport(err, REPORT_STREAM, (ULONG)oldfile, NULL)) return(TRUE);
	}

	if((newfile = Open((STRPTR)filename2, MODE_NEWFILE)) != NULL) {
		l1=TGLD_ID;
		Write(newfile,&l1,4);
		l1=0;
		Write(newfile,&l1,4);		// Init offset alla directory

		offset = 8;
		err = 0;
		numtext = 0;
		for(node=TexturesList.lh_Head; node->ln_Succ; node=node->ln_Succ) {

			tnode=(struct TextDirNode *)node;

			if(tnode->tdn_type) {			// Se è una texture vera e propria
				if(tnode->tdn_location) {	// Legge da file temporaneo

					nframes=(long)(tnode->tdn_type);

					if(nframes>1)
						broffs = 16 + (nframes<<2);	// Offset del primo brush
					else
						broffs = 16;				// Offset del brush

					hdlen = broffs + 4;			// Lunghezza della testata della texture

					if(tnode->tdn_switch) { // Se è uno switch, la lunghezza della texture va calcolata in maniera diversa
						swoffs = (long)(tnode->tdn_width) * (long)(tnode->tdn_height);
						brlen = (swoffs<<1) + 20;
						l2 = brlen;
						swoffs += (broffs + 4);		// Offset al secondo frame dello switch
					} else {
						brlen = (long)(tnode->tdn_width) * (long)(tnode->tdn_height);
						l2 = brlen * nframes;
						swoffs = 0;
					}

					if(ReadTempTextFile(l2, tnode->tdn_name, TRUE)) {
						err = 1;
						goto WTesci;
					}

					ftext.Width = tnode->tdn_width;
					ftext.Animation = nframes;
					ftext.Height = tnode->tdn_height;
					ftext.HShift = BitPos(tnode->tdn_height);
					ftext.Frame = broffs;
					ftext.zero = swoffs;

					if(nframes>1) {			// Texture animata ?
						ftext.FrameList[nframes] = 0;
						for(i=0; i<nframes; i++) {
							ftext.FrameList[i] = broffs;
							broffs+=brlen;
						}
					} else {
						ftext.FrameList[0] = 0;
					}

					Write(newfile, &ftext, hdlen);
					Write(newfile, GfxBuffer, (brlen * nframes));

					tnode->tdn_length = hdlen + (brlen * nframes);

				} else {					// Legge da vecchio file gld

					if(Seek(oldfile, tnode->tdn_offset, OFFSET_BEGINNING) == -1) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)oldfile, NULL)) {
								err=1;
								goto WTesci;
							}
					}
					if(Read(oldfile, GfxBuffer, tnode->tdn_length) < tnode->tdn_length) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)oldfile, NULL)) {
								err=1;
								goto WTesci;
							}
					}
					if(Write(newfile, GfxBuffer, tnode->tdn_length) < tnode->tdn_length) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
								err=1;
								goto WTesci;
							}
					}
				}

				tnode->tdn_location = 0;	// Ora la texture e' su file GLD
				tnode->tdn_offset = offset;

				offset += tnode->tdn_length;
				numtext++;
			}
		}

		Write(newfile, &numtext, 4);	// Write numero textures

		//*** Write directory delle textures

		for(node=TexturesList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			tnode=(struct TextDirNode *)node;

			if(tnode->tdn_type) {		// Se è una texture vera e propria
				memcpy(ftentry.name, tnode->tdn_name, 8);
				ftentry.offset = tnode->tdn_offset;
				ftentry.length = tnode->tdn_length;

				if(Write(newfile, &ftentry, sizeof(struct FTextDirEntry)) < sizeof(struct FTextDirEntry)) {
					if(err=IoErr())
						if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
							err=1;
							goto WTesci;
						}
				}
			}
		}

		if(Seek(newfile, 4, OFFSET_BEGINNING) == -1) {
			if(err=IoErr())
				if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
					err=1;
					goto WTesci;
				}
		}
		Write(newfile, &offset, 4);

		//*** Cancella il vecchio file e rinomina il nuovo

		if(oldfile) {
			Close(oldfile);
			DeleteFile((STRPTR)filename1);
		}
		if(newfile)	Close(newfile);

		Rename((STRPTR)filename2, (STRPTR)filename1);

		return(0);

	} else {
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) err=1;
	}

WTesci:

	if(error) ShowErrorMessage(error, NULL);
	if(oldfile) Close(oldfile);
	if(newfile)	Close(newfile);
	return(err);
}




//*** Scrive l' Objects GLD
//*** Se non ci sono errori restituisce FALSE.

int WriteObjectsGLD() {

	BPTR					oldfile, newfile;
	long					err;
	long					l1, offset, numobj, nframes;
	long					i;
	char					filename1[FILENAME_LEN], filename2[FILENAME_LEN];
	struct Node				*node;
	struct ObjDirNode		*onode;
	struct FObject			fobj;
	struct FObjDirEntry		foentry;

	if(!ModifiedObjList_fl) return(0);

	if(!MakeFileName(filename1, ProjectDir, ProjectPrefix, ProjectObjFileName, ".gld", FILENAME_LEN)) return(1);
	if(!MakeFileName(filename2, ProjectDir, ProjectPrefix, ProjectObjFileName, ".newgld", FILENAME_LEN)) return(1);

	printf("WriteObjectsGLD(%ls)\n",filename1);

	if((oldfile = Open((STRPTR)filename1, MODE_OLDFILE)) == NULL) {
		err=IoErr();
		if(err!=0 && err!=ERROR_OBJECT_NOT_FOUND)
			if(ErrorReport(err, REPORT_STREAM, (ULONG)oldfile, NULL)) return(TRUE);
	}

	if((newfile = Open((STRPTR)filename2, MODE_NEWFILE)) != NULL) {
		l1=OGLD_ID;
		Write(newfile,&l1,4);
		l1=0;
		Write(newfile,&l1,4);		// Init offset alla directory

		offset = 8;
		err = 0;
		numobj = 0;
		for(node=ObjectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {

			onode=(struct ObjDirNode *)node;
	printf("numframes=%ld  location=%ld\n",onode->odn_numframes,onode->odn_location);
			if(onode->odn_numframes) {
				if(onode->odn_location) {	// Legge da file temporaneo

					if(ReadTempObjFile(onode->odn_name, onode->odn_length, TRUE)) {
						err = 1;
						goto WOesci;
					}
					if(Write(newfile, GfxBuffer, onode->odn_length) < onode->odn_length) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
								err=1;
								goto WOesci;
							}
					}

				} else {					// Legge da vecchio file gld

					if(Seek(oldfile, onode->odn_offset, OFFSET_BEGINNING) == -1) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)oldfile, NULL)) {
								err=1;
								goto WOesci;
							}
					}
					if(Read(oldfile, GfxBuffer, onode->odn_length) < onode->odn_length) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)oldfile, NULL)) {
								err=1;
								goto WOesci;
							}
					}
					if(Write(newfile, GfxBuffer, onode->odn_length) < onode->odn_length) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
								err=1;
								goto WOesci;
							}
					}
				}

				onode->odn_location = 0;	// Ora l'oggetto e' su file GLD
				onode->odn_offset = offset;

				offset += onode->odn_length;
				numobj++;
			}
		}

		Write(newfile, &numobj, 4);	// Write numero oggetti

		//*** Write directory degli oggetti

		for(node=ObjectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			onode=(struct ObjDirNode *)node;

			if(onode->odn_numframes) {
				memcpy(foentry.name, onode->odn_name, 4);
				foentry.offset = onode->odn_offset;
				foentry.length = onode->odn_length;

				if(Write(newfile, &foentry, sizeof(struct FObjDirEntry)) < sizeof(struct FObjDirEntry)) {
					if(err=IoErr())
						if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
							err=1;
							goto WOesci;
						}
				}
			}
		}


		//*** Write Descrizioni oggetti

		for(node=ObjectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			onode=(struct ObjDirNode *)node;

			if(onode->odn_numframes) {
				Write(newfile, &(onode->odn_name[9]), 30);
			}
		}


		//*** Write offset alla directory

		if(Seek(newfile, 4, OFFSET_BEGINNING) == -1) {
			if(err=IoErr())
				if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
					err=1;
					goto WOesci;
				}
		}
		Write(newfile, &offset, 4);

		//*** Cancella il vecchio file e rinomina il nuovo

		if(oldfile) {
			Close(oldfile);
			DeleteFile((STRPTR)filename1);
		}
		if(newfile)	Close(newfile);

		Rename((STRPTR)filename2, (STRPTR)filename1);

		return(0);

	} else {
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) err=1;
	}

WOesci:

	if(error) ShowErrorMessage(error, NULL);
	if(oldfile) Close(oldfile);
	if(newfile)	Close(newfile);
	return(err);
}



//*** Scrive il file Gfx GLD
//*** Se non ci sono errori restituisce FALSE.

int WriteGfxGLD() {

	BPTR					oldfile, newfile;
	long					err;
	long					l1, offset, numpic, len;
	long					i;
	WORD					w1;
	char					filename1[FILENAME_LEN], filename2[FILENAME_LEN];
	struct Node				*node;
	struct GfxNode			*gnode;
	struct FGfx				fgfx;
	struct FGfxDirEntry		fgentry;


	if(!ModifiedGfx_fl) return(0);

	if(!MakeFileName(filename1, ProjectDir, ProjectPrefix, ProjectGfxFileName, ".gld", FILENAME_LEN)) return(1);
	if(!MakeFileName(filename2, ProjectDir, ProjectPrefix, ProjectGfxFileName, ".newgld", FILENAME_LEN)) return(1);

	printf("WriteGfxGLD(%ls)  ",filename1);

	if((oldfile = Open((STRPTR)filename1, MODE_OLDFILE)) == NULL) {
		err=IoErr();
		if(err!=0 && err!=ERROR_OBJECT_NOT_FOUND)
			if(ErrorReport(err, REPORT_STREAM, (ULONG)oldfile, NULL)) return(TRUE);
	}

	if((newfile = Open((STRPTR)filename2, MODE_NEWFILE)) != NULL) {
		l1=GGLD_ID;
		Write(newfile,&l1,4);
		l1=0;
		Write(newfile,&l1,4);		// Init offset alla directory

		Read(oldfile,&l1,4);	// Read ID
		Read(oldfile,&l1,4);	// Read old dir offset

		//*** ATTENZIONE!!!
		//*** Al momento palettes e LightingTables non sono gestite
		//*** dal mapeditor, per cui viene fatta una semplice copia
		//*** di esse dall'oldfile al newfile

		Read(oldfile, &w1, 2);		// Num. palette
		Write(newfile, &w1, 2);
		Read(oldfile, GfxBuffer, (long)(w1*768));	// Palettes
		Write(newfile, GfxBuffer, (long)(w1*768));

		Read(oldfile, &w1, 2);		// Num. LightingTables
		Write(newfile, &w1, 2);
		Read(oldfile, GfxBuffer, (long)(w1*8192));	// LightingTables
		Write(newfile, GfxBuffer, (long)(w1*8192));



		//*** Trova posizione corrente per inizializzare offset

		if((offset=Seek(newfile, 0, OFFSET_CURRENT)) == -1) {
			if(err=IoErr())
				if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
					err=1;
					goto WGesci;
				}
		}

		err = 0;
		numpic = 0;
		for(node=GfxList.lh_Head; node->ln_Succ; node=node->ln_Succ) {

			gnode=(struct GfxNode *)node;
			if(gnode->gfx_type!=GFXTYPE_EMPTY) {
	printf("location=%ld\n",gnode->gfx_location);
				if(gnode->gfx_location) {	// Legge da file temporaneo

					fgfx.type 	= gnode->gfx_type;
					fgfx.noused = 0;
					fgfx.x 		= gnode->gfx_x;
					fgfx.y 		= gnode->gfx_y;
					fgfx.width 	= gnode->gfx_width;
					fgfx.height = gnode->gfx_height;

					if(Write(newfile, &fgfx, sizeof(struct FGfx)) < sizeof(struct FGfx)) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
								err=1;
								goto WGesci;
							}
					}

					len = (gnode->gfx_width * gnode->gfx_height + 3*256);	// Lunghezza pic in byte

/*					if(ReadTempGfxFile(gnode->gfx_name, len, TRUE)) {
						err = 1;
						goto WGesci;
					}
*/

		//*** ATTENZIONE!!! Il seguente if() sostituisce momentaneamente quello precedente

					if(len=ReadTempGfxFile2(gnode->gfx_name)) {
						gnode->gfx_length = len + sizeof(struct FGfx);
					} else {
						err = 1;
						goto WGesci;
					}

					if(Write(newfile, GfxBuffer, len) < len) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
								err=1;
								goto WGesci;
							}
					}
				} else {					// Legge da vecchio file gld

					if(Seek(oldfile, gnode->gfx_offset, OFFSET_BEGINNING) == -1) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)oldfile, NULL)) {
								err=1;
								goto WGesci;
							}
					}
					if(Read(oldfile, GfxBuffer, gnode->gfx_length) < gnode->gfx_length) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)oldfile, NULL)) {
								err=1;
								goto WGesci;
							}
					}
					if(Write(newfile, GfxBuffer, gnode->gfx_length) < gnode->gfx_length) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
								err=1;
								goto WGesci;
							}
					}
				}

				gnode->gfx_location = 0;	// Ora la pic e' su file GLD
				gnode->gfx_offset = offset;

				//*** Trova posizione corrente
				if((offset=Seek(newfile, 0, OFFSET_CURRENT)) == -1) {
					if(err=IoErr())
						if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
							err=1;
							goto WGesci;
						}
				}

//				offset += gnode->gfx_length;
				numpic++;
			}
		}

		Write(newfile, &numpic, 4);	// Write numero pics

		//*** Write directory

		for(node=GfxList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			gnode=(struct GfxNode *)node;
			if(gnode->gfx_type!=GFXTYPE_EMPTY) {

				memcpy(fgentry.name, gnode->gfx_name, 4);
				fgentry.offset = gnode->gfx_offset;
				fgentry.length = gnode->gfx_length;

				if(Write(newfile, &fgentry, sizeof(struct FGfxDirEntry)) < sizeof(struct FGfxDirEntry)) {
					if(err=IoErr())
						if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
							err=1;
							goto WGesci;
						}
				}
			}
		}


		//*** Write descrizioni

		for(node=GfxList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			gnode=(struct GfxNode *)node;
			if(gnode->gfx_type!=GFXTYPE_EMPTY)
				Write(newfile, &(gnode->gfx_name[9]), 30);
		}


		//*** Write offset alla directory

		if(Seek(newfile, 4, OFFSET_BEGINNING) == -1) {
			if(err=IoErr())
				if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
					err=1;
					goto WGesci;
				}
		}
		Write(newfile, &offset, 4);

		//*** Cancella il vecchio file e rinomina il nuovo

		if(oldfile) {
			Close(oldfile);
			DeleteFile((STRPTR)filename1);
		}
		if(newfile)	Close(newfile);

		Rename((STRPTR)filename2, (STRPTR)filename1);

		return(0);

	} else {
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) err=1;
	}

WGesci:

	if(error) ShowErrorMessage(error, NULL);
	if(oldfile) Close(oldfile);
	if(newfile)	Close(newfile);
	return(err);
}




//*** Scrive il Sounds GLD
//*** Se non ci sono errori restituisce FALSE.

int WriteSoundsGLD() {

	BPTR					oldfile, newfile;
	long					err;
	long					l1, offset, numsnd;
	long					i;
	char					filename1[FILENAME_LEN], filename2[FILENAME_LEN];
	struct Node				*node;
	struct SoundNode		*snode;
	struct FSound			fsound;
	struct FSoundDirEntry	fsentry;

	if(!ModifiedSoundList_fl) return(0);

	if(!MakeFileName(filename1, ProjectDir, ProjectPrefix, ProjectSoundFileName, ".gld", FILENAME_LEN)) return(1);
	if(!MakeFileName(filename2, ProjectDir, ProjectPrefix, ProjectSoundFileName, ".newgld", FILENAME_LEN)) return(1);

	printf("WriteSoundsGLD(%ls)  ",filename1);

	if((oldfile = Open((STRPTR)filename1, MODE_OLDFILE)) == NULL) {
		err=IoErr();
		if(err!=0 && err!=ERROR_OBJECT_NOT_FOUND)
			if(ErrorReport(err, REPORT_STREAM, (ULONG)oldfile, NULL)) return(TRUE);
	}

	if((newfile = Open((STRPTR)filename2, MODE_NEWFILE)) != NULL) {
		l1=SGLD_ID;
		Write(newfile,&l1,4);
		l1=0;
		Write(newfile,&l1,4);		// Init offset alla directory

		offset = 8;
		err = 0;
		numsnd = 0;
		for(node=SoundsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			snode=(struct SoundNode *)node;
			if(snode->snd_type!=SOUNDTYPE_EMPTY) {
	printf("location=%ld\n",snode->snd_location);
				if(snode->snd_location) {	// Legge da file temporaneo

					fsound.type = ((snode->snd_type==SOUNDTYPE_RND) ? -1 : snode->snd_type);
					fsound.code = snode->snd_code;
					fsound.length = snode->snd_length>>1;
					fsound.period = snode->snd_period;
					fsound.volume = snode->snd_volume;
					fsound.loop = snode->snd_loop;
					fsound.priority = snode->snd_priority;
					fsound.mask = snode->snd_mask | snode->snd_alone;
					switch(snode->snd_type) {
						case SOUNDTYPE_MOD:
							fsound.sample=0;
							break;
						case SOUNDTYPE_GLOBAL:
						case SOUNDTYPE_OBJECT:
							if(strisempty(snode->snd_sample)) {
								fsound.sample=0;
							} else {
								fsound.sample = (ULONG)((snode->snd_sample[0]<<24) |
														(snode->snd_sample[1]<<16) |
														(snode->snd_sample[2]<<8) |
														 snode->snd_sample[3]);
							}
							break;
						case SOUNDTYPE_RND:
							fsound.code = 0;
							if(strisempty(snode->snd_sound1)) {
								fsound.sample=0;
							} else {
								fsound.code++;
								fsound.sample = (ULONG)((snode->snd_sound1[0]<<24) |
														(snode->snd_sound1[1]<<16) |
														(snode->snd_sound1[2]<<8) |
														 snode->snd_sound1[3]);
							}
							if(strisempty(snode->snd_sound2)) {
								fsound.length=0;
								fsound.period=0;
							} else {
								fsound.code++;
								fsound.length = (UWORD)((snode->snd_sound2[0]<<8) |
														 snode->snd_sound2[1]);
								fsound.period = (UWORD)((snode->snd_sound2[2]<<8) |
														 snode->snd_sound2[3]);
							}
							if(strisempty(snode->snd_sound3)) {
								fsound.volume=0;
								fsound.loop=0;
							} else {
								fsound.code++;
								fsound.volume = (UWORD)((snode->snd_sound3[0]<<8) |
														 snode->snd_sound3[1]);
								fsound.loop = (UWORD)((snode->snd_sound3[2]<<8) |
													   snode->snd_sound3[3]);
							}
							break;
					}

					if(Write(newfile, &fsound, sizeof(struct FSound)) < sizeof(struct FSound)) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
								err=1;
								goto WSesci;
							}
					}

					if(fsound.sample == NULL) {
						if(ReadTempSoundFile(snode->snd_name, snode->snd_flength, TRUE)) {
							err = 1;
							goto WSesci;
						}
						if(Write(newfile, GfxBuffer, snode->snd_length) < snode->snd_length) {
							if(err=IoErr())
								if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
									err=1;
									goto WSesci;
								}
						}
					}

				} else {					// Legge da vecchio file gld

					if(Seek(oldfile, snode->snd_offset, OFFSET_BEGINNING) == -1) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)oldfile, NULL)) {
								err=1;
								goto WSesci;
							}
					}
					if(Read(oldfile, GfxBuffer, snode->snd_flength) < snode->snd_flength) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)oldfile, NULL)) {
								err=1;
								goto WSesci;
							}
					}
					if(Write(newfile, GfxBuffer, snode->snd_flength) < snode->snd_flength) {
						if(err=IoErr())
							if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
								err=1;
								goto WSesci;
							}
					}
				}

				snode->snd_location = 0;	// Ora il suono e' su file GLD
				snode->snd_offset = offset;

				offset += snode->snd_flength;
				numsnd++;
			}
		}

		Write(newfile, &numsnd, 4);	// Write numero suoni

		//*** Write directory dei suoni

		for(node=SoundsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			snode=(struct SoundNode *)node;
			if(snode->snd_type!=SOUNDTYPE_EMPTY) {

				memcpy(fsentry.name, snode->snd_name, 4);
				fsentry.offset = snode->snd_offset;
				fsentry.length = snode->snd_flength;

				if(Write(newfile, &fsentry, sizeof(struct FSoundDirEntry)) < sizeof(struct FSoundDirEntry)) {
					if(err=IoErr())
						if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
							err=1;
							goto WSesci;
						}
				}
			}
		}


		//*** Write descrizioni suoni

		for(node=SoundsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			snode=(struct SoundNode *)node;
			if(snode->snd_type!=SOUNDTYPE_EMPTY)
				Write(newfile, &(snode->snd_name[9]), 30);
		}


		//*** Write offset alla directory

		if(Seek(newfile, 4, OFFSET_BEGINNING) == -1) {
			if(err=IoErr())
				if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) {
					err=1;
					goto WSesci;
				}
		}
		Write(newfile, &offset, 4);

		//*** Cancella il vecchio file e rinomina il nuovo

		if(oldfile) {
			Close(oldfile);
			DeleteFile((STRPTR)filename1);
		}
		if(newfile)	Close(newfile);

		Rename((STRPTR)filename2, (STRPTR)filename1);

		return(0);

	} else {
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)newfile, NULL)) err=1;
	}

WSesci:

	if(error) ShowErrorMessage(error, NULL);
	if(oldfile) Close(oldfile);
	if(newfile)	Close(newfile);
	return(err);
}




//*** Scrive il file GLD principale
//*** Se non ci sono errori restituisce FALSE.

int WriteMainGLD() {

	BPTR			file;
	long			err, l1, lun;
	WORD			w1;
	char			str[30], filename[FILENAME_LEN];
	struct Node		*node;
	struct GLNode	*glnode;

	if(!MakeFileName(filename, ProjectDir, ProjectName, ".gld", NULL, FILENAME_LEN)) return(1);

	printf("WriteMainGLD(%ls)  ",filename);

	err=0;

	if((file = Open((STRPTR)filename, MODE_NEWFILE)) != NULL) {
		printf("OK\n");

		l1=MGLD_ID;
		Write(file,&l1,4);
		Write(file,ProjectNotes,32);

		strncpy(str,"MUSTLOG1LOG2BTITCREDGAOVLAST",28);
		Write(file,str,28);		// Nomi musica e schermate presentazione

//		memset(str,0,28);
//		Write(file,str,28-20);		// Filler

		Write(file,ProjectPrefix,4);				// Filenames prefix
		Write(file,ProjectGfxFileName,4);
		Write(file,ProjectTextFileName,4);
		Write(file,ProjectObjFileName,4);
		Write(file,ProjectSoundFileName,4);

		//*** Calcola lunghezza directory dei livelli

		lun=0;
		for(node=GLList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			glnode=(struct GLNode *)node;
			if(!glnode->gln_type) {		// Game node
				lun+=22;
			} else {					// Level node
				lun+=24;
			}
		}

		Write(file,&lun,4);		// Lunghezza

		w1=NumGame;
		Write(file,&w1,2);		// Numero di games del project

		for(node=GLList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			glnode=(struct GLNode *)node;

			if(!glnode->gln_type) {		// Game node

				Write(file,&(glnode->gln_num),2);		// Num. level per game
				Write(file,glnode->gln_gamename,20);	// Nome game

			} else {					// Level node

				Write(file,glnode->gln_filename,4);		// Nome file level
				Write(file,glnode->gln_levelname,20);	// Nome level

			}
		}
	} else {
		printf("FAILED\n");
		if(err=IoErr())
			if(ErrorReport(err, REPORT_STREAM, (ULONG)file, NULL)) err=1;
	}

	if(file)	Close(file);
	return(err);
}

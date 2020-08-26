//*****************************************************************************
//***
//***		Sounds.c
//***
//***	Gestione suoni
//***
//***
//***
//*****************************************************************************

#include	"MapEditor3d.h"
#include	"Definitions.h"


//*****************************************************************************


//*** Cerca il sound di nome name (4 char)

struct SoundNode *SearchSound(char *name) {

	struct Node			*node;
	char				*str;

	for(node=SoundsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
		str=((struct SoundNode *)node)->snd_name;
		if((*str++ == name[0]) && (*str++ == name[1]) &&
		   (*str++ == name[2]) && (*str++ == name[3]))	return((struct SoundNode *)node);
	}

	return(NULL);
}



//*** Seleziona dalla SoundsList i suoni utilizzati nella mappa corrente.
//*** I suoni vengono poi numerati a partire da uno.
//*** Ritorna l'occupazione di memoria in byte dei suoni.

long ArrangeSoundsList() {

	register short		i;
	long				len, l1, *lpun, ttt;
	struct Node			*node, *node2;
	struct ObjDirNode	*onode;
	struct SoundNode	*snode, *snode2;


	//*** Azzera snd_num di tutti i suoni

	for(node=SoundsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
		((struct SoundNode *)node)->snd_num = 0;
	}

	//*** Scorre la SoundsList per segnare tutti i suoni globali

	for(node=SoundsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
		if(((struct SoundNode *)node)->snd_type == SOUNDTYPE_GLOBAL)
			((struct SoundNode *)node)->snd_num = 1;
	}

	//*** Scorre la ObjectsList e per ogni oggetto usato in mappa,
    //*** segna i suoni da esso usati

	for(node2=ObjectsList.lh_Head; node2->ln_Succ; node2=node2->ln_Succ) {
		onode=(struct ObjDirNode *)node2;
		if(onode->odn_num) {
			if(((l1=onode->odn_sound1) != NULL) && ((l1=onode->odn_sound1) != 0x20202020)) {
				for(node=SoundsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
					lpun=(long *)(((struct SoundNode *)node)->snd_name);
					if(*lpun==l1) {
						((struct SoundNode *)node)->snd_num = 1;
						break;
					}
				}
			}
			if(((l1=onode->odn_sound2) != NULL) && ((l1=onode->odn_sound2) != 0x20202020)) {
				for(node=SoundsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
					lpun=(long *)(((struct SoundNode *)node)->snd_name);
					if(*lpun==l1) {
						((struct SoundNode *)node)->snd_num = 1;
						break;
					}
				}
			}
			if(((l1=onode->odn_sound3) != NULL) && ((l1=onode->odn_sound3) != 0x20202020)) {
				for(node=SoundsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
					lpun=(long *)(((struct SoundNode *)node)->snd_name);
					if(*lpun==l1) {
						((struct SoundNode *)node)->snd_num = 1;
						break;
					}
				}
			}
		}
	}

	//*** Scorre la SoundsList 2 volte e cerca eventuali link tra i suoni usati

	for(ttt=0; ttt<2; ttt++) {
		for(node=SoundsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			snode=(struct SoundNode *)node;
			if(snode->snd_num) {
				if(snode->snd_type!=SOUNDTYPE_RND) {
					if(!strisempty(snode->snd_sample)) {
						if((snode2=SearchSound(snode->snd_sample))!=NULL) snode2->snd_num=1;
					}
				} else {
					if(!strisempty(snode->snd_sound1)) {
						if((snode2=SearchSound(snode->snd_sound1))!=NULL) snode2->snd_num=1;
					}
					if(!strisempty(snode->snd_sound2)) {
						if((snode2=SearchSound(snode->snd_sound2))!=NULL) snode2->snd_num=1;
					}
					if(!strisempty(snode->snd_sound3)) {
						if((snode2=SearchSound(snode->snd_sound3))!=NULL) snode2->snd_num=1;
					}
				}
			}
		}
	}


	//*** Segna eventuale modulo protracker del livello

	if(!strisempty(n_LevelMod))
		if((snode=SearchSound(n_LevelMod))!=NULL) snode->snd_num=1;


	//*** Scorre la SoundsList per numerare tutti i suoni usati

	len=0;
	i=0;
	for(node=SoundsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
		if(((struct SoundNode *)node)->snd_num) {
			((struct SoundNode *)node)->snd_num = ++i;
			len+=((struct SoundNode *)node)->snd_flength;
		}
	}
	NumUsedSounds=i;

	return(len);
}

//*****************************************************************************

//*** Legge il sample di nome name e lunghezza length
//*** Se non ci sono errori restituisce FALSE.

int ReadSound(char *name, long length) {

	struct FileHandle	*file;
	long				err;

	if ((file = (struct FileHandle *)Open((STRPTR)name, MODE_OLDFILE)) != NULL) {
		do {
			err=0;
			if(Read((BPTR)file,GfxBuffer,length)<length) {
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



//*** Legge dalla directory temporanea, il suono di nome name,
//*** di lunghezza length.
//*** Se delflag=TRUE, il file viene cancellato dopo essere stato letto.
//*** Se non ci sono errori restituisce FALSE.

int	ReadTempSoundFile(char *name, long length, int delflag) {

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



//*** Scrive il file temporaneo del sound
//*** mode =	MODE_NEWFILE
//***			MODE_OLDFILE
//*** Se non ci sono errori restituisce FALSE.

int	WriteTempSoundFile(char *name, long l, long mode) {

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



//*** Rimuove un sound dalla lista

void RemoveSound(struct SoundNode *sound) {

	if(sound && (sound->snd_type!=SOUNDTYPE_EMPTY)) {
		GT_SetGadgetAttrs(SndListWinGadgets[SNDLISTWINGAD_LIST],
							SndListWin,NULL,
							GTLV_Labels, NULL,
							TAG_DONE, NULL);

		Remove((struct Node *)sound);
		FreeMem(sound,sizeof(struct SoundNode));

		GT_SetGadgetAttrs(SndListWinGadgets[SNDLISTWINGAD_LIST],
							SndListWin,NULL,
							GTLV_Labels, &SoundsList,
							TAG_DONE, NULL);

		ModifiedSoundList_fl=TRUE;
	}
}



//*** Se sound==NULL , aggiunge un nuovo suono alla lista
//*** Se sound!=NULL , modifica suono

void AddModifySound(struct SoundNode *sound) {

	struct SoundNode		snode, *nsnode;
	struct Node				savenode;
	long					l1, offset;
	char					*str, *str2, sndname[9];


	GT_GetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_NAME], SoundsWin,NULL, GTST_String,&str, TAG_DONE,0);
	GT_GetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_DESCR], SoundsWin,NULL, GTST_String,&str2, TAG_DONE,0);
	sprintf(snode.snd_name,"%-4s     %-30s",str,str2);
	strcpy(sndname,str);

	if(strisempty(str)) {
		ShowMessage("You MUST specify sound name !",0);
		return;
	}

	GT_GetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_TYPE],SoundsWin, NULL, GTCY_Active,&l1, TAG_DONE,0);
	snode.snd_type = l1;

	snode.snd_length = (((struct StringInfo *)SoundsWinGadgets[SOUNDWINGAD_LENGTH]->SpecialInfo)->LongInt);
	snode.snd_period = (((struct StringInfo *)SoundsWinGadgets[SOUNDWINGAD_PERIOD]->SpecialInfo)->LongInt);
	snode.snd_volume = (((struct StringInfo *)SoundsWinGadgets[SOUNDWINGAD_VOLUME]->SpecialInfo)->LongInt);
	snode.snd_loop = (((struct StringInfo *)SoundsWinGadgets[SOUNDWINGAD_LOOP]->SpecialInfo)->LongInt);
	snode.snd_priority = (((struct StringInfo *)SoundsWinGadgets[SOUNDWINGAD_PRIORITY]->SpecialInfo)->LongInt);
	snode.snd_code = (((struct StringInfo *)SoundsWinGadgets[SOUNDWINGAD_CODE]->SpecialInfo)->LongInt);
	snode.snd_mask = ((SoundsWinGadgets[SOUNDWINGAD_CHANNEL1]->Flags & SELECTED) ? 1 : 0);
	snode.snd_mask |= ((SoundsWinGadgets[SOUNDWINGAD_CHANNEL2]->Flags & SELECTED) ? 2 : 0);
	snode.snd_mask |= ((SoundsWinGadgets[SOUNDWINGAD_CHANNEL3]->Flags & SELECTED) ? 4 : 0);
	snode.snd_mask |= ((SoundsWinGadgets[SOUNDWINGAD_CHANNEL4]->Flags & SELECTED) ? 8 : 0);
	snode.snd_alone = ((SoundsWinGadgets[SOUNDWINGAD_ALONE]->Flags & SELECTED) ? 0x80 : 0);

	GT_GetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND1], SoundsWin,NULL, GTST_String,&str, TAG_DONE,0);
	strcpy(snode.snd_sound1,str);
	snode.snd_sound1[4]='\0';

	GT_GetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND2], SoundsWin,NULL, GTST_String,&str, TAG_DONE,0);
	strcpy(snode.snd_sound2,str);
	snode.snd_sound2[4]='\0';

	GT_GetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND3], SoundsWin,NULL, GTST_String,&str, TAG_DONE,0);
	strcpy(snode.snd_sound3,str);
	snode.snd_sound3[4]='\0';

	GT_GetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SAMPLE], SoundsWin,NULL, GTST_String,&str, TAG_DONE,0);
	strcpy(snode.snd_sample,str);
	snode.snd_sample[4]='\0';


	if(strisempty(str) && (snode.snd_type!=SOUNDTYPE_RND)) {
		if(rtFileRequest(SndFileReq, filename, "Pick a directory", RTFI_Flags,FREQF_NOFILES, TAG_END,NULL)) {
			strcpy(SoundsDir, SndFileReq->Dir);

			if(!MakeFileName(filename, SoundsDir, sndname, NULL, NULL, FILENAME_LEN)) {
				ShowErrorMessage(BADFILENAME,filename);
				goto AMSexit;
			}

			if(ReadSound(filename, snode.snd_length)) goto AMSexit;

			if(WriteTempSoundFile(snode.snd_name, snode.snd_length, MODE_NEWFILE)) goto AMSexit;

			snode.snd_offset = 		0;
			snode.snd_flength = 	snode.snd_length + sizeof(struct FSound);
			snode.snd_location = 	1;

		} else {
			goto AMSexit;
		}
	} else {

		snode.snd_offset = 		0;
		snode.snd_flength = 	sizeof(struct FSound);
		snode.snd_location = 	1;

	}

	//*** Aggiunge entry nella lista

	GT_SetGadgetAttrs(SndListWinGadgets[SNDLISTWINGAD_LIST],
						SndListWin,NULL,
						GTLV_Labels, NULL,
						TAG_DONE, NULL);

	if(sound==NULL) {
		if(!(nsnode = (struct SoundNode *)AllocMem(sizeof(struct SoundNode),MEMF_CLEAR))) {
			error=NO_MEMORY;
			goto AMSexit;
		}
		*nsnode = snode;

		nsnode->snd_node.ln_Type=0;
		nsnode->snd_node.ln_Pri	=0;
		nsnode->snd_node.ln_Name=nsnode->snd_name;
		AddTail(&SoundsList,&(nsnode->snd_node));

	} else {
		nsnode = sound;
		savenode = sound->snd_node;
		*nsnode = snode;
		nsnode->snd_node = savenode;
	}

	GT_SetGadgetAttrs(SndListWinGadgets[SNDLISTWINGAD_LIST],
						SndListWin,NULL,
						GTLV_Labels, &SoundsList,
						TAG_DONE, NULL);

	ModifiedSoundList_fl=TRUE;


AMSexit:;

}



//*** In base al valore di type, setta
//*** i gadget della finestra SoundWin

void ProcessSoundType(UBYTE type) {

	register long	i;
	char			*str;

	switch(type) {
		case SOUNDTYPE_MOD:
			GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_LENGTH],SoundsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
			for(i=SOUNDWINGAD_PERIOD; i<=SOUNDWINGAD_CODE; i++)
				GT_SetGadgetAttrs(SoundsWinGadgets[i],SoundsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
			for(i=SOUNDWINGAD_CHANNEL1; i<=SOUNDWINGAD_ALONE; i++)
				GT_SetGadgetAttrs(SoundsWinGadgets[i],SoundsWin, NULL, GTCB_Checked,FALSE, GA_DISABLED,FALSE, TAG_DONE,0);
			for(i=SOUNDWINGAD_SAMPLE; i<=SOUNDWINGAD_SOUND3; i++)
				GT_SetGadgetAttrs(SoundsWinGadgets[i],SoundsWin, NULL, GTST_String,(long)"", GA_DISABLED,TRUE, TAG_DONE,0);
			break;
		case SOUNDTYPE_GLOBAL:
		case SOUNDTYPE_OBJECT:
			for(i=SOUNDWINGAD_LENGTH; i<=SOUNDWINGAD_SAMPLE; i++)
				GT_SetGadgetAttrs(SoundsWinGadgets[i],SoundsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
			for(i=SOUNDWINGAD_SOUND1; i<=SOUNDWINGAD_SOUND3; i++)
				GT_SetGadgetAttrs(SoundsWinGadgets[i],SoundsWin, NULL, GTST_String,(long)"", GA_DISABLED,TRUE, TAG_DONE,0);
			break;
		case SOUNDTYPE_RND:
			for(i=SOUNDWINGAD_LENGTH; i<=SOUNDWINGAD_CODE; i++)
				GT_SetGadgetAttrs(SoundsWinGadgets[i],SoundsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
			for(i=SOUNDWINGAD_CHANNEL1; i<=SOUNDWINGAD_CHANNEL4; i++)
				GT_SetGadgetAttrs(SoundsWinGadgets[i],SoundsWin, NULL, GTCB_Checked,FALSE, GA_DISABLED,FALSE, TAG_DONE,0);

			GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_ALONE],SoundsWin, NULL, GTCB_Checked,FALSE, GA_DISABLED,TRUE, TAG_DONE,0);

			GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SAMPLE],SoundsWin, NULL, GTST_String,(long)"", GA_DISABLED,TRUE, TAG_DONE,0);

			GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND1],SoundsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);

			GT_GetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND1], SoundsWin,NULL, GTST_String,&str, TAG_DONE,0);
			if(strisempty(str))	{
				GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND2],SoundsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
				GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND3],SoundsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			} else {
				GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND2],SoundsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
			}

			GT_GetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND2], SoundsWin,NULL, GTST_String,&str, TAG_DONE,0);
			if(strisempty(str))	{
				GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND3],SoundsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			} else {
				GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND3],SoundsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
			}

			break;
	}
}


//*** Apre finestra Sounds
//*** Se sound==NULL : inserimento nuovo suono
//*** Se sound!=NULL : modifica del suono puntato da sound

void OpenSoundsWindow(struct SoundNode *sound) {

	register long		i;
	int					cont;
	long				l1;
	ULONG				signals;
	ULONG				imsgClass;
	UWORD				imsgCode;
	char				str[31], *sss;
	struct Gadget		*gad;
	struct SoundNode	sndnode;


	if(sound==NULL) {
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_NAME],SoundsWin, NULL, GTST_String,"", GA_DISABLED,FALSE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_DESCR],SoundsWin, NULL, GTST_String,"", GA_DISABLED,FALSE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_TYPE],SoundsWin, NULL, GTCY_Active,SOUNDTYPE_MOD, GA_DISABLED,FALSE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_LENGTH],SoundsWin, NULL, GTIN_Number,0, GA_DISABLED,FALSE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_PERIOD],SoundsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_VOLUME],SoundsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_LOOP],SoundsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_PRIORITY],SoundsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_CODE],SoundsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_CHANNEL1],SoundsWin, NULL, GTCB_Checked,FALSE, GA_DISABLED,FALSE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_CHANNEL2],SoundsWin, NULL, GTCB_Checked,FALSE, GA_DISABLED,FALSE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_CHANNEL3],SoundsWin, NULL, GTCB_Checked,FALSE, GA_DISABLED,FALSE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_CHANNEL4],SoundsWin, NULL, GTCB_Checked,FALSE, GA_DISABLED,FALSE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_ALONE],SoundsWin, NULL, GTCB_Checked,FALSE, GA_DISABLED,TRUE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SAMPLE],SoundsWin, NULL, GTST_String,"", GA_DISABLED,FALSE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND1],SoundsWin, NULL, GTST_String,"", GA_DISABLED,TRUE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND2],SoundsWin, NULL, GTST_String,"", GA_DISABLED,TRUE, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND3],SoundsWin, NULL, GTST_String,"", GA_DISABLED,TRUE, TAG_DONE,0);
	} else {
		strncpy(str,sound->snd_name,4);
		str[4]='\0';
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_NAME],SoundsWin, NULL, GTST_String,str, TAG_DONE,0);
		strncpy(str,&(sound->snd_name[9]),30);
		str[30]='\0';
		strrtrim(str);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_DESCR],SoundsWin, NULL, GTST_String,str, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_TYPE],SoundsWin, NULL, GTCY_Active,(long)sound->snd_type, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_LENGTH],SoundsWin, NULL, GTIN_Number,(long)sound->snd_length, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_PERIOD],SoundsWin, NULL, GTIN_Number,(long)sound->snd_period, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_VOLUME],SoundsWin, NULL, GTIN_Number,(long)sound->snd_volume, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_LOOP],SoundsWin, NULL, GTIN_Number,(long)sound->snd_loop, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_PRIORITY],SoundsWin, NULL, GTIN_Number,(long)sound->snd_priority, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_CODE],SoundsWin, NULL, GTIN_Number,(long)sound->snd_code, TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_CHANNEL1],SoundsWin, NULL, GTCB_Checked,((sound->snd_mask & 1) ? 1 : 0), TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_CHANNEL2],SoundsWin, NULL, GTCB_Checked,((sound->snd_mask & 2) ? 1 : 0), TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_CHANNEL3],SoundsWin, NULL, GTCB_Checked,((sound->snd_mask & 4) ? 1 : 0), TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_CHANNEL4],SoundsWin, NULL, GTCB_Checked,((sound->snd_mask & 8) ? 1 : 0), TAG_DONE,0);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_ALONE],SoundsWin, NULL, GTCB_Checked,((sound->snd_alone & 0x80) ? 1 : 0), TAG_DONE,0);
		strncpy(str,sound->snd_sample,4);
		str[4]='\0';
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SAMPLE],SoundsWin, NULL, GTST_String,str, TAG_DONE,0);
		strncpy(str,sound->snd_sound1,4);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND1],SoundsWin, NULL, GTST_String,str, TAG_DONE,0);
		strncpy(str,sound->snd_sound2,4);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND2],SoundsWin, NULL, GTST_String,str, TAG_DONE,0);
		strncpy(str,sound->snd_sound3,4);
		GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND3],SoundsWin, NULL, GTST_String,str, TAG_DONE,0);
		ProcessSoundType(sound->snd_type);
	}

	SoundsWin = OpenWindowTags(NULL,
						WA_Left,	77,
						WA_Top,		44,
						WA_Width,	486,
						WA_Height,	148,
						WA_Flags,	WFLG_DRAGBAR|WFLG_DEPTHGADGET|
									WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|
									WFLG_ACTIVATE|WFLG_NEWLOOKMENUS,
						WA_IDCMP,	IDCMP_CLOSEWINDOW|
									IDCMP_GADGETUP|IDCMP_INTUITICKS,
						WA_Title,	"Sound",
						WA_Gadgets,	SoundsWinGadList,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

	if(!SoundsWin) {
		ShowMessage("Problems opening Sounds window !",0);
		error=GENERIC_ERROR;
		return;
	}

//	DrawBevelBox(ObjectsWin->RPort,8,58,508,85, GT_VisualInfo,VInfo, TAG_DONE,0);

	GT_RefreshWindow(SoundsWin,NULL);

	SoundsWinSigBit = 1 << SoundsWin->UserPort->mp_SigBit;
	OpenedWindow |= SoundsWinSigBit;

	TurnOffIDCMP(0xffffffff ^ SoundsWinSigBit);

	cont=TRUE;

	while(cont && !error) {
		if(signals = Wait(SoundsWinSigBit)) {
			while(!error && (imsg = GT_GetIMsg(SoundsWin->UserPort))) {
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

							case SOUNDWINGAD_TYPE:
								GT_GetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_TYPE],SoundsWin, NULL, GTCY_Active,&l1, TAG_DONE,0);
								ProcessSoundType((UBYTE)l1);
								break;

							case SOUNDWINGAD_OK:
								AddModifySound(sound);
								cont=FALSE;
								break;

							case SOUNDWINGAD_CANCEL:
								cont=FALSE;
								break;
						}
						break;
				}

				GT_GetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND1], SoundsWin,NULL, GTST_String,&sss, TAG_DONE,0);
				if(strisempty(sss))	{
					GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND2],SoundsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
					GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND3],SoundsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
				} else {
					GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND2],SoundsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
				}

				GT_GetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND2], SoundsWin,NULL, GTST_String,&sss, TAG_DONE,0);
				if(strisempty(sss))	{
					GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND3],SoundsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
				} else {
					GT_SetGadgetAttrs(SoundsWinGadgets[SOUNDWINGAD_SOUND3],SoundsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
				}
			}
		}
	}

	CloseSoundsWindow();

	TurnOnIDCMP(0xffffffff);
}



//*****************************************************************************


//*** Processa l'input sulla listview dei suoni
//*** Se è stata effettuata una selezione di un suono, restituisce TRUE

int ProcessSndList(UWORD imsgCode, ULONG seconds, ULONG micros) {

	static ULONG		startsecs=0, startmicros=0, oldsel=0xffff;
	char				*str;
	int					ret;
	struct SoundNode	*nnode;

	ret=FALSE;

	SelectedSound = (struct SoundNode *)FindNode(&SoundsList,imsgCode);

	if((oldsel == imsgCode) && DoubleClick(startsecs, startmicros, seconds, micros)) {
		if(SoundSelect) {
			if((SoundSelectWin==ObjectsWin) && (OpenedWindow & ObjectsWinSigBit)) {
				switch(SoundSelect) {
					case OBJWINGAD_SOUND1:	str=n_ObjSound1;	break;
					case OBJWINGAD_SOUND2:	str=n_ObjSound2;	break;
					case OBJWINGAD_SOUND3:	str=n_ObjSound3;	break;
					default:				str=n_ObjSound1;	break;
				}
				strncpy(str,SelectedSound->snd_name,4);
				SoundSelect=FALSE;
			}
			else if((SoundSelectWin==LevelWin) && (OpenedWindow & LevelWinSigBit)) {
				strncpy(n_LevelMod,SelectedSound->snd_name,4);
				if(SoundSelect) TurnOnIDCMP(0xffffffff ^ SndListWinSigBit);
				CloseSndListWindow();
				SoundSelect=FALSE;
				ModifiedMap_fl=TRUE;
			}
			ret=TRUE;
		} else {
			if(SelectedSound->snd_type!=SOUNDTYPE_EMPTY)
				OpenSoundsWindow(SelectedSound);
		}
		oldsel=0xffff;
	} else {
		oldsel=imsgCode;
	}
	startsecs=seconds;
	startmicros=micros;

	return(ret);
}



//*** Gestisce l'input della SndList window nel caso in cui
//*** si debba selezionare un suono per un'altra finestra

void ProcessSndListWindow() {

	ULONG				signals;
	ULONG				imsgClass;
	UWORD				imsgCode;
	ULONG				seconds,micros;
	int					cont;
	struct Gadget		*gad;

	cont=TRUE;

	while(cont && !error) {
		if(signals = Wait(SndListWinSigBit)) {
			while(!error && cont && (imsg = GT_GetIMsg(SndListWin->UserPort))) {
				imsgClass = imsg->Class;
				imsgCode = imsg->Code;
				seconds = imsg->Seconds;
				micros = imsg->Micros;

				gad = (struct Gadget *)imsg->IAddress;

				GT_ReplyIMsg(imsg);

				switch(imsgClass) {
					case IDCMP_CLOSEWINDOW:
						cont=FALSE;
						break;

					case IDCMP_GADGETUP:
						switch(gad->GadgetID) {
							case SNDLISTWINGAD_LIST:
								if(ProcessSndList(imsgCode, seconds, micros))	cont=FALSE;
								break;
							case SNDLISTWINGAD_ADD:		break;
							case SNDLISTWINGAD_MODIFY:	break;
							case SNDLISTWINGAD_REMOVE:	break;
						}
						break;
				}
			}
		}
	}

	CloseSndListWindow();
}

//*****************************************************************************
//***
//***		Effects.c
//***
//***	Gestione effetti
//***
//***
//***
//*****************************************************************************

#include	"MapEditor3d.h"
#include	"Definitions.h"

//*****************************************************************************

//*** Controlla gli effetti definiti per verificare se sono utilizzati.
//*** Quelli non utilizzati vengono segnalati.

void CheckEffectsList() {

	register int			found;
	struct Block			*bpun;
	struct MapObject		*mapobj;
	struct EffectDirNode	*effnode;
	struct Node				*node;

	for(node=EffectsList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
		effnode=(struct EffectDirNode *)node;
		found=FALSE;

		if(effnode->eff_trigger) {				// E' un effetto

			//*** Controlla se l'effetto è usato nella mappa

			for(bpun=BlockList; (bpun!=NULL) && !found; bpun = bpun->Next) {
				if(bpun->Trigger==effnode)	found=TRUE;
				if(bpun->Trigger2==effnode)	found=TRUE;
			}

			//*** Controlla se l'effetto è usato da un oggetto

			for(mapobj=MapObjectList; mapobj && !found; mapobj=mapobj->Next) {
				if(mapobj->Effect==effnode)	found=TRUE;
			}

			if(!found)	ShowMessage2("Effect trigger %ld not used !",0,effnode->eff_trigger);

		} else {								// E' un separatore di lista

			if(effnode->eff_listnum) {
				//*** Controlla se la effect list e' usata nella mappa

				for(bpun=BlockList; (bpun!=NULL) && !found; bpun = bpun->Next) {
					if(bpun->Effect==effnode)	found=TRUE;
				}

				if(!found)	ShowMessage2("Effect list %ld not used !",0,effnode->eff_listnum);
			}
		}
	}
}

//*****************************************************************************

//*** Apre finestra Fx

void OpenFxWindow() {

	register long	i;
	int				cont;
	ULONG			signals;
	ULONG			imsgClass;
	UWORD			imsgCode;
	ULONG			seconds, micros;
	static ULONG	startsecs=0, startmicros=0, oldsel=0xffff;
	struct Gadget	*gad;
	struct FxNode	*fxnode;

	if(FxWin) return;		// Se già aperta, ritorna subito

	TurnOffMenu();

	FxWin = OpenWindowTags(NULL,
						WA_Left,	222,
						WA_Top,		25,
						WA_Width,	196,
						WA_Height,	150,
						WA_Flags,	WFLG_DRAGBAR|WFLG_DEPTHGADGET|WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|WFLG_ACTIVATE,
						WA_IDCMP,	IDCMP_CLOSEWINDOW|IDCMP_GADGETUP|LISTVIEWIDCMP,
						WA_Title,	"Fx window",
						WA_Gadgets,	FxWinGadList,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

	if(!FxWin) {
		ShowMessage("Problems opening Fx window !",0);
		error=1;
		return;
	}

	GT_RefreshWindow(FxWin,NULL);

	FxWinSigBit = 1 << FxWin->UserPort->mp_SigBit;
	OpenedWindow |= FxWinSigBit;


	cont=TRUE;

	while(cont && !error) {
		if(signals = Wait(FxWinSigBit)) {
			while(!error && (imsg = GT_GetIMsg(FxWin->UserPort))) {
				imsgClass = imsg->Class;
				imsgCode = imsg->Code;
				seconds = imsg->Seconds;
				micros = imsg->Micros;

				gad = (struct Gadget *)imsg->IAddress;

				GT_ReplyIMsg(imsg);

				switch(imsgClass) {
					case IDCMP_CLOSEWINDOW:
						SelectedFx=NULL;
						cont=FALSE;
						break;
					case IDCMP_GADGETUP:
						switch(gad->GadgetID) {
							case FXWINGAD_LIST:
								if(oldsel == imsgCode) {
									if(DoubleClick(startsecs, startmicros, seconds, micros)) {
										fxnode=(struct FxNode *)FindNode(&FxList,imsgCode);
										strncpy(n_Effect,&(fxnode->fx_name[6]),20);
										strcpy(n_EffParam1,fxnode->fx_param1);
										strcpy(n_EffParam2,fxnode->fx_param2);
										GT_RefreshWindow(EffectsWin,NULL);
										GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_EFFECT],EffectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
										GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_EFFECT],EffectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
										GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_PARAM1],EffectsWin, NULL, GTIN_Number,0, GA_DISABLED,strisempty(fxnode->fx_param1), TAG_DONE,0);
										GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_PARAM2],EffectsWin, NULL, GTIN_Number,0, GA_DISABLED,strisempty(fxnode->fx_param2), TAG_DONE,0);
										SelectedFx=fxnode;
										oldsel=0xffff;
										cont=FALSE;
									}
								} else {
								}
								startsecs=seconds;
								startmicros=micros;
								oldsel=imsgCode;
								break;
						}
						break;
				}
			}
		}
	}

	CloseFxWindow();

	TurnOnMenu();
}



//*** Aggiunge una nuova lista di effetti
//*** Ritorna FALSE se tutto ok

int AddEffectList() {

	long					pos1, posnn;
	struct EffectDirNode	*enode;

	if(LastEffectList==255) {
		ShowMessage("Too many effect lists !",0);
		return(TRUE);
	}

	if(!(enode = (struct EffectDirNode *)AllocMem(sizeof(struct EffectDirNode),MEMF_CLEAR))) {
		error=NO_MEMORY;
		return(TRUE);
	}

	LastEffectList++;

	sprintf(enode->eff_name,"%3ld",LastEffectList);
	strcat(enode->eff_name, " ------------------------------------");

	enode->eff_listnum = LastEffectList;
	enode->eff_trigger = 0;
	enode->eff_fx = (struct FxNode *)NULL;
	enode->eff_effect = 0;
	enode->eff_param1 = 0;
	enode->eff_param2 = 0;
	enode->eff_key = 0;
	enode->eff_noused = 0;


	GT_GetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Top,&pos1, TAG_DONE,NULL);
	GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Labels,NULL, TAG_DONE,NULL);

	enode->eff_node.ln_Type	=0;
	enode->eff_node.ln_Pri	=0;
	enode->eff_node.ln_Name	=enode->eff_name;
	AddTail(&EffectsList,&(enode->eff_node));

	posnn=FindPosNum(&EffectsList,(struct Node *)enode);
	GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Labels,&EffectsList, GTLV_Selected,posnn, GTLV_Top,pos1, TAG_DONE,NULL);

	SelectedEffectList=enode;
	SelectedEffectNode=enode;

	ModifiedMap_fl=TRUE;

	return(FALSE);
}



//*** Aggiunge un effetto ad una lista di effetti
//*** Ritorna FALSE se tutto ok

int AddFx() {

	struct EffectDirNode	*enode, *senode, *lenode;
	long					pos1, posnn;

	if(LastTrigger==255) {
		ShowMessage("Too many effects !",0);
		return(TRUE);
	}

	if(!(enode = (struct EffectDirNode *)AllocMem(sizeof(struct EffectDirNode),MEMF_CLEAR))) {
		error=NO_MEMORY;
		return(TRUE);
	}

	LastTrigger++;

	sprintf(enode->eff_name,"    %3ld %20s        ",LastTrigger,n_Effect);

	enode->eff_listnum = SelectedEffectNode->eff_listnum;
	enode->eff_trigger = LastTrigger;
	enode->eff_fx = SelectedFx;
	enode->eff_effect = SelectedFx->fx_code;
	enode->eff_param1 = 0;
	enode->eff_param2 = 0;
	enode->eff_key = 0;
	enode->eff_noused = 0;

	GT_GetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Top,&pos1, TAG_DONE,NULL);
	GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Labels,NULL, TAG_DONE,NULL);

	enode->eff_node.ln_Type	=0;
	enode->eff_node.ln_Pri	=0;
	enode->eff_node.ln_Name	=enode->eff_name;

	//*** Cerca l'ultimo effetto della lista di effetti a cui appartiene il nodo SelectedEffectNode
	for(senode=SelectedEffectNode; (senode->eff_listnum)==(SelectedEffectNode->eff_listnum); senode=(struct EffectDirNode *)((senode->eff_node).ln_Succ))
		lenode=senode;

	Insert(&EffectsList,&(enode->eff_node),(struct Node *)lenode);

	posnn=FindPosNum(&EffectsList,(struct Node *)enode);
	GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Labels,&EffectsList, GTLV_Selected,posnn, GTLV_Top,pos1, TAG_DONE,NULL);

	SelectedEffect=enode;
	SelectedEffectNode=enode;

	ModifiedMap_fl=TRUE;

	return(FALSE);
}



//*** Cancella un effetto da una lista
//*** Ritorna FALSE se non e' possibile cancellare.

int DeleteFX(struct EffectDirNode *delenode) {

	long				pos1, posnn;
	struct Block		*bpun;
	struct MapObject	*mapobj;

	//*** Controlla se l'effetto è usato nella mappa

	for(bpun=BlockList; bpun!=NULL; bpun = bpun->Next) {
		if(bpun->Trigger==delenode)	return(FALSE);
		if(bpun->Trigger2==delenode)	return(FALSE);
	}

	//*** Controlla se l'effetto è usato da un oggetto

	for(mapobj=MapObjectList; mapobj; mapobj=mapobj->Next) {
		if(mapobj->Effect==delenode)	return(FALSE);
	}

	GT_GetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Top,&pos1, TAG_DONE,NULL);
	GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Labels,NULL, TAG_DONE,NULL);

	Remove((struct Node *)delenode);

	posnn=FindPosNum(&EffectsList,(struct Node *)SelectedEffect);
	GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Labels,&EffectsList, GTLV_Selected,posnn, GTLV_Top,pos1, TAG_DONE,NULL);

	FreeMem(delenode,sizeof(struct EffectDirNode));

	ModifiedMap_fl=TRUE;

	return(TRUE);
}



//*** Cancella una lista con tutti i suoi effetti
//*** Ritorna FALSE se non e' possibile cancellare.

int DeleteEffectList(struct EffectDirNode *delenode) {

	long					pos1, posnn;
	struct Block			*bpun;
	struct EffectDirNode	*enode, *nnode;
	struct MapObject		*mapobj;

	//*** Controlla se la effect list e' usata nella mappa

	for(bpun=BlockList; bpun!=NULL; bpun = bpun->Next) {
		if(bpun->Effect==delenode)	return(FALSE);
	}

	//*** Controlla se qualche effetto della lista e' usato nella mappa
	//*** o in qualche oggetto in mappa

	enode = (struct EffectDirNode *)delenode->eff_node.ln_Succ;
	while(enode->eff_node.ln_Succ && (enode->eff_listnum==delenode->eff_listnum)) {
		nnode=(struct EffectDirNode *)enode->eff_node.ln_Succ;
		for(bpun=BlockList; bpun!=NULL; bpun = bpun->Next) {
			if(bpun->Trigger==enode)	return(FALSE);
			if(bpun->Trigger2==enode)	return(FALSE);
		}
		for(mapobj=MapObjectList; mapobj; mapobj=mapobj->Next) {
			if(mapobj->Effect==enode)	return(FALSE);
		}
		enode=nnode;
	}

	GT_GetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Top,&pos1, TAG_DONE,NULL);
	GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Labels,NULL, TAG_DONE,NULL);

	//*** Cancella gli effetti della lista

	enode = (struct EffectDirNode *)delenode->eff_node.ln_Succ;
	while(enode->eff_node.ln_Succ && (enode->eff_listnum==delenode->eff_listnum)) {
		nnode=(struct EffectDirNode *)enode->eff_node.ln_Succ;
		Remove((struct Node *)enode);
		FreeMem(enode,sizeof(struct EffectDirNode));
		enode=nnode;
	}

	//*** Rinumera le liste successive

	while(enode->eff_node.ln_Succ) {
		enode->eff_listnum -= 1;
		if(!enode->eff_trigger) {
			sprintf(enode->eff_name,"%3ld",enode->eff_listnum);
			enode->eff_name[3]=' ';
		}
		enode=(struct EffectDirNode *)enode->eff_node.ln_Succ;
	}

	Remove((struct Node *)delenode);

	posnn=FindPosNum(&EffectsList,(struct Node *)SelectedEffect);
	GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Labels,&EffectsList, GTLV_Selected,posnn, GTLV_Top,pos1, TAG_DONE,NULL);

	FreeMem(delenode,sizeof(struct EffectDirNode));

	ModifiedMap_fl=TRUE;

	return(TRUE);
}



//*** Azzera e disabilita alcuni gadget della finestra Effects

void ResetEffectGadgets() {

	register long			i;

	memset(n_Effect,' ',20);
	memset(n_EffParam1,' ',20);
	memset(n_EffParam2,' ',20);
	GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_NAMEPARAM1],EffectsWin, NULL, GTTX_Text,n_EffParam1, TAG_DONE,0);
	GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_NAMEPARAM2],EffectsWin, NULL, GTTX_Text,n_EffParam2, TAG_DONE,0);
	GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_PARAM1],EffectsWin, NULL, GTIN_Number,0, TAG_DONE,0);
	GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_PARAM2],EffectsWin, NULL, GTIN_Number,0, TAG_DONE,0);
	for(i=EFFWINGAD_ADDFX; i<=EFFWINGAD_KEY; i++)
		GT_SetGadgetAttrs(EffectsWinGadgets[i],EffectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
}


//*** Controlla se il codice effetto contenuto in *enode
//*** è tra quelli accettabili per il trigger2 del blocco,
//*** nel qual caso restituisce TRUE.

short CheckTrigger2FX(struct EffectDirNode *enode) {

	register long	i;

	if(enode->eff_trigger==0 && enode->eff_listnum==0) return(TRUE);

	for(i=0; Trigger2FX[i]; i++)
		if(enode->eff_effect==Trigger2FX[i]) return(TRUE);

	return(FALSE);
}



//*** Processa i gadget della finestra Effects

void ProcessEffectsWinGad(struct Gadget *gad, UWORD imsgCode, ULONG seconds, ULONG micros) {

	register long			i;
	long					pos1, posnn, nosel, l1;
	static ULONG			startsecs=0, startmicros=0, oldsel=0xffff;
	struct EffectDirNode	*enode;
	char					*str;

	switch(gad->GadgetID) {
		case EFFWINGAD_LIST:
			enode=(struct EffectDirNode *)FindNode(&EffectsList,imsgCode);
			nosel=TRUE;
			if(EffectSelect==1) {
				if(oldsel == imsgCode) {
					if(DoubleClick(startsecs, startmicros, seconds, micros)) {
						BlockEffect=enode;
						if(BlockEffect->eff_listnum>0)
							sprintf(n_EffectNum,"%3ld",BlockEffect->eff_listnum);
						else
							strcpy(n_EffectNum,"---");
						EffectSelect=FALSE;
						TurnOnIDCMP(0xffffffff ^ EffectsWinSigBit);
						imsgCode=0xffff;
						nosel=FALSE;
						CloseEffectsWindow();
					}
				}
			} else if(TriggerSelect==1) {
				if(oldsel == imsgCode) {
					if(DoubleClick(startsecs, startmicros, seconds, micros)) {
						if(enode->eff_trigger || (enode->eff_trigger==0 && enode->eff_listnum==0)) {
							BlockTrigger=enode;
							if(BlockTrigger->eff_trigger>0)
								sprintf(n_TriggerNum,"%3ld",BlockTrigger->eff_trigger);
							else
								strcpy(n_TriggerNum,"---");
						}
						TriggerSelect=FALSE;
						TurnOnIDCMP(0xffffffff ^ EffectsWinSigBit);
						imsgCode=0xffff;
						nosel=FALSE;
						CloseEffectsWindow();
					}
				}
			} else if(TriggerSelect==2) {
				if(oldsel == imsgCode) {
					if(DoubleClick(startsecs, startmicros, seconds, micros)) {
						if(enode->eff_trigger || (enode->eff_trigger==0 && enode->eff_listnum==0)) {
							if(CheckTrigger2FX(enode)) {
								BlockTrigger2=enode;
								if(BlockTrigger2->eff_trigger>0)
									sprintf(n_TriggerNum2,"%3ld",BlockTrigger2->eff_trigger);
								else
									strcpy(n_TriggerNum2,"---");
							} else {
								str=&(EngineFx[enode->eff_effect-1].fx_name[6]);
					 			ShowMessage2("You can't use FX %s\n        for Trigger2 !",0,str);
							}
						}
						TriggerSelect=FALSE;
						TurnOnIDCMP(0xffffffff ^ EffectsWinSigBit);
						imsgCode=0xffff;
						nosel=FALSE;
						CloseEffectsWindow();
					}
				}
			} else if(TriggerSelect==3) {
				if(oldsel == imsgCode) {
					if(DoubleClick(startsecs, startmicros, seconds, micros)) {
						if(enode->eff_trigger || (enode->eff_trigger==0 && enode->eff_listnum==0)) {
							MapObjEffect=enode;
							if(MapObjEffect->eff_trigger>0)
								sprintf(n_MapObjTriggerNum,"%3ld",MapObjEffect->eff_trigger);
							else
								strcpy(n_MapObjTriggerNum,"---");
						}
						TriggerSelect=FALSE;
						TurnOnIDCMP(0xffffffff ^ EffectsWinSigBit);
						imsgCode=0xffff;
						nosel=FALSE;
						CloseEffectsWindow();
					}
				}
			}
			if(nosel) {
				if(enode->eff_listnum>0) {
					if(enode->eff_trigger) {	// Fx selected
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_ADDFX],EffectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_DELLIST],EffectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_DELFX],EffectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
						strncpy(n_Effect,&(enode->eff_fx->fx_name[6]),20);
						strcpy(n_EffParam1,enode->eff_fx->fx_param1);
						strcpy(n_EffParam2,enode->eff_fx->fx_param2);
						GT_RefreshWindow(EffectsWin,NULL);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_EFFECT],EffectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_EFFECT],EffectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_NAMEPARAM1],EffectsWin, NULL, GTTX_Text,n_EffParam1, GA_DISABLED,FALSE, TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_NAMEPARAM2],EffectsWin, NULL, GTTX_Text,n_EffParam2, GA_DISABLED,FALSE, TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_PARAM1],EffectsWin, NULL, GTIN_Number,enode->eff_param1, GA_DISABLED,strisempty(enode->eff_fx->fx_param1), TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_PARAM2],EffectsWin, NULL, GTIN_Number,enode->eff_param2, GA_DISABLED,strisempty(enode->eff_fx->fx_param2), TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_KEY],EffectsWin, NULL, GTCY_Active,(long)enode->eff_key, GA_DISABLED,FALSE, TAG_DONE,0);
						SelectedEffect=enode;
						SelectedEffectNode=enode;
					} else {					// List selected
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_ADDFX],EffectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_DELLIST],EffectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_DELFX],EffectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
						memset(n_Effect,' ',20);
						memset(n_EffParam1,' ',20);
						memset(n_EffParam2,' ',20);
						GT_RefreshWindow(EffectsWin,NULL);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_EFFECT],EffectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_EFFECT],EffectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_NAMEPARAM1],EffectsWin, NULL, GTTX_Text,n_EffParam1, GA_DISABLED,FALSE, TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_NAMEPARAM2],EffectsWin, NULL, GTTX_Text,n_EffParam2, GA_DISABLED,FALSE, TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_PARAM1],EffectsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_PARAM2],EffectsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
						GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_KEY],EffectsWin, NULL, GTCY_Active,0, GA_DISABLED,TRUE, TAG_DONE,0);
						SelectedEffectList=enode;
						SelectedEffectNode=enode;
					}
				} else {
					ResetEffectGadgets();
				}
			}
			startsecs=seconds;
			startmicros=micros;
			oldsel=imsgCode;
			break;

		case EFFWINGAD_ADDLIST:
			if(!AddEffectList()) {
				GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_ADDFX],EffectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
				GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_DELLIST],EffectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
				for(i=EFFWINGAD_DELFX; i<=EFFWINGAD_KEY; i++)
					GT_SetGadgetAttrs(EffectsWinGadgets[i],EffectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			}
			break;

		case EFFWINGAD_ADDFX:
			GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_DELLIST],EffectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_DELFX],EffectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
			memset(n_Effect,' ',20);
			memset(n_EffParam1,' ',20);
			memset(n_EffParam2,' ',20);
			GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_EFFECT],EffectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_NAMEPARAM1],EffectsWin, NULL, GTTX_Text,n_EffParam1, GA_DISABLED,FALSE, TAG_DONE,0);
			GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_NAMEPARAM2],EffectsWin, NULL, GTTX_Text,n_EffParam2, GA_DISABLED,FALSE, TAG_DONE,0);
			GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_PARAM1],EffectsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_PARAM2],EffectsWin, NULL, GTIN_Number,0, GA_DISABLED,TRUE, TAG_DONE,0);
			GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_KEY],EffectsWin, NULL, GTCY_Active,0, GA_DISABLED,TRUE, TAG_DONE,0);
			OpenFxWindow();
			if(SelectedFx)	AddFx();
			break;

		case EFFWINGAD_DELLIST:
			if(DeleteEffectList(SelectedEffectList)) {
				ResetEffectGadgets();
				SelectedEffectList=NULL;
				SelectedEffect=NULL;
				SelectedEffectNode=NULL;
			} else {
	 			ShowMessage("Cannot delete !\nList and/or FX in use.",0);
			}
			break;

		case EFFWINGAD_DELFX:
			if(DeleteFX(SelectedEffect)) {
				ResetEffectGadgets();
				SelectedEffectList=NULL;
				SelectedEffect=NULL;
				SelectedEffectNode=NULL;
			} else {
	 			ShowMessage("Cannot delete !\nFX in use.",0);
			}
			break;

		case EFFWINGAD_EFFECT:
			OpenFxWindow();
			if(SelectedFx) {
				strncpy(&(SelectedEffect->eff_name[8]),&(SelectedFx->fx_name[6]),20);
				SelectedEffect->eff_effect = SelectedFx->fx_code;
				ModifiedMap_fl=TRUE;
			}
			break;

		case EFFWINGAD_PARAM1:
			SelectedEffect->eff_param1 = (((struct StringInfo *)EffectsWinGadgets[EFFWINGAD_PARAM1]->SpecialInfo)->LongInt);
			GT_GetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Top,&pos1, TAG_DONE,NULL);
			GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Labels,NULL, TAG_DONE,NULL);
			sprintf(&(SelectedEffect->eff_name[29]),"%5ld %5ld",SelectedEffect->eff_param1,SelectedEffect->eff_param2);
			posnn=FindPosNum(&EffectsList,(struct Node *)SelectedEffect);
			GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Labels,&EffectsList, GTLV_Selected,posnn, GTLV_Top,pos1, TAG_DONE,NULL);
			ModifiedMap_fl=TRUE;
			break;

		case EFFWINGAD_PARAM2:
			SelectedEffect->eff_param2 = (((struct StringInfo *)EffectsWinGadgets[EFFWINGAD_PARAM2]->SpecialInfo)->LongInt);
			GT_GetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Top,&pos1, TAG_DONE,NULL);
			GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Labels,NULL, TAG_DONE,NULL);
			sprintf(&(SelectedEffect->eff_name[29]),"%5ld %5ld",SelectedEffect->eff_param1,SelectedEffect->eff_param2);
			posnn=FindPosNum(&EffectsList,(struct Node *)SelectedEffect);
			GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Labels,&EffectsList, GTLV_Selected,posnn, GTLV_Top,pos1, TAG_DONE,NULL);
			ModifiedMap_fl=TRUE;
			break;

		case EFFWINGAD_KEY:
			GT_GetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_KEY],EffectsWin, NULL, GTCY_Active,&l1, TAG_DONE,0);
			SelectedEffect->eff_key = (char)l1;
			ModifiedMap_fl=TRUE;
			break;
	}

}


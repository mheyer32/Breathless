//*****************************************************************************
//***
//***		MapEditor3d.c
//***
//***
//***
//***
//***
//*****************************************************************************

#include	"MapEditor3d.h"

#include	"FxList.h"

#include	"Images.h"

//*****************************************************************************
//***	Definizioni di variabili globali
//*****************************************************************************



//*** Puntatori alle librerie usate

struct IntuitionBase	*IntuitionBase=NULL;
struct GfxBase			*GfxBase=NULL;
struct Library			*GadToolsBase=NULL;
struct Library			*AslBase=NULL;
struct ReqToolsBase		*ReqToolsBase=NULL;



//*** Definizione di dati e strutture usate dal programma

 //*** Variabili varie

int			error = 0;				// Codice di errore. Se=0, nessun errore.
long		ScrWidth = 640;
long		ScrHeight = 256;

long		NumGame=0;				// Numero game definiti nel project corrente

long		MapWinX1=4,MapWinY1=11; // Posizione in alto a sinistra dell'area utile nella finestra Map
long		MapWinWidth,MapWinHeight;// Dimensioni spazio utile nella finestra Map
long		MapWinWidthR,MapWinHeightR;// Dimensioni arrotondate spazio utile nella finestra Map.
long		MapZoom=10;				// Zoom sulla mappa. Valori da 1 a 10. Corrisponde alle dimensioni dei blocchi a video.
short		MouseX,MouseY;			// Coordinate mouse nella finestra Map
short		MapX1Pos=0,MapY1Pos=0;	// Posizione nella mappa del primo blocco visualizzato in alto a sinistra nella finestra Map.
short		MapXPos,MapYPos;		// Posizione del mouse nella mappa. Se<0, la posizione non è valida.
short		X1DrawTool,Y1DrawTool;	// Coordinate nella mappa del primo punto della linea o del box da tracciare
short		MapWidth,MapHeight;		// Numero blocchi visualizzati nella finestra Map
int			MapGridType=1;			// Tipo griglia mappa:
									//		0 : nessuna
									//		1 : point
									//		2 : line
int			DrawWhat=0;				// Cosa si sta disegnando:
									//		0 : niente
									//		1 : blocco
									//		2 : oggetto

int			TextureSelect=FALSE;	// Se!=0, indica che è in corso una selezione di una texture per mezzo della
									// finestra Textures. Il valore != 0 contenuto in questa variabile è quello dei
									// vari gadget di selezione di texture della finestra Block.
									// Ad es.:   BLOCKWINGAD_FLOORTEXT
int			EffectSelect=FALSE;		// Se!=0, indica che è in corso una selezione di una lista di effetti per mezzo
									// della finestra Effects
									// Se=1 la selezione è relativa alla finestra Block
int			TriggerSelect=FALSE;	// Se!=0, indica che è in corso una selezione di un trigger number per mezzo
									// della finestra Effects.
									// Se=1 la selezione è relativa al Trigger1.
									// Se=2 la selezione è relativa al Trigger2.
									// Se=3 la selezione è relativa alla finestra MapObj

int			SoundSelect=FALSE;		// Se!=0, indica che è in corso una selezione di un suono
									// per mezzo della finestra SndList
struct Window *SoundSelectWin=NULL;	// Pun. alla finestra che ha richiesto la selezione del suono

int			GfxSelect=FALSE;		// Se!=0, indica che è in corso una selezione di una pic
									// per mezzo della finestra Gfx
struct Window *GfxSelectWin=NULL;	// Pun. alla finestra che ha richiesto la selezione della pic.

long		NumUsedTexture;			// Numero di texture usate dalla mappa corrente
long		NumUsedObjects;			// Numero oggetti usati nella mappa corrente
long		NumUsedSounds;			// Numero suoni usati nella mappa corrente
long		NumObjects;				// Numero oggetti in mappa
long		LastBlock=0;			// Codice ultimo blocco definito
long		LastEdge=0;				// Codice ultimo edge definito

//*** Dati blocco corrente

long		FloorHeight=0, CeilHeight=0, Illumination=0;
WORD		SkyCeil=FALSE;
WORD		FogLighting=FALSE;
WORD		UnpeggedUpE1=0, UnpeggedLowE1=0, SwitchE1=0;
WORD		UnpeggedUpE2=0, UnpeggedLowE2=0, SwitchE2=0;
WORD		UnpeggedUpE3=0, UnpeggedLowE3=0, SwitchE3=0;
WORD		UnpeggedUpE4=0, UnpeggedLowE4=0, SwitchE4=0;
char		*n_FloorTexture="        ";
char		*n_CeilTexture="        ";
char		*n_UpTextureE1="        ";
char		*n_NormTextureE1="        ";
char		*n_LowTextureE1="        ";
char		*n_UpTextureE2="        ";
char		*n_NormTextureE2="        ";
char		*n_LowTextureE2="        ";
char		*n_UpTextureE3="        ";
char		*n_NormTextureE3="        ";
char		*n_LowTextureE3="        ";
char		*n_UpTextureE4="        ";
char		*n_NormTextureE4="        ";
char		*n_LowTextureE4="        ";

struct TextDirNode	*FloorTexture,*CeilTexture;
struct TextDirNode	*UpTextureE1,*NormTextureE1,*LowTextureE1;
struct TextDirNode	*UpTextureE2,*NormTextureE2,*LowTextureE2;
struct TextDirNode	*UpTextureE3,*NormTextureE3,*LowTextureE3;
struct TextDirNode	*UpTextureE4,*NormTextureE4,*LowTextureE4;

char					*n_EffectNum="   ";
char					*n_TriggerNum="   ";
char					*n_TriggerNum2="   ";
struct EffectDirNode	*BlockEffect;
struct EffectDirNode	*BlockTrigger,*BlockTrigger2;

WORD	BlockType=0;
WORD	EnemyBlocker=FALSE;

//*** Fine dati blocco corrente


char					*n_LevelLoadPic="    ";
char					*n_LevelMod="    ";

char					*n_MapObjName="    ";
char					*n_MapObjTriggerNum="   ";
struct EffectDirNode	*MapObjEffect;


char	*n_Effect="                    ";
char	*n_EffParam1="                    ";
char	*n_EffParam2="                    ";

char	*n_ObjSound1="    ";
char	*n_ObjSound2="    ";
char	*n_ObjSound3="    ";

long	LastTrigger=0;					// Ultimo numero di trigger usato
long	LastEffectList=0;				// Ultimo numero di effect list usato

struct FxNode	*SelectedFx=NULL;		// Ultimo Effetto selezionato dalla finestra FxWin
struct EffectDirNode	*SelectedEffectList=NULL;	// Effect list selezionata nella finestra EffectsWin
struct EffectDirNode	*SelectedEffect=NULL;		// Effetto selezionato nella finestra EffectsWin
struct EffectDirNode	*SelectedEffectNode=NULL;	// Nodo selezionato nella finestra EffectsWin

WORD			CurrBlockCode=0;		// Codice blocco corrente
struct Block	*CurrBlockPun=NULL;		// Puntatore al blocco corrente

WORD				CurrObjCode=0;		// Codice oggetto corrente
struct ObjDirNode	*CurrObjPun=NULL;	// Pun. all'oggetto corrente
struct ObjDirNode	*SelectedObj=NULL;	// Pun. all'oggetto selezionato nella list box della finestra ObjListWin

struct MapObject	*SelectedMapObj=NULL;	// Pun. all'oggetto in mappa selezionato
ULONG				MapObjStartSecs, MapObjStartMicros;

struct SoundNode	*SelectedSound=NULL;	// Pun. al suono selezionato

struct GfxNode		*SelectedGfx=NULL;		// Pun. al gfx selezionato


UBYTE		Palette[3*256];			// Current 256 colors palette

WORD		SelectedTexture=0;		// Texture correntemente selezionata

WORD		SelectedTool=0;			// ID del tool di disegno selezionato
WORD		OldSelectedTool=0;		// ID del tool di disegno selezionato prima di quello attuale
WORD		ToolType=0;				// Indica di che tipo è il tool di disegno selezionato
									// Ad es. per il tool box:  0=Box;  1=Filled box
WORD		OldToolType=0;			// Tipo del tool di disegno precedente

UBYTE		KeyColor=63;			// Colore neutro, utilizzato come colore di fondo per gli oggetti

struct GLNode	*CurrentLevel;		// Pun. al GLNode relativo al livello (mappa) correntemente in edit

WORD		Player1StartX=2048;		// Posizione iniziale player 1
WORD		Player1StartY=2048;
WORD		Player2StartX=2048;		// Posizione iniziale player 2
WORD		Player2StartY=2048;

 //*** Puntatori a memoria allocata

UBYTE		*GfxBuffer;				// Memoria per la grafica (textures, oggetti, etc)
WORD		*MapBuffer;				// Memoria per la mappa
ULONG		*ColorTable;			// Memoria per la palette di colori da passare a LoadRGB32


 //*** Flags (i nomi delle variabili flag devono finire con "_fl")

int			ShowWarns_fl=TRUE;			// Se TRUE, mostra i messaggi di allerta
int			EditPrj_fl=FALSE;			// Se TRUE, c'è un project in edit
int			ModifiedPrj_fl=FALSE;		// Se TRUE, il project in edit è stato modificato
int			ModifiedMap_fl=FALSE;		// Se TRUE, la mappa in edit è stata modificata
int			ModifiedTextList_fl=FALSE;	// Se TRUE, è stata modificata la texture list
int			ModifiedObjList_fl=FALSE;	// Se TRUE, è stata modificata la objects list
int			ModifiedSoundList_fl=FALSE;	// Se TRUE, è stata modificata la sounds list
int			ModifiedGfx_fl=FALSE;		// Se TRUE, è stato modificata una pic o una palette
int			NamedPrj_fl=FALSE;			// Se TRUE, il project ha un nome
int			ShowText_fl=TRUE;			// Se TRUE, mostra automaticamente le textures appena caricate
int			SolidWall_fl=FALSE;			// Se TRUE, il blocco corrente viene tracciato nella mappa con codice negativo
int			ShowMapObj_fl=TRUE;			// Se TRUE, mostra gli oggetti presenti in mappa


 //*** Nomi di file e di directory e altre stringhe relative al project

char		filename[256];			// Stringa puttana usata come nome file temporaneo

char		ProjectName[256]="";	// Nome del project corrente (non comprende la path)
char		ProjectDir[256]="";		// Path corrente per il project

char		ProjectNotes[34]="";	// Note per il project corrente
char		ProjectPrefix[6]="";	// Prefisso per i nomi file del project corrente
char		ProjectSoundFileName[6]="0004\0";	// Nome file sonoro/musica
char		ProjectTextFileName[6]="0001\0";	// Nome file textures
char		ProjectObjFileName[6]="0003\0";	// Nome file objects
char		ProjectGfxFileName[6]="0002\0";	// Nome file grafica

char		TextureName[64]="";		// Nome della texture corrente (non comprende la path)
char		TexturesDir[256]="";	// Path corrente per le textures
char		ObjectsDir[256]="";		// Path corrente per gli oggetti
char		SoundsDir[256]="";		// Path corrente per i suoni
char		GfxDir[256]="";			// Path corrente per Gfx


 //*** Preferenze (i nomi delle variabili devono finire con "_Pref")

char		TempDir_Pref[255];		// Directory per i file temporanei



 //*** Struct

struct PictureHeader	TexturePicHead, ObjectPicHead, GfxPicHead;

struct Block			*BlockList=NULL, CurrBlock;
struct Edge				*EdgeList=NULL, Edge1, Edge2, Edge3, Edge4;
struct MapObject		*MapObjectList=NULL;


//*** Definizione di strutture di sistema

struct Screen	*MainScr=NULL;
struct Screen	*GraphScr=NULL;
struct Window	*MainWin=NULL;
struct Window	*ProjectWin=NULL;
struct Window	*LevelWin=NULL;
struct Window	*GraphWin=NULL;
struct Window	*TexturesWin=NULL;
struct Window	*ObjListWin=NULL;
struct Window	*ObjectsWin=NULL;
struct Window	*MapObjWin=NULL;
struct Window	*SndListWin=NULL;
struct Window	*SoundsWin=NULL;
struct Window	*GfxListWin=NULL;
struct Window	*EffectsWin=NULL;
struct Window	*FxWin=NULL;
struct Window	*MapWin=NULL;
struct Window	*ToolsWin=NULL;
struct Window	*BlockWin=NULL;
struct Window	*DirsWin=NULL;
struct Menu		*myMenu=NULL;

struct RastPort	*GraphScrRP;		// Rastport dello schermo GraphScr
struct RastPort	*MapWinRP;			// Rastport della finestra Map
struct RastPort	rp;					// Rastport puttana, usata soprattutto per importare grafica
struct ViewPort	*GraphScrVP;		// ViewPort dello schermo GraphScr

ULONG			ActiveWindow=NULL;	// Ogni bit corrisponde ad una finestra.
									// Se tale bit è a 1, la finestra può ricevere un input.
									// N.B.:possono essere a 1 anche bit non corrispondenti
									//      a finestre aperte.
ULONG			OpenedWindow=NULL;	// Simile al precedente, ma ogni bit a 1
									// indica una finestra aperta.

ULONG			MainWinSigBit=NULL;
ULONG			ProjectWinSigBit=NULL;
ULONG			LevelWinSigBit=NULL;
ULONG			GraphWinSigBit=NULL;
ULONG			TexturesWinSigBit=NULL;
ULONG			ObjListWinSigBit=NULL;
ULONG			ObjectsWinSigBit=NULL;
ULONG			MapObjWinSigBit=NULL;
ULONG			SndListWinSigBit=NULL;
ULONG			SoundsWinSigBit=NULL;
ULONG			GfxListWinSigBit=NULL;
ULONG			EffectsWinSigBit=NULL;
ULONG			FxWinSigBit=NULL;
ULONG			BlockWinSigBit=NULL;
ULONG			MapWinSigBit=NULL;
ULONG			ToolsWinSigBit=NULL;
ULONG			DirsWinSigBit=NULL;

struct Node		*nodo;				// Pun. puttana a struttura Node
struct List		GLList;				// Lista games & levels
struct List		TexturesList;		// Lista delle texture del project
struct List		ObjectsList;		// Lista degli oggetti del project
struct List		SoundsList;			// Lista dei suoni del project
struct List		GfxList;			// Lista dei gfx del project
struct List		EffectsList;		// Lista degli effetti della mappa corrente

struct Gadget		*PrevGadget;
struct Gadget		*ProjectWinGadList, *ProjectWinGadgets[PRJWIN_MAXGAD];
struct Gadget		*LevelWinGadList, *LevelWinGadgets[LEVELWIN_MAXGAD];
struct Gadget		*TexturesWinGadList, *TexturesWinGadgets[TEXTWIN_MAXGAD];
struct Gadget		*ObjListWinGadList, *ObjListWinGadgets[OBJLISTWIN_MAXGAD];
struct Gadget		*ObjectsWinGadList, *ObjectsWinGadgets[OBJWIN_MAXGAD];
struct Gadget		*MapObjWinGadList, *MapObjWinGadgets[MAPOBJWIN_MAXGAD];
struct Gadget		*SndListWinGadList, *SndListWinGadgets[SNDLISTWIN_MAXGAD];
struct Gadget		*SoundsWinGadList, *SoundsWinGadgets[SOUNDWIN_MAXGAD];
struct Gadget		*GfxListWinGadList, *GfxListWinGadgets[GFXLISTWIN_MAXGAD];
struct Gadget		*EffectsWinGadList, *EffectsWinGadgets[EFFWIN_MAXGAD];
struct Gadget		*FxWinGadList, *FxWinGadgets[EFFWIN_MAXGAD];
struct Gadget		*BlockWinGadList, *BlockWinGadgets[BLOCKWIN_MAXGAD];
struct Gadget		*MapWinGadList, *MapWinGadgets[MAPWIN_MAXGAD];
struct Gadget		*ToolsWinGadList, *ToolsWinGadgets[TOOLSWIN_MAXGAD];
struct Gadget		*DirsWinGadList, *DirsWinGadgets[DIRSWIN_MAXGAD];
struct NewGadget	NewGad;


APTR VInfo=NULL;

struct DrawInfo			*DrInfo;

struct FileRequester	*FileReq;
struct rtFileRequester	*PrjFileReq, *TextFileReq, *ObjFileReq;
struct rtFileRequester	*SndFileReq, *GfxFileReq;

struct IntuiMessage		*imsg;
struct MenuItem			*MItem;



//*** Definizione di alcune funzioni

void SaveProject();
void InitNewMap();
void InitMap();
void TurnOffMenu();
void TurnOnMenu();

//*****************************************************************************
//***	Visualizzazione di messaggi e richieste
//*****************************************************************************


//*** Indicatore di stato.
//*** Visualizza una finestra di titolo title e una barra
//*** di stato.
//*** Se la finestra e' chiusa, viene aperta ed inizializzata.
//*** Se la finestra e' aperta, viene aggiornata la barra di stato
//*** in base al valore di level, relativamente al valore di max.
//*** Se level=>max, la finestra, se era aperta, viene chiusa o non viene aperta.
//*** Per chiudere o assicurarsi che sia chiusa la finestra, basta
//*** passare level==max. Se la finestra e' gia' chiusa non viene aperta.

void ShowProgress(long level, long maxlevel, char *title) {

	static struct Window	*ProgressWin=NULL;
	long					x;

	if((level>=maxlevel) && (ProgressWin==NULL)) return;

	if(ProgressWin==NULL) {
		ProgressWin = OpenWindowTags(NULL,
						WA_Left,	160,
						WA_Top,		90,
						WA_Width,	320,
						WA_Height,	50,
						WA_Flags,	WFLG_DRAGBAR|
									WFLG_SMART_REFRESH|
									WFLG_ACTIVATE,
						WA_IDCMP,	NULL,
						WA_Title,	title,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

		if(!ProgressWin) {
			ShowMessage("Problems opening Progress window !",0);
			error=GENERIC_ERROR;
			return;
		}

		DrawBevelBox(ProgressWin->RPort,6,24,308,13, GT_VisualInfo,VInfo, TAG_DONE,0);

		TurnOffMenu();
	}

	if(level<=maxlevel) {
		if(maxlevel>0)
			x=(300 * level) / maxlevel;
		else
			x=300;

		SetAPen(ProgressWin->RPort,3);
		RectFill(ProgressWin->RPort,10,26,x+10,34);
	}

	if(level>=maxlevel) {
		WaitTOF();
		WaitTOF();
		WaitTOF();
		CloseWindow(ProgressWin);
		ProgressWin=NULL;
		TurnOnMenu();
	}
}

int ShowMessage(char *str,int flag) {

	struct EasyStruct es={sizeof(struct EasyStruct),0,(UBYTE*)" Message",0,0};
	es.es_TextFormat=(UBYTE*)str;
	switch(flag) {
		case 0:		es.es_GadgetFormat=(UBYTE*)"Ok";		break;
		case 1:		es.es_GadgetFormat=(UBYTE*)"Ok|Cancel";	break;
		case 2:		es.es_GadgetFormat=(UBYTE*)"Yes|No";	break;
	}
	return(EasyRequest(MainWin,&es,NULL,NULL));
}

int ShowMessage2(char *str,int flag,APTR param) {

	struct EasyStruct es={sizeof(struct EasyStruct),0,(UBYTE*)" Message",0,0};
	es.es_TextFormat=(UBYTE*)str;
	if (flag) es.es_GadgetFormat=(UBYTE*)"Ok|Cancel";
		else es.es_GadgetFormat=(UBYTE*)"Ok";
	return(EasyRequest(MainWin,&es,NULL,param));
}

int ShowMessageW(struct Window *win,char *str,int flag) {

	struct EasyStruct es={sizeof(struct EasyStruct),0,(UBYTE*)" Message",0,0};
	es.es_TextFormat=(UBYTE*)str;
	if (flag) es.es_GadgetFormat=(UBYTE*)"Ok|Cancel";
		else es.es_GadgetFormat=(UBYTE*)"Ok";
	return(EasyRequest(win,&es,NULL,NULL));
}

void ShowAbout() {

	struct EasyStruct es={
		sizeof(struct EasyStruct),
		0,
		(UBYTE *)" About...",
		(UBYTE *)"            Map Ed.  v0.8\n      Copyright (C) 1994-1995\nby Fields Of Vision software design",
		(UBYTE *)"Ok"
	};

	EasyRequest(MainWin,&es,NULL,NULL);
}


//*** Mostra informazioni sul progetto e sulla mappa correnti

void ShowInfos() {

	char	testo[512],	str[80];
	long	lentext,lenobj, lensnd, tot;
	long	numobj, numenemies, numthings;

	if(!EditPrj_fl)
		ShowMessage("No project loaded!",0);

	lentext=ArrangeTextureList();
	lenobj=ArrangeObjectsList();
	lensnd=ArrangeSoundsList();
	numobj=CountObjects(&numenemies, &numthings);

	tot = (LastBlock<<5) + (LastEdge<<4) + lentext + lenobj + lensnd;

	strcpy(testo,"Memory occupation\n");
	strcat(testo,"-----------------\n");

	sprintf(str,"Blocks     %6ld\n", (LastBlock<<5));
	strcat(testo,str);
	sprintf(str,"Edges      %6ld\n", (LastEdge<<4));
	strcat(testo,str);
	sprintf(str,"Textures   %6ld\n",lentext);
	strcat(testo,str);
	sprintf(str,"Objects    %6ld\n",lenobj);
	strcat(testo,str);
	sprintf(str,"Sounds     %6ld\n",lensnd);
	strcat(testo,str);
	strcat(testo,"-----------------\n");
	sprintf(str,"Total     %7ld\n\n",tot);
	strcat(testo,str);

	strcat(testo," Objects  number\n");
	strcat(testo,"-----------------\n");

	sprintf(str,"Things       %3ld\n",numthings);
	strcat(testo,str);
	sprintf(str,"Enemies      %3ld\n",numenemies);
	strcat(testo,str);
	strcat(testo,"-----------------\n");
	sprintf(str,"Total       %4ld\n",numobj);
	strcat(testo,str);

	printf("Testolen=%ld\n",strlen(testo));

	ShowMessage(testo,0);
}



void ShowErrorMessage(int err, APTR message) {

	switch(err) {
		case NO_MEMORY:			ShowMessage("Not enough memory !",0);
								break;
		case BADFILENAME:		ShowMessage("Bad filename !",0);
								break;
		case BADGLDFILE:	 	ShowMessage2("Bad GLD file\n %s",0,message);
								break;
		case IFFERR_CANT_OPEN: 	ShowMessage2("Error opening file\n %s",0,message);
								break;
		case IFFERR_FILE_NOT_FORM: ShowMessage2("Error opening file\n %s \nNot a FORM iff file !",0,message);
								break;
		case IFFERR_FILE_NOT_ILBM: ShowMessage2("Error opening file\n %s \nNot a FORM-ILBM iff file !",0,message);
								break;
		case IFFERR_NO_MEMORY: 	ShowMessage2("Error opening file\n %s \nNot enough memory !",0,message);
								break;
		case IFFERR_CHUNK_NOT_FOUND: ShowMessage2("Error opening file\n %s \nIff chunk not found !",0,message);
								break;
	}
}

void ShowWarningMessage() {

	if(!ShowWarns_fl) return;

}

//*****************************************************************************

//*** Abilita tutti i menu

void TurnOnMenu() {

	register int	i;

	for(i=0; i<=MAX_MENU; i++)
		OnMenu(MainWin, i|(NOITEM<<5));
}

//*** Disabilita tutti i menu

void TurnOffMenu() {

	register int	i;

	for(i=0; i<=MAX_MENU; i++)
		OffMenu(MainWin, i|(NOITEM<<5));
}


//*** Disabilita gli input IDCMP per le finestre specificate
//*** dal parametro winbit. In tale parametro ogni bit corrisponde
//*** ad una finiestra. Se un bit è attivo alla finetra con SigBit
//*** corrispondente viene disabilitato l'input.

void TurnOffIDCMP(ULONG winbit) {

	register long	i;

	ActiveWindow = 0xffffffff ^ winbit;

	if(winbit & MainWinSigBit) {
//		for(i=0; i<MAINWIN_MAXGAD; i++)
//			GT_SetGadgetAttrs(TexturesWinGadgets[i],MainWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
		TurnOffMenu();
		SetWindowPointer(MainWin, WA_BusyPointer,TRUE, WA_PointerDelay,TRUE, TAG_DONE,0);
	}

	if(winbit & LevelWinSigBit) {
		for(i=0; i<LEVELWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(LevelWinGadgets[i],LevelWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
		SetWindowPointer(LevelWin, WA_BusyPointer,TRUE, WA_PointerDelay,TRUE, TAG_DONE,0);
	}

	if(winbit & TexturesWinSigBit) {
		for(i=0; i<TEXTWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(TexturesWinGadgets[i],TexturesWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
		SetWindowPointer(TexturesWin, WA_BusyPointer,TRUE, WA_PointerDelay,TRUE, TAG_DONE,0);
	}

	if(winbit & ObjListWinSigBit) {
		for(i=0; i<OBJLISTWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(ObjListWinGadgets[i],ObjListWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
		SetWindowPointer(ObjListWin, WA_BusyPointer,TRUE, WA_PointerDelay,TRUE, TAG_DONE,0);
	}

	if(winbit & SndListWinSigBit) {
		for(i=0; i<SNDLISTWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(SndListWinGadgets[i],SndListWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
		SetWindowPointer(SndListWin, WA_BusyPointer,TRUE, WA_PointerDelay,TRUE, TAG_DONE,0);
	}

	if(winbit & GfxListWinSigBit) {
		for(i=0; i<GFXLISTWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(GfxListWinGadgets[i],GfxListWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
		SetWindowPointer(GfxListWin, WA_BusyPointer,TRUE, WA_PointerDelay,TRUE, TAG_DONE,0);
	}

	if(winbit & EffectsWinSigBit) {
		for(i=0; i<EFFWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(EffectsWinGadgets[i],EffectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
		SetWindowPointer(EffectsWin, WA_BusyPointer,TRUE, WA_PointerDelay,TRUE, TAG_DONE,0);
	}

	if(winbit & BlockWinSigBit) {
		for(i=0; i<BLOCKWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(BlockWinGadgets[i],BlockWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
		SetWindowPointer(BlockWin, WA_BusyPointer,TRUE, WA_PointerDelay,TRUE, TAG_DONE,0);
	}

	if(winbit & MapObjWinSigBit) {
		for(i=0; i<MAPOBJWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(MapObjWinGadgets[i],MapObjWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
		SetWindowPointer(MapObjWin, WA_BusyPointer,TRUE, WA_PointerDelay,TRUE, TAG_DONE,0);
	}

	if(winbit & ObjectsWinSigBit) {
		for(i=0; i<OBJWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
		SetWindowPointer(ObjectsWin, WA_BusyPointer,TRUE, WA_PointerDelay,TRUE, TAG_DONE,0);
	}

	if(winbit & MapWinSigBit) {
		for(i=0; i<MAPWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(MapWinGadgets[i],MapWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
		SetWindowPointer(MapWin, WA_BusyPointer,TRUE, WA_PointerDelay,TRUE, TAG_DONE,0);
	}

}


//*** Abilita gli input IDCMP per le finestre specificate
//*** dal parametro winbit. Vedi anche TurnOffIDCMP() per altre spiegazioni.

void TurnOnIDCMP(ULONG winbit) {

	register long	i;

	ActiveWindow |= winbit;

	if(winbit & MainWinSigBit) {
//		for(i=0; i<MAINWIN_MAXGAD; i++)
//			GT_SetGadgetAttrs(TexturesWinGadgets[i],MainWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
		TurnOnMenu();
		SetWindowPointer(MainWin, WA_BusyPointer,FALSE, WA_PointerDelay,FALSE, TAG_DONE,0);
	}

	if(winbit & LevelWinSigBit) {
		for(i=0; i<LEVELWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(LevelWinGadgets[i],LevelWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
		SetWindowPointer(LevelWin, WA_BusyPointer,FALSE, WA_PointerDelay,FALSE, TAG_DONE,0);
	}

	if(winbit & TexturesWinSigBit) {
		for(i=0; i<TEXTWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(TexturesWinGadgets[i],TexturesWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
		SetWindowPointer(TexturesWin, WA_BusyPointer,FALSE, WA_PointerDelay,FALSE, TAG_DONE,0);
	}

	if(winbit & ObjListWinSigBit) {
		for(i=0; i<OBJLISTWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(ObjListWinGadgets[i],ObjListWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
		SetWindowPointer(ObjListWin, WA_BusyPointer,FALSE, WA_PointerDelay,FALSE, TAG_DONE,0);
	}

	if(winbit & SndListWinSigBit) {
		for(i=0; i<SNDLISTWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(SndListWinGadgets[i],SndListWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
		SetWindowPointer(SndListWin, WA_BusyPointer,FALSE, WA_PointerDelay,FALSE, TAG_DONE,0);
	}

	if(winbit & GfxListWinSigBit) {
		for(i=0; i<GFXLISTWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(GfxListWinGadgets[i],GfxListWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
		SetWindowPointer(GfxListWin, WA_BusyPointer,FALSE, WA_PointerDelay,FALSE, TAG_DONE,0);
	}

	if(winbit & EffectsWinSigBit) {
		for(i=0; i<EFFWINGAD_ADDFX; i++)
			GT_SetGadgetAttrs(EffectsWinGadgets[i],EffectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
		for(i=EFFWINGAD_ADDFX; i<=EFFWINGAD_PARAM2; i++)
			GT_SetGadgetAttrs(EffectsWinGadgets[i],EffectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
		SetWindowPointer(EffectsWin, WA_BusyPointer,FALSE, WA_PointerDelay,FALSE, TAG_DONE,0);
	}

	if(winbit & BlockWinSigBit) {
		for(i=0; i<BLOCKWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(BlockWinGadgets[i],BlockWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
		SetWindowPointer(BlockWin, WA_BusyPointer,FALSE, WA_PointerDelay,FALSE, TAG_DONE,0);
	}

	if(winbit & MapObjWinSigBit) {
		for(i=0; i<MAPOBJWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(MapObjWinGadgets[i],MapObjWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
		SetWindowPointer(MapObjWin, WA_BusyPointer,FALSE, WA_PointerDelay,FALSE, TAG_DONE,0);
	}

	if(winbit & ObjectsWinSigBit) {
		for(i=0; i<OBJWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(ObjectsWinGadgets[i],ObjectsWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
		SetWindowPointer(ObjectsWin, WA_BusyPointer,FALSE, WA_PointerDelay,FALSE, TAG_DONE,0);
	}

	if(winbit & MapWinSigBit) {
		for(i=0; i<MAPWIN_MAXGAD; i++)
			GT_SetGadgetAttrs(MapWinGadgets[i],MapWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
		SetWindowPointer(MapWin, WA_BusyPointer,FALSE, WA_PointerDelay,FALSE, TAG_DONE,0);
	}
}

//*****************************************************************************

//*** A partire dalla palette nel formato (R G B)*256
//*** riempie la ColorTable per l'uso con LoadRGB32

void MakeRGB32Table(UBYTE *palette) {

	register int	i;
	ULONG			*p;

	p=ColorTable;
	*p++ = (ULONG)(256<<16);
	for(i=0; i<(256*3); i++) 
		*p++=(ULONG)(palette[i]<<24);
	*p = 0;
}


//*****************************************************************************


//*** Apre finestra directories

void OpenDirsWindow() {

	int				cont;
	ULONG			signals;
	ULONG			imsgClass;
	UWORD			imsgCode;
	struct Gadget	*gad;
	char			*str;

	if(DirsWin) return;		// Se già aperta, ritorna subito

	DirsWin = OpenWindowTags(NULL,
							WA_Left,	120,
							WA_Top,		58,
							WA_Width,	400,
							WA_Height,	140,
							WA_Flags,	WFLG_DRAGBAR|WFLG_DEPTHGADGET|WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|WFLG_ACTIVATE,
							WA_IDCMP,	IDCMP_CLOSEWINDOW|IDCMP_GADGETUP,
							WA_Title,	"Directories...",
							WA_Gadgets,	DirsWinGadList,
							WA_CustomScreen, MainScr,
							TAG_DONE,0);

	if(!DirsWin) {
		ShowMessage("Problems opening Directories window !",0);
		error=GENERIC_ERROR;
		return;
	}

	GT_RefreshWindow(DirsWin,NULL);

	DirsWinSigBit = 1 << DirsWin->UserPort->mp_SigBit;
	OpenedWindow |= DirsWinSigBit;

	cont=TRUE;

	while(cont && !error) {
		if(signals = Wait(DirsWinSigBit)) {
			while(!error && (imsg = GT_GetIMsg(DirsWin->UserPort))) {
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
							case DIRSWINGAD_OK:
								GT_GetGadgetAttrs(DirsWinGadgets[DIRSWINGAD_TEMP],
													DirsWin, NULL,
													GTST_String, &str,
													TAG_DONE,0);
								strcpy(TempDir_Pref, str);
								cont=FALSE;
								break;
							case DIRSWINGAD_CANCEL:	cont=FALSE; break;
							case DIRSWINGAD_TEMP:	break;
						}
						break;
				}
			}
		}
	}

	CloseDirsWindow();
}



//*** Assegna al level il primo nome file libero
//*** I nomi file da 0001 a 0006 sono riservati

void AssignName(struct GLNode *level) {

	register long	l, found;
	char			ss[5];
	struct Node		*node;
	struct GLNode	*glnode;

	ss[4] = '\0';

	l=5;

	do {
		l++;
		found=TRUE;
		for(node=GLList.lh_Head; node->ln_Succ; node=node->ln_Succ) {
			glnode=(struct GLNode *)node;

			if(glnode->gln_type == 1) {
				memcpy(ss,glnode->gln_filename,4);
				if(l == atol(ss)) {
					found=FALSE;
					break;
				}
			}
		}
	} while(!found);

	sprintf(ss,"%04ld",l);
	memcpy(level->gln_filename,ss,4);

	ModifiedPrj_fl=TRUE;

	printf("AssignName = %ls\n",ss);
}



//*** Aggiunge un nuovo game di nome name al project

void AddNewGameEntry(char *name) {

	struct GLNode	*glnode;

	if(!(glnode = (struct GLNode *)AllocMem(sizeof(struct GLNode),MEMF_CLEAR))) {
		error=NO_MEMORY;
		return;
	}

	NumGame++;		// Incrementa il numero di game del project

	sprintf(glnode->gln_gamenum,"%3ld ", NumGame);
	memset(glnode->gln_gamename,' ',20);
	strncpy(glnode->gln_gamename,name,strlen(name));
	glnode->gln_pad1=' ';
	memset(glnode->gln_levelnum,' ',4);
	memset(glnode->gln_levelname,' ',20);
	glnode->gln_pad2=' ';
	glnode->gln_num=0;
	memset(glnode->gln_filename,0,4);

	glnode->gln_type = 0;

	glnode->gln_node.ln_Type=0;
	glnode->gln_node.ln_Pri	=0;
	glnode->gln_node.ln_Name=glnode->gln_gamenum;
	AddTail(&GLList,&(glnode->gln_node));

	ModifiedPrj_fl=TRUE;
}


//*** Modifica un game del project

void ModifyGameEntry(struct GLNode	*glnode, char *name) {

	memset(glnode->gln_gamename,' ',20);
	strncpy(glnode->gln_gamename,name,strlen(name));

	ModifiedPrj_fl=TRUE;
}


//*** Aggiunge un nuovo level di nome name al game gamenode

void AddNewLevelEntry(struct GLNode	*gamenode, char *name) {

	struct GLNode	*glnode;
	register int	i;

	if(!(glnode = (struct GLNode *)AllocMem(sizeof(struct GLNode),MEMF_CLEAR))) {
		error=NO_MEMORY;
		return;
	}

	gamenode->gln_num++;	// Incrementa il numero di level del game

	memset(glnode->gln_gamenum,' ',4);
	memset(glnode->gln_gamename,' ',20);
	glnode->gln_pad1=' ';
	sprintf(glnode->gln_levelnum,"%3ld ", gamenode->gln_num);
	memset(glnode->gln_levelname,' ',20);
	strncpy(glnode->gln_levelname,name,strlen(name));
	glnode->gln_pad2=' ';
	glnode->gln_num=0;
	memset(glnode->gln_filename,0,4);

	glnode->gln_type = 1;

	glnode->gln_node.ln_Type=0;
	glnode->gln_node.ln_Pri	=0;
	glnode->gln_node.ln_Name=glnode->gln_gamenum;

	for(i=gamenode->gln_num-1; i>0; i--)		// Cerca il nodo dell'ultimo livello del game
		gamenode = (struct GLNode *)gamenode->gln_node.ln_Succ;

	Insert(&GLList,&(glnode->gln_node),(struct Node *)gamenode);

	ModifiedPrj_fl=TRUE;
}


//*** Modifica un level del game

void ModifyLevelEntry(struct GLNode *glnode, char *name) {

	memset(glnode->gln_levelname,' ',20);
	strncpy(glnode->gln_levelname,name,strlen(name));

	ModifiedPrj_fl=TRUE;
}



//*** Rimuove un game con tutti i suoi level dal project

void DelGameEntry(struct GLNode *glnode) {

	ShowMessage("Non ancora implementato.",0);

//	ModifiedPrj_fl=TRUE;
}



//*** Rimuove un level

void DelLevelEntry(struct GLNode *glnode) {

	ShowMessage("Non ancora implementato.",0);

//	ModifiedPrj_fl=TRUE;
}



//*** Apre finestra Project

void OpenProjectWindow() {

	register long	i;
	int				cont, action;
	ULONG			signals;
	ULONG			imsgClass;
	UWORD			imsgCode;
	struct Gadget	*gad;
	char			*str, sss[50];
	struct GLNode	*glnode;
	static struct IntuiText ProjectWinIText[]={
		 1,0, JAM2, 166,32, NULL, (UBYTE *)" File names ", NULL
	};


	if(ProjectWin) return;		// Se già aperta, ritorna subito

	TurnOffMenu();

	ProjectWin = OpenWindowTags(NULL,
							WA_Left,	102,
							WA_Top,		25,
							WA_Width,	436,
							WA_Height,	220,
							WA_Flags,	WFLG_DRAGBAR|WFLG_DEPTHGADGET|WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|WFLG_ACTIVATE,
							WA_IDCMP,	IDCMP_CLOSEWINDOW|IDCMP_GADGETUP|LISTVIEWIDCMP,
							WA_Title,	"Project window",
							WA_Gadgets,	ProjectWinGadList,
							WA_CustomScreen, MainScr,
							TAG_DONE,0);

	if(!ProjectWin) {
		ShowMessage("Problems opening Project window !",0);
		error=1;
		return;
	}

	DrawBevelBox(ProjectWin->RPort,8,46,420,37, GT_VisualInfo,VInfo, TAG_DONE,0);
	PrintIText(ProjectWin->RPort, ProjectWinIText, ProjectWin->BorderLeft, ProjectWin->BorderTop);

	GT_RefreshWindow(ProjectWin,NULL);

	ProjectWinSigBit = 1 << ProjectWin->UserPort->mp_SigBit;
	OpenedWindow |= ProjectWinSigBit;

	if(!EditPrj_fl) {
		for(i=PRJWINGAD_NOTES; i<=PRJWINGAD_OK; i++)
			GT_SetGadgetAttrs(ProjectWinGadgets[i],ProjectWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
	} else {
		for(i=PRJWINGAD_PRJNAME; i<PRJWINGAD_OK; i++)
			GT_SetGadgetAttrs(ProjectWinGadgets[i],ProjectWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
		GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_NOTES],ProjectWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
		GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_ADDGAME],ProjectWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);

		GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_PRJNAME], ProjectWin, NULL,
							GTST_String, ProjectName, TAG_DONE,0);
		GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_NOTES], ProjectWin, NULL,
							GTST_String, ProjectNotes, TAG_DONE,0);
		GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_PREFIX], ProjectWin, NULL,
							GTST_String, ProjectPrefix, TAG_DONE,0);

		GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_LIST], ProjectWin,NULL,
							GTLV_Labels, NULL, TAG_DONE, NULL);
		GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_LIST], ProjectWin,NULL,
							GTLV_Labels, &GLList, TAG_DONE, NULL);
	}

	action=-1;
	cont=TRUE;

	while(cont && !error) {
		if(signals = Wait(ProjectWinSigBit)) {
			while(!error && (imsg = GT_GetIMsg(ProjectWin->UserPort))) {
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
							case PRJWINGAD_PRJNAME:
								GT_GetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_PRJNAME],
													ProjectWin, NULL,
													GTST_String, &str,
													TAG_DONE,0);
								if(!strisempty(str)) {
									for(i=PRJWINGAD_NOTES; i<=PRJWINGAD_ADDGAME; i++)
										GT_SetGadgetAttrs(ProjectWinGadgets[i],ProjectWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
									GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_OK],ProjectWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
								}
								strcpy(ProjectName, str);
								strncpy(ProjectPrefix, str, 4);
								ProjectPrefix[4]='\0';
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_PREFIX],
													ProjectWin, NULL,
													GTST_String, ProjectPrefix,
													TAG_DONE,0);
								break;
							case PRJWINGAD_NOTES:
								GT_GetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_NOTES],
													ProjectWin, NULL,
													GTST_String, &str,
													TAG_DONE,0);
								strcpy(ProjectNotes, str);
								break;
							case PRJWINGAD_LIST:
								glnode=(struct GLNode *)FindNode(&GLList,imsgCode);
								if(glnode->gln_type) {
									strncpy(sss,glnode->gln_levelname,20);
									action=3;	// Modify Level
								} else {
									strncpy(sss,glnode->gln_gamename,20);
									action=1;	// Modify Game
								}
								sss[20]='\0';
								strrtrim(sss);
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_DESCR],
													ProjectWin, NULL,
													GTST_String, sss,
													TAG_DONE,0);
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_DESCR],ProjectWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
								if(action==1) {
									GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_ADDLEVEL],ProjectWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
									GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_EDITLEVEL],ProjectWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
								} else {
									GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_ADDLEVEL],ProjectWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
									if(EditPrj_fl) {
										GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_EDITLEVEL],ProjectWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
									}
								}
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_DEL],ProjectWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
								ActivateGadget(ProjectWinGadgets[PRJWINGAD_DESCR],ProjectWin,NULL);
								break;
							case PRJWINGAD_ADDGAME:
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_DEL],ProjectWin, NULL, GA_DISABLED,FALSE, TAG_DONE,0);
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_DESCR],
													ProjectWin, NULL,
													GA_DISABLED, FALSE,
													GTST_String, NULL,
													TAG_DONE,0);
								ActivateGadget(ProjectWinGadgets[PRJWINGAD_DESCR],ProjectWin,NULL);
								action=0;	// Add Game
								break;
							case PRJWINGAD_ADDLEVEL:
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_DESCR],
													ProjectWin, NULL,
													GA_DISABLED, FALSE,
													GTST_String, NULL,
													TAG_DONE,0);
								ActivateGadget(ProjectWinGadgets[PRJWINGAD_DESCR],ProjectWin,NULL);
								action=2;	// Add Level
								break;
							case PRJWINGAD_DEL:
								switch(action) {
									case 0:		// Add Game
										break;
									case 1:		// Modify Game
										DelGameEntry(glnode);
										break;
									case 2:		// Add Level
										break;
									case 3:		// Modify Level
										DelLevelEntry(glnode);
										break;
								}
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_DESCR],
													ProjectWin, NULL,
													GA_DISABLED, TRUE,
													GTST_String, NULL,
													TAG_DONE,0);
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_ADDLEVEL],ProjectWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_DEL],ProjectWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
								break;
							case PRJWINGAD_DESCR:
								GT_GetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_DESCR],
													ProjectWin, NULL,
													GTST_String, &str,
													TAG_DONE,0);
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_LIST],
													ProjectWin,NULL,
													GTLV_Labels, NULL,
													TAG_DONE, NULL);
								switch(action) {
									case 0:		// Add Game
										AddNewGameEntry(str);
										break;
									case 1:		// Modify Game
										ModifyGameEntry(glnode,str);
										break;
									case 2:		// Add Level
										AddNewLevelEntry(glnode,str);
										break;
									case 3:		// Modify Level
										ModifyLevelEntry(glnode,str);
										break;
								}
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_LIST],
												ProjectWin,NULL,
												GTLV_Labels, &GLList,
												TAG_DONE, NULL);
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_DESCR],
													ProjectWin, NULL,
													GA_DISABLED, TRUE,
													GTST_String, NULL,
													TAG_DONE,0);
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_ADDLEVEL],ProjectWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
								GT_SetGadgetAttrs(ProjectWinGadgets[PRJWINGAD_DEL],ProjectWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);
								break;
							case PRJWINGAD_EDITLEVEL:
								if(ModifiedMap_fl) {
									if((CurrentLevel != glnode) && (CurrentLevel != NULL))
										SaveProject();
								}
								CurrentLevel = glnode;
								if(CurrentLevel->gln_filename[0] != 0) {
									InitMap();
									ReadMapGLD(CurrentLevel);
								} else {
									InitNewMap();
									AssignName(CurrentLevel);
									ModifiedMap_fl=TRUE;
								}
								OpenMapWindow();
								MapWinDim();
								DrawMap();
								cont=FALSE;
								break;
							case PRJWINGAD_CANCEL:
								cont=FALSE;
								break;
							case PRJWINGAD_OK:
								EditPrj_fl=TRUE;
								ModifiedPrj_fl=TRUE;
								while(!NamedPrj_fl) {
									if(!SelectPrjName())
										ShowMessage("You MUST select a directory.",0);
								}
								cont=FALSE;
								break;
						}
						break;
				}
			}
		}
	}

	CloseProjectWindow();

	TurnOnMenu();
}




//*** Inizializza lista oggetti

void InitObjList() {

	struct ObjDirNode	*onode;

	GT_SetGadgetAttrs(ObjListWinGadgets[OBJLISTWINGAD_LIST],
						ObjListWin,NULL,
						GTLV_Labels, NULL,
						TAG_DONE, NULL);

	//*** Add player

	if(!(onode = (struct ObjDirNode *)AllocMem(sizeof(struct ObjDirNode),MEMF_CLEAR))) {
		error=NO_MEMORY;
		return;
	}

	strcpy(onode->odn_name,"PLAY     Player start position         ");
	onode->odn_numframes =	0;
	onode->odn_radius =		0;
	onode->odn_height =		0;
	onode->odn_animtype =	-1;
	onode->odn_objtype =	1;
	onode->odn_param1 =		0;
	onode->odn_param2 =		0;
	onode->odn_param3 =		0;
	onode->odn_param4 =		0;
	onode->odn_param5 =		0;
	onode->odn_param6 =		0;
	onode->odn_offset = 	0;
	onode->odn_length = 	0;
	onode->odn_location = 	0;

	onode->odn_node.ln_Type	=0;
	onode->odn_node.ln_Pri	=0;
	onode->odn_node.ln_Name	=onode->odn_name;
	AddHead(&ObjectsList,&(onode->odn_node));

	GT_SetGadgetAttrs(ObjListWinGadgets[OBJLISTWINGAD_LIST],
						ObjListWin,NULL,
						GTLV_Labels, &ObjectsList,
						TAG_DONE, NULL);
}



//*** Inizializza lista textures, inserendo una texture vuota fittizia

void InitTextList() {

	struct TextDirNode	*tnode;

	if(!(tnode = (struct TextDirNode *)AllocMem(sizeof(struct TextDirNode),MEMF_CLEAR))) {
		error=NO_MEMORY;
		return;
	}

	strcpy(tnode->tdn_name, "--------   Empty ");
	tnode->tdn_name[17]='\0';

	tnode->tdn_width=TexturePicHead.Header.Width;
	tnode->tdn_height=TexturePicHead.Header.Height;
	tnode->tdn_location=1;			// Segnala che la texture è su un file nella directory temporanea
	tnode->tdn_type=0;				// Segnala che è la texture nulla

	GT_SetGadgetAttrs(TexturesWinGadgets[TEXTWINGAD_LIST],
						TexturesWin,NULL,
						GTLV_Labels, NULL,
						TAG_DONE, NULL);

	tnode->tdn_node.ln_Type	=0;
	tnode->tdn_node.ln_Pri	=0;
	tnode->tdn_node.ln_Name	=tnode->tdn_name;
	AddHead(&TexturesList,&(tnode->tdn_node));

	GT_SetGadgetAttrs(TexturesWinGadgets[TEXTWINGAD_LIST],
						TexturesWin,NULL,
						GTLV_Labels, &TexturesList,
						TAG_DONE, NULL);
}


//*** Inizializza lista effetti

void InitEffectsList() {

	struct EffectDirNode	*enode;

	GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Labels,NULL, TAG_DONE,NULL);

	//*** Inserisce la lista num. 0

	if(!(enode = (struct EffectDirNode *)AllocMem(sizeof(struct EffectDirNode),MEMF_CLEAR))) {
		error=NO_MEMORY;
		return;
	}

	strcpy(enode->eff_name, "--- ------------------------------------");

	enode->eff_listnum = 0;
	enode->eff_trigger = 0;
	enode->eff_fx = (struct FxNode *)NULL;
	enode->eff_effect = 0;
	enode->eff_param1 = 0;
	enode->eff_param2 = 0;

	enode->eff_node.ln_Type	=0;
	enode->eff_node.ln_Pri	=0;
	enode->eff_node.ln_Name	=enode->eff_name;
	AddHead(&EffectsList,&(enode->eff_node));



	//*** Inserisce il trigger num. 0

	if(!(enode = (struct EffectDirNode *)AllocMem(sizeof(struct EffectDirNode),MEMF_CLEAR))) {
		error=NO_MEMORY;
		return;
	}

	strcpy(enode->eff_name,"    --- Empty                       ");

	enode->eff_listnum = 0;
	enode->eff_trigger = 0;
	enode->eff_fx      = (struct FxNode *)NULL;
	enode->eff_effect  = 0;
	enode->eff_param1  = 0;
	enode->eff_param2  = 0;

	enode->eff_node.ln_Type	=0;
	enode->eff_node.ln_Pri	=0;
	enode->eff_node.ln_Name	=enode->eff_name;
	AddTail(&EffectsList,&(enode->eff_node));

	GT_SetGadgetAttrs(EffectsWinGadgets[EFFWINGAD_LIST], EffectsWin,NULL, GTLV_Labels,&EffectsList, TAG_DONE,NULL);
}



//*** Inizializza SoundsList, inserendo un sound vuoto

void InitSoundsList() {

	struct 	SoundNode	*snode;

	GT_SetGadgetAttrs(SndListWinGadgets[SNDLISTWINGAD_LIST],
						SndListWin,NULL,
						GTLV_Labels, NULL,
						TAG_DONE, NULL);

	if(!(snode = (struct SoundNode *)AllocMem(sizeof(struct SoundNode),MEMF_CLEAR))) {
		error=NO_MEMORY;
		return;
	}

	strcpy(snode->snd_name,"         ------------------------------");
	snode->snd_type			= SOUNDTYPE_EMPTY;
	snode->snd_code			= 0;
	snode->snd_length		= 0;
	snode->snd_period		= 0;
	snode->snd_volume		= 0;
	snode->snd_loop			= 0;
	snode->snd_priority		= 0;
	snode->snd_mask			= 0;
	snode->snd_sample[0]	= '\0';
	snode->snd_sound1[0]	= '\0';
	snode->snd_sound2[0]	= '\0';
	snode->snd_sound3[0]	= '\0';
	snode->snd_offset		= 0;
	snode->snd_flength		= 0;
	snode->snd_location		= 0;
	snode->snd_num			= 0;

	snode->snd_node.ln_Type	=0;
	snode->snd_node.ln_Pri	=0;
	snode->snd_node.ln_Name	=snode->snd_name;
	AddHead(&SoundsList,&(snode->snd_node));

	GT_SetGadgetAttrs(SndListWinGadgets[SNDLISTWINGAD_LIST],
						SndListWin,NULL,
						GTLV_Labels, &SoundsList,
						TAG_DONE, NULL);
}



//*** Inizializza GfxList, inserendo una entry vuota

void InitGfxList() {

	struct 	GfxNode		*gnode;

	GT_SetGadgetAttrs(GfxListWinGadgets[GFXLISTWINGAD_LIST],
						GfxListWin,NULL,
						GTLV_Labels, NULL,
						TAG_DONE, NULL);

	if(!(gnode = (struct GfxNode *)AllocMem(sizeof(struct GfxNode),MEMF_CLEAR))) {
		error=NO_MEMORY;
		return;
	}

	strcpy(gnode->gfx_name,"         ------------------------------");
	gnode->gfx_type			= GFXTYPE_EMPTY;
	gnode->gfx_noused		= 0;
	gnode->gfx_x			= 0;
	gnode->gfx_y			= 0;
	gnode->gfx_width		= 0;
	gnode->gfx_height		= 0;
	gnode->gfx_offset		= 0;
	gnode->gfx_length		= 0;
	gnode->gfx_location		= 0;

	gnode->gfx_node.ln_Type	=0;
	gnode->gfx_node.ln_Pri	=0;
	gnode->gfx_node.ln_Name	=gnode->gfx_name;
	AddHead(&GfxList,&(gnode->gfx_node));

	GT_SetGadgetAttrs(GfxListWinGadgets[GFXLISTWINGAD_LIST],
						GfxListWin,NULL,
						GTLV_Labels, &GfxList,
						TAG_DONE, NULL);
}



//*** Inizializza la finestra Block

void InitBlockWin() {

	struct TextDirNode	*nnode;

	nnode=(struct TextDirNode *)FindNode(&TexturesList,0);

	FloorHeight=0;
	CeilHeight=0;
	FloorTexture=nnode;
	CeilTexture=nnode;
	Illumination=0;

	FogLighting=FALSE;
	BlockType=0;
	EnemyBlocker=FALSE;

	BlockEffect = (struct EffectDirNode *)EffectsList.lh_Head;
	BlockTrigger = (struct EffectDirNode *)((EffectsList.lh_Head)->ln_Succ);
	BlockTrigger2 = (struct EffectDirNode *)((EffectsList.lh_Head)->ln_Succ);

	NormTextureE1=nnode;
	UpTextureE1=nnode;
	LowTextureE1=nnode;
	UnpeggedUpE1=0;
	UnpeggedLowE1=0;
	SwitchE1=0;

	NormTextureE2=nnode;
	UpTextureE2=nnode;
	LowTextureE2=nnode;
	UnpeggedUpE2=0;
	UnpeggedLowE2=0;
	SwitchE2=0;

	NormTextureE3=nnode;
	UpTextureE3=nnode;
	LowTextureE3=nnode;
	UnpeggedUpE3=0;
	UnpeggedLowE3=0;
	SwitchE3=0;

	NormTextureE4=nnode;
	UpTextureE4=nnode;
	LowTextureE4=nnode;
	UnpeggedUpE4=0;
	UnpeggedLowE4=0;
	SwitchE4=0;

	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_FLOORH_NUM],BlockWin,NULL, GTIN_Number,FloorHeight, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_FLOORH_SLIDE],BlockWin,NULL, GTSL_Level,FloorHeight+8192, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_CEILH_NUM],BlockWin,NULL, GTIN_Number,CeilHeight, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_CEILH_SLIDE],BlockWin,NULL, GTSL_Level,CeilHeight+8192, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_ILLUM_NUM],BlockWin,NULL, GTIN_Number,Illumination, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_ILLUM_SLIDE],BlockWin,NULL, GTSL_Level,Illumination+128, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_SOLIDWALL],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_SKYCEIL],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_FOG],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_TYPE],BlockWin,NULL, GTCY_Active,0, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_ENEMYBLOCKER],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);

	strncpy(n_FloorTexture,((struct Node *)nnode)->ln_Name,8);
	strncpy(n_CeilTexture,((struct Node *)nnode)->ln_Name,8);
	strncpy(n_UpTextureE1,((struct Node *)nnode)->ln_Name,8);
	strncpy(n_NormTextureE1,((struct Node *)nnode)->ln_Name,8);
	strncpy(n_LowTextureE1,((struct Node *)nnode)->ln_Name,8);
	strncpy(n_UpTextureE2,((struct Node *)nnode)->ln_Name,8);
	strncpy(n_NormTextureE2,((struct Node *)nnode)->ln_Name,8);
	strncpy(n_LowTextureE2,((struct Node *)nnode)->ln_Name,8);
	strncpy(n_UpTextureE3,((struct Node *)nnode)->ln_Name,8);
	strncpy(n_NormTextureE3,((struct Node *)nnode)->ln_Name,8);
	strncpy(n_LowTextureE3,((struct Node *)nnode)->ln_Name,8);
	strncpy(n_UpTextureE4,((struct Node *)nnode)->ln_Name,8);
	strncpy(n_NormTextureE4,((struct Node *)nnode)->ln_Name,8);
	strncpy(n_LowTextureE4,((struct Node *)nnode)->ln_Name,8);

	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E1_UNPEGUP],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E1_UNPEGLOW],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E2_UNPEGUP],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E2_UNPEGLOW],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E3_UNPEGUP],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E3_UNPEGLOW],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E4_UNPEGUP],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E4_UNPEGLOW],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);

	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E1_SWITCH],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E2_SWITCH],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E3_SWITCH],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E4_SWITCH],BlockWin,NULL, GTCB_Checked,FALSE, TAG_DONE,0);
}



//*** Inizializza i dati per una nuova mappa (Blocks, Edges, etc.)

void InitNewMap() {

	CurrBlockCode = 0;
	LastBlock = 0;
	LastEdge = 0;
	LastTrigger=0;		
	LastEffectList=0;
	NumObjects=0;

	SelectedTexture=NULL;
	SelectedFx=NULL;
	SelectedEffect=NULL;
	SelectedEffectList=NULL;
	SelectedEffectNode=NULL;
	SelectedObj=NULL;
	SelectedMapObj=NULL;
	SelectedSound=NULL;
	SelectedGfx=NULL;

	memset(n_LevelLoadPic,' ',4);
	memset(n_LevelMod,' ',4);

	FreeEdgeBlockLists();
	FreeMapObjectList();
	FreeEffectsList();
	InitEffectsList();
	InitBlockWin();
	AcceptBlock();		// Create empty block
	ClearMap();

	ModifiedMap_fl=FALSE;
}



//*** Inizializza i dati della mappa per caricarne una nuova

void InitMap() {

	CurrBlockCode = 0;
	LastBlock = 0;
	LastEdge = 0;
	LastTrigger=0;		
	LastEffectList=0;
	NumObjects=0;

	SelectedTexture=NULL;
	SelectedFx=NULL;
	SelectedEffect=NULL;
	SelectedEffectList=NULL;
	SelectedEffectNode=NULL;
	SelectedObj=NULL;
	SelectedMapObj=NULL;
	SelectedSound=NULL;
	SelectedGfx=NULL;

	FreeEdgeBlockLists();
	FreeMapObjectList();
	FreeEffectsList();
	InitEffectsList();
	InitBlockWin();
	ClearMap();

	ModifiedMap_fl=FALSE;
}




//*** Azzera un eventuale project presente in memoria

void ClearProject() {

	FreeGLList();
	FreeTextList();
	FreeObjList();
	FreeSoundList();
	FreeGfxList();
	NewList(&TexturesList);
	NewList(&GLList);
	InitTextList();
	InitObjList();
	InitSoundsList();
	InitGfxList();
	InitNewMap();

	SelectedTexture=NULL;
	SelectedFx=NULL;
	SelectedEffect=NULL;
	SelectedEffectList=NULL;
	SelectedEffectNode=NULL;
	SelectedObj=NULL;
	SelectedMapObj=NULL;
	SelectedSound=NULL;
	SelectedGfx=NULL;

	EditPrj_fl = FALSE;
	ModifiedPrj_fl = FALSE;
	ModifiedTextList_fl = FALSE;
	ModifiedObjList_fl = FALSE;
	ModifiedSoundList_fl = FALSE;
	ModifiedGfx_fl = FALSE;
	NamedPrj_fl = FALSE;

	CurrentLevel = NULL;
}



//*** Apre un project
//*** Restituisce FALSE se non ha aperto il project

int OpenProject() {

/*
	if(AslRequestTags(FileReq, 	ASL_FuncFlags,FILF_NEWIDCMP,
								ASL_Hail,"Open Project",
								ASL_Window,MainWin,
								ASL_Dir,(long)ProjectDir,
								ASL_File,(long)ProjectName,
								TAG_DONE, NULL)) {
		strcpy(ProjectDir, (char *)FileReq->rf_Dir);
		strcpy(ProjectName, (char *)FileReq->rf_File);
*/
	strcpy(filename, ProjectName);
	if(rtFileRequest(PrjFileReq, filename, "Open Project", TAG_END,NULL)) {
		strcpy(ProjectDir, PrjFileReq->Dir);
		strcpy(ProjectName, filename);


		ClearProject();

		NamedPrj_fl = TRUE;

		GT_SetGadgetAttrs(TexturesWinGadgets[TEXTWINGAD_LIST],
							TexturesWin,NULL,
							GTLV_Labels, NULL,
							TAG_DONE, NULL);

		GT_SetGadgetAttrs(ObjListWinGadgets[OBJLISTWINGAD_LIST],
							ObjectsWin,NULL,
							GTLV_Labels, NULL,
							TAG_DONE, NULL);

		GT_SetGadgetAttrs(SndListWinGadgets[SNDLISTWINGAD_LIST],
							SndListWin,NULL,
							GTLV_Labels, NULL,
							TAG_DONE, NULL);

		GT_SetGadgetAttrs(GfxListWinGadgets[GFXLISTWINGAD_LIST],
							GfxListWin,NULL,
							GTLV_Labels, NULL,
							TAG_DONE, NULL);

		if(!ReadMainGLD()) {
			if(!ReadGfxGLD()) {
				if(!ReadTexturesGLD()) {
					if(!ReadObjectsGLD()) {
						if(!ReadSoundsGLD()) {

							SetAPen(GraphScrRP,0);
							RectFill(GraphScrRP,0,0,319,255);	// Clear Graph screen

							MakeRGB32Table(Palette);
							LoadRGB32(GraphScrVP,ColorTable);

							EditPrj_fl = TRUE;

						} else {
							ShowMessage("Problems opening Sounds file !",0);
						}
					} else {
						ShowMessage("Problems opening Objects file !",0);
					}
				} else {
					ShowMessage("Problems opening Textures file !",0);
				}
			} else {
				ShowMessage("Problems opening Gfx file !",0);
			}
		} else {
			ShowMessage("Problems opening Main GLD file !",0);
		}
	}

	if(EditPrj_fl) {
		GT_SetGadgetAttrs(TexturesWinGadgets[TEXTWINGAD_LIST],
							TexturesWin,NULL,
							GTLV_Labels, &TexturesList,
							TAG_DONE, NULL);
		GT_SetGadgetAttrs(ObjListWinGadgets[OBJLISTWINGAD_LIST],
							ObjectsWin,NULL,
							GTLV_Labels, &ObjectsList,
							TAG_DONE, NULL);
		GT_SetGadgetAttrs(SndListWinGadgets[SNDLISTWINGAD_LIST],
							SndListWin,NULL,
							GTLV_Labels, &SoundsList,
							TAG_DONE, NULL);
		GT_SetGadgetAttrs(GfxListWinGadgets[GFXLISTWINGAD_LIST],
							GfxListWin,NULL,
							GTLV_Labels, &GfxList,
							TAG_DONE, NULL);
		RemExtension(ProjectName,".gld");
		return(TRUE);
	} else {
		ClearProject();
		return(FALSE);
	}
}


//*** Selezione del nome del project.
//*** Restituisce FALSE se non è stato selezionato alcun nome.

int SelectPrjName() {

/*
	if(AslRequestTags(FileReq, 	ASL_FuncFlags,FILF_SAVE|FILF_NEWIDCMP,
								ASL_Hail,"Save Project As",
								ASL_Window,MainWin,
								ASL_Dir,(long)ProjectDir,
								ASL_File,(long)ProjectName,
								TAG_DONE, NULL)) {
		strcpy(ProjectDir, (char *)FileReq->rf_Dir);
		strcpy(ProjectName, (char *)FileReq->rf_File);
*/
	strcpy(filename, ProjectName);
	if(rtFileRequest(PrjFileReq, filename, "Save Project As", TAG_END,NULL)) {
		strcpy(ProjectDir, PrjFileReq->Dir);
		strcpy(ProjectName, filename);

		printf("prj name=%ls|\n",ProjectName);
		NamedPrj_fl = TRUE;
	}

	return(NamedPrj_fl);
}


//*** Salva il project (se modificato)
//*** e la mappa correntemente in edit (se modificata)

void SaveProject() {

	if(!NamedPrj_fl)	SelectPrjName();

	if(ModifiedPrj_fl) 			WriteMainGLD();

	if(ModifiedGfx_fl)			WriteGfxGLD();

	if(ModifiedTextList_fl)		WriteTexturesGLD();

	if(ModifiedObjList_fl)		WriteObjectsGLD();

	if(ModifiedSoundList_fl)	WriteSoundsGLD();

	if(ModifiedMap_fl && (CurrentLevel != NULL)) {
		OptimizeMap();
		ArrangeTextureList();
		ArrangeObjectsList();
		ArrangeSoundsList();
		CheckEffectsList();
		WriteMapGLD(CurrentLevel);
	}

	ModifiedPrj_fl = FALSE;
	ModifiedMap_fl = FALSE;
	ModifiedTextList_fl=FALSE;
	ModifiedObjList_fl=FALSE;
	ModifiedSoundList_fl=FALSE;
	ModifiedGfx_fl = FALSE;

	ShowMessage("Project saved.",0);
}




//*** Inizializza un nuovo progetto

void InitNewProject() {

	ClearProject();

	OpenProjectWindow();

	EditPrj_fl = TRUE;
	ModifiedPrj_fl = TRUE;
	ModifiedTextList_fl = TRUE;
	ModifiedObjList_fl = TRUE;
	ModifiedSoundList_fl = TRUE;
	ModifiedGfx_fl = TRUE;

	OpenTexturesWindow();
}



//------------------------------------------------------------------------------

//*** Processa i menu.
// Se ritorna con un valore != 0 vuol dire che è stato selezionato l'item quit.

int ProcessMenu(UWORD imsgCode) {

	ULONG	quit=FALSE;
    ULONG	menu, item, sub;

	while(imsgCode!=MENUNULL) {
		MItem=ItemAddress(myMenu, imsgCode);
		menu=MENUNUM(imsgCode);
		item=ITEMNUM(imsgCode);
		sub=SUBNUM(imsgCode);

		switch(menu) {

			case MENU_PROJECT:
				switch(item) {
					case ITEM_PROJECT_NEW:
						if(EditPrj_fl && ModifiedPrj_fl) {
							if(ShowMessage("Current Project modified !",1)) {
								InitNewProject();
							}
						} else {
							InitNewProject();
						}
						break;

					case ITEM_PROJECT_OPEN:
						if(OpenProject())
							OpenProjectWindow();
						break;

					case ITEM_PROJECT_SAVE:
						if(EditPrj_fl) {
							SaveProject();
						} else {
							ShowMessage("No project loaded!",0);
						}
						break;

					case ITEM_PROJECT_SAVEAS:
						if(EditPrj_fl) {
							SelectPrjName();
							SaveProject();
						} else {
							ShowMessage("No project loaded!",0);
						}
						break;

					case ITEM_PROJECT_INFOS:
						ShowInfos();
						break;

					case ITEM_PROJECT_ABOUT:
						ShowAbout();
						break;

					case ITEM_PROJECT_QUIT:
						if(ModifiedPrj_fl || ModifiedMap_fl) {
							if(ShowMessage("Project has been changed.\nQuit anyway ?",1))	quit=TRUE;
						} else {
							if(ShowMessage("Quit program ?",1))	quit=TRUE;
						}
						break;
				}
				break;

			case MENU_EDIT:
				switch(item) {
					case ITEM_EDIT_COPY:
						break;
				}
				break;

			case MENU_WINDOW:
				switch(item) {
					case ITEM_WINDOW_PROJECT:
						if(EditPrj_fl) {
							OpenProjectWindow();
						} else {
							ShowMessage("No project loaded!",0);
						}
						break;

					case ITEM_WINDOW_GLOBAL:
						break;

					case ITEM_WINDOW_LEVEL:
						if(EditPrj_fl) {
							OpenLevelWindow();
						} else {
							ShowMessage("No project loaded!",0);
						}
						break;

					case ITEM_WINDOW_MAP:
						if(EditPrj_fl) {
							OpenMapWindow();
							MapWinDim();
							DrawMap();
						} else {
							ShowMessage("No project loaded!",0);
						}
						break;

					case ITEM_WINDOW_BLOCK:
						if(EditPrj_fl) {
							OpenBlockWindow();
						} else {
							ShowMessage("No project loaded!",0);
						}
						break;

					case ITEM_WINDOW_TEXTURES:
						if(EditPrj_fl) {
							OpenTexturesWindow();
						} else {
							ShowMessage("No project loaded!",0);
						}
						break;

					case ITEM_WINDOW_OBJECTS:
						if(EditPrj_fl) {
							OpenObjListWindow();
						} else {
							ShowMessage("No project loaded!",0);
						}
						break;

					case ITEM_WINDOW_EFFECTS:
						if(EditPrj_fl) {
							OpenEffectsWindow();
						} else {
							ShowMessage("No project loaded!",0);
						}
						break;

					case ITEM_WINDOW_SOUNDS:
						if(EditPrj_fl) {
							OpenSndListWindow();
						} else {
							ShowMessage("No project loaded!",0);
						}
						break;

					case ITEM_WINDOW_GFX:
						if(EditPrj_fl) {
							OpenGfxListWindow();
						} else {
							ShowMessage("No project loaded!",0);
						}
						break;

					case ITEM_WINDOW_TOOLS:
						if(EditPrj_fl) {
							OpenToolsWindow();
						} else {
							ShowMessage("No project loaded!",0);
						}
						break;
				}
				break;

			case MENU_OPTIONS:
				switch(item) {
					case ITEM_OPTIONS_SCREENTYPE:
						break;

					case ITEM_OPTIONS_DIRS:
						TurnOffMenu();
						OpenDirsWindow();
						TurnOnMenu();
						break;

					case ITEM_OPTIONS_SHOWWARN:
						ShowWarns_fl=!ShowWarns_fl;
						break;

					case ITEM_OPTIONS_SHOWMAPOBJ:
						ShowMapObj_fl=!ShowMapObj_fl;
						if(DrawWhat!=2) DrawMap();
						break;

					case ITEM_OPTIONS_CALCPALETTE:
						break;

					case ITEM_OPTIONS_GRID:
						if(MapGridType!=sub) {
							MapGridType = sub;
							DrawMap();
						}
						break;
				}
				break;
		}

		imsgCode = MItem->NextSelect;
	}

	return(quit);
}



//*** Processa i gadget della finestra Block

void ProcessBlockWinGad(struct Gadget *gad, UWORD imsgCode) {

	long	i;

	switch(gad->GadgetID) {
		case BLOCKWINGAD_FLOORH_SLIDE:
			FloorHeight = (imsgCode-8192);
			GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_FLOORH_NUM],
								BlockWin, NULL,
								GTIN_Number, FloorHeight,
								TAG_DONE,0);
			break;
		case BLOCKWINGAD_FLOORH_NUM:
			FloorHeight = (((struct StringInfo *)BlockWinGadgets[BLOCKWINGAD_FLOORH_NUM]->SpecialInfo)->LongInt);
			GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_FLOORH_SLIDE],
								BlockWin, NULL,
								GTSL_Level, FloorHeight + 8192,
								TAG_DONE,0);
			break;

		case BLOCKWINGAD_CEILH_SLIDE:
			CeilHeight = (imsgCode-8192);
			GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_CEILH_NUM],
								BlockWin, NULL,
								GTIN_Number, CeilHeight,
								TAG_DONE,0);
			break;
		case BLOCKWINGAD_CEILH_NUM:
			CeilHeight = (((struct StringInfo *)BlockWinGadgets[BLOCKWINGAD_CEILH_NUM]->SpecialInfo)->LongInt);
			GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_CEILH_SLIDE],
								BlockWin, NULL,
								GTSL_Level, CeilHeight + 8192,
								TAG_DONE,0);
			break;

		case BLOCKWINGAD_FOG:
			FogLighting = (gad->Flags & SELECTED) ? 1 : 0;
			break;

		case BLOCKWINGAD_ILLUM_SLIDE:
			Illumination = (imsgCode-128);
			GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_ILLUM_NUM],
								BlockWin, NULL,
								GTIN_Number, Illumination,
								TAG_DONE,0);
			break;
		case BLOCKWINGAD_ILLUM_NUM:
			Illumination = (((struct StringInfo *)BlockWinGadgets[BLOCKWINGAD_ILLUM_NUM]->SpecialInfo)->LongInt);
			GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_ILLUM_SLIDE],
								BlockWin, NULL,
								GTSL_Level, Illumination + 128,
								TAG_DONE,0);
			break;

		case BLOCKWINGAD_EFFECT:
			EffectSelect = 1;
			break;

		case BLOCKWINGAD_TRIGGER:
			TriggerSelect = 1;
			break;

		case BLOCKWINGAD_TRIGGER2:
			TriggerSelect = 2;
			break;

		case BLOCKWINGAD_TYPE:
			GT_GetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_TYPE],BlockWin, NULL, GTCY_Active,&i, TAG_DONE,0);
			BlockType = (WORD)i;
			break;

		case BLOCKWINGAD_ENEMYBLOCKER:
			EnemyBlocker = (gad->Flags & SELECTED) ? 8 : 0;
			break;

		case BLOCKWINGAD_FLOORTEXT:
		case BLOCKWINGAD_CEILTEXT:
		case BLOCKWINGAD_E1_UPTEXT:
		case BLOCKWINGAD_E1_NORMTEXT:
		case BLOCKWINGAD_E1_LOWTEXT:
		case BLOCKWINGAD_E2_UPTEXT:
		case BLOCKWINGAD_E2_NORMTEXT:
		case BLOCKWINGAD_E2_LOWTEXT:
		case BLOCKWINGAD_E3_UPTEXT:
		case BLOCKWINGAD_E3_NORMTEXT:
		case BLOCKWINGAD_E3_LOWTEXT:
		case BLOCKWINGAD_E4_UPTEXT:
		case BLOCKWINGAD_E4_NORMTEXT:
		case BLOCKWINGAD_E4_LOWTEXT:
			TextureSelect = gad->GadgetID;
			break;

		case BLOCKWINGAD_SKYCEIL:
			SkyCeil = !SkyCeil;
			break;

		case BLOCKWINGAD_E1_UNPEGUP:
			UnpeggedUpE1 = (gad->Flags & SELECTED) ? 1 : 0;
			break;
		case BLOCKWINGAD_E1_UNPEGLOW:
			UnpeggedLowE1 = (gad->Flags & SELECTED) ? 2 : 0;
			break;

		case BLOCKWINGAD_E2_UNPEGUP:
			UnpeggedUpE2 = (gad->Flags & SELECTED) ? 1 : 0;
			break;
		case BLOCKWINGAD_E2_UNPEGLOW:
			UnpeggedLowE2 = (gad->Flags & SELECTED) ? 2 : 0;
			break;

		case BLOCKWINGAD_E3_UNPEGUP:
			UnpeggedUpE3 = (gad->Flags & SELECTED) ? 1 : 0;
			break;
		case BLOCKWINGAD_E3_UNPEGLOW:
			UnpeggedLowE3 = (gad->Flags & SELECTED) ? 2 : 0;
			break;

		case BLOCKWINGAD_E4_UNPEGUP:
			UnpeggedUpE4 = (gad->Flags & SELECTED) ? 1 : 0;
			break;
		case BLOCKWINGAD_E4_UNPEGLOW:
			UnpeggedLowE4 = (gad->Flags & SELECTED) ? 2 : 0;
			break;

		case BLOCKWINGAD_E1_SWITCH:
			SwitchE1 = (gad->Flags & SELECTED) ? 16 : 0;
			break;
		case BLOCKWINGAD_E2_SWITCH:
			SwitchE2 = (gad->Flags & SELECTED) ? 32 : 0;
			break;
		case BLOCKWINGAD_E3_SWITCH:
			SwitchE3 = (gad->Flags & SELECTED) ? 64 : 0;
			break;
		case BLOCKWINGAD_E4_SWITCH:
			SwitchE4 = (gad->Flags & SELECTED) ? 128 : 0;
			break;

		case BLOCKWINGAD_SOLIDWALL:
			SolidWall_fl = !SolidWall_fl;
			SetMapWinTitle();
			break;

		case BLOCKWINGAD_ACCEPT:
			AcceptBlock();
			CloseBlockWindow();
			DrawWhat=1;
			break;

		case BLOCKWINGAD_MODIFY:
			ModifyBlock();
			DrawWhat=1;
			break;
	}

	if(TextureSelect) {
		OpenTexturesWindow();
		TurnOffIDCMP(0xffffffff ^ TexturesWinSigBit);
	}

	if(EffectSelect || TriggerSelect) {
		OpenEffectsWindow();
		TurnOffIDCMP(0xffffffff ^ EffectsWinSigBit);
	}
}



//*** Processa i gadget della finestra Tools

void ProcessToolsWinGad(ULONG GadgetID, UWORD imsgCode, UWORD MouseY) {

	UWORD	oldgadpos;

	OldSelectedTool = SelectedTool;
	OldToolType = ToolType;

	//*** Deselect previous tool gadget

	oldgadpos = RemoveGadget(ToolsWin,ToolsWinGadgets[SelectedTool]);
	switch(SelectedTool) {
		case TOOLSWINGAD_DRAW:
			ToolsWinGadgets[SelectedTool]->GadgetRender = (APTR)&DrawToolImage;
			break;
		case TOOLSWINGAD_LINE:
			ToolsWinGadgets[SelectedTool]->GadgetRender = (APTR)&LineToolImage;
			break;
		case TOOLSWINGAD_BOX:
			ToolsWinGadgets[SelectedTool]->GadgetRender = (APTR)&BoxToolImage;
			break;
		case TOOLSWINGAD_FILL:
			ToolsWinGadgets[SelectedTool]->GadgetRender = (APTR)&FillToolImage;
			break;
		case TOOLSWINGAD_UNDO:
			ToolsWinGadgets[SelectedTool]->GadgetRender = (APTR)&UndoToolImage;
			break;
		case TOOLSWINGAD_PICK:
			ToolsWinGadgets[SelectedTool]->GadgetRender = (APTR)&PickToolImage;
			break;
		case TOOLSWINGAD_OBJ:
			ToolsWinGadgets[SelectedTool]->GadgetRender = (APTR)&ObjToolImage;
			break;
	}
	AddGadget(ToolsWin,ToolsWinGadgets[SelectedTool],oldgadpos);
	RefreshGList(ToolsWinGadgets[SelectedTool],ToolsWin,NULL,1);

	//*** Select new tool gadget

	ToolType=0;
	oldgadpos = RemoveGadget(ToolsWin,ToolsWinGadgets[GadgetID]);
	switch(GadgetID) {
		case TOOLSWINGAD_DRAW:
			ToolsWinGadgets[GadgetID]->GadgetRender = (APTR)&SelDrawToolImage;
			DrawWhat=1;
			break;
		case TOOLSWINGAD_LINE:
			ToolsWinGadgets[GadgetID]->GadgetRender = (APTR)&SelLineToolImage;
			DrawWhat=1;
			break;
		case TOOLSWINGAD_BOX:
			if(MouseY<=16) {
				ToolsWinGadgets[GadgetID]->GadgetRender = (APTR)&SelBoxToolImage;
			} else {
				ToolsWinGadgets[GadgetID]->GadgetRender = (APTR)&SelFilledBoxToolImage;
				ToolType=1;
			}
			DrawWhat=1;
			break;
		case TOOLSWINGAD_FILL:
			ToolsWinGadgets[GadgetID]->GadgetRender = (APTR)&SelFillToolImage;
			DrawWhat=1;
			break;
		case TOOLSWINGAD_UNDO:
			ToolsWinGadgets[GadgetID]->GadgetRender = (APTR)&SelUndoToolImage;
			DrawWhat=1;
			break;
		case TOOLSWINGAD_PICK:
			ToolsWinGadgets[GadgetID]->GadgetRender = (APTR)&SelPickToolImage;
			DrawWhat=1;
			break;
		case TOOLSWINGAD_OBJ:
			ToolsWinGadgets[GadgetID]->GadgetRender = (APTR)&SelObjToolImage;
			DrawWhat=2;
			break;
	}
	AddGadget(ToolsWin,ToolsWinGadgets[GadgetID],oldgadpos);
	RefreshGList(ToolsWinGadgets[GadgetID],ToolsWin,NULL,1);

	SelectedTool = GadgetID;
}



//*** Processa i gadget della finestra Map

void ProcessMapWinGad(ULONG GadgetID, UWORD imsgCode) {

	switch(GadgetID) {
		case MAPWINGAD_VSCROLL:
			MapY1Pos=imsgCode;
			MapWinDim();
			DrawMap();
			break;

		case MAPWINGAD_HSCROLL:
			MapX1Pos=imsgCode;
			MapWinDim();
			DrawMap();
			break;

		case MAPWINGAD_ZOOMIN:
			if(MapZoom<12) {
				MapZoom+=2;
				SetMapWinTitle();
				MapWinDim();
				DrawMap();
			}
			break;

		case MAPWINGAD_ZOOMOUT:
			if(MapZoom>4) {
				MapZoom-=2;
				SetMapWinTitle();
				MapWinDim();
				DrawMap();
			}
			break;
	}
}



//*** Elimina tutti gli IDCMP message diretti alle finestre indicate
//*** tramite il parametro winbit.
//*** Ogni bit di winbit corrisponde ad un SigBit

void DiscardWindowInput(ULONG winbit) {

	struct IntuiMessage		*imsg;

	if(winbit & MainWinSigBit)
		while(imsg = GT_GetIMsg(MainWin->UserPort))
			GT_ReplyIMsg(imsg);

	if(winbit & LevelWinSigBit)
		while(imsg = GT_GetIMsg(LevelWin->UserPort))
			GT_ReplyIMsg(imsg);

	if(winbit & TexturesWinSigBit)
		while(imsg = GT_GetIMsg(TexturesWin->UserPort))
			GT_ReplyIMsg(imsg);

	if(winbit & BlockWinSigBit)
		while(imsg = GT_GetIMsg(BlockWin->UserPort))
			GT_ReplyIMsg(imsg);

	if(winbit & ObjListWinSigBit)
		while(imsg = GT_GetIMsg(ObjListWin->UserPort))
			GT_ReplyIMsg(imsg);

	if(winbit & EffectsWinSigBit)
		while(imsg = GT_GetIMsg(EffectsWin->UserPort))
			GT_ReplyIMsg(imsg);

	if(winbit & SndListWinSigBit)
		while(imsg = GT_GetIMsg(SndListWin->UserPort))
			GT_ReplyIMsg(imsg);

	if(winbit & GfxListWinSigBit)
		while(imsg = GT_GetIMsg(GfxListWin->UserPort))
			GT_ReplyIMsg(imsg);

	if(winbit & MapWinSigBit)
		while(imsg = GT_GetIMsg(MapWin->UserPort))
			GT_ReplyIMsg(imsg);

	if(winbit & ToolsWinSigBit)
		while(imsg = GT_GetIMsg(ToolsWin->UserPort))
			GT_ReplyIMsg(imsg);

}




//*** Programma principale

void main()
{
	int		cont;
	int		i,j;
	int		drawflag;
	short	ox,oy;

	ULONG	signals;
	ULONG	imsgClass;
	UWORD	imsgCode;
	ULONG	seconds,micros;

	struct Gadget *gad;

	struct MapObject	*mapobj;

	struct Process	*myproc;
	APTR			oldwinptr;



	myproc=(struct Process *)FindTask(NULL);
	oldwinptr=myproc->pr_WindowPtr;

	if(GetPreferences()) exit(0);

	//*** Aggiusta lista effetti disponibili
	EngineFx[0].fx_node.ln_Pred = (struct Node *)&(FxList.lh_Head);
	EngineFx[FXNUMBER-1].fx_node.ln_Succ = (struct Node *)&(FxList.lh_Tail);

	if(SetUpAll()) CleanUp();

	myproc->pr_WindowPtr = MainWin;		// Setta il pun. alla window del task


	drawflag=FALSE;
	seconds=micros=0;
	ActiveWindow = 0xffffffff;	// Attiva per l'input tutte le finestre
	cont=TRUE;

	while(cont && !error) {

		signals = Wait(MainWinSigBit | TexturesWinSigBit | BlockWinSigBit |
						ObjListWinSigBit | EffectsWinSigBit | MapWinSigBit |
						ToolsWinSigBit | MapObjWinSigBit | SndListWinSigBit |
						GfxListWinSigBit | LevelWinSigBit);

		if(signals & MainWinSigBit) {
			while(!error && cont && (imsg = GT_GetIMsg(MainWin->UserPort))) {
				imsgClass = imsg->Class;
				imsgCode = imsg->Code;

				GT_ReplyIMsg(imsg);

				if(ActiveWindow & MainWinSigBit) {
					switch(imsgClass) {
						case IDCMP_MENUPICK:
							if(ProcessMenu(imsgCode)) cont=FALSE;
							break;
					}
				}
			}
		}
		else if(signals & LevelWinSigBit) {
			while(!error && cont && (imsg = GT_GetIMsg(LevelWin->UserPort))) {
				imsgClass = imsg->Class;
				imsgCode = imsg->Code;

				gad = (struct Gadget *)imsg->IAddress;

				GT_ReplyIMsg(imsg);

				if(ActiveWindow & LevelWinSigBit) {
					switch(imsgClass) {
						case IDCMP_CLOSEWINDOW:
							CloseLevelWindow();
							break;
						case IDCMP_GADGETUP:
							switch(gad->GadgetID) {
								case LEVELWINGAD_LOADPIC:
									GfxSelectWin = LevelWin;
									GfxSelect = gad->GadgetID;
									OpenGfxListWindow();
									TurnOffIDCMP(0xffffffff ^ GfxListWinSigBit);
									break;
								case LEVELWINGAD_MOD:
									SoundSelectWin = LevelWin;
									SoundSelect = gad->GadgetID;
									OpenSndListWindow();
									TurnOffIDCMP(0xffffffff ^ SndListWinSigBit);
									break;
							}
							break;
						case IDCMP_MENUPICK:
							if(ProcessMenu(imsgCode)) cont=FALSE;
							break;
					}
				}
				if(!LevelWin) break;
			}
		}
		else if(signals & TexturesWinSigBit) {
			while(!error && cont && (imsg = GT_GetIMsg(TexturesWin->UserPort))) {
				imsgClass = imsg->Class;
				imsgCode = imsg->Code;
				seconds = imsg->Seconds;
				micros = imsg->Micros;

				gad = (struct Gadget *)imsg->IAddress;

				GT_ReplyIMsg(imsg);

				if(ActiveWindow & TexturesWinSigBit) {
					switch(imsgClass) {
						case IDCMP_CLOSEWINDOW:
							if(TextureSelect) TurnOnIDCMP(0xffffffff ^ TexturesWinSigBit);
							TextureSelect=FALSE;
							CloseTexturesWindow();
							break;
						case IDCMP_GADGETUP:
							switch(gad->GadgetID) {
								case TEXTWINGAD_LIST:		ProcessTextureList(imsgCode, seconds, micros); break;
								case TEXTWINGAD_ADD:		AddNewTexture(0); break;
								case TEXTWINGAD_ADDANIM:	AddNewTexture(1); break;
								case TEXTWINGAD_ADDSWITCH:	AddSwitchTexture(); break;
								case TEXTWINGAD_MODIFY:		ModifyTexture(); break;
								case TEXTWINGAD_REMOVE:		RemoveTexture(SelectedTexture); break;
								case TEXTWINGAD_SHOW:		ShowText_fl=!ShowText_fl; break;
							}
							break;
						case IDCMP_MENUPICK:
							if(ProcessMenu(imsgCode)) cont=FALSE;
							break;
					}
				}
				if(!TexturesWin) break;
			}
		}
		else if(signals & ObjListWinSigBit) {
			while(!error && cont && (imsg = GT_GetIMsg(ObjListWin->UserPort))) {
				imsgClass = imsg->Class;
				imsgCode = imsg->Code;
				seconds = imsg->Seconds;
				micros = imsg->Micros;

				gad = (struct Gadget *)imsg->IAddress;

				GT_ReplyIMsg(imsg);

				if(ActiveWindow & ObjListWinSigBit) {
					switch(imsgClass) {
						case IDCMP_CLOSEWINDOW:
							CloseObjListWindow();
							break;
						case IDCMP_GADGETUP:
							switch(gad->GadgetID) {
								case OBJLISTWINGAD_LIST:	ProcessObjList(imsgCode, seconds, micros);	break;
								case OBJLISTWINGAD_ADD:		OpenObjectsWindow(NULL,1); break;
								case OBJLISTWINGAD_RELOAD:	if(SelectedObj) OpenObjectsWindow(SelectedObj,1); break;
								case OBJLISTWINGAD_MODIFY:	if(SelectedObj) OpenObjectsWindow(SelectedObj,0); break;
								case OBJLISTWINGAD_REMOVE:	if(SelectedObj) RemoveObject(SelectedObj); break;
							}
							if(DrawWhat==2) ProcessToolsWinGad(TOOLSWINGAD_OBJ, 0, 0);
							break;
						case IDCMP_MENUPICK:
							if(ProcessMenu(imsgCode)) cont=FALSE;
							break;
					}
				}
				if(!ObjListWin) break;
			}
		}
		else if(signals & SndListWinSigBit) {
			while(!error && cont && (imsg = GT_GetIMsg(SndListWin->UserPort))) {
				imsgClass = imsg->Class;
				imsgCode = imsg->Code;
				seconds = imsg->Seconds;
				micros = imsg->Micros;

				gad = (struct Gadget *)imsg->IAddress;

				GT_ReplyIMsg(imsg);

				if(ActiveWindow & SndListWinSigBit) {
					switch(imsgClass) {
						case IDCMP_CLOSEWINDOW:
							if(SoundSelect) TurnOnIDCMP(0xffffffff ^ SndListWinSigBit);
							SoundSelect=FALSE;
							CloseSndListWindow();
							break;
						case IDCMP_GADGETUP:
							switch(gad->GadgetID) {
								case SNDLISTWINGAD_LIST:	ProcessSndList(imsgCode, seconds, micros);	break;
								case SNDLISTWINGAD_ADD:		OpenSoundsWindow(NULL); break;
								case SNDLISTWINGAD_MODIFY:	if(SelectedSound) OpenSoundsWindow(SelectedSound); break;
								case SNDLISTWINGAD_REMOVE:	if(SelectedSound) RemoveSound(SelectedSound); break;
							}
							break;
						case IDCMP_MENUPICK:
							if(ProcessMenu(imsgCode)) cont=FALSE;
							break;
					}
				}
				if(!SndListWin) break;
			}
		}
		else if(signals & GfxListWinSigBit) {
			while(!error && cont && (imsg = GT_GetIMsg(GfxListWin->UserPort))) {
				imsgClass = imsg->Class;
				imsgCode = imsg->Code;
				seconds = imsg->Seconds;
				micros = imsg->Micros;

				gad = (struct Gadget *)imsg->IAddress;

				GT_ReplyIMsg(imsg);

				if(ActiveWindow & GfxListWinSigBit) {
					switch(imsgClass) {
						case IDCMP_CLOSEWINDOW:
							if(GfxSelect) TurnOnIDCMP(0xffffffff ^ GfxListWinSigBit);
							GfxSelect=FALSE;
							CloseGfxListWindow();
							break;
						case IDCMP_GADGETUP:
							switch(gad->GadgetID) {
								case GFXLISTWINGAD_LIST:	ProcessGfxList(imsgCode, seconds, micros);	break;
								case GFXLISTWINGAD_ADD:		AddNewPic(); break;
								case GFXLISTWINGAD_MODIFY:	break;
								case GFXLISTWINGAD_REMOVE:	if(SelectedGfx) RemovePic(SelectedGfx); break;
							}
							break;
						case IDCMP_MENUPICK:
							if(ProcessMenu(imsgCode)) cont=FALSE;
							break;
					}
				}
				if(!GfxListWin) break;
			}
		}
		else if(signals & EffectsWinSigBit) {
			while(!error && cont && (imsg = GT_GetIMsg(EffectsWin->UserPort))) {
				imsgClass = imsg->Class;
				imsgCode = imsg->Code;
				seconds = imsg->Seconds;
				micros = imsg->Micros;

				gad = (struct Gadget *)imsg->IAddress;

				GT_ReplyIMsg(imsg);

				if(ActiveWindow & EffectsWinSigBit) {
					switch(imsgClass) {
						case IDCMP_CLOSEWINDOW:
							if(EffectSelect || TriggerSelect) TurnOnIDCMP(0xffffffff ^ EffectsWinSigBit);
							EffectSelect=FALSE;
							TriggerSelect=FALSE;
							CloseEffectsWindow();
							break;
						case IDCMP_GADGETUP:
							ProcessEffectsWinGad(gad, imsgCode, seconds, micros);
							break;
						case IDCMP_MENUPICK:
							if(ProcessMenu(imsgCode)) cont=FALSE;
							break;
					}
				}
				if(!EffectsWin) break;
			}
		}
		else if(signals & MapObjWinSigBit) {
			while(!error && cont && (imsg = GT_GetIMsg(MapObjWin->UserPort))) {
				imsgClass = imsg->Class;
				imsgCode = imsg->Code;

				gad = (struct Gadget *)imsg->IAddress;

				GT_ReplyIMsg(imsg);

				if(ActiveWindow & MapObjWinSigBit) {
					switch(imsgClass) {
						case IDCMP_CLOSEWINDOW:
							CloseMapObjWindow();
							break;
						case IDCMP_GADGETUP:
							ProcessMapObjWinGad(gad, imsgCode);
							break;
						case IDCMP_MENUPICK:
							if(ProcessMenu(imsgCode)) cont=FALSE;
							break;
					}
				}
				if(!EffectsWin) break;
			}
		}
		else if(signals & BlockWinSigBit) {
			while(!error && cont && (imsg = GT_GetIMsg(BlockWin->UserPort))) {
				imsgClass = imsg->Class;
				imsgCode = imsg->Code;

				gad = (struct Gadget *)imsg->IAddress;

				GT_ReplyIMsg(imsg);

				if(ActiveWindow & BlockWinSigBit) {
					switch(imsgClass) {
						case IDCMP_CLOSEWINDOW:
							CloseBlockWindow();
							break;
						case IDCMP_MOUSEMOVE:
						case IDCMP_GADGETDOWN:
						case IDCMP_GADGETUP:
							ProcessBlockWinGad(gad, imsgCode);
							break;
						case IDCMP_MENUPICK:
							if(ProcessMenu(imsgCode)) cont=FALSE;
							break;
					}
				}
				if(!BlockWin) break;
			}
		}
		else if(signals & ToolsWinSigBit) {
			while(!error && cont && (imsg = GT_GetIMsg(ToolsWin->UserPort))) {
				imsgClass = imsg->Class;
				imsgCode = imsg->Code;

				gad = (struct Gadget *)imsg->IAddress;

				GT_ReplyIMsg(imsg);

				if(ActiveWindow & ToolsWinSigBit) {
					switch(imsgClass) {
						case IDCMP_ACTIVEWINDOW:
							break;
						case IDCMP_INACTIVEWINDOW:
							break;
						case IDCMP_CLOSEWINDOW:
							CloseToolsWindow();
							break;
						case IDCMP_GADGETDOWN:
						case IDCMP_GADGETUP:
							ProcessToolsWinGad(gad->GadgetID, imsgCode, imsg->MouseY);
							if(MapWin)
								ActivateWindow(MapWin);
							else
								OpenMapWindow();
							break;
						case IDCMP_MENUPICK:
							if(ProcessMenu(imsgCode)) cont=FALSE;
							break;
					}
				}
				if(!ToolsWin) break;
			}
		}
		else if(signals & MapWinSigBit) {
			while(!error && cont && (imsg = GT_GetIMsg(MapWin->UserPort))) {
				imsgClass = imsg->Class;
				imsgCode = imsg->Code;
				seconds = imsg->Seconds;
				micros = imsg->Micros;

				gad = (struct Gadget *)imsg->IAddress;

				GT_ReplyIMsg(imsg);

				if(ActiveWindow & MapWinSigBit) {
					switch(imsgClass) {
						case IDCMP_ACTIVEWINDOW:
							MouseX=MapWin->MouseX;
							MouseY=MapWin->MouseY;
							MouseMapPos();
							SetMapWinTitle();
							drawflag=FALSE;
							if(imsg = GT_GetIMsg(MapWin->UserPort)) {
								imsgClass = imsg->Class;
								imsgCode = imsg->Code;
								GT_ReplyIMsg(imsg);
							}
							break;
						case IDCMP_INACTIVEWINDOW:
							SetWindowTitles(MapWin,(UBYTE *)"Map",(UBYTE *)~0);
							drawflag=FALSE;
							break;
						case IDCMP_CLOSEWINDOW:
							CloseMapWindow();
							break;
						case IDCMP_MOUSEMOVE:
							ox=MapXPos;
							oy=MapYPos;
							MouseX=imsg->MouseX;
							MouseY=imsg->MouseY;
							MouseMapPos();
							SetMapWinTitle();
							if(drawflag) {
								switch(SelectedTool) {
									case TOOLSWINGAD_DRAW:
										PlotBlock(MapXPos,MapYPos,CurrBlockCode);
										break;
									case TOOLSWINGAD_LINE:
										if(MapXPos>=0 && MapYPos>=0) {
											ShowLine(X1DrawTool,Y1DrawTool,ox,oy);
											ShowLine(X1DrawTool,Y1DrawTool,MapXPos,MapYPos);
										} else {
											MapXPos=ox;
											MapYPos=oy;
										}
										break;
									case TOOLSWINGAD_BOX:
										if(MapXPos>=0 && MapYPos>=0) {
											ShowBox(X1DrawTool,Y1DrawTool,ox,oy);
											ShowBox(X1DrawTool,Y1DrawTool,MapXPos,MapYPos);
										} else {
											MapXPos=ox;
											MapYPos=oy;
										}
										break;
									default:
										break;
								}
							}
							break;
						case IDCMP_MOUSEBUTTONS:
							if(imsgCode==SELECTDOWN) {
								switch(DrawWhat) {
									case 1:		// Block
										switch(SelectedTool) {
											case TOOLSWINGAD_DRAW:
												drawflag=TRUE;
												PlotBlock(MapXPos,MapYPos,CurrBlockCode);
												break;
											case TOOLSWINGAD_LINE:
												if(MapXPos>=0 && MapYPos>=0) {
													X1DrawTool = MapXPos;
													Y1DrawTool = MapYPos;
													drawflag=TRUE;
													ShowLine(X1DrawTool,Y1DrawTool,MapXPos,MapYPos);
												}
												break;
											case TOOLSWINGAD_BOX:
												if(MapXPos>=0 && MapYPos>=0) {
													X1DrawTool = MapXPos;
													Y1DrawTool = MapYPos;
													drawflag=TRUE;
													ShowBox(X1DrawTool,Y1DrawTool,MapXPos,MapYPos);
												}
												break;
											case TOOLSWINGAD_FILL:
												break;
											case TOOLSWINGAD_PICK:
												PickBlock(MapXPos,MapYPos);
												if(BlockWin) {
													RefreshGadgets(BlockWinGadgets[0],BlockWin,NULL);
													GT_RefreshWindow(BlockWin,NULL);
												}
												ProcessToolsWinGad(ToolsWinGadgets[OldSelectedTool]->GadgetID, 0, (OldToolType ? 17 : 0));
												break;
											default:
												break;
										}
										break;

/*									case 2:		// Player
										Player1StartX = (MapXPos<<6)+32;
										Player1StartY = (MapYPos<<6)+32;
										ModifiedMap_fl=TRUE;
										DrawWhat = 1;
										break;
*/
									case 2:		// Object
										if(MapXPos>=0 && MapYPos>=0) {
											if(mapobj=CheckMapObject(MapXPos,MapYPos)) {
												if((SelectedMapObj==mapobj) && DoubleClick(MapObjStartSecs, MapObjStartMicros, seconds, micros)) {
													OpenMapObjWindow(mapobj);
													MapObjStartSecs=0;
													MapObjStartMicros=0;
												} else {
													SelectMapObject(mapobj);
													X1DrawTool = MapXPos;
													Y1DrawTool = MapYPos;
													drawflag=TRUE;
													MapObjStartSecs=seconds;
													MapObjStartMicros=micros;
													CurrObjPun=mapobj->Object;
												}
											} else {
												if(CurrObjPun) {
													if(AddMapObject(MapXPos,MapYPos,CurrObjPun))
														PlotObject(MapXPos,MapYPos,CurrObjPun);
												} else {
													ShowMessage("You must select an object !",0);
													OpenObjListWindow();
												}
											}
										}
										break;

									default:
										break;
								}

							} else {

								if(drawflag) {
									switch(DrawWhat) {
										case 1:		// Block
											switch(SelectedTool) {
												case TOOLSWINGAD_LINE:
													if(MapXPos>=0 && MapYPos>=0) {
														DrawBlockLine(X1DrawTool,Y1DrawTool,MapXPos,MapYPos,CurrBlockCode);
													}
													break;
												case TOOLSWINGAD_BOX:
													if(MapXPos>=0 && MapYPos>=0) {
														DrawBlockBox(X1DrawTool,Y1DrawTool,MapXPos,MapYPos,CurrBlockCode);
													}
													break;
												default:
													break;
											}
											DrawMapObjects();
											break;

										case 2:		// Object
											if(MapXPos>=0 && MapYPos>=0 && (MapXPos!=X1DrawTool || MapYPos!=Y1DrawTool)) {
												MoveMapObject(MapXPos,MapYPos,SelectedMapObj);
											}
											break;
									}
									drawflag=FALSE;
								}
							}
							break;
						case IDCMP_GADGETDOWN:
						case IDCMP_GADGETUP:
							ProcessMapWinGad(gad->GadgetID, imsgCode);
							break;
						case IDCMP_MENUPICK:
							if(ProcessMenu(imsgCode)) cont=FALSE;
							break;
					}
				}
				if(!MapWin) break;
			}
		}
	}

	if(error) ShowErrorMessage(error, NULL);

	// Risponde a tutti i messaggi eventualmente rimasti in sospeso

	while(imsg = GT_GetIMsg(MainWin->UserPort)) {
		imsgClass = imsg->Class;
		imsgCode = imsg->Code;
		GT_ReplyIMsg(imsg);
	}

	// Dealloca tutte le risorse usate

	myproc->pr_WindowPtr = oldwinptr;	// Ripristina il puntatore originale

	CleanUp();
}


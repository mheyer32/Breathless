//*****************************************************************************
//***
//***		SetUp.c
//***
//***	Routines di setup e cleanup per MapEditor3d.c
//***
//***
//***
//*****************************************************************************

#include	"MapEditor3d.h"
#include	"Definitions.h"

#include <proto/asl.h>

#include <stdio.h>
#include <stdlib.h>
//*****************************************************************************



UWORD screenpens[] = { 0xffff };

struct NewScreen	NScr1 = {
	0,0,						// LeftEdge,TopEdge
	MAINSCR_W,MAINSCR_H,3,		// Width,Height,Depth
	1,2,						// Pens
	HIRES,						// ViewMode
	CUSTOMSCREEN,				// Type
	NULL,						// Font
	(STRPTR)"Map Editor 3d",	// Title
	NULL,						// Gadgets
	NULL						// Bitmap
};

struct NewScreen	NScr2 = {
	0,0,						// LeftEdge,TopEdge
	GRAPHSCR_W,GRAPHSCR_H,8,	// Width,Height,Depth
	1,2	,						// Pens
	NULL	,					// ViewMode
	CUSTOMSCREEN|SCREENQUIET|SCREENBEHIND,			// Type
	NULL,						// Font
	(STRPTR)"Textures",			// Title
	NULL,						// Gadgets
	NULL						// Bitmap
};

ULONG MainPalette[26] = {
	0x00080000,	/* Record Header */
	0x93333333,0x8CCCCCCC,0x93333333,
	0x00000000,0x00000000,0x00000000,
	0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
	0x2AAAAAAA,0x74444444,0xBBBBBBBB,
	0xFFFFFFFF,0xFFFFFFFF,0x00000000,
	0xFFFFFFFF,0x00000000,0x00000000,
	0x00000000,0xFFFFFFFF,0xFFFFFFFF,
	0x00000000,0xC8888888,0x00000000,
	0x00000000	/* Terminator */
};


struct NewMenu	NMenu[] = {
	{ NM_TITLE,	(STRPTR)"Project",	 0, 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"New",		(STRPTR)  0, 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Open",	(STRPTR)"O", 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Save", 	(STRPTR)"S", 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Save As",	(STRPTR)"A", 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Informations",	  0, 0, 0, 0,},
	{	NM_ITEM, NM_BARLABEL,0,0,0,0,},
	{	NM_ITEM, (STRPTR)"About",	(STRPTR)  0, 0, 0, 0,},
	{	NM_ITEM, NM_BARLABEL,0,0,0,0,},
	{	NM_ITEM, (STRPTR)"Quit",	(STRPTR)"Q", 0, 0, 0,},

	{ NM_TITLE,	(STRPTR)"Edit",		  0, 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Copy",	 (STRPTR) 0, 0, 0, 0,},

	{ NM_TITLE,	(STRPTR)"Windows",	  (STRPTR)  0, 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Project",	  (STRPTR)  0, 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Global",	  (STRPTR)  0, 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Level",	  (STRPTR)  0, 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Map",		  (STRPTR)"M", 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Block",	  (STRPTR)"B", 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Textures",  (STRPTR)"T", 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Objects",   (STRPTR)  0, 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Effects",   (STRPTR)"E", 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Sounds",    (STRPTR)  0, 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Gfx",		  (STRPTR)"G", 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Tools bar", (STRPTR)  0, 0, 0, 0,},

	{ NM_TITLE,	(STRPTR)"Options",	  0, 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Screen type...",(STRPTR) 0, 0, 0, 0,},
	{	NM_ITEM, (STRPTR)"Directories...",(STRPTR) 0, 0, 0, 0,},
	{	NM_ITEM, NM_BARLABEL,0,0,0,0,},
	{	NM_ITEM, (STRPTR)"Show warnings", (STRPTR) 0, CHECKED|MENUTOGGLE|CHECKIT, 0, 0,},
	{	NM_ITEM, (STRPTR)"Show objects",  (STRPTR) 0, CHECKED|MENUTOGGLE|CHECKIT, 0, 0,},
	{	NM_ITEM, (STRPTR)"Calculate palettes",  (STRPTR) 0, CHECKED|MENUTOGGLE|CHECKIT, 0, 0,},
	{	NM_ITEM, (STRPTR)"Grid",		  (STRPTR) 0, 0, 0, 0,},
	{	  NM_SUB,(STRPTR)"No Grid",		  (STRPTR) 0, CHECKIT,			~(1<<0), 0,},
	{	  NM_SUB,(STRPTR)"Point Grid",	  (STRPTR) 0, CHECKED|CHECKIT,	~(1<<1), 0,},
	{	  NM_SUB,(STRPTR)"Line Grid",	  (STRPTR) 0, CHECKIT, 			~(1<<2), 0,},

	{ NM_END, 0, 0, 0, 0, 0},
};





struct IntuiText LevelWinIText[]={
	 1,0, JAM2, 8,10, NULL, (UBYTE *)"Loading picture", &LevelWinIText[1],
	 1,0, JAM2, 8,26, NULL, (UBYTE *)"Protracker MOD", NULL
};



struct IntuiText BlockWinIText[]={
	 1,0, JAM2, 8,82, NULL, (UBYTE *)"Floor Tx.", &BlockWinIText[1],
	 1,0, JAM2, 177,82, NULL, (UBYTE *)"Ceil Tx.", &BlockWinIText[2],

	 1,0, JAM2, 8,51, NULL, (UBYTE *)"Effect", &BlockWinIText[3],
	 1,0, JAM2, 116,51, NULL, (UBYTE *)"Trigger", &BlockWinIText[4],
	 1,0, JAM2, 230,51, NULL, (UBYTE *)"Trigger2", &BlockWinIText[5],

	 1,0, JAM2, 8,110, NULL, (UBYTE *)"Edge1", &BlockWinIText[6],
	 1,0, JAM2, 8,124, NULL, (UBYTE *)"Edge2", &BlockWinIText[7],
	 1,0, JAM2, 8,138, NULL, (UBYTE *)"Edge3", &BlockWinIText[8],
	 1,0, JAM2, 8,152, NULL, (UBYTE *)"Edge4", &BlockWinIText[9],

	 1,0, JAM2,  73,100, NULL, (UBYTE *)"Upper", &BlockWinIText[10],
	 1,0, JAM2, 154,100, NULL, (UBYTE *)"Normal", &BlockWinIText[11],
	 1,0, JAM2, 243,100, NULL, (UBYTE *)"Lower", &BlockWinIText[12],
	 1,0, JAM2, 330,100, NULL, (UBYTE *)"Unpeg", &BlockWinIText[13],
	 1,0, JAM2, 400,100, NULL, (UBYTE *)"Sw", NULL
};


struct IntuiText EffectsWinIText[]={
	 1,0, JAM2, 53,160, NULL, (UBYTE *)"Effect", NULL
};



//*** Array di stringhe per i cycle gadget della finestra Block

char	*BlockTypeArray[] = {	"Normal",
								"-2  Health",
								"-5  Health",
								"-10 Health",
								NULL			};


//*** Array di stringhe per i cycle gadget della finestra Objects

char	*ObjectTypeArray[] = {	"Thing",
								"Player",
								"Enemy",
								"Pick thing",
								"Shot",
								"Explosion",
								NULL			};

char	*AnimTypeArray[] = {	"Directional",
								"None",
								"Simple",
								NULL		};


//*** Array di stringhe per i cycle gadget della finestra Effects

char	*KeysArray[] = {	"None",
							"Green",
							"Yellow",
							"Red",
							"Blue",
							NULL		};


//*** Array di stringhe per i cycle gadget della finestra Sounds

char	*SoundTypeArray[] = {	"Protracker MOD",
								"Global sound",
								"Object sound",
								"Rnd sound",
								NULL			};


//*** Array di stringhe per i cycle gadget della finestra MapObj

char	*HeadingArray[] = {		"East",
								"South-East",
								"South",
								"South-West",
								"West",
								"North-West",
								"North",
								"North-East",
								NULL			};


//*** Gadget per la finestra Tools

struct Gadget ObjToolGadget = {
	(struct Gadget *)NULL,					// Next Gadget
	130,11, 21,12,							// LeftEdge,TopEdge, Width,Height
	GFLG_GADGHCOMP | GFLG_GADGIMAGE,		// Flags
	GACT_IMMEDIATE | GACT_RELVERIFY,		// Activation
	GTYP_BOOLGADGET,						// GadgetType
	(APTR)&ObjToolImage, (APTR)NULL,		// GadgetRender, SelectRender
	(struct IntuiText *)NULL,				// Gadget Text
	NULL, (APTR)NULL,						// MutualExclude, SpecialInfo
	TOOLSWINGAD_OBJ, (APTR)NULL				// GadgetID, UserData
};

struct Gadget PickToolGadget = {
	&ObjToolGadget,							// Next Gadget
	109,11, 21,12,							// LeftEdge,TopEdge, Width,Height
	GFLG_GADGHCOMP | GFLG_GADGIMAGE,		// Flags
	GACT_IMMEDIATE | GACT_RELVERIFY,		// Activation
	GTYP_BOOLGADGET,						// GadgetType
	(APTR)&PickToolImage, (APTR)NULL,		// GadgetRender, SelectRender
	(struct IntuiText *)NULL,				// Gadget Text
	NULL, (APTR)NULL,						// MutualExclude, SpecialInfo
	TOOLSWINGAD_PICK, (APTR)NULL			// GadgetID, UserData
};

struct Gadget UndoToolGadget = {
	&PickToolGadget,						// Next Gadget
	88,11, 21,12,							// LeftEdge,TopEdge, Width,Height
	GFLG_GADGHCOMP | GFLG_GADGIMAGE,		// Flags
	GACT_IMMEDIATE | GACT_RELVERIFY,		// Activation
	GTYP_BOOLGADGET,						// GadgetType
	(APTR)&UndoToolImage, (APTR)NULL,		// GadgetRender, SelectRender
	(struct IntuiText *)NULL,				// Gadget Text
	NULL, (APTR)NULL,						// MutualExclude, SpecialInfo
	TOOLSWINGAD_UNDO, (APTR)NULL			// GadgetID, UserData
};

struct Gadget FillToolGadget = {
	&UndoToolGadget,						// Next Gadget
	67,11, 21,12,							// LeftEdge,TopEdge, Width,Height
	GFLG_GADGHCOMP | GFLG_GADGIMAGE,		// Flags
	GACT_IMMEDIATE | GACT_RELVERIFY,		// Activation
	GTYP_BOOLGADGET,						// GadgetType
	(APTR)&FillToolImage, (APTR)NULL,		// GadgetRender, SelectRender
	(struct IntuiText *)NULL,				// Gadget Text
	NULL, (APTR)NULL,						// MutualExclude, SpecialInfo
	TOOLSWINGAD_FILL, (APTR)NULL			// GadgetID, UserData
};

struct Gadget BoxToolGadget = {
	&FillToolGadget,						// Next Gadget
	46,11, 21,12,							// LeftEdge,TopEdge, Width,Height
	GFLG_GADGHCOMP | GFLG_GADGIMAGE,		// Flags
	GACT_IMMEDIATE | GACT_RELVERIFY,		// Activation
	GTYP_BOOLGADGET,						// GadgetType
	(APTR)&BoxToolImage, (APTR)NULL,		// GadgetRender, SelectRender
	(struct IntuiText *)NULL,				// Gadget Text
	NULL, (APTR)NULL,						// MutualExclude, SpecialInfo
	TOOLSWINGAD_BOX, (APTR)NULL			// GadgetID, UserData
};

struct Gadget LineToolGadget = {
	&BoxToolGadget,							// Next Gadget
	25,11, 21,12,							// LeftEdge,TopEdge, Width,Height
	GFLG_GADGHCOMP | GFLG_GADGIMAGE,		// Flags
	GACT_IMMEDIATE | GACT_RELVERIFY,		// Activation
	GTYP_BOOLGADGET,						// GadgetType
	(APTR)&LineToolImage, (APTR)NULL,		// GadgetRender, SelectRender
	(struct IntuiText *)NULL,				// Gadget Text
	NULL, (APTR)NULL,						// MutualExclude, SpecialInfo
	TOOLSWINGAD_LINE, (APTR)NULL			// GadgetID, UserData
};

struct Gadget DrawToolGadget = {
	&LineToolGadget,						// Next Gadget
	4,11, 21,12,							// LeftEdge,TopEdge, Width,Height
	GFLG_GADGHCOMP | GFLG_GADGIMAGE,		// Flags
	GACT_IMMEDIATE | GACT_RELVERIFY,		// Activation
	GTYP_BOOLGADGET,						// GadgetType
	(APTR)&SelDrawToolImage, (APTR)NULL,	// GadgetRender, SelectRender
	(struct IntuiText *)NULL,				// Gadget Text
	NULL, (APTR)NULL,						// MutualExclude, SpecialInfo
	TOOLSWINGAD_DRAW, (APTR)NULL			// GadgetID, UserData
};

//*****************************************************************************
// Apre e inizializza tutto cio' che viene usato dal programma

int SetUpAll() {

 //*** Open libraries

	IntuitionBase=(struct IntuitionBase *)OpenLibrary((UBYTE *)"intuition.library",37);
	if(!IntuitionBase) {
		printf("Richiesto Amiga OS 2.0 o superiore\n");
		return(1);
	}

	GfxBase=(struct GfxBase *)OpenLibrary((UBYTE *)"graphics.library",36);
	if(!GfxBase) {
		printf("La libreria graphics versione 37 non è presente\n");
		return(1);
	}

	GadToolsBase=(struct Library *)OpenLibrary((UBYTE *)"gadtools.library",37);
	if(!GadToolsBase) {
		printf("La libreria gadtools versione 37 non è presente\n");
		return(1);
	}

	AslBase=(struct Library *)OpenLibrary((UBYTE *)"asl.library",NULL);
	if(!AslBase) {
		printf("La libreria asl non è presente\n");
		return(1);
	}

	ReqToolsBase=(struct Library *)OpenLibrary((UBYTE *)"reqtools.library",38L);
	if(!ReqToolsBase) {
		printf("C'e' bisogno della reqtools.library V38 o successiva!\n");
		return(1);
	}

 //*** Memory allocation

	if(!(GfxBuffer = (UBYTE *)AllocMem(GFXBUFFER_LEN,MEMF_CLEAR))) {
		printf("Poca memoria allocando GfxBuffer\n");
		return(1);
	}

	if(!(MapBuffer = (WORD *)AllocMem(MAP_LEN,MEMF_CLEAR))) {
		printf("Poca memoria allocando MapBuffer\n");
		return(1);
	}

	if(!(ColorTable = (ULONG *)AllocMem(COLORTABLE_LEN,MEMF_CLEAR))) {
		printf("Poca memoria allocando ColorTable\n");
		return(1);
	}


 //*** Init various data and structures

	InitRastPort(&rp);


 //*** Screens

	if(!(GraphScr = OpenScreenTags(&NScr2, SA_Pens,screenpens, SA_ShowTitle,TRUE,TAG_END,0))) {
		printf("Problemi nell'apertura dello schermo grafico\n");
		return(1);
	}
//	ShowTitle(GraphScr,FALSE);

	GraphScrRP = &(GraphScr->RastPort);
	GraphScrVP = &(GraphScr->ViewPort);

	if(!(MainScr = OpenScreenTags(&NScr1, SA_Pens,screenpens,TAG_END,0))) {
		printf("Problemi nell'apertura dello schermo principale\n");
		return(1);
	}

	LoadRGB32(&(MainScr->ViewPort),MainPalette);

	if(!(VInfo=GetVisualInfo(MainScr,TAG_DONE,0))) {
		printf("Problemi con GetVisualInfo\n");
		return(1);
	}

	if(!(DrInfo=GetScreenDrawInfo(MainScr))) {
		printf("Problemi con GetScreenDrawInfo\n");
		return(1);
	}


 //*** GraphWin

    GraphWin = OpenWindowTags(NULL,
						WA_Left,	0,
						WA_Top,		0,
						WA_Width,	GRAPHSCR_W,
						WA_Height,	GRAPHSCR_H,
						WA_Flags,	WFLG_BACKDROP|WFLG_BORDERLESS|WFLG_SMART_REFRESH|WFLG_RMBTRAP,
						WA_IDCMP,	IDCMP_MOUSEBUTTONS,
						WA_Title,	NULL,
						WA_CustomScreen, GraphScr,
						TAG_DONE,0);

	if(!GraphWin) {
		printf("Problemi nell'apertura della finestra GraphWin\n");
		return(1);
	}

	GraphWinSigBit = 1 << GraphWin->UserPort->mp_SigBit;
	OpenedWindow |= GraphWinSigBit;


 //*** Menus

	NewGad.ng_VisualInfo=VInfo;

	myMenu = CreateMenus(NMenu, GTNM_FrontPen, 1, TAG_DONE,0);

	if(!myMenu) {
		printf("Problemi nell'apertura dei menu\n");
		return(1);
	}

	if(!LayoutMenus(myMenu, VInfo, GTMN_NewLookMenus,1, TAG_DONE,0)) {
		printf("Problemi con LayoutMenus\n");
		return(1);
	}


 //*** Main window

    MainWin = OpenWindowTags(NULL,
						WA_Left,	0,
						WA_Top,		0,
						WA_Width,	640,
						WA_Height,	256,
						WA_Flags,	WFLG_BACKDROP|WFLG_BORDERLESS|WFLG_SMART_REFRESH|WFLG_ACTIVATE|WFLG_NEWLOOKMENUS,
						WA_IDCMP,	IDCMP_MENUPICK|IDCMP_MOUSEBUTTONS|IDCMP_GADGETUP|IDCMP_GADGETDOWN|IDCMP_MOUSEMOVE|IDCMP_INTUITICKS,
						WA_Title,	NULL,
					//	WA_Gadgets,	MyGadList,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

	if(!MainWin) {
		printf("Problemi nell'apertura della finestra\n");
		return(1);
	}

	MainWinSigBit = 1 << MainWin->UserPort->mp_SigBit;
	OpenedWindow |= MainWinSigBit;

	if(!SetMenuStrip(MainWin, myMenu)) {
		printf("Problemi con SetMenuStrip\n");
		return(1);
	}

	if(!(FileReq=AllocAslRequest(ASL_FileRequest, NULL))) {
		printf("Problemi con l'allocazione del file requester\n");
		return(1);
	}

	if(!(PrjFileReq=rtAllocRequestA(RT_FILEREQ,NULL))) {
		printf("Problemi con l'allocazione del PrjFileReq\n");
		return(1);
	}

	if(!(TextFileReq=rtAllocRequestA(RT_FILEREQ,NULL))) {
		printf("Problemi con l'allocazione del TextFileReq\n");
		return(1);
	}

	if(!(ObjFileReq=rtAllocRequestA(RT_FILEREQ,NULL))) {
		printf("Problemi con l'allocazione del ObjFileReq\n");
		return(1);
	}

	if(!(SndFileReq=rtAllocRequestA(RT_FILEREQ,NULL))) {
		printf("Problemi con l'allocazione del SndFileReq\n");
		return(1);
	}

	if(!(GfxFileReq=rtAllocRequestA(RT_FILEREQ,NULL))) {
		printf("Problemi con l'allocazione del GfxFileReq\n");
		return(1);
	}

 //**** Crea e aggiusta liste Exec

	NewList(&GLList);
	NewList(&TexturesList);
	NewList(&ObjectsList);
	NewList(&EffectsList);
	NewList(&SoundsList);
	NewList(&GfxList);



 //**** Crea la lista di gadget per la finestra Project

	if(!(PrevGadget=CreateContext(&ProjectWinGadList))) {
		printf("Problemi in CreateContext(&ProjectWinGadList)\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=8;
	NewGad.ng_TopEdge	=85;
	NewGad.ng_Width		=420;
	NewGad.ng_Height	=84;
	NewGad.ng_GadgetID	=PRJWINGAD_LIST;
	NewGad.ng_GadgetText=NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(LISTVIEW_KIND,PrevGadget,&NewGad,
							GTLV_Labels, &GLList,
							GTLV_ShowSelected, NULL,
							TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_LIST]=PrevGadget;

	NewGad.ng_LeftEdge	=138;
	NewGad.ng_TopEdge	=14;
	NewGad.ng_Width		=160;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_PRJNAME;
	NewGad.ng_GadgetText=(UBYTE *)"Project name";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(STRING_KIND,PrevGadget,&NewGad,
							GTST_String, ProjectName,
							GTST_MaxChars, 16,
							STRINGA_Justification, GACT_STRINGCENTER,
							TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_PRJNAME]=PrevGadget;

	NewGad.ng_LeftEdge	=83;
	NewGad.ng_TopEdge	=29;
	NewGad.ng_Width		=270;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_NOTES;
	NewGad.ng_GadgetText=(UBYTE *)"Notes";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(STRING_KIND,PrevGadget,&NewGad,
							GTST_String, ProjectNotes,
							GTST_MaxChars, 32,
							STRINGA_Justification, GACT_STRINGCENTER,
							TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_NOTES]=PrevGadget;

	NewGad.ng_LeftEdge	=85;
	NewGad.ng_TopEdge	=52;
	NewGad.ng_Width		=52;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_PREFIX;
	NewGad.ng_GadgetText=(UBYTE *)"Prefix";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(STRING_KIND,PrevGadget,&NewGad,
							GTST_String, ProjectPrefix,
							GTST_MaxChars, 4,
							TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_PREFIX]=PrevGadget;

	NewGad.ng_LeftEdge	=370;
	NewGad.ng_TopEdge	=52;
	NewGad.ng_Width		=52;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_SOUNDFILENAME;
	NewGad.ng_GadgetText=(UBYTE *)"Sound";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, ProjectSoundFileName,
							GTTX_Border, TRUE,
							TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_SOUNDFILENAME]=PrevGadget;

	NewGad.ng_LeftEdge	=85;
	NewGad.ng_TopEdge	=67;
	NewGad.ng_Width		=52;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_TEXTFILENAME;
	NewGad.ng_GadgetText=(UBYTE *)"Textures";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, ProjectTextFileName,
							GTTX_Border, TRUE,
							TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_TEXTFILENAME]=PrevGadget;

	NewGad.ng_LeftEdge	=230;
	NewGad.ng_TopEdge	=67;
	NewGad.ng_Width		=52;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_OBJFILENAME;
	NewGad.ng_GadgetText=(UBYTE *)"Objects";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, ProjectObjFileName,
							GTTX_Border, TRUE,
							TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_OBJFILENAME]=PrevGadget;

	NewGad.ng_LeftEdge	=370;
	NewGad.ng_TopEdge	=67;
	NewGad.ng_Width		=52;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_GFXFILENAME;
	NewGad.ng_GadgetText=(UBYTE *)"Graphics";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, ProjectGfxFileName,
							GTTX_Border, TRUE,
							TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_GFXFILENAME]=PrevGadget;

	NewGad.ng_LeftEdge	=8;
	NewGad.ng_TopEdge	=171;
	NewGad.ng_Width		=82;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_ADDGAME;
	NewGad.ng_GadgetText=(UBYTE *)"Add game";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_ADDGAME]=PrevGadget;

	NewGad.ng_LeftEdge	=96;
	NewGad.ng_TopEdge	=171;
	NewGad.ng_Width		=82;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_ADDLEVEL;
	NewGad.ng_GadgetText=(UBYTE *)"Add level";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad, GA_DISABLED,TRUE, TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_ADDLEVEL]=PrevGadget;

	NewGad.ng_LeftEdge	=184;
	NewGad.ng_TopEdge	=171;
	NewGad.ng_Width		=46;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_DEL;
	NewGad.ng_GadgetText=(UBYTE *)"Del";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad, GA_DISABLED,TRUE, TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_DEL]=PrevGadget;

	NewGad.ng_LeftEdge	=236;
	NewGad.ng_TopEdge	=171;
	NewGad.ng_Width		=192;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_DESCR;
	NewGad.ng_GadgetText=(UBYTE *)"";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(STRING_KIND,PrevGadget,&NewGad,
							GTST_MaxChars, 20,
							GA_DISABLED,TRUE,
							TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_DESCR]=PrevGadget;

	NewGad.ng_LeftEdge	=8;
	NewGad.ng_TopEdge	=186;
	NewGad.ng_Width		=82;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_MOVEUP;
	NewGad.ng_GadgetText=(UBYTE *)"Move up";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_MOVEUP]=PrevGadget;

	NewGad.ng_LeftEdge	=96;
	NewGad.ng_TopEdge	=186;
	NewGad.ng_Width		=82;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_MOVEDOWN;
	NewGad.ng_GadgetText=(UBYTE *)"Move down";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_MOVEDOWN]=PrevGadget;

	NewGad.ng_LeftEdge	=342;
	NewGad.ng_TopEdge	=186;
	NewGad.ng_Width		=86;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_EDITLEVEL;
	NewGad.ng_GadgetText=(UBYTE *)"Edit level";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_EDITLEVEL]=PrevGadget;

	NewGad.ng_LeftEdge	=128;
	NewGad.ng_TopEdge	=204;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_OK;
	NewGad.ng_GadgetText=(UBYTE *)"Ok";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_OK]=PrevGadget;

	NewGad.ng_LeftEdge	=248;
	NewGad.ng_TopEdge	=204;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=PRJWINGAD_CANCEL;
	NewGad.ng_GadgetText=(UBYTE *)"Cancel";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ProjectWinGadgets[PRJWINGAD_CANCEL]=PrevGadget;

	if(!PrevGadget) {
		printf("Problemi con la creazione dei gadget per ProjectWin\n");
		return(1);
	}



 //**** Crea la lista di gadget per la finestra Level

	if(!(PrevGadget=CreateContext(&LevelWinGadList))) {
		printf("Problemi in CreateContext(&LevelWinGadList)\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=150;
	NewGad.ng_TopEdge	=20;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=LEVELWINGAD_LOADPIC;
	NewGad.ng_GadgetText=(UBYTE *)n_LevelLoadPic;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	LevelWinGadgets[LEVELWINGAD_LOADPIC]=PrevGadget;

	NewGad.ng_LeftEdge	=150;
	NewGad.ng_TopEdge	=36;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=LEVELWINGAD_MOD;
	NewGad.ng_GadgetText=(UBYTE *)n_LevelMod;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	LevelWinGadgets[LEVELWINGAD_MOD]=PrevGadget;

	if(!PrevGadget) {
		printf("Problemi con la creazione dei gadget per ProjectWin\n");
		return(1);
	}



 //**** Crea la lista di gadget per la finestra Textures

	if(!(PrevGadget=CreateContext(&TexturesWinGadList))) {
		printf("Problemi in CreateContext(&TexturesWinGadList)\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=8;
	NewGad.ng_TopEdge	=14;
	NewGad.ng_Width		=160;
	NewGad.ng_Height	=150;
	NewGad.ng_GadgetID	=TEXTWINGAD_LIST;
	NewGad.ng_GadgetText=NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(LISTVIEW_KIND,PrevGadget,&NewGad,
							GTLV_Labels, &TexturesList,
							GTLV_ShowSelected, NULL,
							TAG_DONE,0);
	TexturesWinGadgets[TEXTWINGAD_LIST]=PrevGadget;

	NewGad.ng_LeftEdge	=172;
	NewGad.ng_TopEdge	=14;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=15;
	NewGad.ng_GadgetID	=TEXTWINGAD_ADD;
	NewGad.ng_GadgetText=(UBYTE *)"Add";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	TexturesWinGadgets[TEXTWINGAD_ADD]=PrevGadget;

	NewGad.ng_LeftEdge	=172;
	NewGad.ng_TopEdge	=32;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=15;
	NewGad.ng_GadgetID	=TEXTWINGAD_ADDANIM;
	NewGad.ng_GadgetText=(UBYTE *)"Add an.";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	TexturesWinGadgets[TEXTWINGAD_ADDANIM]=PrevGadget;

	NewGad.ng_LeftEdge	=172;
	NewGad.ng_TopEdge	=50;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=15;
	NewGad.ng_GadgetID	=TEXTWINGAD_ADDSWITCH;
	NewGad.ng_GadgetText=(UBYTE *)"Add sw.";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	TexturesWinGadgets[TEXTWINGAD_ADDSWITCH]=PrevGadget;

	NewGad.ng_LeftEdge	=172;
	NewGad.ng_TopEdge	=68;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=15;
	NewGad.ng_GadgetID	=TEXTWINGAD_MODIFY;
	NewGad.ng_GadgetText=(UBYTE *)"Modify";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	TexturesWinGadgets[TEXTWINGAD_MODIFY]=PrevGadget;

	NewGad.ng_LeftEdge	=172;
	NewGad.ng_TopEdge	=86;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=15;
	NewGad.ng_GadgetID	=TEXTWINGAD_REMOVE;
	NewGad.ng_GadgetText=(UBYTE *)"Remove";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	TexturesWinGadgets[TEXTWINGAD_REMOVE]=PrevGadget;

	NewGad.ng_LeftEdge	=172;
	NewGad.ng_TopEdge	=130;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=TEXTWINGAD_SHOW;
	NewGad.ng_GadgetText=(UBYTE *)"        Show";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,
							GTCB_Checked, TRUE,
							TAG_DONE,0);
	TexturesWinGadgets[TEXTWINGAD_SHOW]=PrevGadget;

	if(!PrevGadget) {
		printf("Problemi con la creazione dei gadget per TexturesWin\n");
		return(1);
	}


 //**** Crea la lista di gadget per la finestra ObjList

	if(!(PrevGadget=CreateContext(&ObjListWinGadList))) {
		printf("Problemi in CreateContext(&ObjListWinGadList)\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=8;
	NewGad.ng_TopEdge	=14;
	NewGad.ng_Width		=328;
	NewGad.ng_Height	=150;
	NewGad.ng_GadgetID	=OBJLISTWINGAD_LIST;
	NewGad.ng_GadgetText=NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(LISTVIEW_KIND,PrevGadget,&NewGad,
							GTLV_Labels, &ObjectsList,
							GTLV_ShowSelected, NULL,
							TAG_DONE,0);
	ObjListWinGadgets[OBJLISTWINGAD_LIST]=PrevGadget;

	NewGad.ng_LeftEdge	=342;
	NewGad.ng_TopEdge	=14;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJLISTWINGAD_ADD;
	NewGad.ng_GadgetText=(UBYTE *)"Add";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ObjListWinGadgets[OBJLISTWINGAD_ADD]=PrevGadget;

	NewGad.ng_LeftEdge	=342;
	NewGad.ng_TopEdge	=30;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJLISTWINGAD_RELOAD;
	NewGad.ng_GadgetText=(UBYTE *)"Reload";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ObjListWinGadgets[OBJLISTWINGAD_RELOAD]=PrevGadget;

	NewGad.ng_LeftEdge	=342;
	NewGad.ng_TopEdge	=46;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJLISTWINGAD_MODIFY;
	NewGad.ng_GadgetText=(UBYTE *)"Modify";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ObjListWinGadgets[OBJLISTWINGAD_MODIFY]=PrevGadget;

	NewGad.ng_LeftEdge	=342;
	NewGad.ng_TopEdge	=62;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJLISTWINGAD_REMOVE;
	NewGad.ng_GadgetText=(UBYTE *)"Remove";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ObjListWinGadgets[OBJLISTWINGAD_REMOVE]=PrevGadget;

	if(!PrevGadget) {
		printf("Problemi con la creazione dei gadget per ObjListWin\n");
		return(1);
	}



 //**** Crea la lista di gadget per la finestra Objects

	if(!(PrevGadget=CreateContext(&ObjectsWinGadList))) {
		printf("Problemi in CreateContext(&ObjectsWinGadList)\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=8;
	NewGad.ng_TopEdge	=24;
	NewGad.ng_Width		=120;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_OBJTYPE;
	NewGad.ng_GadgetText=(UBYTE *)"Obj type";
	NewGad.ng_Flags		=PLACETEXT_ABOVE;
	PrevGadget=CreateGadget(CYCLE_KIND,PrevGadget,&NewGad,
							GTCY_Labels, ObjectTypeArray,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_OBJTYPE]=PrevGadget;

	NewGad.ng_LeftEdge	=134;
	NewGad.ng_TopEdge	=24;
	NewGad.ng_Width		=120;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_ANIMTYPE;
	NewGad.ng_GadgetText=(UBYTE *)"Anim type";
	NewGad.ng_Flags		=PLACETEXT_ABOVE;
	PrevGadget=CreateGadget(CYCLE_KIND,PrevGadget,&NewGad,
							GTCY_Labels, AnimTypeArray,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_ANIMTYPE]=PrevGadget;

	NewGad.ng_LeftEdge	=333;
	NewGad.ng_TopEdge	=24;
	NewGad.ng_Width		=48;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NUMFRAMES;
	NewGad.ng_GadgetText=(UBYTE *)"Frame #";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 3,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NUMFRAMES]=PrevGadget;

	NewGad.ng_LeftEdge	=428;
	NewGad.ng_TopEdge	=24;
	NewGad.ng_Width		=88;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAME;
	NewGad.ng_GadgetText=(UBYTE *)"Name";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(STRING_KIND,PrevGadget,&NewGad,
					//		GTST_String, 0,
							GTST_MaxChars, 4,
							STRINGA_Justification, GACT_STRINGCENTER,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAME]=PrevGadget;

	NewGad.ng_LeftEdge	=63;
	NewGad.ng_TopEdge	=42;
	NewGad.ng_Width		=48;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_RADIUS;
	NewGad.ng_GadgetText=(UBYTE *)"Radius";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 3,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_RADIUS]=PrevGadget;

	NewGad.ng_LeftEdge	=206;
	NewGad.ng_TopEdge	=42;
	NewGad.ng_Width		=48;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_HEIGHT;
	NewGad.ng_GadgetText=(UBYTE *)"Height";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 3,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_HEIGHT]=PrevGadget;

	NewGad.ng_LeftEdge	=325;
	NewGad.ng_TopEdge	=42;
	NewGad.ng_Width		=191;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_DESCR;
	NewGad.ng_GadgetText=(UBYTE *)"Descr.";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(STRING_KIND,PrevGadget,&NewGad,
					//		GTST_String, 0,
							GTST_MaxChars, 30,
							STRINGA_Justification, GACT_STRINGCENTER,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_DESCR]=PrevGadget;

	NewGad.ng_LeftEdge	=176;
	NewGad.ng_TopEdge	=62;
	NewGad.ng_Width		=68;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_PARAM1;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_PARAM1]=PrevGadget;

	NewGad.ng_LeftEdge	=438;
	NewGad.ng_TopEdge	=62;
	NewGad.ng_Width		=68;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_PARAM2;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_PARAM2]=PrevGadget;

	NewGad.ng_LeftEdge	=176;
	NewGad.ng_TopEdge	=78;
	NewGad.ng_Width		=68;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_PARAM3;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_PARAM3]=PrevGadget;

	NewGad.ng_LeftEdge	=438;
	NewGad.ng_TopEdge	=78;
	NewGad.ng_Width		=68;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_PARAM4;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_PARAM4]=PrevGadget;

	NewGad.ng_LeftEdge	=176;
	NewGad.ng_TopEdge	=94;
	NewGad.ng_Width		=68;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_PARAM5;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_PARAM5]=PrevGadget;

	NewGad.ng_LeftEdge	=438;
	NewGad.ng_TopEdge	=94;
	NewGad.ng_Width		=68;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_PARAM6;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_PARAM6]=PrevGadget;

	NewGad.ng_LeftEdge	=176;
	NewGad.ng_TopEdge	=110;
	NewGad.ng_Width		=68;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_PARAM7;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_PARAM7]=PrevGadget;

	NewGad.ng_LeftEdge	=438;
	NewGad.ng_TopEdge	=110;
	NewGad.ng_Width		=68;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_PARAM8;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_PARAM8]=PrevGadget;

	NewGad.ng_LeftEdge	=176;
	NewGad.ng_TopEdge	=126;
	NewGad.ng_Width		=68;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_PARAM9;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_PARAM9]=PrevGadget;

	NewGad.ng_LeftEdge	=438;
	NewGad.ng_TopEdge	=126;
	NewGad.ng_Width		=68;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_PARAM10;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_PARAM10]=PrevGadget;

	NewGad.ng_LeftEdge	=176;
	NewGad.ng_TopEdge	=142;
	NewGad.ng_Width		=68;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_PARAM11;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_PARAM11]=PrevGadget;

	NewGad.ng_LeftEdge	=438;
	NewGad.ng_TopEdge	=142;
	NewGad.ng_Width		=68;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_PARAM12;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_PARAM12]=PrevGadget;

	NewGad.ng_LeftEdge	=124;
	NewGad.ng_TopEdge	=166;
	NewGad.ng_Width		=44;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_SOUND1;
	NewGad.ng_GadgetText=(UBYTE *)n_ObjSound1;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_SOUND1]=PrevGadget;

	NewGad.ng_LeftEdge	=293;
	NewGad.ng_TopEdge	=166;
	NewGad.ng_Width		=44;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_SOUND2;
	NewGad.ng_GadgetText=(UBYTE *)n_ObjSound2;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_SOUND2]=PrevGadget;

	NewGad.ng_LeftEdge	=462;
	NewGad.ng_TopEdge	=166;
	NewGad.ng_Width		=44;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_SOUND3;
	NewGad.ng_GadgetText=(UBYTE *)n_ObjSound3;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_SOUND3]=PrevGadget;

	NewGad.ng_LeftEdge	=12;
	NewGad.ng_TopEdge	=62;
	NewGad.ng_Width		=162;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMEPARAM1;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMEPARAM1]=PrevGadget;

	NewGad.ng_LeftEdge	=274;
	NewGad.ng_TopEdge	=62;
	NewGad.ng_Width		=162;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMEPARAM2;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMEPARAM2]=PrevGadget;

	NewGad.ng_LeftEdge	=12;
	NewGad.ng_TopEdge	=78;
	NewGad.ng_Width		=162;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMEPARAM3;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMEPARAM3]=PrevGadget;

	NewGad.ng_LeftEdge	=274;
	NewGad.ng_TopEdge	=78;
	NewGad.ng_Width		=162;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMEPARAM4;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMEPARAM4]=PrevGadget;

	NewGad.ng_LeftEdge	=12;
	NewGad.ng_TopEdge	=94;
	NewGad.ng_Width		=162;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMEPARAM5;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMEPARAM5]=PrevGadget;

	NewGad.ng_LeftEdge	=274;
	NewGad.ng_TopEdge	=94;
	NewGad.ng_Width		=162;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMEPARAM6;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMEPARAM6]=PrevGadget;

	NewGad.ng_LeftEdge	=12;
	NewGad.ng_TopEdge	=110;
	NewGad.ng_Width		=162;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMEPARAM7;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMEPARAM7]=PrevGadget;

	NewGad.ng_LeftEdge	=274;
	NewGad.ng_TopEdge	=110;
	NewGad.ng_Width		=162;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMEPARAM8;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMEPARAM8]=PrevGadget;

	NewGad.ng_LeftEdge	=12;
	NewGad.ng_TopEdge	=126;
	NewGad.ng_Width		=162;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMEPARAM9;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMEPARAM9]=PrevGadget;

	NewGad.ng_LeftEdge	=274;
	NewGad.ng_TopEdge	=126;
	NewGad.ng_Width		=162;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMEPARAM10;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMEPARAM10]=PrevGadget;

	NewGad.ng_LeftEdge	=12;
	NewGad.ng_TopEdge	=142;
	NewGad.ng_Width		=162;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMEPARAM11;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMEPARAM11]=PrevGadget;

	NewGad.ng_LeftEdge	=274;
	NewGad.ng_TopEdge	=142;
	NewGad.ng_Width		=162;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMEPARAM12;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMEPARAM12]=PrevGadget;

	NewGad.ng_LeftEdge	=12;
	NewGad.ng_TopEdge	=166;
	NewGad.ng_Width		=112;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMESOUND1;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMESOUND1]=PrevGadget;

	NewGad.ng_LeftEdge	=181;
	NewGad.ng_TopEdge	=166;
	NewGad.ng_Width		=112;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMESOUND2;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMESOUND2]=PrevGadget;

	NewGad.ng_LeftEdge	=350;
	NewGad.ng_TopEdge	=166;
	NewGad.ng_Width		=112;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_NAMESOUND3;
	NewGad.ng_GadgetText=(UBYTE *)0;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, "",
							GTTX_Border, FALSE,
							TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_NAMESOUND3]=PrevGadget;

	NewGad.ng_LeftEdge	=121;
	NewGad.ng_TopEdge	=192;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_OK;
	NewGad.ng_GadgetText=(UBYTE *)"Ok";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_OK]=PrevGadget;

	NewGad.ng_LeftEdge	=323;
	NewGad.ng_TopEdge	=192;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=OBJWINGAD_CANCEL;
	NewGad.ng_GadgetText=(UBYTE *)"Cancel";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	ObjectsWinGadgets[OBJWINGAD_CANCEL]=PrevGadget;

	if(!PrevGadget) {
		printf("Problemi con la creazione dei gadget per ObjectsWin\n");
		return(1);
	}


 //**** Crea la lista di gadget per la finestra MapObj

	if(!(PrevGadget=CreateContext(&MapObjWinGadList))) {
		printf("Problemi in CreateContext(&MapObjWinGadList)\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=72;
	NewGad.ng_TopEdge	=14;
	NewGad.ng_Width		=45;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=MAPOBJWINGAD_OBJ;
	NewGad.ng_GadgetText=(UBYTE *)"Object";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, NULL,
							GTTX_Border, TRUE,
							TAG_DONE,0);
	MapObjWinGadgets[MAPOBJWINGAD_OBJ]=PrevGadget;

	NewGad.ng_LeftEdge	=36;
	NewGad.ng_TopEdge	=32;
	NewGad.ng_Width		=45;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=MAPOBJWINGAD_X;
	NewGad.ng_GadgetText=(UBYTE *)"X";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(NUMBER_KIND,PrevGadget,&NewGad,
							GTNM_Number, 0,
							GTNM_Border, TRUE,
							TAG_DONE,0);
	MapObjWinGadgets[MAPOBJWINGAD_X]=PrevGadget;

	NewGad.ng_LeftEdge	=122;
	NewGad.ng_TopEdge	=32;
	NewGad.ng_Width		=45;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=MAPOBJWINGAD_Y;
	NewGad.ng_GadgetText=(UBYTE *)"Y";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(NUMBER_KIND,PrevGadget,&NewGad,
							GTNM_Number, 0,
							GTNM_Border, TRUE,
							TAG_DONE,0);
	MapObjWinGadgets[MAPOBJWINGAD_Y]=PrevGadget;

	NewGad.ng_LeftEdge	=72;
	NewGad.ng_TopEdge	=50;
	NewGad.ng_Width		=106;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=MAPOBJWINGAD_HEADING;
	NewGad.ng_GadgetText=(UBYTE *)"Heading";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(CYCLE_KIND,PrevGadget,&NewGad,
							GTCY_Labels, HeadingArray,
							TAG_DONE,0);
	MapObjWinGadgets[MAPOBJWINGAD_HEADING]=PrevGadget;

	NewGad.ng_LeftEdge	=72;
	NewGad.ng_TopEdge	=76;
	NewGad.ng_Width		=40;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=MAPOBJWINGAD_TRIGGER;
	NewGad.ng_GadgetText=(UBYTE *)n_MapObjTriggerNum;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	MapObjWinGadgets[MAPOBJWINGAD_TRIGGER]=PrevGadget;

	NewGad.ng_LeftEdge	=15;
	NewGad.ng_TopEdge	=92;
	NewGad.ng_Width		=155;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=MAPOBJWINGAD_DEL;
	NewGad.ng_GadgetText=(UBYTE *)"Delete Object";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	MapObjWinGadgets[MAPOBJWINGAD_DEL]=PrevGadget;

	NewGad.ng_LeftEdge	=15;
	NewGad.ng_TopEdge	=110;
	NewGad.ng_Width		=70;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=MAPOBJWINGAD_OK;
	NewGad.ng_GadgetText=(UBYTE *)"Ok";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	MapObjWinGadgets[MAPOBJWINGAD_OK]=PrevGadget;

	NewGad.ng_LeftEdge	=100;
	NewGad.ng_TopEdge	=110;
	NewGad.ng_Width		=70;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=MAPOBJWINGAD_CANCEL;
	NewGad.ng_GadgetText=(UBYTE *)"Cancel";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	MapObjWinGadgets[MAPOBJWINGAD_CANCEL]=PrevGadget;

	if(!PrevGadget) {
		printf("Problemi con la creazione dei gadget per MapObjWin\n");
		return(1);
	}



 //**** Crea la lista di gadget per la finestra SndList

	if(!(PrevGadget=CreateContext(&SndListWinGadList))) {
		printf("Problemi in CreateContext(&SndListWinGadList)\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=8;
	NewGad.ng_TopEdge	=14;
	NewGad.ng_Width		=328;
	NewGad.ng_Height	=150;
	NewGad.ng_GadgetID	=SNDLISTWINGAD_LIST;
	NewGad.ng_GadgetText=NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(LISTVIEW_KIND,PrevGadget,&NewGad,
							GTLV_Labels, &SoundsList,
							GTLV_ShowSelected, NULL,
							TAG_DONE,0);
	SndListWinGadgets[SNDLISTWINGAD_LIST]=PrevGadget;

	NewGad.ng_LeftEdge	=342;
	NewGad.ng_TopEdge	=14;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SNDLISTWINGAD_ADD;
	NewGad.ng_GadgetText=(UBYTE *)"Add";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	SndListWinGadgets[SNDLISTWINGAD_ADD]=PrevGadget;

	NewGad.ng_LeftEdge	=342;
	NewGad.ng_TopEdge	=30;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SNDLISTWINGAD_MODIFY;
	NewGad.ng_GadgetText=(UBYTE *)"Modify";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	SndListWinGadgets[SNDLISTWINGAD_MODIFY]=PrevGadget;

	NewGad.ng_LeftEdge	=342;
	NewGad.ng_TopEdge	=46;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SNDLISTWINGAD_REMOVE;
	NewGad.ng_GadgetText=(UBYTE *)"Remove";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	SndListWinGadgets[SNDLISTWINGAD_REMOVE]=PrevGadget;

	if(!PrevGadget) {
		printf("Problemi con la creazione dei gadget per SndListWin\n");
		return(1);
	}



 //**** Crea la lista di gadget per la finestra Sounds

	if(!(PrevGadget=CreateContext(&SoundsWinGadList))) {
		printf("Problemi in CreateContext(&SoundsWinGadList)\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=80;
	NewGad.ng_TopEdge	=14;
	NewGad.ng_Width		=150;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_TYPE;
	NewGad.ng_GadgetText=(UBYTE *)"Type";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(CYCLE_KIND,PrevGadget,&NewGad,
							GTCY_Labels, SoundTypeArray,
							TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_TYPE]=PrevGadget;

	NewGad.ng_LeftEdge	=80;
	NewGad.ng_TopEdge	=32;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_NAME;
	NewGad.ng_GadgetText=(UBYTE *)"Name";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(STRING_KIND,PrevGadget,&NewGad,
					//		GTST_String, 0,
							GTST_MaxChars, 4,
							STRINGA_Justification, GACT_STRINGCENTER,
							TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_NAME]=PrevGadget;

	NewGad.ng_LeftEdge	=220;
	NewGad.ng_TopEdge	=32;
	NewGad.ng_Width		=258;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_DESCR;
	NewGad.ng_GadgetText=(UBYTE *)"Descr.";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(STRING_KIND,PrevGadget,&NewGad,
					//		GTST_String, 0,
							GTST_MaxChars, 30,
							STRINGA_Justification, GACT_STRINGCENTER,
							TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_DESCR]=PrevGadget;

	NewGad.ng_LeftEdge	=80;
	NewGad.ng_TopEdge	=51;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_LENGTH;
	NewGad.ng_GadgetText=(UBYTE *)"Length";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 5,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_LENGTH]=PrevGadget;

	NewGad.ng_LeftEdge	=220;
	NewGad.ng_TopEdge	=51;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_PERIOD;
	NewGad.ng_GadgetText=(UBYTE *)"Period";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 4,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_PERIOD]=PrevGadget;

	NewGad.ng_LeftEdge	=80;
	NewGad.ng_TopEdge	=67;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_VOLUME;
	NewGad.ng_GadgetText=(UBYTE *)"Volume";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 2,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_VOLUME]=PrevGadget;

	NewGad.ng_LeftEdge	=220;
	NewGad.ng_TopEdge	=67;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_LOOP;
	NewGad.ng_GadgetText=(UBYTE *)"Loop";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 5,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_LOOP]=PrevGadget;

	NewGad.ng_LeftEdge	=80;
	NewGad.ng_TopEdge	=83;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_PRIORITY;
	NewGad.ng_GadgetText=(UBYTE *)"Priority";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 1,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_PRIORITY]=PrevGadget;

	NewGad.ng_LeftEdge	=220;
	NewGad.ng_TopEdge	=83;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_CODE;
	NewGad.ng_GadgetText=(UBYTE *)"Code";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 2,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_CODE]=PrevGadget;

	NewGad.ng_LeftEdge	=360;
	NewGad.ng_TopEdge	=51;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=SOUNDWINGAD_CHANNEL1;
	NewGad.ng_GadgetText=(UBYTE *)"Ch.1";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_CHANNEL1]=PrevGadget;

	NewGad.ng_LeftEdge	=410+CHECKBOX_WIDTH;
	NewGad.ng_TopEdge	=51;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=SOUNDWINGAD_CHANNEL2;
	NewGad.ng_GadgetText=(UBYTE *)"Ch.2";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_CHANNEL2]=PrevGadget;

	NewGad.ng_LeftEdge	=360;
	NewGad.ng_TopEdge	=67;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=SOUNDWINGAD_CHANNEL3;
	NewGad.ng_GadgetText=(UBYTE *)"Ch.3";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_CHANNEL3]=PrevGadget;

	NewGad.ng_LeftEdge	=410+CHECKBOX_WIDTH;
	NewGad.ng_TopEdge	=67;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=SOUNDWINGAD_CHANNEL4;
	NewGad.ng_GadgetText=(UBYTE *)"Ch.4";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_CHANNEL4]=PrevGadget;

	NewGad.ng_LeftEdge	=410+CHECKBOX_WIDTH;
	NewGad.ng_TopEdge	=14;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=SOUNDWINGAD_ALONE;
	NewGad.ng_GadgetText=(UBYTE *)"Alone";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_ALONE]=PrevGadget;

	NewGad.ng_LeftEdge	=402;
	NewGad.ng_TopEdge	=83;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_SAMPLE;
	NewGad.ng_GadgetText=(UBYTE *)"Sample link";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(STRING_KIND,PrevGadget,&NewGad,
					//		GTST_String, 0,
							GTST_MaxChars, 4,
							STRINGA_Justification, GACT_STRINGCENTER,
							TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_SAMPLE]=PrevGadget;

	NewGad.ng_LeftEdge	=80;
	NewGad.ng_TopEdge	=99;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_SOUND1;
	NewGad.ng_GadgetText=(UBYTE *)"Sound1";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(STRING_KIND,PrevGadget,&NewGad,
					//		GTST_String, 0,
							GTST_MaxChars, 4,
							STRINGA_Justification, GACT_STRINGCENTER,
							TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_SOUND1]=PrevGadget;

	NewGad.ng_LeftEdge	=220;
	NewGad.ng_TopEdge	=99;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_SOUND2;
	NewGad.ng_GadgetText=(UBYTE *)"Sound2";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(STRING_KIND,PrevGadget,&NewGad,
					//		GTST_String, 0,
							GTST_MaxChars, 4,
							STRINGA_Justification, GACT_STRINGCENTER,
							TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_SOUND2]=PrevGadget;

	NewGad.ng_LeftEdge	=402;
	NewGad.ng_TopEdge	=99;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_SOUND3;
	NewGad.ng_GadgetText=(UBYTE *)"Sound3";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(STRING_KIND,PrevGadget,&NewGad,
					//		GTST_String, 0,
							GTST_MaxChars, 4,
							STRINGA_Justification, GACT_STRINGCENTER,
							TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_SOUND3]=PrevGadget;

	NewGad.ng_LeftEdge	=108;
	NewGad.ng_TopEdge	=121;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_OK;
	NewGad.ng_GadgetText=(UBYTE *)"Ok";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_OK]=PrevGadget;

	NewGad.ng_LeftEdge	=298;
	NewGad.ng_TopEdge	=121;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=SOUNDWINGAD_CANCEL;
	NewGad.ng_GadgetText=(UBYTE *)"Cancel";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	SoundsWinGadgets[SOUNDWINGAD_CANCEL]=PrevGadget;

	if(!PrevGadget) {
		printf("Problemi con la creazione dei gadget per SoundsWin\n");
		return(1);
	}



 //**** Crea la lista di gadget per la finestra GfxList

	if(!(PrevGadget=CreateContext(&GfxListWinGadList))) {
		printf("Problemi in CreateContext(&GfxListWinGadList)\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=8;
	NewGad.ng_TopEdge	=14;
	NewGad.ng_Width		=328;
	NewGad.ng_Height	=150;
	NewGad.ng_GadgetID	=GFXLISTWINGAD_LIST;
	NewGad.ng_GadgetText=NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(LISTVIEW_KIND,PrevGadget,&NewGad,
							GTLV_Labels, &GfxList,
							GTLV_ShowSelected, NULL,
							TAG_DONE,0);
	GfxListWinGadgets[GFXLISTWINGAD_LIST]=PrevGadget;

	NewGad.ng_LeftEdge	=342;
	NewGad.ng_TopEdge	=14;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=GFXLISTWINGAD_ADD;
	NewGad.ng_GadgetText=(UBYTE *)"Add";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	GfxListWinGadgets[GFXLISTWINGAD_ADD]=PrevGadget;

	NewGad.ng_LeftEdge	=342;
	NewGad.ng_TopEdge	=30;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=GFXLISTWINGAD_MODIFY;
	NewGad.ng_GadgetText=(UBYTE *)"Modify";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	GfxListWinGadgets[GFXLISTWINGAD_MODIFY]=PrevGadget;

	NewGad.ng_LeftEdge	=342;
	NewGad.ng_TopEdge	=46;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=GFXLISTWINGAD_REMOVE;
	NewGad.ng_GadgetText=(UBYTE *)"Remove";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	GfxListWinGadgets[GFXLISTWINGAD_REMOVE]=PrevGadget;

	if(!PrevGadget) {
		printf("Problemi con la creazione dei gadget per GfxListWin\n");
		return(1);
	}



 //**** Crea la lista di gadget per la finestra Effects

	if(!(PrevGadget=CreateContext(&EffectsWinGadList))) {
		printf("Problemi in CreateContext(&EffectsWinGadList)\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=8;
	NewGad.ng_TopEdge	=14;
	NewGad.ng_Width		=344;
	NewGad.ng_Height	=135;
	NewGad.ng_GadgetID	=EFFWINGAD_LIST;
	NewGad.ng_GadgetText=NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(LISTVIEW_KIND,PrevGadget,&NewGad,
							GTLV_Labels, &EffectsList,
							GTLV_ShowSelected, NULL,
							TAG_DONE,0);
	EffectsWinGadgets[EFFWINGAD_LIST]=PrevGadget;

	NewGad.ng_LeftEdge	=8;
	NewGad.ng_TopEdge	=149;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=EFFWINGAD_ADDLIST;
	NewGad.ng_GadgetText=(UBYTE *)"Add list";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	EffectsWinGadgets[EFFWINGAD_ADDLIST]=PrevGadget;

	NewGad.ng_LeftEdge	=94;
	NewGad.ng_TopEdge	=149;
	NewGad.ng_Width		=72;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=EFFWINGAD_ADDFX;
	NewGad.ng_GadgetText=(UBYTE *)"Add fx";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	EffectsWinGadgets[EFFWINGAD_ADDFX]=PrevGadget;

	NewGad.ng_LeftEdge	=172;
	NewGad.ng_TopEdge	=149;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=EFFWINGAD_DELLIST;
	NewGad.ng_GadgetText=(UBYTE *)"Del list";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	EffectsWinGadgets[EFFWINGAD_DELLIST]=PrevGadget;

	NewGad.ng_LeftEdge	=258;
	NewGad.ng_TopEdge	=149;
	NewGad.ng_Width		=72;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=EFFWINGAD_DELFX;
	NewGad.ng_GadgetText=(UBYTE *)"Del fx";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	EffectsWinGadgets[EFFWINGAD_DELFX]=PrevGadget;

	NewGad.ng_LeftEdge	=117;
	NewGad.ng_TopEdge	=168;
	NewGad.ng_Width		=180;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=EFFWINGAD_EFFECT;
	NewGad.ng_GadgetText=(UBYTE *)n_Effect;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	EffectsWinGadgets[EFFWINGAD_EFFECT]=PrevGadget;

	NewGad.ng_LeftEdge	=229;
	NewGad.ng_TopEdge	=183;
	NewGad.ng_Width		=68;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=EFFWINGAD_PARAM1;
	NewGad.ng_GadgetText=(UBYTE *)NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	EffectsWinGadgets[EFFWINGAD_PARAM1]=PrevGadget;

	NewGad.ng_LeftEdge	=229;
	NewGad.ng_TopEdge	=198;
	NewGad.ng_Width		=68;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=EFFWINGAD_PARAM2;
	NewGad.ng_GadgetText=(UBYTE *)NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							STRINGA_Justification, GACT_STRINGRIGHT,
							TAG_DONE,0);
	EffectsWinGadgets[EFFWINGAD_PARAM2]=PrevGadget;

	NewGad.ng_LeftEdge	=202;
	NewGad.ng_TopEdge	=213;
	NewGad.ng_Width		=95;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=EFFWINGAD_KEY;
	NewGad.ng_GadgetText=(UBYTE *)"Key";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(CYCLE_KIND,PrevGadget,&NewGad,
							GTCY_Labels, KeysArray,
							TAG_DONE,0);
	EffectsWinGadgets[EFFWINGAD_KEY]=PrevGadget;

	if(!PrevGadget) {
		printf("Problemi con la creazione dei gadget per EffectsWin\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=60;
	NewGad.ng_TopEdge	=183;
	NewGad.ng_Width		=168;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=EFFWINGAD_NAMEPARAM1;
	NewGad.ng_GadgetText=(UBYTE *)NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, n_EffParam1,
							GTTX_Border, FALSE,
							TAG_DONE,0);
	EffectsWinGadgets[EFFWINGAD_NAMEPARAM1]=PrevGadget;

	NewGad.ng_LeftEdge	=60;
	NewGad.ng_TopEdge	=198;
	NewGad.ng_Width		=168;
	NewGad.ng_Height	=13;
	NewGad.ng_GadgetID	=EFFWINGAD_NAMEPARAM2;
	NewGad.ng_GadgetText=(UBYTE *)NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(TEXT_KIND,PrevGadget,&NewGad,
							GTTX_Text, n_EffParam2,
							GTTX_Border, FALSE,
							TAG_DONE,0);
	EffectsWinGadgets[EFFWINGAD_NAMEPARAM2]=PrevGadget;



 //**** Crea la lista di gadget per la finestra Fx

	if(!(PrevGadget=CreateContext(&FxWinGadList))) {
		printf("Problemi in CreateContext(&FxWinGadList)\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=8;
	NewGad.ng_TopEdge	=14;
	NewGad.ng_Width		=180;
	NewGad.ng_Height	=120;
	NewGad.ng_GadgetID	=FXWINGAD_LIST;
	NewGad.ng_GadgetText=NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(LISTVIEW_KIND,PrevGadget,&NewGad,
							GTLV_Labels, &FxList,
							GTLV_ShowSelected, NULL,
							TAG_DONE,0);
	FxWinGadgets[FXWINGAD_LIST]=PrevGadget;

	if(!PrevGadget) {
		printf("Problemi con la creazione dei gadget per FxWin\n");
		return(1);
	}


 //**** Crea la lista di gadget per la finestra Block

	if(!(PrevGadget=CreateContext(&BlockWinGadList))) {
		printf("Problemi in CreateContext(&BlockWinGadList)\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=90;
	NewGad.ng_TopEdge	=16;
	NewGad.ng_Width		=234;
	NewGad.ng_Height	=12;
	NewGad.ng_GadgetID	=BLOCKWINGAD_FLOORH_SLIDE;
	NewGad.ng_GadgetText=(UBYTE *)"Floor H.";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(SLIDER_KIND,PrevGadget,&NewGad,
							GA_Immediate, TRUE,
							GA_RelVerify, TRUE,
							GTSL_Min, 0,
							GTSL_Max,  16383,
							GTSL_Level,	8192,
							GTSL_LevelFormat, "",
							TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_FLOORH_SLIDE]=PrevGadget;

	NewGad.ng_LeftEdge	=330;
	NewGad.ng_TopEdge	=16;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=12;
	NewGad.ng_GadgetID	=BLOCKWINGAD_FLOORH_NUM;
	NewGad.ng_GadgetText=NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_FLOORH_NUM]=PrevGadget;

	NewGad.ng_LeftEdge	=90;
	NewGad.ng_TopEdge	=30;
	NewGad.ng_Width		=234;
	NewGad.ng_Height	=12;
	NewGad.ng_GadgetID	=BLOCKWINGAD_CEILH_SLIDE;
	NewGad.ng_GadgetText=(UBYTE *)"Ceil H. ";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(SLIDER_KIND,PrevGadget,&NewGad,
							GA_Immediate, TRUE,
							GA_RelVerify, TRUE,
							GTSL_Min, 0,
							GTSL_Max,  16383,
							GTSL_Level,	8192,
							GTSL_LevelFormat, "",
							TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_CEILH_SLIDE]=PrevGadget;

	NewGad.ng_LeftEdge	=330;
	NewGad.ng_TopEdge	=30;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=12;
	NewGad.ng_GadgetID	=BLOCKWINGAD_CEILH_NUM;
	NewGad.ng_GadgetText=NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 6,
							TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_CEILH_NUM]=PrevGadget;

	NewGad.ng_LeftEdge	=45;
	NewGad.ng_TopEdge	=44;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_FOG;
	NewGad.ng_GadgetText=(UBYTE *)"Fog       ";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_FOG]=PrevGadget;

	NewGad.ng_LeftEdge	=148;
	NewGad.ng_TopEdge	=44;
	NewGad.ng_Width		=176;
	NewGad.ng_Height	=12;
	NewGad.ng_GadgetID	=BLOCKWINGAD_ILLUM_SLIDE;
	NewGad.ng_GadgetText=(UBYTE *)"Illumin.";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(SLIDER_KIND,PrevGadget,&NewGad,
							GA_Immediate, TRUE,
							GA_RelVerify, TRUE,
							GTSL_Min, 0,
							GTSL_Max,  255,
							GTSL_Level,	128,
							GTSL_LevelFormat, "",
							TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_ILLUM_SLIDE]=PrevGadget;

	NewGad.ng_LeftEdge	=330;
	NewGad.ng_TopEdge	=44;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=12;
	NewGad.ng_GadgetID	=BLOCKWINGAD_ILLUM_NUM;
	NewGad.ng_GadgetText=NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(INTEGER_KIND,PrevGadget,&NewGad,
							GTIN_Number, 0,
							GTIN_MaxChars, 4,
							TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_ILLUM_NUM]=PrevGadget;

	NewGad.ng_LeftEdge	=68;
	NewGad.ng_TopEdge	=60;
	NewGad.ng_Width		=40;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_EFFECT;
	NewGad.ng_GadgetText=(UBYTE *)n_EffectNum;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_EFFECT]=PrevGadget;

	NewGad.ng_LeftEdge	=185;
	NewGad.ng_TopEdge	=60;
	NewGad.ng_Width		=40;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_TRIGGER;
	NewGad.ng_GadgetText=(UBYTE *)n_TriggerNum;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_TRIGGER]=PrevGadget;

	NewGad.ng_LeftEdge	=302;
	NewGad.ng_TopEdge	=60;
	NewGad.ng_Width		=40;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_TRIGGER2;
	NewGad.ng_GadgetText=(UBYTE *)n_TriggerNum2;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_TRIGGER2]=PrevGadget;

	NewGad.ng_LeftEdge	=347+(CHECKBOX_WIDTH<<1);
	NewGad.ng_TopEdge	=60;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_SOLIDWALL;
	NewGad.ng_GadgetText=(UBYTE *)"Solid";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_SOLIDWALL]=PrevGadget;

	NewGad.ng_LeftEdge	=68;
	NewGad.ng_TopEdge	=75;
	NewGad.ng_Width		=116;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_TYPE;
	NewGad.ng_GadgetText=(UBYTE *)"Type";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(CYCLE_KIND,PrevGadget,&NewGad,
							GTCY_Labels, BlockTypeArray,
							TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_TYPE]=PrevGadget;

	NewGad.ng_LeftEdge	=316;
	NewGad.ng_TopEdge	=75;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_ENEMYBLOCKER;
	NewGad.ng_GadgetText=(UBYTE *)"Enemies blocker";
	NewGad.ng_Flags		=PLACETEXT_LEFT;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_ENEMYBLOCKER]=PrevGadget;

	NewGad.ng_LeftEdge	=84;
	NewGad.ng_TopEdge	=92;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_FLOORTEXT;
	NewGad.ng_GadgetText=(UBYTE *)n_FloorTexture;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_FLOORTEXT]=PrevGadget;

	NewGad.ng_LeftEdge	=245;
	NewGad.ng_TopEdge	=92;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_CEILTEXT;
	NewGad.ng_GadgetText=(UBYTE *)n_CeilTexture;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_CEILTEXT]=PrevGadget;

	NewGad.ng_LeftEdge	=338+CHECKBOX_WIDTH;
	NewGad.ng_TopEdge	=92;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_SKYCEIL;
	NewGad.ng_GadgetText=(UBYTE *)"Sky       ";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_SKYCEIL]=PrevGadget;

	//*** Edge1
	NewGad.ng_LeftEdge	=55;
	NewGad.ng_TopEdge	=120;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E1_UPTEXT;
	NewGad.ng_GadgetText=(UBYTE *)n_UpTextureE1;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E1_UPTEXT]=PrevGadget;

	NewGad.ng_LeftEdge	=140;
	NewGad.ng_TopEdge	=120;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E1_NORMTEXT;
	NewGad.ng_GadgetText=(UBYTE *)n_NormTextureE1;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E1_NORMTEXT]=PrevGadget;

	NewGad.ng_LeftEdge	=225;
	NewGad.ng_TopEdge	=120;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E1_LOWTEXT;
	NewGad.ng_GadgetText=(UBYTE *)n_LowTextureE1;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E1_LOWTEXT]=PrevGadget;

	NewGad.ng_LeftEdge	=323;
	NewGad.ng_TopEdge	=120;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E1_UNPEGUP;
	NewGad.ng_GadgetText=(UBYTE *)"U     ";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E1_UNPEGUP]=PrevGadget;

	NewGad.ng_LeftEdge	=338+CHECKBOX_WIDTH;
	NewGad.ng_TopEdge	=120;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E1_UNPEGLOW;
	NewGad.ng_GadgetText=(UBYTE *)"L     ";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E1_UNPEGLOW]=PrevGadget;

	NewGad.ng_LeftEdge	=347+(CHECKBOX_WIDTH<<1);
	NewGad.ng_TopEdge	=120;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E1_SWITCH;
	NewGad.ng_GadgetText=(UBYTE *)NULL;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E1_SWITCH]=PrevGadget;

	//*** Edge2
	NewGad.ng_LeftEdge	=55;
	NewGad.ng_TopEdge	=134;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E2_UPTEXT;
	NewGad.ng_GadgetText=(UBYTE *)n_UpTextureE2;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E2_UPTEXT]=PrevGadget;

	NewGad.ng_LeftEdge	=140;
	NewGad.ng_TopEdge	=134;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E2_NORMTEXT;
	NewGad.ng_GadgetText=(UBYTE *)n_NormTextureE2;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E2_NORMTEXT]=PrevGadget;

	NewGad.ng_LeftEdge	=225;
	NewGad.ng_TopEdge	=134;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E2_LOWTEXT;
	NewGad.ng_GadgetText=(UBYTE *)n_LowTextureE2;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E2_LOWTEXT]=PrevGadget;

	NewGad.ng_LeftEdge	=323;
	NewGad.ng_TopEdge	=134;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E2_UNPEGUP;
	NewGad.ng_GadgetText=(UBYTE *)"U     ";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E2_UNPEGUP]=PrevGadget;

	NewGad.ng_LeftEdge	=338+CHECKBOX_WIDTH;
	NewGad.ng_TopEdge	=134;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E2_UNPEGLOW;
	NewGad.ng_GadgetText=(UBYTE *)"L     ";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E2_UNPEGLOW]=PrevGadget;

	NewGad.ng_LeftEdge	=347+(CHECKBOX_WIDTH<<1);
	NewGad.ng_TopEdge	=134;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E2_SWITCH;
	NewGad.ng_GadgetText=(UBYTE *)NULL;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E2_SWITCH]=PrevGadget;

	//*** Edge3
	NewGad.ng_LeftEdge	=55;
	NewGad.ng_TopEdge	=148;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E3_UPTEXT;
	NewGad.ng_GadgetText=(UBYTE *)n_UpTextureE3;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E3_UPTEXT]=PrevGadget;

	NewGad.ng_LeftEdge	=140;
	NewGad.ng_TopEdge	=148;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E3_NORMTEXT;
	NewGad.ng_GadgetText=(UBYTE *)n_NormTextureE3;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E3_NORMTEXT]=PrevGadget;

	NewGad.ng_LeftEdge	=225;
	NewGad.ng_TopEdge	=148;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E3_LOWTEXT;
	NewGad.ng_GadgetText=(UBYTE *)n_LowTextureE3;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E3_LOWTEXT]=PrevGadget;

	NewGad.ng_LeftEdge	=323;
	NewGad.ng_TopEdge	=148;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E3_UNPEGUP;
	NewGad.ng_GadgetText=(UBYTE *)"U     ";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E3_UNPEGUP]=PrevGadget;

	NewGad.ng_LeftEdge	=338+CHECKBOX_WIDTH;
	NewGad.ng_TopEdge	=148;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E3_UNPEGLOW;
	NewGad.ng_GadgetText=(UBYTE *)"L     ";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E3_UNPEGLOW]=PrevGadget;

	NewGad.ng_LeftEdge	=347+(CHECKBOX_WIDTH<<1);
	NewGad.ng_TopEdge	=148;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E3_SWITCH;
	NewGad.ng_GadgetText=(UBYTE *)NULL;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E3_SWITCH]=PrevGadget;

	//*** Edge4
	NewGad.ng_LeftEdge	=55;
	NewGad.ng_TopEdge	=162;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E4_UPTEXT;
	NewGad.ng_GadgetText=(UBYTE *)n_UpTextureE4;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E4_UPTEXT]=PrevGadget;

	NewGad.ng_LeftEdge	=140;
	NewGad.ng_TopEdge	=162;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E4_NORMTEXT;
	NewGad.ng_GadgetText=(UBYTE *)n_NormTextureE4;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E4_NORMTEXT]=PrevGadget;

	NewGad.ng_LeftEdge	=225;
	NewGad.ng_TopEdge	=162;
	NewGad.ng_Width		=80;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E4_LOWTEXT;
	NewGad.ng_GadgetText=(UBYTE *)n_LowTextureE4;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E4_LOWTEXT]=PrevGadget;

	NewGad.ng_LeftEdge	=323;
	NewGad.ng_TopEdge	=162;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E4_UNPEGUP;
	NewGad.ng_GadgetText=(UBYTE *)"U     ";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E4_UNPEGUP]=PrevGadget;

	NewGad.ng_LeftEdge	=338+CHECKBOX_WIDTH;
	NewGad.ng_TopEdge	=162;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E4_UNPEGLOW;
	NewGad.ng_GadgetText=(UBYTE *)"L     ";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E4_UNPEGLOW]=PrevGadget;

	NewGad.ng_LeftEdge	=347+(CHECKBOX_WIDTH<<1);
	NewGad.ng_TopEdge	=162;
	NewGad.ng_Width		=CHECKBOX_WIDTH;
	NewGad.ng_Height	=CHECKBOX_HEIGHT;
	NewGad.ng_GadgetID	=BLOCKWINGAD_E4_SWITCH;
	NewGad.ng_GadgetText=(UBYTE *)NULL;
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(CHECKBOX_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_E4_SWITCH]=PrevGadget;

	NewGad.ng_LeftEdge	=88;
	NewGad.ng_TopEdge	=186;
	NewGad.ng_Width		=70;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_ACCEPT;
	NewGad.ng_GadgetText=(UBYTE *)"Accept";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_ACCEPT]=PrevGadget;

	NewGad.ng_LeftEdge	=242;
	NewGad.ng_TopEdge	=186;
	NewGad.ng_Width		=70;
	NewGad.ng_Height	=11;
	NewGad.ng_GadgetID	=BLOCKWINGAD_MODIFY;
	NewGad.ng_GadgetText=(UBYTE *)"Modify";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	BlockWinGadgets[BLOCKWINGAD_MODIFY]=PrevGadget;

	if(!PrevGadget) {
		printf("Problemi con la creazione dei gadget per BlockWin\n");
		return(1);
	}



 //**** Crea la lista di gadget per la finestra Map

	if(!(PrevGadget=CreateContext(&MapWinGadList))) {
		printf("Problemi in CreateContext(&MapWinGadList)\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=618;
	NewGad.ng_TopEdge	=11;
	NewGad.ng_Width		=18;
	NewGad.ng_Height	=214;
	NewGad.ng_GadgetID	=MAPWINGAD_VSCROLL;
	NewGad.ng_GadgetText=NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(SCROLLER_KIND,PrevGadget,&NewGad,
//							GA_Immediate, TRUE,
							GA_RelVerify, TRUE,
							PGA_Freedom, LORIENT_VERT,
							GTSC_Top, 0,
							GTSC_Total, 128,
							GTSC_Visible, 29,
							GTSC_Arrows, 9,
							TAG_DONE,0);
	MapWinGadgets[MAPWINGAD_VSCROLL]=PrevGadget;

	NewGad.ng_LeftEdge	=4;
	NewGad.ng_TopEdge	=234;
	NewGad.ng_Width		=594;
	NewGad.ng_Height	=9;
	NewGad.ng_GadgetID	=MAPWINGAD_HSCROLL;
	NewGad.ng_GadgetText=NULL;
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(SCROLLER_KIND,PrevGadget,&NewGad,
//							GA_Immediate, TRUE,
							GA_RelVerify, TRUE,
							PGA_Freedom, LORIENT_HORIZ,
							GTSC_Top, 0,
							GTSC_Total, 128,
							GTSC_Visible, 29,
							GTSC_Arrows, 18,
							TAG_DONE,0);
	MapWinGadgets[MAPWINGAD_HSCROLL]=PrevGadget;

	NewGad.ng_LeftEdge	=618;
	NewGad.ng_TopEdge	=225;
	NewGad.ng_Width		=18;
	NewGad.ng_Height	=9;
	NewGad.ng_GadgetID	=MAPWINGAD_ZOOMIN;
	NewGad.ng_GadgetText=(UBYTE *)"+";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	MapWinGadgets[MAPWINGAD_ZOOMIN]=PrevGadget;

	NewGad.ng_LeftEdge	=598;
	NewGad.ng_TopEdge	=234;
	NewGad.ng_Width		=18;
	NewGad.ng_Height	=9;
	NewGad.ng_GadgetID	=MAPWINGAD_ZOOMOUT;
	NewGad.ng_GadgetText=(UBYTE *)"-";
	NewGad.ng_Flags		=PLACETEXT_IN;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	MapWinGadgets[MAPWINGAD_ZOOMOUT]=PrevGadget;


	if(!PrevGadget) {
		printf("Problemi con la creazione dei gadget per MapWin\n");
		return(1);
	}



 //**** Crea la lista di gadget per la finestra Tools
 //**** N.B.
 //****     Non si tratta di gadget della GadTools

	ToolsWinGadgets[TOOLSWINGAD_DRAW]=&DrawToolGadget;
	ToolsWinGadgets[TOOLSWINGAD_LINE]=&LineToolGadget;
	ToolsWinGadgets[TOOLSWINGAD_BOX] =&BoxToolGadget;
	ToolsWinGadgets[TOOLSWINGAD_FILL]=&FillToolGadget;
	ToolsWinGadgets[TOOLSWINGAD_UNDO]=&UndoToolGadget;
	ToolsWinGadgets[TOOLSWINGAD_PICK]=&PickToolGadget;
	ToolsWinGadgets[TOOLSWINGAD_OBJ] =&ObjToolGadget;

	ToolsWinGadList = ToolsWinGadgets[TOOLSWINGAD_DRAW];




 //**** Crea la lista di gadget per la finestra Directories

	if(!(PrevGadget=CreateContext(&DirsWinGadList))) {
		printf("Problemi in CreateContext(&DirsWinGadList)\n");
		return(1);
	}

	NewGad.ng_LeftEdge	=110;
	NewGad.ng_TopEdge	=120;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=15;
	NewGad.ng_GadgetID	=DIRSWINGAD_OK;
	NewGad.ng_GadgetText=(UBYTE *)"Ok";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	DirsWinGadgets[DIRSWINGAD_OK]=PrevGadget;

	NewGad.ng_LeftEdge	=230;
	NewGad.ng_TopEdge	=120;
	NewGad.ng_Width		=60;
	NewGad.ng_Height	=15;
	NewGad.ng_GadgetID	=DIRSWINGAD_CANCEL;
	NewGad.ng_GadgetText=(UBYTE *)"Cancel";
	NewGad.ng_Flags		=NULL;
	PrevGadget=CreateGadget(BUTTON_KIND,PrevGadget,&NewGad,TAG_DONE,0);
	DirsWinGadgets[DIRSWINGAD_CANCEL]=PrevGadget;

	NewGad.ng_LeftEdge	=12;
	NewGad.ng_TopEdge	=20;
	NewGad.ng_Width		=220;
	NewGad.ng_Height	=14;
	NewGad.ng_GadgetID	=DIRSWINGAD_TEMP;
	NewGad.ng_GadgetText=(UBYTE *)"Temporary files";
	NewGad.ng_Flags		=PLACETEXT_RIGHT;
	PrevGadget=CreateGadget(STRING_KIND,PrevGadget,&NewGad,
							GTST_String, TempDir_Pref,
							GTST_MaxChars, 255,
							TAG_DONE,0);
	DirsWinGadgets[DIRSWINGAD_TEMP]=PrevGadget;

	if(!PrevGadget) {
		printf("Problemi con la creazione dei gadget per DirsWin\n");
		return(1);
	}

	return(0);
}


//*****************************************************************************

//*** Legge file preferenze

int	GetPreferences() {

	strcpy(TempDir_Pref,"ram:");

	return(0);
}


//*****************************************************************************



//*** Apre finestra level properties

void OpenLevelWindow() {

	if(LevelWin) {		// Se già aperta, la porta di fronte e ritorna subito
		WindowToFront(LevelWin);
		ActivateWindow(LevelWin);
		return;
	}

	LevelWin = OpenWindowTags(NULL,
						WA_Left,	160,
						WA_Top,		70,
						WA_Width,	320,
						WA_Height,	100,
						WA_Flags,	WFLG_DRAGBAR|WFLG_DEPTHGADGET|
									WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|
									WFLG_ACTIVATE|WFLG_NEWLOOKMENUS,
						WA_IDCMP,	IDCMP_CLOSEWINDOW|IDCMP_MENUPICK|
									IDCMP_GADGETUP|IDCMP_INTUITICKS,
						WA_Title,	"Level properties",
						WA_Gadgets,	LevelWinGadList,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

	if(!LevelWin) {
		ShowMessage("Problems opening Level window !",0);
		error=GENERIC_ERROR;
		return;
	}

	PrintIText(LevelWin->RPort, LevelWinIText, LevelWin->BorderLeft, LevelWin->BorderTop);

	GT_RefreshWindow(LevelWin,NULL);

	LevelWinSigBit = 1 << LevelWin->UserPort->mp_SigBit;
	OpenedWindow |= LevelWinSigBit;

	if(!SetMenuStrip(LevelWin, myMenu)) {
		ShowMessage("Problems with Level window SetMenuStrip !",0);
		error=GENERIC_ERROR;
		return;
	}
}



//*** Apre finestra block

void OpenBlockWindow() {

	if(BlockWin) {		// Se già aperta, la porta di fronte e ritorna subito
		WindowToFront(BlockWin);
		ActivateWindow(BlockWin);
		return;
	}

	BlockWin = OpenWindowTags(NULL,
						WA_Left,	0,
						WA_Top,		11,
						WA_Width,	441,
						WA_Height,	200,
						WA_Flags,	WFLG_DRAGBAR|WFLG_DEPTHGADGET|
									WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|
									WFLG_ACTIVATE|WFLG_NEWLOOKMENUS,
						WA_IDCMP,	IDCMP_CLOSEWINDOW|IDCMP_MENUPICK|
									IDCMP_GADGETUP|IDCMP_GADGETDOWN|
									IDCMP_MOUSEMOVE|IDCMP_INTUITICKS,
						WA_Title,	"Block",
						WA_Gadgets,	BlockWinGadList,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

	if(!BlockWin) {
		ShowMessage("Problems opening Block window !",0);
		error=GENERIC_ERROR;
		return;
	}

	PrintIText(BlockWin->RPort, BlockWinIText, BlockWin->BorderLeft, BlockWin->BorderTop);

	GT_RefreshWindow(BlockWin,NULL);

	BlockWinSigBit = 1 << BlockWin->UserPort->mp_SigBit;
	OpenedWindow |= BlockWinSigBit;

	if(!SetMenuStrip(BlockWin, myMenu)) {
		ShowMessage("Problems with Block window SetMenuStrip !",0);
		error=GENERIC_ERROR;
		return;
	}
}


//*** Apre finestra textures

void OpenTexturesWindow() {

	if(TexturesWin) {		// Se già aperta, la porta di fronte e ritorna subito
		WindowToFront(TexturesWin);
		ActivateWindow(TexturesWin);
		return;
	}

	TexturesWin = OpenWindowTags(NULL,
						WA_Left,	400,
						WA_Top,		11,
						WA_Width,	240,
						WA_Height,	190,
						WA_Flags,	WFLG_DRAGBAR|WFLG_DEPTHGADGET|
									WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|
									WFLG_ACTIVATE|WFLG_NEWLOOKMENUS,
						WA_IDCMP,	IDCMP_CLOSEWINDOW|IDCMP_MENUPICK|
									IDCMP_GADGETUP|IDCMP_INTUITICKS|LISTVIEWIDCMP,
						WA_Title,	"Textures",
						WA_Gadgets,	TexturesWinGadList,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

	if(!TexturesWin) {
		ShowMessage("Problems opening Textures window !",0);
		error=GENERIC_ERROR;
		return;
	}

	GT_RefreshWindow(TexturesWin,NULL);

	TexturesWinSigBit = 1 << TexturesWin->UserPort->mp_SigBit;
	OpenedWindow |= TexturesWinSigBit;

	if(!SetMenuStrip(TexturesWin, myMenu)) {
		ShowMessage("Problems with Textures window SetMenuStrip !",0);
		error=GENERIC_ERROR;
		return;
	}
}



//*** Apre finestra ObjList

void OpenObjListWindow() {

	if(ObjListWin) {		// Se già aperta, la porta di fronte e ritorna subito
		WindowToFront(ObjListWin);
		ActivateWindow(ObjListWin);
		return;
	}

	ObjListWin = OpenWindowTags(NULL,
						WA_Left,	115,
						WA_Top,		11,
						WA_Width,	410,
						WA_Height,	190,
						WA_Flags,	WFLG_DRAGBAR|WFLG_DEPTHGADGET|
									WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|
									WFLG_ACTIVATE|WFLG_NEWLOOKMENUS,
						WA_IDCMP,	IDCMP_CLOSEWINDOW|IDCMP_MENUPICK|
									IDCMP_GADGETUP|IDCMP_INTUITICKS|LISTVIEWIDCMP,
						WA_Title,	"Objects",
						WA_Gadgets,	ObjListWinGadList,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

	if(!ObjListWin) {
		ShowMessage("Problems opening ObjList window !",0);
		error=GENERIC_ERROR;
		return;
	}

	GT_RefreshWindow(ObjListWin,NULL);

	ObjListWinSigBit = 1 << ObjListWin->UserPort->mp_SigBit;
	OpenedWindow |= ObjListWinSigBit;

	if(!SetMenuStrip(ObjListWin, myMenu)) {
		ShowMessage("Problems with ObjList window SetMenuStrip !",0);
		error=GENERIC_ERROR;
		return;
	}
}



//*** Apre finestra SndList

void OpenSndListWindow() {

	if(SndListWin) {		// Se già aperta, la porta di fronte e ritorna subito
		WindowToFront(SndListWin);
		ActivateWindow(SndListWin);
		return;
	}

	SndListWin = OpenWindowTags(NULL,
						WA_Left,	115,
						WA_Top,		11,
						WA_Width,	410,
						WA_Height,	190,
						WA_Flags,	WFLG_DRAGBAR|WFLG_DEPTHGADGET|
									WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|
									WFLG_ACTIVATE|WFLG_NEWLOOKMENUS,
						WA_IDCMP,	IDCMP_CLOSEWINDOW|IDCMP_MENUPICK|
									IDCMP_GADGETUP|IDCMP_INTUITICKS|LISTVIEWIDCMP,
						WA_Title,	"Sounds",
						WA_Gadgets,	SndListWinGadList,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

	if(!SndListWin) {
		ShowMessage("Problems opening SndList window !",0);
		error=GENERIC_ERROR;
		return;
	}

	GT_RefreshWindow(SndListWin,NULL);

	SndListWinSigBit = 1 << SndListWin->UserPort->mp_SigBit;
	OpenedWindow |= SndListWinSigBit;

	if(!SetMenuStrip(SndListWin, myMenu)) {
		ShowMessage("Problems with SndList window SetMenuStrip !",0);
		error=GENERIC_ERROR;
		return;
	}
}



//*** Apre finestra GfxList

void OpenGfxListWindow() {

	if(GfxListWin) {		// Se già aperta, la porta di fronte e ritorna subito
		WindowToFront(GfxListWin);
		ActivateWindow(GfxListWin);
		return;
	}

	GfxListWin = OpenWindowTags(NULL,
						WA_Left,	115,
						WA_Top,		11,
						WA_Width,	410,
						WA_Height,	190,
						WA_Flags,	WFLG_DRAGBAR|WFLG_DEPTHGADGET|
									WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|
									WFLG_ACTIVATE|WFLG_NEWLOOKMENUS,
						WA_IDCMP,	IDCMP_CLOSEWINDOW|IDCMP_MENUPICK|
									IDCMP_GADGETUP|IDCMP_INTUITICKS|LISTVIEWIDCMP,
						WA_Title,	"Gfx",
						WA_Gadgets,	GfxListWinGadList,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

	if(!GfxListWin) {
		ShowMessage("Problems opening GfxList window !",0);
		error=GENERIC_ERROR;
		return;
	}

	GT_RefreshWindow(GfxListWin,NULL);

	GfxListWinSigBit = 1 << GfxListWin->UserPort->mp_SigBit;
	OpenedWindow |= GfxListWinSigBit;

	if(!SetMenuStrip(GfxListWin, myMenu)) {
		ShowMessage("Problems with GfxList window SetMenuStrip !",0);
		error=GENERIC_ERROR;
		return;
	}
}



//*** Apre finestra Effects

void OpenEffectsWindow() {

	register int		i;

	if(EffectsWin) {		// Se già aperta, la porta di fronte e ritorna subito
		WindowToFront(EffectsWin);
		ActivateWindow(EffectsWin);
		return;
	}

	EffectsWin = OpenWindowTags(NULL,
						WA_Left,	140,
						WA_Top,		11,
						WA_Width,	360,
						WA_Height,	236,
						WA_Flags,	WFLG_DRAGBAR|WFLG_DEPTHGADGET|
									WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|
									WFLG_ACTIVATE|WFLG_NEWLOOKMENUS,
						WA_IDCMP,	IDCMP_CLOSEWINDOW|IDCMP_MENUPICK|
									IDCMP_GADGETUP|IDCMP_INTUITICKS|LISTVIEWIDCMP,
						WA_Title,	"Effects",
						WA_Gadgets,	EffectsWinGadList,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

	if(!EffectsWin) {
		ShowMessage("Problems opening Effects window !",0);
		error=GENERIC_ERROR;
		return;
	}

	DrawBevelBox(EffectsWin->RPort,52,165,256,64, GT_VisualInfo,VInfo, TAG_DONE,0);
	PrintIText(EffectsWin->RPort, EffectsWinIText, EffectsWin->BorderLeft, EffectsWin->BorderTop);

	GT_RefreshWindow(EffectsWin,NULL);

	for(i=EFFWINGAD_ADDFX; i<=EFFWINGAD_KEY; i++)
		GT_SetGadgetAttrs(EffectsWinGadgets[i],EffectsWin, NULL, GA_DISABLED,TRUE, TAG_DONE,0);

	EffectsWinSigBit = 1 << EffectsWin->UserPort->mp_SigBit;
	OpenedWindow |= EffectsWinSigBit;

	if(!SetMenuStrip(EffectsWin, myMenu)) {
		ShowMessage("Problems with Effects window SetMenuStrip !",0);
		error=GENERIC_ERROR;
		return;
	}
}



//*** Apre finestra Map

void OpenMapWindow() {

	if(MapWin) {		// Se già aperta, la porta di fronte e ritorna subito
		WindowToFront(MapWin);
		ActivateWindow(MapWin);
		return;
	}

	MapWin = OpenWindowTags(NULL,
						WA_Left,	0,
						WA_Top,		11,
						WA_Width,	640,
						WA_Height,	245,
						WA_Flags,	WFLG_DEPTHGADGET|WFLG_CLOSEGADGET|
									WFLG_SMART_REFRESH|	WFLG_REPORTMOUSE|
									WFLG_ACTIVATE|WFLG_NEWLOOKMENUS,
						WA_IDCMP,	IDCMP_CLOSEWINDOW|IDCMP_MENUPICK|
									ARROWIDCMP|SCROLLERIDCMP|
									IDCMP_ACTIVEWINDOW|IDCMP_INACTIVEWINDOW|
									IDCMP_INTUITICKS,
						WA_Title,	"Map",
						WA_Gadgets,	MapWinGadList,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

	if(!MapWin) {
		ShowMessage("Problems opening Map window !",0);
		error=GENERIC_ERROR;
		return;
	}

	GT_RefreshWindow(MapWin,NULL);

	MapWinSigBit = 1 << MapWin->UserPort->mp_SigBit;
	OpenedWindow |= MapWinSigBit;

	if(!SetMenuStrip(MapWin, myMenu)) {
		ShowMessage("Problems with Map window SetMenuStrip !",0);
		error=GENERIC_ERROR;
		return;
	}

	MapWinRP = MapWin->RPort;

	OpenToolsWindow();
	ActivateWindow(MapWin);
}



//*** Apre finestra tools

void OpenToolsWindow() {

	if(ToolsWin) {		// Se già aperta, la porta di fronte e ritorna subito
		WindowToFront(ToolsWin);
		ActivateWindow(ToolsWin);
		return;
	}

	ToolsWin = OpenWindowTags(NULL,
						WA_Left,	400,
						WA_Top,		0,
						WA_Width,	155,
						WA_Height,	25,
						WA_Flags,	WFLG_DRAGBAR|WFLG_DEPTHGADGET|
									WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|
									WFLG_ACTIVATE|WFLG_NEWLOOKMENUS,
						WA_IDCMP,	IDCMP_CLOSEWINDOW|IDCMP_MENUPICK|
									IDCMP_GADGETUP,
						WA_Title,	"Tools",
						WA_Gadgets,	ToolsWinGadList,
						WA_CustomScreen, MainScr,
						TAG_DONE,0);

	if(!ToolsWin) {
		ShowMessage("Problems opening Tools window !",0);
		error=GENERIC_ERROR;
		return;
	}

//	GT_RefreshWindow(ToolsWin,NULL);

	ToolsWinSigBit = 1 << ToolsWin->UserPort->mp_SigBit;
	OpenedWindow |= ToolsWinSigBit;

	if(!SetMenuStrip(ToolsWin, myMenu)) {
		ShowMessage("Problems with Tools window SetMenuStrip !",0);
		error=GENERIC_ERROR;
		return;
	}
}


//*****************************************************************************

// Chiude finestra Project

void CloseProjectWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(ProjectWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(ProjectWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		CloseWindow(ProjectWin);
		OpenedWindow &= (0xffffffff ^ ProjectWinSigBit);
		ProjectWin = NULL;
		ProjectWinSigBit = NULL;
	}
}


// Chiude finestra directories

void CloseDirsWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(DirsWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(DirsWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		CloseWindow(DirsWin);
		OpenedWindow &= (0xffffffff ^ DirsWinSigBit);
		DirsWin = NULL;
		DirsWinSigBit = NULL;
	}
}


// Chiude finestra level

void CloseLevelWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(LevelWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(LevelWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		CloseWindow(LevelWin);
		OpenedWindow &= (0xffffffff ^ LevelWinSigBit);
		LevelWin = NULL;
		LevelWinSigBit = NULL;
	}
}


// Chiude finestra block

void CloseBlockWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(BlockWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(BlockWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		ClearMenuStrip(BlockWin);
		CloseWindow(BlockWin);
		OpenedWindow &= (0xffffffff ^ BlockWinSigBit);
		BlockWin = NULL;
		BlockWinSigBit = NULL;
	}
}


// Chiude finestra textures

void CloseTexturesWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(TexturesWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(TexturesWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		ClearMenuStrip(TexturesWin);
		CloseWindow(TexturesWin);
		OpenedWindow &= (0xffffffff ^ TexturesWinSigBit);
		TexturesWin = NULL;
		TexturesWinSigBit = NULL;
	}
}


// Chiude finestra ObjList

void CloseObjListWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(ObjListWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(ObjListWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		ClearMenuStrip(ObjListWin);
		CloseWindow(ObjListWin);
		OpenedWindow &= (0xffffffff ^ ObjListWinSigBit);
		ObjListWin = NULL;
		ObjListWinSigBit = NULL;
	}
}


// Chiude finestra Objects

void CloseObjectsWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(ObjectsWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(ObjectsWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		ClearMenuStrip(ObjectsWin);
		CloseWindow(ObjectsWin);
		OpenedWindow &= (0xffffffff ^ ObjectsWinSigBit);
		ObjectsWin = NULL;
		ObjectsWinSigBit = NULL;
	}
}


// Chiude finestra SndList

void CloseSndListWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(SndListWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(SndListWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		ClearMenuStrip(SndListWin);
		CloseWindow(SndListWin);
		OpenedWindow &= (0xffffffff ^ SndListWinSigBit);
		SndListWin = NULL;
		SndListWinSigBit = NULL;
	}
}


// Chiude finestra Sounds

void CloseSoundsWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(SoundsWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(SoundsWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		ClearMenuStrip(SoundsWin);
		CloseWindow(SoundsWin);
		OpenedWindow &= (0xffffffff ^ SoundsWinSigBit);
		SoundsWin = NULL;
		SoundsWinSigBit = NULL;
	}
}


// Chiude finestra GfxList

void CloseGfxListWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(GfxListWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(GfxListWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		ClearMenuStrip(GfxListWin);
		CloseWindow(GfxListWin);
		OpenedWindow &= (0xffffffff ^ GfxListWinSigBit);
		GfxListWin = NULL;
		GfxListWinSigBit = NULL;
	}
}


// Chiude finestra Effects

void CloseEffectsWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(EffectsWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(EffectsWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		ClearMenuStrip(EffectsWin);
		CloseWindow(EffectsWin);
		OpenedWindow &= (0xffffffff ^ EffectsWinSigBit);
		EffectsWin = NULL;
		EffectsWinSigBit = NULL;
	}
}


// Chiude finestra Effects

void CloseFxWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(FxWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(FxWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		ClearMenuStrip(FxWin);
		CloseWindow(FxWin);
		OpenedWindow &= (0xffffffff ^ FxWinSigBit);
		FxWin = NULL;
		FxWinSigBit = NULL;
	}
}


// Chiude finestra Map

void CloseMapWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(MapWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(MapWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		ClearMenuStrip(MapWin);
		CloseWindow(MapWin);
		OpenedWindow &= (0xffffffff ^ MapWinSigBit);
		MapWin = NULL;
		MapWinSigBit = NULL;
	}
}



// Chiude finestra Tools

void CloseToolsWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(ToolsWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(ToolsWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		ClearMenuStrip(ToolsWin);
		CloseWindow(ToolsWin);
		OpenedWindow &= (0xffffffff ^ ToolsWinSigBit);
		ToolsWin = NULL;
		ToolsWinSigBit = NULL;
	}
}


// Chiude finestra MapObj

void CloseMapObjWindow() {
	ULONG	imsgClass;
	UWORD	imsgCode;

	if(MapObjWin) {
		// Risponde a tutti i messaggi eventualmente rimasti in sospeso
		while(imsg = GT_GetIMsg(MapObjWin->UserPort)) {
			imsgClass = imsg->Class;
			imsgCode = imsg->Code;
			GT_ReplyIMsg(imsg);
		}

		ClearMenuStrip(MapObjWin);
		CloseWindow(MapObjWin);
		OpenedWindow &= (0xffffffff ^ MapObjWinSigBit);
		MapObjWin = NULL;
		MapObjWinSigBit = NULL;
	}
}


//*****************************************************************************

//*** Dealloca memoria per le varie entry della lista games e levels

void FreeGLList() {

	struct Node		*gnode,*nnode;

	gnode = GLList.lh_Head;
	while(gnode->ln_Succ) {
		nnode = gnode->ln_Succ;
		FreeMem(gnode,sizeof(struct GLNode));
		gnode = nnode;
	}
	NewList(&GLList);
}


//*** Dealloca memoria per le varie entry della directory delle texture

void FreeTextList() {

	struct Node		*tnode,*nnode;

	tnode = TexturesList.lh_Head;
	while(tnode->ln_Succ) {
		nnode = tnode->ln_Succ;
		FreeMem(tnode,sizeof(struct TextDirNode));
		tnode = nnode;
	}
	NewList(&TexturesList);
}


//*** Dealloca memoria per le varie entry delle liste di effetti

void FreeEffectsList() {

	struct Node		*tnode,*nnode;

	tnode = EffectsList.lh_Head;
	while(tnode->ln_Succ) {
		nnode = tnode->ln_Succ;
		FreeMem(tnode,sizeof(struct EffectDirNode));
		tnode = nnode;
	}
	NewList(&EffectsList);
}


//*** Dealloca memoria per le varie entry della directory degli oggetti

void FreeObjList() {

	struct Node		*tnode,*nnode;

	tnode = ObjectsList.lh_Head;
	while(tnode->ln_Succ) {
		nnode = tnode->ln_Succ;
		FreeMem(tnode,sizeof(struct ObjDirNode));
		tnode = nnode;
	}
	NewList(&ObjectsList);
}



//*** Dealloca memoria per le varie entry della directory dei suoni

void FreeSoundList() {

	struct Node		*tnode,*nnode;

	tnode = SoundsList.lh_Head;
	while(tnode->ln_Succ) {
		nnode = tnode->ln_Succ;
		FreeMem(tnode,sizeof(struct SoundNode));
		tnode = nnode;
	}
	NewList(&SoundsList);
}



//*** Dealloca memoria per le varie entry della directory gfx

void FreeGfxList() {

	struct Node		*tnode,*nnode;

	tnode = GfxList.lh_Head;
	while(tnode->ln_Succ) {
		nnode = tnode->ln_Succ;
		FreeMem(tnode,sizeof(struct GfxNode));
		tnode = nnode;
	}
	NewList(&GfxList);
}



//*** Dealloca la memoria della Edge e della Block List

void FreeEdgeBlockLists() {

	struct Block	*bp1, *bp2;
	struct Edge		*ep1, *ep2;

 //*** Libera la memoria della EdgeList

	ep1 = EdgeList;
	while(ep1) {
		ep2 = ep1->Next;
		FreeMem(ep1,sizeof(struct Edge));
		ep1 = ep2;
	}
	EdgeList = NULL;

 //*** Libera la memoria della BlockList

	bp1 = BlockList;
	while(bp1) {
		bp2 = bp1->Next;
		FreeMem(bp1,sizeof(struct Block));
		bp1 = bp2;
	}
	BlockList = NULL;
}



//*** Dealloca la memoria della MapObjectList

void FreeMapObjectList() {

	struct MapObject	*mp1, *mp2;

	mp1 = MapObjectList;
	while(mp1) {
		mp2 = mp1->Next;
		FreeMem(mp1,sizeof(struct MapObject));
		mp1 = mp2;
	}
	MapObjectList = NULL;

}


//*****************************************************************************

//*** Chiude tutto cio' che e' stato aperto

void CleanUp() {

	FreeGLList();
	FreeTextList();
	FreeEffectsList();
	FreeObjList();
	FreeSoundList();
	FreeGfxList();
	FreeEdgeBlockLists();
	FreeMapObjectList();

	if(FileReq)	FreeAslRequest(FileReq);
	if(PrjFileReq)	rtFreeRequest(PrjFileReq);
	if(TextFileReq)	rtFreeRequest(TextFileReq);
	if(ObjFileReq)	rtFreeRequest(ObjFileReq);
	if(SndFileReq)	rtFreeRequest(SndFileReq);
	if(GfxFileReq)	rtFreeRequest(GfxFileReq);

	if(MainWin) {
		if(myMenu)	ClearMenuStrip(MainWin);
		CloseWindow(MainWin);
	}

	if(GraphWin) CloseWindow(GraphWin);

	CloseProjectWindow();
	CloseLevelWindow();
	CloseDirsWindow();
	CloseTexturesWindow();
	CloseObjListWindow();
	CloseObjectsWindow();
	CloseMapObjWindow();
	CloseSndListWindow();
	CloseSoundsWindow();
	CloseGfxListWindow();
	CloseEffectsWindow();
	CloseBlockWindow();
	CloseMapWindow();
	CloseToolsWindow();
	CloseDirsWindow();

	if(ProjectWinGadList)	FreeGadgets(ProjectWinGadList);
	if(LevelWinGadList)		FreeGadgets(LevelWinGadList);
	if(MapWinGadList)		FreeGadgets(MapWinGadList);
	if(TexturesWinGadList)	FreeGadgets(TexturesWinGadList);
	if(ObjListWinGadList)	FreeGadgets(ObjListWinGadList);
	if(ObjectsWinGadList)	FreeGadgets(ObjectsWinGadList);
	if(MapObjWinGadList)	FreeGadgets(MapObjWinGadList);
	if(SndListWinGadList)	FreeGadgets(SndListWinGadList);
	if(SoundsWinGadList)	FreeGadgets(SoundsWinGadList);
	if(GfxListWinGadList)	FreeGadgets(GfxListWinGadList);
	if(EffectsWinGadList)	FreeGadgets(EffectsWinGadList);
	if(FxWinGadList)		FreeGadgets(FxWinGadList);
	if(BlockWinGadList) 	FreeGadgets(BlockWinGadList);
	if(DirsWinGadList)		FreeGadgets(DirsWinGadList);

	if(myMenu)	FreeMenus(myMenu);
	if(VInfo)	FreeVisualInfo(VInfo);
	if(DrInfo)	FreeScreenDrawInfo(MainScr, DrInfo);

	if(MainScr)		CloseScreen(MainScr);
	if(GraphScr)	CloseScreen(GraphScr);

	if(ColorTable)		FreeMem(ColorTable,COLORTABLE_LEN);
	if(MapBuffer)		FreeMem(MapBuffer,MAP_LEN);
	if(GfxBuffer)		FreeMem(GfxBuffer,GFXBUFFER_LEN);

	if(ReqToolsBase)	CloseLibrary((struct Library *)ReqToolsBase);
	if(AslBase)			CloseLibrary((struct Library *)AslBase);
	if(GadToolsBase)	CloseLibrary((struct Library *)GadToolsBase);
	if(GfxBase)			CloseLibrary((struct Library *)GfxBase);
	if(IntuitionBase)	CloseLibrary((struct Library *)IntuitionBase);

	exit(0);
}



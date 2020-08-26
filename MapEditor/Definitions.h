//*****************************************************************************
//***
//***		Definitions.h
//***
//***	Definizioni di variabili e funzioni.
//***
//***
//***
//*****************************************************************************

//*****************************************************************************

//*** Puntatori alle librerie usate

extern struct IntuitionBase		*IntuitionBase;
extern struct GfxBase			*GfxBase;
extern struct Library			*GadToolsBase;
extern struct Library			*AslBase;
extern struct Library           *ReqToolsBase;

//*** Definizione di dati e strutture usate dal programma

 //*** Variabili varie

extern int		error;
extern long		ScrWidth, ScrHeight;
extern long		NumGame;
extern long		MapWinX1,MapWinY1,MapWinWidth,MapWinHeight,MapZoom;
extern long		MapWinWidthR,MapWinHeightR;
extern short	MouseX,MouseY;
extern short	MapX1Pos,MapY1Pos,MapXPos,MapYPos;
extern short	MapWidth,MapHeight;
extern int		MapGridType,DrawWhat,TextureSelect,EffectSelect,TriggerSelect;
extern int		SoundSelect, GfxSelect;
extern struct Window	*GfxSelectWin, *SoundSelectWin;

extern long		NumUsedTexture,NumUsedObjects,NumUsedSounds,NumObjects;
extern long		LastBlock,LastEdge;
extern long		FloorHeight,CeilHeight,Illumination;
extern WORD		SkyCeil,FogLighting;
extern WORD		UnpeggedUpE1,UnpeggedLowE1,SwitchE1;
extern WORD		UnpeggedUpE2,UnpeggedLowE2,SwitchE2;
extern WORD		UnpeggedUpE3,UnpeggedLowE3,SwitchE3;
extern WORD		UnpeggedUpE4,UnpeggedLowE4,SwitchE4;
extern char		*n_FloorTexture,*n_CeilTexture,*n_UpTextureE1,*n_NormTextureE1;
extern char		*n_LowTextureE1,*n_UpTextureE2,*n_NormTextureE2,*n_LowTextureE2;
extern char		*n_UpTextureE3,*n_NormTextureE3,*n_LowTextureE3,*n_UpTextureE4;
extern char		*n_NormTextureE4,*n_LowTextureE4;

extern struct TextDirNode	*FloorTexture,*CeilTexture,*UpTextureE1,*NormTextureE1;
extern struct TextDirNode	*LowTextureE1,*UpTextureE2,*NormTextureE2,*LowTextureE2;
extern struct TextDirNode	*UpTextureE3,*NormTextureE3,*LowTextureE3,*UpTextureE4;
extern struct TextDirNode	*NormTextureE4,*LowTextureE4;

extern char		*n_MapObjTriggerNum,*n_EffectNum,*n_TriggerNum,*n_TriggerNum2;
extern struct EffectDirNode		*MapObjEffect, *BlockEffect;
extern struct EffectDirNode		*BlockTrigger, *BlockTrigger2;

extern WORD	BlockType,EnemyBlocker;

extern char	*n_LevelLoadPic,*n_LevelMod;

extern char	*n_MapObjName;

extern char	*n_Effect,*n_EffParam1,*n_EffParam2;

extern char *n_ObjSound1,*n_ObjSound2,*n_ObjSound3;

extern long	LastTrigger,LastEffectList;

extern struct FxNode		*SelectedFx;
extern struct EffectDirNode	*SelectedEffectList,*SelectedEffect,*SelectedEffectNode;
extern WORD  Trigger2FX[];

extern struct FxNode	EngineFx[];

extern WORD			CurrBlockCode;
extern struct Block	*CurrBlockPun;

extern WORD					CurrObjCode;
extern struct ObjDirNode	*CurrObjPun, *SelectedObj;
extern struct MapObject		*SelectedMapObj;

extern struct SoundNode	*SelectedSound;

extern struct GfxNode	*SelectedGfx;

extern UBYTE	Palette[3*256];
extern WORD		SelectedTexture;
extern WORD		SelectedTool, ToolType;

extern UBYTE	KeyColor;

extern WORD		Player1StartX,Player1StartY;
extern WORD		Player2StartX,Player2StartY;

 //*** Puntatori a memoria allocata

extern UBYTE	*GfxBuffer;
extern SHORT	*MapBuffer;
extern ULONG	*ColorTable;


 //*** Flags (i nomi delle variabili flag devono finire con "_fl")

extern int		ShowWarns_fl,EditPrj_fl,ModifiedPrj_fl,NamedPrj_fl,ShowText_fl;
extern int		SolidWall_fl,ModifiedTextList_fl,ModifiedMap_fl;
extern int		ModifiedObjList_fl,ModifiedSoundList_fl,ShowMapObj_fl;
extern int		ModifiedGfx_fl;


 //*** Nomi di file e di directory

extern char		filename[256];

extern char		ProjectName[256],ProjectDir[256];
extern char		ProjectNotes[34],ProjectPrefix[6];
extern char		ProjectSoundFileName[6],ProjectTextFileName[6];
extern char		ProjectObjFileName[6],ProjectGfxFileName[6];
extern char		TextureName[64],TexturesDir[256];
extern char		ObjectsDir[256],SoundsDir[256],GfxDir[256];


 //*** Preferenze (i nomi delle variabili devono finire con "_Pref")

extern char		TempDir_Pref[255];


 //*** Struct

extern struct PictureHeader	TexturePicHead, ObjectPicHead, GfxPicHead;

extern struct Block	*BlockList, CurrBlock;
extern struct Edge	*EdgeList, Edge1, Edge2, Edge3, Edge4;
extern struct MapObject *MapObjectList;


//*** Definizione di strutture di sistema

extern struct Screen	*MainScr,*GraphScr;
extern struct Window	*ProjectWin,*LevelWin;
extern struct Window	*MainWin,*GraphWin,*TexturesWin,*BlockWin,*DirsWin;
extern struct Window	*ObjListWin,*ObjectsWin,*EffectsWin,*FxWin,*MapWin;
extern struct Window	*ToolsWin,*MapObjWin,*SndListWin,*SoundsWin;
extern struct Window	*GfxListWin;
extern struct Menu		*myMenu;

extern struct RastPort	*GraphScrRP,rp,*MapWinRP;
extern struct ViewPort	*GraphScrVP;

extern ULONG	ActiveWindow,OpenedWindow;

extern ULONG	ProjectWinSigBit,LevelWinSigBit;
extern ULONG	MainWinSigBit,GraphWinSigBit,TexturesWinSigBit;
extern ULONG	ObjListWinSigBit,ObjectsWinSigBit,EffectsWinSigBit;
extern ULONG	SndListWinSigBit,SoundsWinSigBit;
extern ULONG	GfxListWinSigBit;
extern ULONG	FxWinSigBit,BlockWinSigBit,MapWinSigBit,ToolsWinSigBit;
extern ULONG	DirsWinSigBit,MapObjWinSigBit;

extern struct Node		*nodo;
extern struct List		GLList;
extern struct List		TexturesList;
extern struct List		ObjectsList;
extern struct List		SoundsList;
extern struct List		GfxList;
extern struct List		EffectsList;
extern struct List		FxList;

extern struct Gadget	*PrevGadget;
extern struct Gadget	*ProjectWinGadList, *ProjectWinGadgets[];
extern struct Gadget	*LevelWinGadList, *LevelWinGadgets[];
extern struct Gadget	*TexturesWinGadList, *TexturesWinGadgets[];
extern struct Gadget	*ObjListWinGadList, *ObjListWinGadgets[];
extern struct Gadget	*ObjectsWinGadList, *ObjectsWinGadgets[];
extern struct Gadget	*MapObjWinGadList, *MapObjWinGadgets[];
extern struct Gadget	*SndListWinGadList, *SndListWinGadgets[];
extern struct Gadget	*SoundsWinGadList, *SoundsWinGadgets[];
extern struct Gadget	*GfxListWinGadList, *GfxListWinGadgets[];
extern struct Gadget	*EffectsWinGadList, *EffectsWinGadgets[];
extern struct Gadget	*FxWinGadList, *FxWinGadgets[];
extern struct Gadget	*BlockWinGadList, *BlockWinGadgets[];
extern struct Gadget	*MapWinGadList, *MapWinGadgets[];
extern struct Gadget	*ToolsWinGadList, *ToolsWinGadgets[];
extern struct Gadget	*DirsWinGadList, *DirsWinGadgets[];
extern struct NewGadget	NewGad;

extern APTR VInfo;

struct DrawInfo			*DrInfo;

extern struct FileRequester		*FileReq;
extern struct rtFileRequester	*PrjFileReq, *TextFileReq;
extern struct rtFileRequester	*ObjFileReq, *SndFileReq, *GfxFileReq;

extern struct IntuiMessage		*imsg;
extern struct MenuItem			*MItem;


extern struct Image DrawToolImage, LineToolImage, BoxToolImage;
extern struct Image FillToolImage, UndoToolImage, PickToolImage, ObjToolImage;
extern struct Image SelDrawToolImage, SelLineToolImage, SelBoxToolImage, SelFilledBoxToolImage;
extern struct Image SelFillToolImage, SelUndoToolImage, SelPickToolImage, SelObjToolImage;

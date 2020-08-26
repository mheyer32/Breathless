//*****************************************************************************
//***
//***		Protos.h
//***
//***	Prototipi delle funzioni.
//***
//***
//***
//*****************************************************************************

#include <exec/types.h>

struct Gadget;
struct PictureHeader;
struct MapObject;
struct SoundNode;
struct TextDirNode;
struct ObjDirNode;
struct GfxNode;
struct Edge;
struct Block;
struct GLNode;
struct Window;

//*** MapEditor3d

void ShowProgress(long level, long maxlevel, char *title);
int ShowMessage(char *str,int flag);
void ShowErrorMessage(int err, APTR message);
void DiscardWindowInput(ULONG winbit);
void MapWinDim(void);
int SelectPrjName(void);
void OptimizeMap(void);
void TurnOffIDCMP(ULONG winbit);
void TurnOnIDCMP(ULONG winbit);
int ShowMessage2(char *str,int flag,APTR param);
int ShowMessageW(struct Window *win,char *str,int flag);
void TurnOffMenu(void);
void TurnOnMenu(void);
void MakeRGB32Table(UBYTE *palette);

//*** Textures

void PlanarToChunky(struct PictureHeader *PicHead, UBYTE *punbuf);
int	ReadTempTextFile(long l, char *name, int delflag);
void ShowTexture(long n);
void AddNewTexture(short type);
void AddSwitchTexture(void);
void ModifyTexture(void);
int RemoveTexture(UWORD ntext);
void ProcessTextureList(UWORD imsgCode, ULONG seconds, ULONG micros);
long ArrangeTextureList(void);


//*** Objects

long ArrangeObjectsList(void);
long CountObjects(long *enemies, long *things);
void RemoveObject(struct ObjDirNode *object);
struct MapObject *AddMapObject(long x, long y, struct ObjDirNode *object);
struct MapObject *CheckMapObject(long x, long y);
int	ReadTempObjFile(char *name, long length, int delflag);
void OpenObjectsWindow(struct ObjDirNode *object, short modflag);
void ProcessObjList(UWORD imsgCode, ULONG seconds, ULONG micros);
void OpenMapObjWindow(struct MapObject *object);
void ProcessMapObjWinGad(struct Gadget *gad, UWORD imsgCode);

//*** Effects

void CheckEffectsList(void);
void ProcessEffectsWinGad(struct Gadget *gad, UWORD imsgCode, ULONG seconds, ULONG micros);


//*** Sounds

struct SoundNode *SearchSound(char *name);
long ArrangeSoundsList(void);
int	ReadTempSoundFile(char *name, long length, int delflag);
void RemoveSound(struct SoundNode *sound);
void OpenSoundsWindow(struct SoundNode *sound);
int ProcessSndList(UWORD imsgCode, ULONG seconds, ULONG micros);
void ProcessSndListWindow(void);


//*** Gfx

void ProcessGfxList(UWORD imsgCode, ULONG seconds, ULONG micros);
int	ReadTempGfxFile(char *name, long length, int delflag);
long ReadTempGfxFile2(char *name);
void RemovePic(struct GfxNode *gfx);
void AddNewPic(void);



//*** ProcessMap.c

void SetMapWinTitle(void);
void MapWinDIm(void);
void MouseMapPosvoid(void);
void DrawMapGrid(void);
void ClearMap(void);
void DrawMap(void);
void HilightBlock(WORD hblock);
void PlotBlock(long x, long y, WORD block);
void ShowLine(long x1, long y1, long x2, long y2);
void DrawBlockLine(long x1, long y1, long x2, long y2, WORD block);
void ShowBox(long x1, long y1, long x2, long y2);
void DrawBlockBox(long x1, long y1, long x2, long y2, WORD block);
void PlotObject(long x, long y, struct ObjDirNode *object);
void DrawMapObjects(void);
void DelMapObject(struct MapObject *object);
void SelectMapObject(struct MapObject *object);
struct Edge *FindEdge(struct Edge *edge);
struct Block *FindBlock(struct Block *block);
struct Block *FindBlockTexture(struct TextDirNode *text);
void AcceptBlock(void);
void ModifyBlock(void);
void PickBlock(long x, long y);
void MouseMapPos(void);
void DrawMapGrid(void);
void MoveMapObject(long x, long y, struct MapObject *object);

//*** SetUp.c

int SetUpAll(void);
int GetPreferences(void);
void OpenLevelWindow(void);
void OpenBlockWindow(void);
void OpenTexturesWindow(void);
void OpenObjListWindow(void);
void OpenSndListWindow(void);
void OpenGfxListWindow(void);
void OpenEffectsWindow(void);
void OpenMapWindow(void);
void OpenToolsWindow(void);
void CloseProjectWindow(void);
void CloseDirsWindow(void);
void CloseLevelWindow(void);
void CloseBlockWindow(void);
void CloseTexturesWindow(void);
void CloseObjectsWindow(void);
void CloseObjListWindow(void);
void CloseSoundsWindow(void);
void CloseSndListWindow(void);
void CloseGfxListWindow(void);
void CloseEffectsWindow(void);
void CloseFxWindow(void);
void CloseMapWindow(void);
void CloseToolsWindow(void);
void CloseMapObjWindow(void);
void FreeGLList(void);
void FreeTextList(void);
void FreeEffectsList(void);
void FreeObjList(void);
void FreeSoundList(void);
void FreeGfxList(void);
void FreeEdgeBlockLists(void);
void FreeMapObjectList(void);
void CleanUp(void);


//*** GLDAccess.c

int ReadMapGLD(struct GLNode *level);
int ReadTexturesGLD(void);
int ReadObjectsGLD(void);
int ReadGfxGLD(void);
int ReadSoundsGLD(void);
int ReadMainGLD(void);

int WriteMapGLD(struct GLNode *level);
int WriteTexturesGLD(void);
int WriteObjectsGLD(void);
int WriteGfxGLD(void);
int WriteSoundsGLD(void);
int WriteMainGLD(void);

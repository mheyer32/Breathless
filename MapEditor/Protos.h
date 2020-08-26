//*****************************************************************************
//***
//***		Protos.h
//***
//***	Prototipi delle funzioni.
//***
//***
//***
//*****************************************************************************


//*** MapEditor3d

void ShowProgress(long level, long maxlevel, char *title);
int ShowMessage(char *str,int flag);
void ShowErrorMessage(int err, APTR message);
void DiscardWindowInput(ULONG winbit);


//*** Textures

void PlanarToChunky(struct PictureHeader *PicHead, UBYTE *punbuf);
int	ReadTempTextFile(long l, char *name, int delflag);
void ShowTexture(long n);
void AddNewTexture(short type);
void AddSwitchTexture();
void ModifyTexture();
int RemoveTexture(UWORD ntext);
void ProcessTextureList(UWORD imsgCode, ULONG seconds, ULONG micros);
long ArrangeTextureList();


//*** Objects

long ArrangeObjectsList();
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

void CheckEffectsList();
void ProcessEffectsWinGad(struct Gadget *gad, UWORD imsgCode, ULONG seconds, ULONG micros);


//*** Sounds

struct SoundNode *SearchSound(char *name);
long ArrangeSoundsList();
int	ReadTempSoundFile(char *name, long length, int delflag);
void RemoveSound(struct SoundNode *sound);
void OpenSoundsWindow(struct SoundNode *sound);
int ProcessSndList(UWORD imsgCode, ULONG seconds, ULONG micros);
void ProcessSndListWindow();


//*** Gfx

void ProcessGfxList(UWORD imsgCode, ULONG seconds, ULONG micros);
int	ReadTempGfxFile(char *name, long length, int delflag);
long ReadTempGfxFile2(char *name);
void RemovePic(struct GfxNode *gfx);
void AddNewPic();



//*** ProcessMap.c

void SetMapTitle();
void MapWinDIm();
void MouseMapPos();
void DrawMapGrid();
void ClearMap();
void DrawMap();
void HilightBlock(WORD hblock);
void PlotBlock(long x, long y, WORD block);
void ShowLine(long x1, long y1, long x2, long y2);
void DrawBlockLine(long x1, long y1, long x2, long y2, WORD block);
void ShowBox(long x1, long y1, long x2, long y2);
void DrawBlockBox(long x1, long y1, long x2, long y2, WORD block);
void PlotObject(long x, long y, struct ObjDirNode *object);
void DrawMapObjects();
void DelMapObject(struct MapObject *object);
void SelectMapObject(struct MapObject *object);
struct Edge *FindEdge(struct Edge *edge);
struct Block *FindBlock(struct Block *block);
struct Block *FindBlockTexture(struct TextDirNode *text);
void AcceptBlock();
void ModifyBlock();
void PickBlock(long x, long y);


//*** SetUp.c

int SetUpAll();
int GetPreferences();
void OpenLevelWindow();
void OpenBlockWindow();
void OpenTexturesWindow();
void OpenObjListWindow();
void OpenSndListWindow();
void OpenGfxListWindow();
void OpenEffectsWindow();
void OpenMapWindow();
void OpenToolsWindow();
void CloseProjectWindow();
void CloseDirsWindow();
void CloseLevelWindow();
void CloseBlockWindow();
void CloseTexturesWindow();
void CloseObjectsWindow();
void CloseObjListWindow();
void CloseSoundsWindow();
void CloseSndListWindow();
void CloseGfxListWindow();
void CloseEffectsWindow();
void CloseFxWindow();
void CloseMapWindow();
void CloseToolsWindow();
void CloseMapObjWindow();
void FreeGLList();
void FreeTextList();
void FreeEffectsList();
void FreeObjList();
void FreeSoundList();
void FreeGfxList();
void FreeEdgeBlockLists();
void FreeMapObjectList();
void CleanUp();


//*** GLDAccess.c

int ReadMapGLD();
int ReadTexturesGLD();
int ReadObjectsGLD();
int ReadGfxGLD();
int ReadSoundsGLD();
int ReadMainGLD();

int WriteMapGLD();
int WriteTexturesGLD();
int WriteObjectsGLD();
int WriteGfxGLD();
int WriteSoundsGLD();
int WriteMainGLD();

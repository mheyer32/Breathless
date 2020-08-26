//*****************************************************************************
//***
//***		MapEditor3d.h
//***
//***
//***
//***
//***
//*****************************************************************************

#include	"PicIff.h"
#include	"Support.h"
#include	"Protos.h"

#include    <proto/exec.h>
#include    <proto/intuition.h>
#include    <proto/gadtools.h>
#include	<proto/reqtools.h>
#include    <proto/graphics.h>
#include    <clib/alib_protos.h>
#include    <dos/dosextens.h>
#include    <libraries/reqtools.h>

//*****************************************************************************

#define MAP_WIDTH				128			/* Dimensioni mappa */
#define MAP_HEIGHT				128
#define MAP_WIDTH_B				7			/* Valore di shift per MAP_WIDTH */

#define	GFXBUFFER_LEN			262144		/* Memoria per il buffer della grafica */
#define	COLORTABLE_LEN			3080		/* Memoria per le color table */
#define	MAP_LEN					32768		/* Memoria per la mappa */

#define	MAINSCR_W				640			/* MainScr width */
#define	MAINSCR_H				256
#define	GRAPHSCR_W				320			/* GraphScr width */
#define	GRAPHSCR_H				256

#define	FILENAME_LEN			256			/* Lunghezza massima delle stringhe per filenames */
#define	MAXFRAME				8			/* Numero massimo di frame per texture animata */
#define	OBJMAXFRAME				140			/* Numero massimo di frame per oggetto */

//*****************************************************************************

//*** Codici d'errore

#define	OK				0
#define GENERIC_ERROR	1		/* Errore generico che viene comunicato all'utente dalla funzione che lo genera */
#define	NO_MEMORY		2
#define BADFILENAME		3
#define BADGLDFILE		4


//*** ID dei file GLD

#define MakeID(a,b,c,d) ((ULONG)(a)<<24|(ULONG)(b)<<16|(ULONG)(c)<<8|(ULONG)(d))

#define MGLD_ID			MakeID('M','G','L','D')		/* Main GLD */
#define LGLD_ID			MakeID('L','G','L','D')		/* Level GLD */
#define TGLD_ID			MakeID('T','G','L','D')		/* Textures GLD */
#define OGLD_ID			MakeID('O','G','L','D')		/* Objects GLD */
#define GGLD_ID			MakeID('G','G','L','D')		/* Gfx GLD */
#define SGLD_ID			MakeID('S','G','L','D')		/* Sounds GLD */

//*****************************************************************************

//*** Nodo per una entry nella directory delle textures

struct TextDirNode {
	struct Node		tdn_node;
	char			tdn_name[18];	// I primi 8 char sono il nome.
									// Seguono due spazi,
									// poi 3 caratteri numerici per width della texture,
									// poi un char 'x',
									// poi 3 caratteri numerici per height della texture,
									// poi un char '\0' come terminatore della stringa
	short			tdn_type;		// Texture type:  0=texture vuota;  1=texture normale; n=texture animata con n frame;
	short			tdn_width;		// Texture horizontal dimensions
	short			tdn_height;		// Texture vertical dimensions
	long			tdn_offset;		// Offset sul file .GLD
	long			tdn_length;		// Lunghezza sul file .GLD
	short			tdn_location;	// Se=0, la texture è sul file .GLD;
									// Se=1, è su un file della directory temporanea
	short			tdn_num;		// Numero texture, usato in fase di save del progetto
	short			tdn_switch;		// Se=1, si tratta di una texture switch, dotata, quindi, di due frame
};


//*** Struttura texture su file

struct FTexture {
	WORD	Width;
	WORD	Animation;				// Numero frame
	WORD	Height;
	WORD	HShift;					// Height shift
	LONG	Frame;					// Offset (rispetto a Height) al primo frame
	LONG	zero;					// Da porre a zero
	LONG	FrameList[MAXFRAME+1];	// Zero terminated list di offset (rispetto a Height) ai frame
};


//*** Struttura textures directory entry su file

struct FTextDirEntry {
	char	name[8];
	long	offset;
	long	length;
};



//*****************************************************************************
//*** define relative agli oggetti

	//*** tipi di oggetti

#define	OBJTYPE_THING			0
#define	OBJTYPE_PLAYER			1
#define	OBJTYPE_ENEMY			2
#define	OBJTYPE_PICKTHING		3
#define	OBJTYPE_SHOT			4
#define	OBJTYPE_EXPLOSION		5

	//*** Tipi di animazioni

#define ANIMTYPE_DIRECTIONAL	0
#define ANIMTYPE_NONE			1
#define ANIMTYPE_SIMPLE			2

//*** Nodo per una entry nella directory degli oggetti

struct ObjDirNode {
	struct Node		odn_node;
	char			odn_name[40];	// I primi 4 char sono il nome.
									// Seguono 5 spazi (utilizzabili come flag, ad esempio),
									// poi una descrizione di 30 char,
									// poi un char '\0' come terminatore della stringa
	WORD			odn_numframes;	// Numero frame
	WORD			odn_radius;		// Raggio in pixel (per ctrl collisioni)
	WORD			odn_height;		// Altezza in pixel (per ctrl collisioni)
	WORD			odn_animtype;	// Tipo animazione
	WORD			odn_objtype;	// Tipo oggetto
	WORD			odn_param1;		// Parametro 1 (cambia significato in base a odn_objtype)
	WORD			odn_param2;		// Parametro 2 (cambia significato in base a odn_objtype)
	WORD			odn_param3;		// Parametro 3 (cambia significato in base a odn_objtype)
	WORD			odn_param4;		// Parametro 4 (cambia significato in base a odn_objtype)
	BYTE			odn_param5;		// Parametro 5 (cambia significato in base a odn_objtype)
	BYTE			odn_param6;		// Parametro 6 (cambia significato in base a odn_objtype)
	BYTE			odn_param7;		// Parametro 7 (cambia significato in base a odn_objtype)
	BYTE			odn_param8;		// Parametro 8 (cambia significato in base a odn_objtype)
	BYTE			odn_param9;		// Parametro 9 (cambia significato in base a odn_objtype)
	BYTE			odn_param10;	// Parametro10 (cambia significato in base a odn_objtype)
	BYTE			odn_param11;	// Parametro11 (cambia significato in base a odn_objtype)
	BYTE			odn_param12;	// Parametro12 (cambia significato in base a odn_objtype)
	long			odn_sound1;		// Nome (4 char) sample
	long			odn_sound2;		// Nome (4 char) sample
	long			odn_sound3;		// Nome (4 char) sample
	long			odn_offset;		// Offset sul file .GLD
	long			odn_length;		// Lunghezza oggetto in byte
	short			odn_location;	// Se=0, l'oggetto è sul file .GLD;
									// Se=1, è su un file della directory temporanea
	short			odn_num;		// Numero oggetto, usato in fase di save del progetto
};


//*** Struttura Object su file

struct FObject {
	WORD	numframes;					// Numero frame
	WORD	radius;						// Raggio in pixel (per ctrl collisioni)
	WORD	height;						// Altezza in pixel (per ctrl collisioni)
	BYTE	animtype;					// Tipo animazione
	BYTE	objtype;					// Tipo oggetto
	WORD	param1;						// Parametro 1 (cambia significato in base a odn_objtype)
	WORD	param2;						// Parametro 2 (cambia significato in base a odn_objtype)
	WORD	param3;						// Parametro 3 (cambia significato in base a odn_objtype)
	WORD	param4;						// Parametro 4 (cambia significato in base a odn_objtype)
	BYTE	param5;						// Parametro 5 (cambia significato in base a odn_objtype)
	BYTE	param6;						// Parametro 6 (cambia significato in base a odn_objtype)
	BYTE	param7;						// Parametro 7 (cambia significato in base a odn_objtype)
	BYTE	param8;						// Parametro 8 (cambia significato in base a odn_objtype)
	BYTE	param9;						// Parametro 9 (cambia significato in base a odn_objtype)
	BYTE	param10;					// Parametro10 (cambia significato in base a odn_objtype)
	BYTE	param11;					// Parametro11 (cambia significato in base a odn_objtype)
	BYTE	param12;					// Parametro12 (cambia significato in base a odn_objtype)
	LONG	sound1;						// Nome (4 char) sample
	LONG	sound2;						// Nome (4 char) sample
	LONG	sound3;						// Nome (4 char) sample
	LONG	frame;						// Offset (rispetto a numframes) al primo frame
	LONG	zero;						// Da porre a zero
	LONG	framelist[OBJMAXFRAME+1];	// Zero terminated list di offset (rispetto a numframes) ai frame
};



//*** Struttura objects directory entry su file

struct FObjDirEntry {
	char	name[4];
	long	offset;
	long	length;
};


//*****************************************************************************


//*** Nodo per una entry nella lista degli effetti disponibili al motore 3d

struct FxNode {
	struct Node		fx_node;
	char			fx_name[27];	// 2 char per il codice dell'effetto,
									// 1 char di spaziatura,
									// 2 char per il modo (W1, WR, S1, SR)
									// 1 char di spaziatura,
									// 20 char per il nome
									// 1 char a zero di terminazione stringa.
	WORD			fx_code;		// Codice effetto
	char			fx_descr[81];	// Descrizione dell'effetto
	char			fx_param1[21];	// Descrizione parametro 1. Se la stringa è tutta a blank, il parametro non è usato.
	char			fx_param2[21];	// Descrizione parametro 2. Se la stringa è tutta a blank, il parametro non è usato.
};



//*** Nodo per una entry nella directory degli effetti

struct EffectDirNode {
	struct Node		eff_node;
	char			eff_name[42];	// I primi 3 char sono il cod. della lista di effetti,
									// segue uno spazio,
									// poi 3 char per il num. di trigger,
									// poi uno spazio,
									// poi 20 char per il nome dell'effetto,
									// poi uno spazio,
									// poi 5 char per il parametro 1,
									// poi uno spazio,
									// poi 5 char per il parametro 2,
									// poi un char '\0' come terminatore della stringa
	short			eff_listnum;	// Numero della lista di effetti.
	struct FxNode	*eff_fx;		// Pun. allo fx selezionato (Se Trigger number <> 0)
	short			eff_trigger;	// Trigger number. Se=0, il nodo è solo il separatore della lista.
	short			eff_effect;		// Codice dell'effetto da eseguire
	short			eff_param1;		// Parametro 1 per l'effetto da eseguire
	short			eff_param2;		// Parametro 2 per l'effetto da eseguire
	char			eff_key;		// Se>0, c'è bisogno di una chiave per attivare l'effetto
	char			eff_noused;		// Non usato. Porre a zero.

	/* N.B.
			Se eff_listnum=0 e eff_trigger=0, il nodo rappresenta il separatore della lista vuota
			oppure il trigger nullo. In pratica vengono creati due nodi fittizi
			con eff_listnum=0 e eff_trigger=0, la cui unica differenza e nel nome
			e che servono all'utente per azzerare il codice di effetto o il
			trigger number di un blocco.
	*/
};

/*  Esempio di lista effetti:

  1---------------------------------
      1 DOOR               128   150
      2 DOOR               128   150
      3 Light up            64   150
  2---------------------------------
      4 Ceil up            256   300
  3---------------------------------
      5 Floor up-down      128   200
  4---------------------------------
      6 Light up            64   150
      7 Ceil up            128   150
*/


//*****************************************************************************
//*** define relative a suoni e moduli


#define	SOUNDTYPE_MOD			0
#define	SOUNDTYPE_GLOBAL		1
#define	SOUNDTYPE_OBJECT		2
#define	SOUNDTYPE_RND			3	/* Su file assume valore -1 */
#define SOUNDTYPE_EMPTY			999


struct SoundNode {
	struct Node		snd_node;
	char			snd_name[40];	// I primi 4 char sono il nome.
									// Seguono 5 spazi (utilizzabili come flag, ad esempio),
									// poi una descrizione di 30 char,
									// poi un char '\0' come terminatore della stringa
	short			snd_type;		// 0=Modulo protracker
									// 1=Global sound
									// 2=Object sound
									// 3=Rnd sound
									// 999=Empty sound
	short			snd_code;
	UWORD			snd_length;		// Lunghezza del sample in byte (il bit 0 viene sempre posto a 0)
	UWORD			snd_period;		// Periodo
	UWORD			snd_volume;		// Volume (0-64)
	UWORD			snd_loop;		// Se<>0, è l'offset per l'inizio del loop
	UBYTE			snd_priority;	// Priorità del suono (1(min) - 7(max))
	UBYTE			snd_mask;		// Maschera di 4 bit per l'utilizzo dei 4 canali audio
									// Se un bit è a 1, il corrispondente canale si può utilizzare
	UBYTE			snd_alone;		// Se<>0, indica che il sound non può essere suonato più volte nello stesso istante
	char			snd_sample[5];	// Se non vuoto, questo sound non contiene un sample.
									// Il sample è lo stesso del sound il cui nome (4 char)
									// è scritto in questo campo.
	char			snd_sound1[5];	// Usato se snd_type=SOUNDTYPE_RND
	char			snd_sound2[5];	// Usato se snd_type=SOUNDTYPE_RND
	char			snd_sound3[5];	// Usato se snd_type=SOUNDTYPE_RND
	long			snd_offset;		// Offset sul file .GLD
	long			snd_flength;	// Lunghezza suono in byte su file
	short			snd_location;	// Se=0, il suono è sul file .GLD;
									// Se=1, è su un file della directory temporanea
	short			snd_num;		// Numero suono, usato in fase di save del progetto
};


//*** Struttura sound su file

struct FSound {
	ULONG			sample;			// Se<>0, questo sound non contiene un sample.
									// Il sample è lo stesso del sound il cui nome (4 char)
									// è scritto in questo campo.
	UWORD			length;			// Lunghezza del sample in byte (il bit 0 viene sempre posto a 0)
	UWORD			period;			// Periodo
	UWORD			volume;			// Volume (0-64)
	UWORD			loop;			// Se<>0, è l'offset per l'inizio del loop
	UBYTE			priority;		// Priorità del suono (1(min) - 7(max))
	UBYTE			mask;			// Maschera di 4 bit per l'utilizzo dei 4 canali audio
									// Se un bit è a 1, il corrispondente canale si può utilizzare
	BYTE			type;
	UBYTE			code;
};


//*** Struttura sounds directory entry su file

struct FSoundDirEntry {
	char	name[4];
	long	offset;
	long	length;
};


//*****************************************************************************
//*** define relative a pics

#define GFXTYPE_PIC				0
#define GFXTYPE_EMPTY			999


struct GfxNode {
	struct Node		gfx_node;
	char			gfx_name[40];	// I primi 4 char sono il nome.
									// Seguono 5 spazi (utilizzabili come flag, ad esempio),
									// poi una descrizione di 30 char,
									// poi un char '\0' come terminatore della stringa
	WORD			gfx_type;		// 0=pic
									// 999=empty
	WORD			gfx_noused;		// Al momento, non utilizzato
	WORD			gfx_x;			// Posizione x a video della pic
	WORD			gfx_y;			// Posizione y a video della pic
	WORD			gfx_width;		// Width in pixel della pic
	WORD			gfx_height;		// Height in pixel della pic
	long			gfx_offset;		// Offset sul file .GLD
	long			gfx_length;		// Lunghezza pic in byte su file GLD (compresa la testata)
	short			gfx_location;	// Se=0, la pic è sul file .GLD;
									// Se=1, è su un file della directory temporanea
};


//*** Struttura Gfx su file

struct FGfx {
	WORD			type;		// 0=pic
								// 999=empty
	WORD			noused;		// Al momento, non utilizzato
	WORD			x;			// Posizione x a video della pic
	WORD			y;			// Posizione y a video della pic
	WORD			width;		// Width in pixel della pic
	WORD			height;		// Height in pixel della pic
};


//*** Struttura gfx directory entry su file

struct FGfxDirEntry {
	char	name[4];
	long	offset;
	long	length;
};


//*****************************************************************************
//*** Nodo per una entry nella lista di games e levels

struct GLNode {
	struct Node		gln_node;
	char			gln_gamenum[4];		// Numero del game + spazio. Se vuoto, la entry rappresenta un level.
	char			gln_gamename[20];	// Nome del game. Se vuoto, la entry rappresenta un level.
	char			gln_pad1;			// Porre a 32. Char di spaziatura.
	char			gln_levelnum[4];	// Numero del level + spazio. Se vuoto, la entry rappresenta un level.
	char			gln_levelname[20];	// Nome del level. Se vuoto, la entry rappresenta un game.
	char			gln_pad2;			// Porre a 0. Char di terminazione e allineamento a word.
	WORD			gln_num;			// Numero livelli per game, se la entry rappresenta un game.
	char			gln_filename[4];	// Seconda parte del nome file del level, se la entry rappresenta un level.
	char			gln_type;			// Tipo nodo: 0=Game; 1=Level
	char			filler;				// ELIMINABILE: Filler per allineare a word.
};




//*****************************************************************************

// Definizioni dei nomi delle possibili entry delle directory

#define	DEF_GLOBAL	(long)'GLOB'
#define	DEF_PICS	(long)'PICS'
#define	DEF_TEXTURE	(long)'TEXT'
#define	DEF_OBJECT	(long)'OBJT'
#define	DEF_PALETTE	(long)'PALE'
#define	DEF_GAME	(long)'G\0\0\0'
#define	DEF_LEVEL	(long)'L\0\0\0'

//*****************************************************************************

#define	FLOOR_CEIL_HEIGHT	16384		/* Range di valore per altezza soffitto/pavimento */

struct Block {
	WORD					FloorHeight;
	WORD					CeilHeight;
	struct TextDirNode		*FloorTexture;
	struct TextDirNode		*CeilTexture;
	WORD					SkyCeil;				// Se<>0, il soffitto è il cielo
	WORD					BlockNumber;
	WORD					Illumination;
	WORD					FogLighting;			// Se<>0, usa la nebbia per l'illuminazione
	struct Edge				*Edge1,*Edge2,*Edge3,*Edge4;
	struct EffectDirNode	*Effect;
	struct EffectDirNode	*Trigger;
	struct EffectDirNode	*Trigger2;
	UBYTE					Attributes;
	struct Block			*Next;
	WORD					Num;		// Usato nell'ottimizzazione della mappa
};

struct Edge {
	struct TextDirNode	*NormTexture,*UpTexture,*LowTexture;
	UWORD				Attribute;		// bit 0 : If set, upper texture is unpegged
										// bit 1 : If set, lower texture is unpegged
	WORD				noused;
	WORD				EdgeNumber;
	struct Edge			*Next;
	WORD				Num;			// Usato nell'ottimizzazione della mappa
};


//*** Struttura block su file

struct FBlock {
	WORD				FloorHeight;
	WORD				CeilHeight;
	WORD				FloorTexture;
	WORD				CeilTexture;
	WORD				BlockNumber;
	WORD				Illumination;
	LONG				Edge1,Edge2,Edge3,Edge4;
	UBYTE				Effect;
	UBYTE				Trigger2;
	UBYTE				Attributes;
	UBYTE				Trigger;
};



//*****************************************************************************

//*** Colori oggetti su mappa

#define PLAYER_OBJ_COLOR	6
#define ENEMY_OBJ_COLOR		5
#define THING_OBJ_COLOR		7




//*** Struttura oggetti in mappa

struct MapObject {
	struct ObjDirNode		*Object;
	WORD					x;
	WORD					y;
	WORD					Heading;
	WORD					PlayerType;
	struct EffectDirNode	*Effect;
	struct MapObject		*Next;
};


//*** Struttura oggetti in mappa su file

struct FMapObject {
	WORD		Object;
	WORD		x;
	WORD		y;
	WORD		Heading;
	UBYTE		Flags;
	UBYTE		Effect;
};

//*****************************************************************************
//*****************************************************************************





#define	MENU_PROJECT		0

#define ITEM_PROJECT_NEW		0
#define	ITEM_PROJECT_OPEN		1
#define	ITEM_PROJECT_SAVE		2
#define	ITEM_PROJECT_SAVEAS		3
#define	ITEM_PROJECT_INFOS		4
#define	ITEM_PROJECT_ABOUT		6
#define	ITEM_PROJECT_QUIT		8

#define	MENU_EDIT			1

#define	ITEM_EDIT_COPY			0

#define	MENU_WINDOW			2

#define	ITEM_WINDOW_PROJECT		0
#define	ITEM_WINDOW_GLOBAL		1
#define	ITEM_WINDOW_LEVEL		2
#define	ITEM_WINDOW_MAP			3
#define	ITEM_WINDOW_BLOCK		4
#define	ITEM_WINDOW_TEXTURES	5
#define	ITEM_WINDOW_OBJECTS		6
#define	ITEM_WINDOW_EFFECTS		7
#define	ITEM_WINDOW_SOUNDS		8
#define	ITEM_WINDOW_GFX			9
#define	ITEM_WINDOW_TOOLS		10

#define	MENU_OPTIONS		3

#define	ITEM_OPTIONS_SCREENTYPE		0
#define	ITEM_OPTIONS_DIRS			1
#define	ITEM_OPTIONS_SHOWWARN		3
#define	ITEM_OPTIONS_SHOWMAPOBJ		4
#define	ITEM_OPTIONS_CALCPALETTE	5
#define	ITEM_OPTIONS_GRID			6
#define	SUB_OPTIONS_GRID_NO				0
#define	SUB_OPTIONS_GRID_POINT			1
#define	SUB_OPTIONS_GRID_LINE			2


#define MAX_MENU		MENU_OPTIONS	// Codice dell'ultimo menu definito



// GadgetID per i gadget della finestra Project
#define	PRJWINGAD_LIST			0
#define	PRJWINGAD_PRJNAME		1
#define	PRJWINGAD_NOTES			2
#define	PRJWINGAD_PREFIX		3
#define	PRJWINGAD_SOUNDFILENAME	4
#define	PRJWINGAD_TEXTFILENAME	5
#define	PRJWINGAD_OBJFILENAME	6
#define	PRJWINGAD_GFXFILENAME	7
#define	PRJWINGAD_ADDGAME		8
#define	PRJWINGAD_ADDLEVEL		9
#define	PRJWINGAD_DEL			10
#define	PRJWINGAD_DESCR			11
#define	PRJWINGAD_MOVEUP		12
#define	PRJWINGAD_MOVEDOWN		13
#define	PRJWINGAD_EDITLEVEL		14
#define	PRJWINGAD_OK			15
#define	PRJWINGAD_CANCEL		16

#define	PRJWIN_MAXGAD			17		// Numero gadget per questa finestra



// GadgetID per i gadget della finestra Level
#define	LEVELWINGAD_NOUSED		0
#define	LEVELWINGAD_LOADPIC		1
#define	LEVELWINGAD_MOD			2

#define	LEVELWIN_MAXGAD			3		// Numero gadget per questa finestra


// GadgetID per i gadget della finestra Textures
#define	TEXTWINGAD_LIST			0
#define	TEXTWINGAD_ADD			1
#define	TEXTWINGAD_ADDANIM		2
#define	TEXTWINGAD_ADDSWITCH	3
#define	TEXTWINGAD_MODIFY		4
#define	TEXTWINGAD_REMOVE		5
#define	TEXTWINGAD_SHOW			6

#define	TEXTWIN_MAXGAD			7		// Numero gadget per questa finestra


// GadgetID per i gadget della finestra Block
#define	BLOCKWINGAD_FLOORH_SLIDE		0
#define	BLOCKWINGAD_FLOORH_NUM			1
#define	BLOCKWINGAD_CEILH_SLIDE			2
#define	BLOCKWINGAD_CEILH_NUM			3
#define	BLOCKWINGAD_FOG					4
#define	BLOCKWINGAD_ILLUM_SLIDE			5
#define	BLOCKWINGAD_ILLUM_NUM			6
#define	BLOCKWINGAD_EFFECT				7
#define	BLOCKWINGAD_TRIGGER				8
#define	BLOCKWINGAD_TRIGGER2			9
#define	BLOCKWINGAD_TYPE				10
#define	BLOCKWINGAD_ENEMYBLOCKER		11
#define	BLOCKWINGAD_FLOORTEXT			12
#define	BLOCKWINGAD_CEILTEXT			13
#define	BLOCKWINGAD_SKYCEIL				14
#define	BLOCKWINGAD_E1_UPTEXT			15
#define	BLOCKWINGAD_E1_NORMTEXT			16
#define	BLOCKWINGAD_E1_LOWTEXT			17
#define	BLOCKWINGAD_E1_UNPEGUP			18
#define	BLOCKWINGAD_E1_UNPEGLOW			19
#define	BLOCKWINGAD_E1_SWITCH			20
#define	BLOCKWINGAD_E2_UPTEXT			21
#define	BLOCKWINGAD_E2_NORMTEXT			22
#define	BLOCKWINGAD_E2_LOWTEXT			23
#define	BLOCKWINGAD_E2_UNPEGUP			24
#define	BLOCKWINGAD_E2_UNPEGLOW			25
#define	BLOCKWINGAD_E2_SWITCH			26
#define	BLOCKWINGAD_E3_UPTEXT			27
#define	BLOCKWINGAD_E3_NORMTEXT			28
#define	BLOCKWINGAD_E3_LOWTEXT			29
#define	BLOCKWINGAD_E3_UNPEGUP			30
#define	BLOCKWINGAD_E3_UNPEGLOW			31
#define	BLOCKWINGAD_E3_SWITCH			32
#define	BLOCKWINGAD_E4_UPTEXT			33
#define	BLOCKWINGAD_E4_NORMTEXT			34
#define	BLOCKWINGAD_E4_LOWTEXT			35
#define	BLOCKWINGAD_E4_UNPEGUP			36
#define	BLOCKWINGAD_E4_UNPEGLOW			37
#define	BLOCKWINGAD_E4_SWITCH			38
#define	BLOCKWINGAD_SOLIDWALL			39
#define	BLOCKWINGAD_ACCEPT				40
#define	BLOCKWINGAD_MODIFY				41

#define	BLOCKWIN_MAXGAD					42		// Numero gadget per questa finestra


// GadgetID per i gadget della finestra ObjList
#define	OBJLISTWINGAD_LIST			0
#define	OBJLISTWINGAD_ADD			1
#define	OBJLISTWINGAD_RELOAD		2
#define	OBJLISTWINGAD_MODIFY		3
#define	OBJLISTWINGAD_REMOVE		4

#define	OBJLISTWIN_MAXGAD			5		// Numero gadget per questa finestra


// GadgetID per i gadget della finestra Objects
#define	OBJWINGAD_OBJTYPE		0
#define	OBJWINGAD_ANIMTYPE		1
#define	OBJWINGAD_NUMFRAMES		2
#define	OBJWINGAD_NAME			3
#define	OBJWINGAD_RADIUS		4
#define	OBJWINGAD_HEIGHT		5
#define	OBJWINGAD_DESCR			6
#define	OBJWINGAD_PARAM1		7
#define	OBJWINGAD_PARAM2		8
#define	OBJWINGAD_PARAM3		9
#define	OBJWINGAD_PARAM4		10
#define	OBJWINGAD_PARAM5		11
#define	OBJWINGAD_PARAM6		12
#define	OBJWINGAD_PARAM7		13
#define	OBJWINGAD_PARAM8		14
#define	OBJWINGAD_PARAM9		15
#define	OBJWINGAD_PARAM10		16
#define	OBJWINGAD_PARAM11		17
#define	OBJWINGAD_PARAM12		18
#define	OBJWINGAD_SOUND1		19
#define	OBJWINGAD_SOUND2		20
#define	OBJWINGAD_SOUND3		21
#define	OBJWINGAD_NAMEPARAM1	22
#define	OBJWINGAD_NAMEPARAM2	23
#define	OBJWINGAD_NAMEPARAM3	24
#define	OBJWINGAD_NAMEPARAM4	25
#define	OBJWINGAD_NAMEPARAM5	26
#define	OBJWINGAD_NAMEPARAM6	27
#define	OBJWINGAD_NAMEPARAM7	28
#define	OBJWINGAD_NAMEPARAM8	29
#define	OBJWINGAD_NAMEPARAM9	30
#define	OBJWINGAD_NAMEPARAM10	31
#define	OBJWINGAD_NAMEPARAM11	32
#define	OBJWINGAD_NAMEPARAM12	33
#define	OBJWINGAD_NAMESOUND1	34
#define	OBJWINGAD_NAMESOUND2	35
#define	OBJWINGAD_NAMESOUND3	36
#define	OBJWINGAD_OK			37
#define	OBJWINGAD_CANCEL		38

#define	OBJWIN_MAXGAD			39		// Numero gadget per questa finestra


// GadgetID per i gadget della finestra Effects
#define	EFFWINGAD_LIST			0
#define	EFFWINGAD_ADDLIST		1
#define	EFFWINGAD_ADDFX			2
#define	EFFWINGAD_DELLIST		3
#define	EFFWINGAD_DELFX			4
#define	EFFWINGAD_EFFECT		5
#define	EFFWINGAD_PARAM1		6
#define	EFFWINGAD_PARAM2		7
#define	EFFWINGAD_KEY			8
#define	EFFWINGAD_NAMEPARAM1	9
#define	EFFWINGAD_NAMEPARAM2	10

#define	EFFWIN_MAXGAD			11		// Numero gadget per questa finestra


// GadgetID per i gadget della finestra Fx (Elenco effetti disponibili al motore)
#define	FXWINGAD_LIST			0

#define	FXWIN_MAXGAD			1		// Numero gadget per questa finestra


// GadgetID per i gadget della finestra Map
#define	MAPWINGAD_VSCROLL			0
#define	MAPWINGAD_HSCROLL			1
#define	MAPWINGAD_ZOOMIN			2
#define	MAPWINGAD_ZOOMOUT			3

#define	MAPWIN_MAXGAD				4		// Numero gadget per questa finestra


// GadgetID per i gadget della finestra Tools
#define TOOLSWINGAD_DRAW			0
#define TOOLSWINGAD_LINE			1
#define TOOLSWINGAD_BOX				2
#define TOOLSWINGAD_FILL			3
#define TOOLSWINGAD_UNDO			4
#define TOOLSWINGAD_PICK			5
#define TOOLSWINGAD_OBJ				6

#define	TOOLSWIN_MAXGAD				7		// Numero gadget per questa finestra


//GadgetID per i gadget della finestra MapObjWin
#define MAPOBJWINGAD_OBJ			0
#define MAPOBJWINGAD_X				1
#define MAPOBJWINGAD_Y				2
#define MAPOBJWINGAD_HEADING		3
#define MAPOBJWINGAD_TRIGGER		4
#define MAPOBJWINGAD_DEL			5
#define MAPOBJWINGAD_OK				6
#define MAPOBJWINGAD_CANCEL			7

#define	MAPOBJWIN_MAXGAD			8		// Numero gadget per questa finestra


//GadgetID per i gadget della finestra SndListWin
#define SNDLISTWINGAD_LIST			0
#define SNDLISTWINGAD_ADD			1
#define SNDLISTWINGAD_MODIFY		2
#define SNDLISTWINGAD_REMOVE		3

#define	SNDLISTWIN_MAXGAD			4		// Numero gadget per questa finestra


//GadgetID per i gadget della finestra SoundWin
#define SOUNDWINGAD_TYPE			0
#define SOUNDWINGAD_NAME			1
#define SOUNDWINGAD_DESCR			2
#define SOUNDWINGAD_LENGTH			3
#define SOUNDWINGAD_PERIOD			4
#define SOUNDWINGAD_VOLUME			5
#define SOUNDWINGAD_LOOP			6
#define SOUNDWINGAD_PRIORITY		7
#define SOUNDWINGAD_CODE			8
#define SOUNDWINGAD_CHANNEL1		9
#define SOUNDWINGAD_CHANNEL2		10
#define SOUNDWINGAD_CHANNEL3		11
#define SOUNDWINGAD_CHANNEL4		12
#define SOUNDWINGAD_ALONE			13
#define SOUNDWINGAD_SAMPLE			14
#define SOUNDWINGAD_SOUND1			15
#define SOUNDWINGAD_SOUND2			16
#define SOUNDWINGAD_SOUND3			17
#define SOUNDWINGAD_OK				18
#define SOUNDWINGAD_CANCEL			19

#define	SOUNDWIN_MAXGAD				20		// Numero gadget per questa finestra


//GadgetID per i gadget della finestra GfxListWin
#define GFXLISTWINGAD_LIST			0
#define GFXLISTWINGAD_ADD			1
#define GFXLISTWINGAD_MODIFY		2
#define GFXLISTWINGAD_REMOVE		3

#define	GFXLISTWIN_MAXGAD			4		// Numero gadget per questa finestra


// GadgetID per i gadget della finestra Directories
#define	DIRSWINGAD_OK			0
#define	DIRSWINGAD_CANCEL		1
#define	DIRSWINGAD_TEMP			2

#define	DIRSWIN_MAXGAD			3		// Numero gadget per questa finestra



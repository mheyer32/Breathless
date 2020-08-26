//******************************************************************************
//***
//***		FxList.h
//***
//***	Elenco degli effetti disponibili al motore 3d
//***
//******************************************************************************

#define FXNUMBER	18

struct FxNode	EngineFx[] = {

//		(struct Node *)(&EngineFx[1]), (struct Node *)NULL, 0,0, EngineFx[0].fx_name,
//		"12345678901234567890123456",
//		1,
//		"12345678901234567890123456789012345678901234567890123456789012345678901234567890",
//		"12345678901234567890",	"12345678901234567890",	},

	{	(struct Node *)(&EngineFx[1]), (struct Node *)NULL, 0,0, EngineFx[0].fx_name,
		"01 W1 Ceil up             ",	// fx_name
		1,								// fx_code
		"Ceiling goes up                                                                 ",
		"Num. pixel          ",	"                    ",	},

	{	(struct Node *)(&EngineFx[2]), (struct Node *)(&EngineFx[0]), 0,0, EngineFx[1].fx_name,
		"02 W1 Floor up            ",
		2,
		"Floor goes up                                                                   ",
		"Num. pixel          ",	"                    ",	},

	{	(struct Node *)(&EngineFx[3]), (struct Node *)(&EngineFx[1]), 0,0, EngineFx[2].fx_name,
		"03 W1 Ceil down           ",
		3,
		"Ceiling goes down                                                               ",
		"Num. pixel          ",	"                    ",	},

	{	(struct Node *)(&EngineFx[4]), (struct Node *)(&EngineFx[2]), 0,0, EngineFx[3].fx_name,
		"04 W1 Floor down          ",
		4,
		"Floor goes down                                                                 ",
		"Num. pixel          ",	"                    ",	},

	{	(struct Node *)(&EngineFx[5]), (struct Node *)(&EngineFx[3]), 0,0, EngineFx[4].fx_name,
		"05 WR Door                ",
		5,
		"Ceil goes up of param1 pixels, pause param2 1/50th sec., then goes down.        ",
		"Num. pixel          ",	"Pause (1/50th sec)  ",	},

	{	(struct Node *)(&EngineFx[6]), (struct Node *)(&EngineFx[4]), 0,0, EngineFx[5].fx_name,
		"06 WR Door2               ",
		6,
		"Ceil goes up of param1 pixels, pause param2 1/50th sec., then goes down.        ",
		"Num. pixel          ",	"Pause (1/50th sec)  ",	},

	{	(struct Node *)(&EngineFx[7]), (struct Node *)(&EngineFx[5]), 0,0, EngineFx[6].fx_name,
		"07 WR Lift up             ",
		7,
		"Floor goes up of param1 pixels, pause param2 1/50th sec., then goes down.       ",
		"Num. pixel          ",	"Pause (1/50th sec)  ",	},

	{	(struct Node *)(&EngineFx[8]), (struct Node *)(&EngineFx[6]), 0,0, EngineFx[7].fx_name,
		"08 WR Lift down           ",
		8,
		"Floor goes down of param1 pixels, pause param2 1/50th sec., then goes up.       ",
		"Num. pixel          ",	"Pause (1/50th sec)  ",	},

	{	(struct Node *)(&EngineFx[9]), (struct Node *)(&EngineFx[7]), 0,0, EngineFx[8].fx_name,
		"09 WR Light up            ",
		9,
		"Lights go up of param1 unities, in a time of param2 1/50th sec.                 ",
		"Light (0-127)       ",	"Time (1/50th sec)   ",	},

	{	(struct Node *)(&EngineFx[10]), (struct Node *)(&EngineFx[8]), 0,0, EngineFx[9].fx_name,
		"10 WR Light down          ",
		10,
		"Lights go down of param1 unities, in a time of param2 1/50th sec.               ",
		"Light (0-127)       ",	"Time (1/50th sec)   ",	},

	{	(struct Node *)(&EngineFx[11]), (struct Node *)(&EngineFx[9]), 0,0, EngineFx[10].fx_name,
		"11 WR Terminal            ",
		11,
		"                                                                                ",
		"Terminal # (1-99)   ",	"                    ",	},

	{	(struct Node *)(&EngineFx[12]), (struct Node *)(&EngineFx[10]), 0,0, EngineFx[11].fx_name,
		"12 WR Door down           ",
		12,
		"Floor goes down of param1 pixels, pause param2 1/50th sec., then goes up.       ",
		"Num. pixel          ",	"Pause (1/50th sec)  ",	},

	{	(struct Node *)(&EngineFx[13]), (struct Node *)(&EngineFx[11]), 0,0, EngineFx[12].fx_name,
		"13 WR Linked light        ",
		13,
		"Lights follow door heigth                                                       ",
		"Light (0-127)       ",	"Linked trigger      ",	},

	{	(struct Node *)(&EngineFx[14]), (struct Node *)(&EngineFx[12]), 0,0, EngineFx[13].fx_name,
		"14 W1 End Level           ",
		14,
		"End level: go to next level                                                     ",
		"                    ",	"                    ",	},

	{	(struct Node *)(&EngineFx[15]), (struct Node *)(&EngineFx[13]), 0,0, EngineFx[14].fx_name,
		"15 WR Teleport            ",
		15,
		"                                                                                ",
		"X coord.            ",	"Y coord.            ",	},

	{	(struct Node *)(&EngineFx[16]), (struct Node *)(&EngineFx[14]), 0,0, EngineFx[15].fx_name,
		"16 W1 Blinking Lights     ",
		16,
		"Lights blink between block illumination and param1 every param2 1/50th sec.     ",
		"Illumination value  ",	"Delay (1/50th sec.) ",	},

	{	(struct Node *)(&EngineFx[17]), (struct Node *)(&EngineFx[15]), 0,0, EngineFx[16].fx_name,
		"17 W1 Active enemy        ",
		17,
		"Wait param1 1/50th sec., then active enemies with same trigger number           ",
		"Pause (1/50th sec.) ",	"                    ",	},

	{	(struct Node *)NULL, (struct Node *)(&EngineFx[16]), 0,0, EngineFx[17].fx_name,
		"18 W1 Lift                ",
		18,
		"Lift                                                                            ",
		"Height 1            ",	"Height 2            ",	},

};

struct List		FxList = {
	(struct Node *)EngineFx,
	(struct Node *)NULL,
	(struct Node *)(&EngineFx[FXNUMBER-1]),
	0, 0
};


//*** Il seguente array contiene i codici degli effetti utilizzabili
//*** per il trigger2. L'array è null-terminated

WORD	Trigger2FX[] = { 9, 10, 13, 16, NULL };


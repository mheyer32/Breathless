//*****************************************************************************
//***
//***		PicIff.h
//***
//***	Include file per gestione pictures IFF
//***
//***
//***
//*****************************************************************************

#ifndef	PICIFF_H
#define	PICIFF_H


#define MakeIFFID(a,b,c,d) ((ULONG)(a)<<24|(ULONG)(b)<<16|(ULONG)(c)<<8|(ULONG)(d))
#define PullIFFID(p) 		((ULONG)((p)[0]<<24)|(ULONG)((p)[1]<<16)|(ULONG)((p)[2]<<8)|(ULONG)(p)[3])

#define IFFID_FORM		MakeIFFID('F','O','R','M')
#define IFFID_LIST		MakeIFFID('L','I','S','T')
#define IFFID_PROP		MakeIFFID('P','R','O','P')
#define IFFID_ILBM		MakeIFFID('I','L','B','M')
#define IFFID_CAT	    MakeIFFID('C','A','T',' ')
#define IFFID_BMHD		MakeIFFID('B','M','H','D')
#define IFFID_BODY		MakeIFFID('B','O','D','Y')
#define IFFID_CMAP		MakeIFFID('C','M','A','P')
#define IFFID_GRAB		MakeIFFID('G','R','A','B')
#define IFFID_DEST		MakeIFFID('D','E','S','T')
#define IFFID_SPRT		MakeIFFID('S','P','R','T')
#define IFFID_CAMG		MakeIFFID('C','A','M','G')


// Codici d'errore che restituisce LoadIFFPic()

#define IFFERR_OK	 				0
#define IFFERR_CANT_OPEN			-1
#define IFFERR_FILE_NOT_FORM	 	-2
#define IFFERR_FILE_NOT_ILBM	 	-3
#define IFFERR_NO_MEMORY	 		-4
#define IFFERR_CHUNK_NOT_FOUND	 	-5

#define mskNone					0
#define mskHasMask				1
#define mskHasTransparentColor	2
#define mskLasso				3

#define cmpNone					0
#define cmpByteRun1				1


struct	BitMapHeader {
 UWORD		Width,Height;
 WORD		XPos,YPos;
 UBYTE		Depth;
 UBYTE		Mask;
 UBYTE		Compression;
 UBYTE		Pad;
 UWORD		TransparentColor;
 UBYTE		XAspect,YAspect;
 WORD		PageWidth,PageHeight;
};


struct	PictureHeader {
 struct BitMapHeader	Header;
 struct BitMap			BitMap;
 UBYTE					Palette[3*256];	// 256 colors palette
};


int FindChunk(ULONG chunktype,long *length);
int CheckIFFPic(void);
int GetBMHD(struct BitMap *BitMap, struct BitMapHeader *Header);
int	BitMapAllocation(struct BitMap *BitMap, struct BitMapHeader *Header);
int ReadIFFPic(struct BitMap *BitMap, struct BitMapHeader *Header);
int IFFFree(struct PictureHeader *PicHead);
int	LoadIFFPic(char *name, struct PictureHeader *PicHead);


#endif	/*	PICIFF_H	*/

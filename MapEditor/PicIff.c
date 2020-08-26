//*****************************************************************************
//***
//***		Gestione pictures IFF
//***
//***
//***
//***
//***
//*****************************************************************************

#include	"PicIff.h"

#include <proto/graphics.h>
#include <stdio.h>

FILE					*FileIFF;


#define MIN(x, y) (((x) < (y)) ? (x) : (y))

// Cerca nel file il chunk id specificato

int FindChunk(ULONG id, long *len) {

	ULONG	id_chunk;
	long	lenght;

	fseek(FileIFF,12,SEEK_SET);
	do {
		fread(&id_chunk,4,1,FileIFF);
		if (!feof(FileIFF)) {
			fread(&lenght,4,1,FileIFF);
			if (id_chunk==id) {
				*len=lenght;
				return(IFFERR_OK);
			}
			if(lenght & 1L) lenght++;
			fseek(FileIFF,lenght,SEEK_CUR);
		}
	} while(!feof(FileIFF));

	return(IFFERR_CHUNK_NOT_FOUND);
}


// Test se il file e' del tipo voluto (FORM ILBM)

int	CheckIFFPic(void) {

	ULONG	id_chunk,lenght;

 id_chunk=0;
 lenght=0;

	fread(&id_chunk,4,1,FileIFF);
	fread(&lenght,4,1,FileIFF);
	if (id_chunk!=IFFID_FORM) return(IFFERR_FILE_NOT_FORM);
	fread(&id_chunk,4,1,FileIFF);
	if (id_chunk!=IFFID_ILBM) return(IFFERR_FILE_NOT_ILBM);
	return(IFFERR_OK);
}


// Legge il bitmap header dal file

int GetBMHD(struct BitMap *BitMap, struct BitMapHeader *Header) {
	long	lenght;
	int		err;

	if (!(err=FindChunk(IFFID_BMHD,&lenght))) {
		fread(&(Header->Width),sizeof(Header->Width),1,FileIFF);
		fread(&(Header->Height),sizeof(Header->Height),1,FileIFF);
		fread(&(Header->XPos),sizeof(Header->XPos),1,FileIFF);
		fread(&(Header->YPos),sizeof(Header->YPos),1,FileIFF);
		fread(&(Header->Depth),sizeof(Header->Depth),1,FileIFF);
		fread(&(Header->Mask),sizeof(Header->Mask),1,FileIFF);
		fread(&(Header->Compression),sizeof(Header->Compression),1,FileIFF);
		fread(&(Header->Pad),sizeof(Header->Pad),1,FileIFF);
		fread(&(Header->TransparentColor),sizeof(Header->TransparentColor),1,FileIFF);
		fread(&(Header->XAspect),sizeof(Header->XAspect),1,FileIFF);
		fread(&(Header->YAspect),sizeof(Header->YAspect),1,FileIFF);
		fread(&(Header->PageWidth),sizeof(Header->PageWidth),1,FileIFF);
		fread(&(Header->PageHeight),sizeof(Header->PageHeight),1,FileIFF);
		InitBitMap(BitMap,Header->Depth,Header->Width,Header->Height);
		return(IFFERR_OK);
	}

	return(err);

}


// Alloca memoria per contenere i bitplanes

int	BitMapAllocation(struct BitMap *BitMap, struct BitMapHeader *Header) {

	register	int	i;

	for(i=0; i<Header->Depth; i++) {
		if (!(BitMap->Planes[i]=AllocRaster(Header->Width,Header->Height))) {
			return(IFFERR_NO_MEMORY);
		}
	}

	return(IFFERR_OK);
}


int ReadIFFPic(struct BitMap *BitMap, struct BitMapHeader *Header) {
 long		lenght;
 BYTE		data,run,c;
 register	int needed,err,line,plane,i,j;
 register	BOOL mask,compress;
 register	UBYTE *dest;

 if (Header->Mask==mskHasMask) mask=TRUE;
                          else mask=FALSE;

 if (Header->Compression==cmpByteRun1) compress=TRUE;
                                  else compress=FALSE;

 if (err=FindChunk(IFFID_BODY,&lenght)) return(err);

 needed=BitMap->BytesPerRow;

 for (line=0;line<Header->Height;line++)
    for (plane=0;plane<Header->Depth;plane++)
       {
        if (mask&line%2) dest=NULL;
                    else dest=BitMap->Planes[plane]+line*needed;
        if (!compress)
            {
             if (dest) fread(dest,needed,1,FileIFF);
                  else for(j=0;j<needed;j++) fread(&c,1,1,FileIFF);
            }
        else
            {
             i=0;
             while (i<needed)
                  {
                   fread(&run,1,1,FileIFF);
                   if (run>=0)
                       {
                        if (dest)
                           {
                            fread(dest,run+1,1,FileIFF);
                            dest+=run+1;
                           }
                        else for(j=0;j<=run;j++) fread(&c,1,1,FileIFF);
                        i+=run+1;
                       }
                   else if (run!=128)
                          {
                           run=-run;
                           i+=run+1;
                           fread(&data,1,1,FileIFF);
                           if (dest) for(j=0;j<=run;j++) *dest++=data;
                          }
                  }
            }
       }
 return(IFFERR_OK);
}


// Legge la palette

int ReadPalette(struct PictureHeader *PicHead) {

	register int	i, maxnum;
	int				err;
	long			lenght;
	UBYTE			temp[3];

	if (err=FindChunk(IFFID_CMAP,&lenght)) return(err);

	maxnum=MIN(3*(1<<PicHead->Header.Depth),lenght);
	for(i=0; i<maxnum; i++) {
		fread(&(PicHead->Palette[i]),1,1,FileIFF);
	}
	return(IFFERR_OK);
}



// Libera tutte le risorse allocate

int IFFFree(struct PictureHeader *PicHead) {

	register	int i;

	for(i=0; i<(PicHead->Header.Depth); i++) {
		if (PicHead->BitMap.Planes[i]) FreeRaster(PicHead->BitMap.Planes[i],
												  PicHead->Header.Width,
												  PicHead->Header.Height);
		PicHead->BitMap.Planes[i]=NULL;
	}

	PicHead->Header.Width=0;
	PicHead->Header.Height=0;
	PicHead->Header.Depth=0;

	return(IFFERR_OK);
}


//*** Funzione principale.
//*** Apre il file e, se IFF, lo legge.

int	LoadIFFPic(char *name, struct PictureHeader *PicHead) {

	int		err;

	err=IFFERR_OK;

	if (FileIFF=fopen(name, "r")) {
		if (!(err=CheckIFFPic())) {
			if (!(err=GetBMHD(&(PicHead->BitMap), &(PicHead->Header)))) {
				if (!(err=BitMapAllocation(&(PicHead->BitMap), &(PicHead->Header)))) {
					if(!(err=ReadPalette(PicHead))) {
						err=ReadIFFPic(&(PicHead->BitMap), &(PicHead->Header));
					}
				}
			}
		}
	} else {
		return(IFFERR_CANT_OPEN);
	}

	fclose(FileIFF);
	if(err) IFFFree(PicHead);
	return(err);
}



// Legge la palette di un file IFF

int LoadIFFPalette(char *name, struct PictureHeader *PicHead) {

	int		err;

	err=IFFERR_OK;

	if (FileIFF=fopen(name, "r")) {
		if (!(err=CheckIFFPic())) {
			if (!(err=GetBMHD(&(PicHead->BitMap), &(PicHead->Header)))) {
				err=ReadPalette(PicHead);
			}
		}
	} else {
		return(IFFERR_CANT_OPEN);
	}

	fclose(FileIFF);
	if(err) IFFFree(PicHead);
	return(err);
}

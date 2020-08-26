//*****************************************************************************
//***
//***		ProcessMap.c
//***
//***		Gestione mappa
//***
//***
//***
//*****************************************************************************

#include	"MapEditor3d.h"
#include	"Definitions.h"

#include <stdio.h>
#include <stdlib.h>
//*****************************************************************************

//*** Setta la barra del titolo della finestra Map

void SetMapWinTitle(void) {

	static char	MapWinTitle[80];
	char		draw[20];

	if(!MapWin) return;

	switch(DrawWhat) {
		case 1:
			if(SolidWall_fl)
				strcpy(draw,"Solid Block");
			else
				strcpy(draw,"Block");
			break;
/*		case 2:
			strcpy(draw,"Player");
			break;
*/		case 2:
			strcpy(draw,"Object : ");
			if(CurrObjPun) {
				strncat(draw,CurrObjPun->odn_name,4);
				draw[13]='\0';
			}
			break;
		default:
			strcpy(draw,"---");
			break;
	}

	sprintf(MapWinTitle,"MapRel:%3ld,%3ld    Zoom:%2ld   Draw:%s  ", MapXPos, MapYPos, MapZoom, draw);
	SetWindowTitles(MapWin,(UBYTE *)MapWinTitle,(UBYTE *)~0);
}


//*** Calcola lo spazio utile nella finestra Map
//*** e setta di conseguenza gli scroller gadget della finestra.

void MapWinDim() {

	MapWinWidth = MapWin->Width - 26;
	MapWinHeight = MapWin->Height - 22;

	MapWidth = MapWinWidth / MapZoom;
	MapHeight = MapWinHeight / (MapZoom>>1);

	if(MapWidth>MAP_WIDTH) MapWidth=128;
	if(MapHeight>MAP_HEIGHT) MapHeight=128;

	MapWinWidthR = MapWidth * MapZoom;
	MapWinHeightR = MapHeight * (MapZoom>>1);

	GT_SetGadgetAttrs(MapWinGadgets[MAPWINGAD_HSCROLL], MapWin, NULL,
						GTSC_Top, (long)MapX1Pos,
						GTSC_Visible, (long)MapWidth,
						TAG_DONE,0);

	GT_SetGadgetAttrs(MapWinGadgets[MAPWINGAD_VSCROLL], MapWin, NULL,
						GTSC_Top, (long)MapY1Pos,
						GTSC_Visible, (long)MapHeight,
						TAG_DONE,0);

}


//*** Calcola la posizione del mouse nella mappa

void MouseMapPos(void) {

	if ((MouseX<MapWinX1) || (MouseY<MapWinY1) ||
		(MouseX>=MapWinX1+MapWinWidthR) || (MouseY>=MapWinY1+MapWinHeightR)) {
		MapXPos=-1;
		MapYPos=-1;
	} else {
		MapXPos = MapX1Pos + (MouseX-MapWinX1)/MapZoom;
		MapYPos = MapY1Pos + (MouseY-MapWinY1)/(MapZoom>>1);
	}
}


//*** Traccia la griglia della mappa

void DrawMapGrid(void) {

	register long	i,j,w,cx,cy;

	SetAPen(MapWinRP,0);
	RectFill(MapWinRP,MapWinX1,MapWinY1,MapWinX1+MapWinWidth-1,MapWinY1+MapWinHeight-1);

	switch(MapGridType) {
		case 0:					// Nessuna griglia
			break;

		case 1:					// Griglia a punti
			SetAPen(MapWinRP,3);
			w=MapWinX1+MapWinWidthR;
			cx=MapZoom;
			cy=cx>>1;
			for(j=MapWinY1; j<=MapWinY1+MapWinHeightR; j+=cy)
				for(i=MapWinX1; i<=w; i+=cx)
					WritePixel(MapWinRP,i,j);
			break;

		case 2:					// Griglia a linee
			SetAPen(MapWinRP,3);
			w=MapWinX1+MapWinWidthR-1;
			cx=MapZoom;
			cy=cx>>1;
			for(j=MapWinY1; j<=MapWinY1+MapWinHeightR; j+=cy) {
				Move(MapWinRP,MapWinX1,j);
				Draw(MapWinRP,w,j);
			}
			w=MapWinY1+MapWinHeightR-1;
			for(i=MapWinX1; i<=MapWinX1+MapWinWidthR; i+=cx) {
				Move(MapWinRP,i,MapWinY1);
				Draw(MapWinRP,i,w);
			}
			break;
		default:
			break;
	}
}



//*** Pulisce la mappa

void ClearMap() {

	register long	i,j;

	for(i=0; i<MAP_HEIGHT; i++)
		for(j=0; j<MAP_WIDTH; j++)
			MapBuffer[(i<<MAP_WIDTH_B) + j] = 0;
}




//*** Traccia la mappa

void DrawMap() {

	register long	i, j, x, y;
	register short	block, oldblock;
	long			bx, by;
	static short	oldrow[MAP_WIDTH];

	if(!MapWin) return;

	DrawMapGrid();

	for(i=0; i<MAP_WIDTH; i++) oldrow[i]=0;

	bx=MapZoom-2;
	by=(MapZoom>>1)-2;

	y=MapWinY1+1;
	for(j=MapY1Pos; j<(MapY1Pos+MapHeight); j++) {
		x=MapWinX1+1;
		oldblock=0;
		for(i=MapX1Pos; i<(MapX1Pos+MapWidth); i++) {
			block=MapBuffer[(j<<MAP_WIDTH_B) + i];
			if(block) {
				if(block<0)	SetAPen(MapWinRP,1); else	SetAPen(MapWinRP,3);
				RectFill(MapWinRP,x,y,x+bx,y+by);
			}
			if(block!=oldblock) {
				SetAPen(MapWinRP,2);
				Move(MapWinRP,x-1,y-1);
				Draw(MapWinRP,x-1,y+by+1);
			}
			if(block!=oldrow[i]) {
				SetAPen(MapWinRP,2);
				Move(MapWinRP,x-1,y-1);
				Draw(MapWinRP,x+bx+1,y-1);
			}
			oldblock=block;
			oldrow[i]=block;
			x+=MapZoom;
		}
		y+=(MapZoom>>1);
	}

	DrawMapObjects();
}



//*** Evidenzia sulla mappa tutti i blocchi con il codice indicato

void HilightBlock(WORD hblock) {

	register long	i, j, x, y;
	register short	block;
	long			bx, by;

	if(!MapWin) return;

	bx=MapZoom-2;
	by=(MapZoom>>1)-2;

	SetAPen(MapWinRP,5);

	y=MapWinY1+1;
	for(j=MapY1Pos; j<(MapY1Pos+MapHeight); j++) {
		x=MapWinX1+1;
		for(i=MapX1Pos; i<(MapX1Pos+MapWidth); i++) {
			block=MapBuffer[(j<<MAP_WIDTH_B) + i];
			if((block==hblock) || (-block==hblock)) {
				RectFill(MapWinRP,x,y,x+bx,y+by);
			}
			x+=MapZoom;
		}
		y+=(MapZoom>>1);
	}
}


//*** Scrive il blocco block nella mappa, alle coordinate di mappa (x,y)

void PlotBlock(long x, long y, WORD block) {

	register long	i,j,p,bx,by,fl;

//	if(!block) return;

	if((x<0) || (x>=MAP_WIDTH) || (y<0) || (y>=MAP_HEIGHT)) return;

	p = y<<MAP_WIDTH_B;

	if(SolidWall_fl)	block = -block;

	MapBuffer[p + x] = block;

	i = MapWinX1 + 1 + (x - MapX1Pos) * MapZoom;
	j = MapWinY1 + 1 + (y - MapY1Pos) * (MapZoom>>1);

	bx=MapZoom-2;
	by=(MapZoom>>1)-2;

	if(block<0)
		SetAPen(MapWinRP,1);
	else if(block==0)
		SetAPen(MapWinRP,0);
	else
		SetAPen(MapWinRP,3);

	RectFill(MapWinRP,i,j,i+bx,j+by);

/*	SetAPen(MapWinRP,0);
	Move(MapWinRP,i-1,j-1);
	Draw(MapWinRP,i-1,j+by+1);
	Draw(MapWinRP,i+bx+1,j+by+1);
	Draw(MapWinRP,i+bx+1,j-1);
	Draw(MapWinRP,i-1,j-1);
*/
	fl=0;
	if((x==0 && block) || (x>0 && MapBuffer[p + x - 1]!=block)) {
		SetAPen(MapWinRP,2);
		fl|=1;
	} else {
		SetAPen(MapWinRP,0);
	}
	Move(MapWinRP,i-1,j-1);
	Draw(MapWinRP,i-1,j+by+1);

	if((x==MAP_WIDTH-1 && block) || (x<MAP_WIDTH-1 && MapBuffer[p + x + 1]!=block)) {
		SetAPen(MapWinRP,2);
		fl|=2;
	} else {
		SetAPen(MapWinRP,0);
	}
	Move(MapWinRP,i+MapZoom-1,j-1);
	Draw(MapWinRP,i+MapZoom-1,j+by+1);

	if((y==0 && block) || (y>0 && MapBuffer[p + x - MAP_WIDTH]!=block)) {
		SetAPen(MapWinRP,2);
		fl|=4;
	} else {
		SetAPen(MapWinRP,0);
	}
	Move(MapWinRP,i-1,j-1);
	Draw(MapWinRP,i+bx+1,j-1);

	if((y==MAP_HEIGHT-1 && block) || (y<MAP_HEIGHT-1 && MapBuffer[p + x + MAP_WIDTH]!=block)) {
		SetAPen(MapWinRP,2);
		fl|=8;
	} else {
		SetAPen(MapWinRP,0);
	}
	Move(MapWinRP,i-1,j+by+1);
	Draw(MapWinRP,i+bx+1,j+by+1);

	if(fl & 5)
		SetAPen(MapWinRP,2);
	else
		SetAPen(MapWinRP,3);
	WritePixel(MapWinRP,i-1,j-1);

	if(fl & 6)
		SetAPen(MapWinRP,2);
	else
		SetAPen(MapWinRP,3);
	WritePixel(MapWinRP,i+MapZoom-1,j-1);

	if(fl & 10)
		SetAPen(MapWinRP,2);
	else
		SetAPen(MapWinRP,3);
	WritePixel(MapWinRP,i+MapZoom-1,j+by+1);

	if(fl & 9)
		SetAPen(MapWinRP,2);
	else
		SetAPen(MapWinRP,3);
	WritePixel(MapWinRP,i-1,j+by+1);

	ModifiedMap_fl=TRUE;
}



//*** Visualizza la linea nella finestra Map, senza tracciarla nella mappa

void ShowLine(long x1, long y1, long x2, long y2) {

	register long	u,v,ax,ay,sx,sy,d,count;
	long			bx,by;

	u = MapWinX1 + 1 + (x1 - MapX1Pos) * MapZoom;
	v = MapWinY1 + 1 + (y1 - MapY1Pos) * (MapZoom>>1);

	bx=MapZoom;
	by=(MapZoom>>1);

	ax = abs(x2 - x1);
	sx = ((x2 - x1)>0) ? bx : -bx;
	ay = abs(y2 - y1);
	sy = ((y2 - y1)>0) ? by : -by;

	bx-=2;
	by-=2;

	SetDrMd(MapWinRP, COMPLEMENT);

	if(ax>ay) {		// X dominant part

		count = ax;
		d = ax>>1;

		do {
			RectFill(MapWinRP,u,v,u+bx,v+by);
			d-=ay;
			if(d<0) {
				d+=ax;
				v+=sy;
			}
			u+=sx;
		} while(count--);

	} else {

		count = ay;
		d = ay>>1;

		do {
			RectFill(MapWinRP,u,v,u+bx,v+by);
			d-=ax;
			if(d<0) {
				d+=ay;
				u+=sx;
			}
			v+=sy;
		} while(count--);
	}

	SetDrMd(MapWinRP, JAM1);
}



//*** Traccia una linea nella mappa

void DrawBlockLine(long x1, long y1, long x2, long y2, WORD block) {

	register long	u,v,ax,ay,sx,sy,d,count;
	long			bx,by;

	u = x1;
	v = y1;

	ax = abs(x2 - x1);
	sx = ((x2 - x1)>0) ? 1 : -1;
	ay = abs(y2 - y1);
	sy = ((y2 - y1)>0) ? 1 : -1;

	if(ax>ay) {		// X dominant part

		count = ax;
		d = ax>>1;

		do {
			PlotBlock(u,v,block);
			d-=ay;
			if(d<0) {
				d+=ax;
				v+=sy;
			}
			u+=sx;
		} while(count--);

	} else {

		count = ay;
		d = ay>>1;

		do {
			PlotBlock(u,v,block);
			d-=ax;
			if(d<0) {
				d+=ay;
				u+=sx;
			}
			v+=sy;
		} while(count--);
	}
}



//*** Visualizza un box nella finestra Map, senza tracciarlo nella mappa

void ShowBox(long x1, long y1, long x2, long y2) {

	register long	u,v,i,sx,sy;
	long			ax,ay,bx,by;

	u = MapWinX1 + 1 + (x1 - MapX1Pos) * MapZoom;
	v = MapWinY1 + 1 + (y1 - MapY1Pos) * (MapZoom>>1);

	bx=MapZoom;
	by=(MapZoom>>1);

	ax = abs(x2 - x1);
	sx = ((x2 - x1)>0) ? bx : -bx;
	ay = abs(y2 - y1);
	sy = ((y2 - y1)>0) ? by : -by;

	bx-=2;
	by-=2;

	SetDrMd(MapWinRP, COMPLEMENT);

	RectFill(MapWinRP,u,v,u+bx,v+by);

	if(ax) {
		for(i=0; i<ax; i++) {
			u+=sx;
			RectFill(MapWinRP,u,v,u+bx,v+by);
		}
	}
	if(ay) {
		for(i=0; i<ay; i++) {
			v+=sy;
			RectFill(MapWinRP,u,v,u+bx,v+by);
		}
	}
	if(ax && ay) {
		for(i=0; i<ax; i++) {
			u-=sx;
			RectFill(MapWinRP,u,v,u+bx,v+by);
		}
	}
	if(ax && ay) {
		for(i=1; i<ay; i++) {
			v-=sy;
			RectFill(MapWinRP,u,v,u+bx,v+by);
		}
	}

	SetDrMd(MapWinRP, JAM1);
}


//*** Traccia un box nella mappa

void DrawBlockBox(long x1, long y1, long x2, long y2, WORD block) {

	register long	u,v,i,j,sx,sy;
	long			ax,ay,uo;

	u = x1;
	v = y1;

	ax = abs(x2 - x1);
	sx = ((x2 - x1)>0) ? 1 : -1;
	ay = abs(y2 - y1);
	sy = ((y2 - y1)>0) ? 1 : -1;

	if(!ToolType) {				// Se box
		PlotBlock(u,v,block);

		if(ax) {
			for(i=0; i<ax; i++) {
				u+=sx;
				PlotBlock(u,v,block);
			}
		}
		if(ay) {
			for(i=0; i<ay; i++) {
				v+=sy;
				PlotBlock(u,v,block);
			}
		}
		if(ax && ay) {
			for(i=0; i<ax; i++) {
				u-=sx;
				PlotBlock(u,v,block);
			}
		}
		if(ax && ay) {
			for(i=1; i<ay; i++) {
				v-=sy;
				PlotBlock(u,v,block);
			}
		}

	} else {			// Se Filled box

		uo=u;
		for(i=0; i<=ay; i++) {
			u=uo;
			for(j=0; j<=ax; j++) {
				PlotBlock(u,v,block);
				u+=sx;
			}
			v+=sy;
		}
	}
}

//*****************************************************************************
//*** Gestione oggetti
//*****************************************************************************


//*** Traccia un oggetto in mappa

void PlotObject(long x, long y, struct ObjDirNode *object) {

	register long	i,j,bx,by;

	i = MapWinX1 + 2 +(x - MapX1Pos) * MapZoom;
	j = MapWinY1 + 1 +(y - MapY1Pos) * (MapZoom>>1);

	bx=MapZoom-4;
	by=(MapZoom>>1)-2;

	switch(object->odn_objtype) {
		case OBJTYPE_THING:
		case OBJTYPE_PICKTHING:
			SetAPen(MapWinRP,THING_OBJ_COLOR);
			break;
		case OBJTYPE_PLAYER:
			SetAPen(MapWinRP,PLAYER_OBJ_COLOR);
			break;
		case OBJTYPE_ENEMY:
			SetAPen(MapWinRP,ENEMY_OBJ_COLOR);
			break;
	}

	Move(MapWinRP,i,j);
	Draw(MapWinRP,i+bx,j);
	Draw(MapWinRP,i+bx,j+by);
	Draw(MapWinRP,i,j+by);
	Draw(MapWinRP,i,j);

}



//*** Traccia tutti gli oggetti in mappa

void DrawMapObjects() {

	struct MapObject	*obj;
	register long		i,j,bx,by;

	if(!ShowMapObj_fl && DrawWhat!=2) return;

	if(MapObjectList==NULL) return;

	bx=MapZoom-4;
	by=(MapZoom>>1)-2;

	for(obj=MapObjectList; obj; obj=obj->Next) {

		i = obj->x>>6;
		j = obj->y>>6;

		if ((i>=MapX1Pos) && (j>=MapY1Pos) &&
			(i<MapX1Pos+MapWidth) && (j<MapY1Pos+MapHeight)) {

			i = MapWinX1 + 2 +(i - MapX1Pos) * MapZoom;
			j = MapWinY1 + 1 +(j - MapY1Pos) * (MapZoom>>1);

			switch(obj->Object->odn_objtype) {
				case OBJTYPE_THING:
				case OBJTYPE_PICKTHING:
					SetAPen(MapWinRP,THING_OBJ_COLOR);
					break;
				case OBJTYPE_PLAYER:
					SetAPen(MapWinRP,PLAYER_OBJ_COLOR);
					break;
				case OBJTYPE_ENEMY:
					SetAPen(MapWinRP,ENEMY_OBJ_COLOR);
					break;
			}

			Move(MapWinRP,i,j);
			Draw(MapWinRP,i+bx,j);
			Draw(MapWinRP,i+bx,j+by);
			Draw(MapWinRP,i,j+by);
			Draw(MapWinRP,i,j);
		}
	}

	SelectMapObject(SelectedMapObj);
}


//*** Elimina dalla mappa l'oggetto object

void DelMapObject(struct MapObject *object) {

	register long	i,j,p,bx,by,x,y;

	bx=MapZoom-2;
	by=(MapZoom>>1)-2;

	if(object) {
		x = (long)((object->x)>>6);
		y = (long)((object->y)>>6);

		p = (y<<MAP_WIDTH_B) + x;

		i = MapWinX1 + 1 + (x - MapX1Pos) * MapZoom;
		j = MapWinY1 + 1 + (y - MapY1Pos) * (MapZoom>>1);

		if(MapBuffer[p]<0)
			SetAPen(MapWinRP,1);
		else if(MapBuffer[p]==0)
			SetAPen(MapWinRP,0);
		else
			SetAPen(MapWinRP,3);

		RectFill(MapWinRP,i,j,i+bx,j+by);

		if(SelectedMapObj==object)	SelectedMapObj=NULL;
	}
}



//*** Seleziona in mappa l'oggetto object, e deseleziona quello
//*** precedentemente selezionato.

void SelectMapObject(struct MapObject *object) {

	register long	i,j,p,bx,by,x,y;

	if(!object) return;

	bx=MapZoom-2;
	by=(MapZoom>>1)-2;

	if(SelectedMapObj) {
		x = (long)((SelectedMapObj->x)>>6);
		y = (long)((SelectedMapObj->y)>>6);

		p = (y<<MAP_WIDTH_B) + x;

		i = MapWinX1 + 1 + (x - MapX1Pos) * MapZoom;
		j = MapWinY1 + 1 + (y - MapY1Pos) * (MapZoom>>1);

		if(MapBuffer[p]<0)
			SetAPen(MapWinRP,1);
		else if(MapBuffer[p]==0)
			SetAPen(MapWinRP,0);
		else
			SetAPen(MapWinRP,3);

		RectFill(MapWinRP,i,j,i+bx,j+by);

		PlotObject(x,y,SelectedMapObj->Object);
	}

	i = MapWinX1 + 1 + (((object->x)>>6) - MapX1Pos) * MapZoom;
	j = MapWinY1 + 1 + (((object->y)>>6) - MapY1Pos) * (MapZoom>>1);

	SetAPen(MapWinRP,4);
	RectFill(MapWinRP,i,j,i+bx,j+by);

	switch(object->Object->odn_objtype) {
		case OBJTYPE_THING:
		case OBJTYPE_PICKTHING:
			SetAPen(MapWinRP,THING_OBJ_COLOR);
			break;
		case OBJTYPE_PLAYER:
			SetAPen(MapWinRP,PLAYER_OBJ_COLOR);
			break;
		case OBJTYPE_ENEMY:
			SetAPen(MapWinRP,ENEMY_OBJ_COLOR);
			break;
	}
	printf("mapx1=%ld  mapy1=%ld  i=%ld  j=%ld\n",MapX1Pos,MapY1Pos,i,j);
	if(MapZoom>=8)
		RectFill(MapWinRP,i+1,j+1,i+bx-1,j+by-1);
	else
		RectFill(MapWinRP,i+1,j,i+bx-1,j+by);

	SelectedMapObj = object;
}


//*** Muove oggetto in mappa dalla vecchia posizione alla nuova

void MoveMapObject(long x, long y, struct MapObject *object) {

	register long	i,j,p,bx,by;

	if(!object) return;

	bx=MapZoom-2;
	by=(MapZoom>>1)-2;

	i = (long)((object->x)>>6);
	j = (long)((object->y)>>6);

	p = (j<<MAP_WIDTH_B) + i;

	i = MapWinX1 + 1 + (i - MapX1Pos) * MapZoom;
	j = MapWinY1 + 1 + (j - MapY1Pos) * (MapZoom>>1);

	if(MapBuffer[p]<0)
		SetAPen(MapWinRP,1);
	else if(MapBuffer[p]==0)
		SetAPen(MapWinRP,0);
	else
		SetAPen(MapWinRP,3);

	RectFill(MapWinRP,i,j,i+bx,j+by);


	object->x = (x<<6)+32;
	object->y = (y<<6)+32;

	PlotObject(x,y,object->Object);

	ModifiedMap_fl=TRUE;
}


//*****************************************************************************
//*** Gestione dei blocchi
//*****************************************************************************



//*** Cerca in EdgeList, un edge uguale a quello passato.
//*** Se lo trova, ne restituisce il puntatore.
//*** Gli edge che contengono una texture di tipo switch
//*** non possono essere riutilizzati, per cui su di essi
//*** non viene effettuata alcuna ricerca.
//*** Se non lo trova, ne crea uno nuovo e ne restituisce il puntatore.

struct Edge *FindEdge(struct Edge *edge) {

	struct Edge		*epun, *epunlast, *epunnew;

	if(!(edge->NormTexture->tdn_switch ||
		 edge->UpTexture->tdn_switch ||
		 edge->LowTexture->tdn_switch)) {

		epun = EdgeList;
		epunlast = NULL;
		while(epun!=NULL) {
			if(!(epun->NormTexture->tdn_switch ||
				 epun->UpTexture->tdn_switch ||
				 epun->LowTexture->tdn_switch)) {

				if((epun->NormTexture == edge->NormTexture) &&
				   (epun->UpTexture == edge->UpTexture) &&
				   (epun->LowTexture == edge->LowTexture) &&
				   (epun->Attribute == edge->Attribute)) {
						return(epun);
				}
			}
			epunlast = epun;
			epun = epun->Next;
		}
	} else {
		epun = EdgeList;
		epunlast = NULL;
		while(epun!=NULL) {
			epunlast = epun;
			epun = epun->Next;
		}
	}

	if(!(epunnew = (struct Edge *)AllocMem(sizeof(struct Edge),MEMF_CLEAR))) {
		error=NO_MEMORY;
		return(NULL);
	}

	*epunnew = *edge;

	if(EdgeList)		// E' il primo edge della lista ?
		epunlast->Next = epunnew;
	else
		EdgeList = epunnew;

	printf("Alloca Edge %ld\n", LastEdge);

	epunnew->EdgeNumber = LastEdge++;

	ModifiedMap_fl=TRUE;

	return(epunnew);
}


//*** Cerca in BlockList, un blocco uguale a quello passato.
//*** Se lo trova, ne restituisce il puntatore.
//*** Se non lo trova, ne crea uno nuovo e ne restituisce il puntatore.

struct Block *FindBlock(struct Block *block) {

	struct Block	*bpun, *bpunlast, *bpunnew;

	bpun = BlockList;
	bpunlast = NULL;
	while(bpun!=NULL) {
		if((bpun->FloorHeight == block->FloorHeight) &&
		   (bpun->CeilHeight == block->CeilHeight) &&
		   (bpun->FloorTexture == block->FloorTexture) &&
		   (bpun->CeilTexture == block->CeilTexture) &&
		   (bpun->SkyCeil == block->SkyCeil) &&
		   (bpun->Illumination == block->Illumination) &&
		   (bpun->FogLighting == block->FogLighting) &&
		   (bpun->Edge1 == block->Edge1) &&
		   (bpun->Edge2 == block->Edge2) &&
		   (bpun->Edge3 == block->Edge3) &&
		   (bpun->Edge4 == block->Edge4) &&
		   (bpun->Effect == block->Effect) &&
		   (bpun->Attributes == block->Attributes) &&
		   (bpun->Trigger == block->Trigger) &&
		   (bpun->Trigger2 == block->Trigger2)) {
				return(bpun);
		}
		bpunlast = bpun;
		bpun = bpun->Next;
	}

	if(!(bpunnew = (struct Block *)AllocMem(sizeof(struct Block),MEMF_CLEAR))) {
		error=NO_MEMORY;
		return(NULL);
	}

	*bpunnew = *block;

	if(BlockList)		// E' il primo blocco della lista ?
		bpunlast->Next = bpunnew;
	else
		BlockList = bpunnew;

	printf("Alloca blocco %ld\n", LastBlock);

	bpunnew->BlockNumber = LastBlock++;

	ModifiedMap_fl=TRUE;

	return(bpunnew);
}



//*** Cerca nella BlockList il primo blocco che usa la texture
//*** passata come parametro. Restituisce il pun. al blocco.

struct Block *FindBlockTexture(struct TextDirNode *text) {

	register struct Block	*bpun, *bpunlast;

	bpun = BlockList;
	bpunlast = NULL;
	while(bpun!=NULL) {
		if((bpun->FloorTexture == text) ||
		   (bpun->CeilTexture == text) ||
		   (bpun->Edge1->NormTexture == text) ||
		   (bpun->Edge1->UpTexture == text) ||
		   (bpun->Edge1->LowTexture == text) ||
		   (bpun->Edge2->NormTexture == text) ||
		   (bpun->Edge2->UpTexture == text) ||
		   (bpun->Edge2->LowTexture == text) ||
		   (bpun->Edge3->NormTexture == text) ||
		   (bpun->Edge3->UpTexture == text) ||
		   (bpun->Edge3->LowTexture == text) ||
		   (bpun->Edge4->NormTexture == text) ||
		   (bpun->Edge4->UpTexture == text) ||
		   (bpun->Edge4->LowTexture == text)) {
				return(bpun);
		}
		bpunlast = bpun;
		bpun = bpun->Next;
	}

	return(NULL);
}



//*** E' stato premuto il button "Accept" della finestra Block,
//*** per cui ricerca se esiste un blocco identico a quello appena
//*** definito. Se non esiste ne crea uno nuovo.

void AcceptBlock() {

	struct Block	*BlockPun;
	struct Edge		*Edge1Pun,*Edge2Pun,*Edge3Pun,*Edge4Pun;


	Edge1.NormTexture = NormTextureE1;
	Edge1.UpTexture = 	UpTextureE1;
	Edge1.LowTexture = 	LowTextureE1;
	Edge1.Attribute = 	UnpeggedUpE1 | UnpeggedLowE1;
	Edge1.noused = 		0;
	Edge1.EdgeNumber = 	0;
	Edge1.Next = 		NULL;

	if(!(Edge1Pun=FindEdge(&Edge1))) return;

	Edge2.NormTexture = NormTextureE2;
	Edge2.UpTexture = 	UpTextureE2;
	Edge2.LowTexture = 	LowTextureE2;
	Edge2.Attribute = 	UnpeggedUpE2 | UnpeggedLowE2;
	Edge2.noused = 		0;
	Edge2.EdgeNumber = 	0;
	Edge2.Next = 		NULL;

	if(!(Edge2Pun=FindEdge(&Edge2))) return;

	Edge3.NormTexture = NormTextureE3;
	Edge3.UpTexture = 	UpTextureE3;
	Edge3.LowTexture = 	LowTextureE3;
	Edge3.Attribute = 	UnpeggedUpE3 | UnpeggedLowE3;
	Edge3.noused = 		0;
	Edge3.EdgeNumber = 	0;
	Edge3.Next = 		NULL;

	if(!(Edge3Pun=FindEdge(&Edge3))) return;

	Edge4.NormTexture = NormTextureE4;
	Edge4.UpTexture = 	UpTextureE4;
	Edge4.LowTexture = 	LowTextureE4;
	Edge4.Attribute = 	UnpeggedUpE4 | UnpeggedLowE4;
	Edge4.noused = 		0;
	Edge4.EdgeNumber = 	0;
	Edge4.Next = 		NULL;

	if(!(Edge4Pun=FindEdge(&Edge4))) return;


	CurrBlock.FloorHeight = 	FloorHeight;
	CurrBlock.CeilHeight = 		CeilHeight;
	CurrBlock.FloorTexture = 	FloorTexture;
	CurrBlock.CeilTexture = 	CeilTexture;
	CurrBlock.SkyCeil = 		SkyCeil;
	CurrBlock.BlockNumber = 	0;
	CurrBlock.Illumination = 	Illumination;
	CurrBlock.FogLighting = 	FogLighting;
	CurrBlock.Edge1 = 			Edge1Pun;
	CurrBlock.Edge2 = 			Edge2Pun;
	CurrBlock.Edge3 = 			Edge3Pun;
	CurrBlock.Edge4 = 			Edge4Pun;
	CurrBlock.Effect = 			BlockEffect;
	CurrBlock.Attributes = 		BlockType | EnemyBlocker | SwitchE1 | SwitchE2 | SwitchE3 | SwitchE4;
	CurrBlock.Trigger = 		BlockTrigger;
	CurrBlock.Trigger2 = 		BlockTrigger2;
	CurrBlock.Next = 			NULL;

	if(!(BlockPun=FindBlock(&CurrBlock))) return;

	CurrBlockCode = BlockPun->BlockNumber;
	CurrBlockPun = BlockPun;

	ModifiedMap_fl=TRUE;

	DrawWhat = 1;
	SetMapWinTitle();

	printf("\n%ld   %ld\n",BlockPun->BlockNumber, BlockList->BlockNumber);
}



//*** Modifica il blocco corrente, con i dati appena inseriti
//*** nella finestra BlockWin

void ModifyBlock() {

	struct Block	*BlockPun;
	struct Edge		*Edge1Pun,*Edge2Pun,*Edge3Pun,*Edge4Pun;

	if(!CurrBlockPun) return;

	HilightBlock(CurrBlockCode);

	if(!ShowMessage("Are you sure you want\nto modify this block ?",1)) {
		DrawMap();
		return;
	}

	Edge1.NormTexture = NormTextureE1;
	Edge1.UpTexture = 	UpTextureE1;
	Edge1.LowTexture = 	LowTextureE1;
	Edge1.Attribute = 	UnpeggedUpE1 | UnpeggedLowE1;
	Edge1.noused = 		0;
	Edge1.EdgeNumber = 	0;
	Edge1.Next = 		NULL;

	if(!(Edge1Pun=FindEdge(&Edge1))) return;

	Edge2.NormTexture = NormTextureE2;
	Edge2.UpTexture = 	UpTextureE2;
	Edge2.LowTexture = 	LowTextureE2;
	Edge2.Attribute = 	UnpeggedUpE2 | UnpeggedLowE2;
	Edge2.noused = 		0;
	Edge2.EdgeNumber = 	0;
	Edge2.Next = 		NULL;

	if(!(Edge2Pun=FindEdge(&Edge2))) return;

	Edge3.NormTexture = NormTextureE3;
	Edge3.UpTexture = 	UpTextureE3;
	Edge3.LowTexture = 	LowTextureE3;
	Edge3.Attribute = 	UnpeggedUpE3 | UnpeggedLowE3;
	Edge3.noused = 		0;
	Edge3.EdgeNumber = 	0;
	Edge3.Next = 		NULL;

	if(!(Edge3Pun=FindEdge(&Edge3))) return;

	Edge4.NormTexture = NormTextureE4;
	Edge4.UpTexture = 	UpTextureE4;
	Edge4.LowTexture = 	LowTextureE4;
	Edge4.Attribute = 	UnpeggedUpE4 | UnpeggedLowE4;
	Edge4.noused = 		0;
	Edge4.EdgeNumber = 	0;
	Edge4.Next = 		NULL;

	if(!(Edge4Pun=FindEdge(&Edge4))) return;


	CurrBlockPun->FloorHeight = 	FloorHeight;
	CurrBlockPun->CeilHeight = 		CeilHeight;
	CurrBlockPun->FloorTexture = 	FloorTexture;
	CurrBlockPun->CeilTexture = 	CeilTexture;
	CurrBlockPun->SkyCeil = 		SkyCeil;
	CurrBlockPun->Illumination = 	Illumination;
	CurrBlockPun->FogLighting = 	FogLighting;
	CurrBlockPun->Edge1 = 			Edge1Pun;
	CurrBlockPun->Edge2 = 			Edge2Pun;
	CurrBlockPun->Edge3 = 			Edge3Pun;
	CurrBlockPun->Edge4 = 			Edge4Pun;
	CurrBlockPun->Effect = 			BlockEffect;
	CurrBlockPun->Attributes = 		BlockType | EnemyBlocker | SwitchE1 | SwitchE2 | SwitchE3 | SwitchE4;
	CurrBlockPun->Trigger = 		BlockTrigger;
	CurrBlockPun->Trigger2 = 		BlockTrigger2;

	ModifiedMap_fl=TRUE;

	DrawWhat = 1;

	DrawMap();
}



//*** Il blocco alle coordinate (x,y) diviene il blocco corrente

void PickBlock(long x, long y) {

	register long			p;
	register WORD			block;
	register struct Block	*bpun;

	if((x<0) || (x>=MAP_WIDTH) || (y<0) || (y>=MAP_HEIGHT)) return;

	p = y<<MAP_WIDTH_B;

	block = MapBuffer[p + x];

	printf("Pick block=%ld\n", block);

	if(block < 0) {
		block=-block;
		SolidWall_fl=TRUE;
	} else
		SolidWall_fl=FALSE;

	// Cerca il blocco

	printf("\n\nblock=%ld\n",block);

	bpun=BlockList;
	printf("bpun=%ld  blocknum=%ld\n",bpun,bpun->BlockNumber);
	while(bpun && (bpun->BlockNumber != block)) {
		bpun = bpun->Next;
	}
	if(!bpun) return;

	FloorHeight =	bpun->FloorHeight;
	CeilHeight =	bpun->CeilHeight;
	FloorTexture =	bpun->FloorTexture;
	CeilTexture =	bpun->CeilTexture;

	SkyCeil =		bpun->SkyCeil;

	Illumination =	bpun->Illumination;

	FogLighting =	bpun->FogLighting;

	BlockEffect =	bpun->Effect;
	BlockTrigger =	bpun->Trigger;
	BlockTrigger2 =	bpun->Trigger2;

	if(BlockEffect->eff_listnum)
		sprintf(n_EffectNum,"%3ld",BlockEffect->eff_listnum);
	else
		strcpy(n_EffectNum,"---");

	if(BlockTrigger->eff_trigger)
		sprintf(n_TriggerNum,"%3ld",BlockTrigger->eff_trigger);
	else
		strcpy(n_TriggerNum,"---");

	if(BlockTrigger2->eff_trigger)
		sprintf(n_TriggerNum2,"%3ld",BlockTrigger2->eff_trigger);
	else
		strcpy(n_TriggerNum2,"---");

	NormTextureE1 =	bpun->Edge1->NormTexture;
	UpTextureE1 =	bpun->Edge1->UpTexture;
	LowTextureE1 =	bpun->Edge1->LowTexture;
	UnpeggedUpE1 =	bpun->Edge1->Attribute & 1;
	UnpeggedLowE1 =	bpun->Edge1->Attribute & 2;

	NormTextureE2 =	bpun->Edge2->NormTexture;
	UpTextureE2 =	bpun->Edge2->UpTexture;
	LowTextureE2 =	bpun->Edge2->LowTexture;
	UnpeggedUpE2 =	bpun->Edge2->Attribute & 1;
	UnpeggedLowE2 =	bpun->Edge2->Attribute & 2;

	NormTextureE3 =	bpun->Edge3->NormTexture;
	UpTextureE3 =	bpun->Edge3->UpTexture;
	LowTextureE3 =	bpun->Edge3->LowTexture;
	UnpeggedUpE3 =	bpun->Edge3->Attribute & 1;
	UnpeggedLowE3 =	bpun->Edge3->Attribute & 2;

	NormTextureE4 =	bpun->Edge4->NormTexture;
	UpTextureE4 =	bpun->Edge4->UpTexture;
	LowTextureE4 =	bpun->Edge4->LowTexture;
	UnpeggedUpE4 =	bpun->Edge4->Attribute & 1;
	UnpeggedLowE4 =	bpun->Edge4->Attribute & 2;

	BlockType = bpun->Attributes & 3;
	EnemyBlocker = bpun->Attributes & 8;

	SwitchE1 = bpun->Attributes & 16;
	SwitchE2 = bpun->Attributes & 32;
	SwitchE3 = bpun->Attributes & 64;
	SwitchE4 = bpun->Attributes & 128;

	strncpy(n_FloorTexture, FloorTexture->tdn_name, 8);
	strncpy(n_CeilTexture, CeilTexture->tdn_name, 8);
	strncpy(n_NormTextureE1, NormTextureE1->tdn_name, 8);
	strncpy(n_UpTextureE1, UpTextureE1->tdn_name, 8);
	strncpy(n_LowTextureE1, LowTextureE1->tdn_name, 8);
	strncpy(n_NormTextureE2, NormTextureE2->tdn_name, 8);
	strncpy(n_UpTextureE2, UpTextureE2->tdn_name, 8);
	strncpy(n_LowTextureE2, LowTextureE2->tdn_name, 8);
	strncpy(n_NormTextureE3, NormTextureE3->tdn_name, 8);
	strncpy(n_UpTextureE3, UpTextureE3->tdn_name, 8);
	strncpy(n_LowTextureE3, LowTextureE3->tdn_name, 8);
	strncpy(n_NormTextureE4, NormTextureE4->tdn_name, 8);
	strncpy(n_UpTextureE4, UpTextureE4->tdn_name, 8);
	strncpy(n_LowTextureE4, LowTextureE4->tdn_name, 8);

	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_FLOORH_SLIDE],BlockWin, NULL, GTSL_Level, FloorHeight+8192, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_FLOORH_NUM],BlockWin, NULL, GTIN_Number, FloorHeight, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_CEILH_SLIDE],BlockWin, NULL, GTSL_Level, CeilHeight+8192, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_CEILH_NUM],BlockWin, NULL, GTIN_Number, CeilHeight, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_ILLUM_SLIDE],BlockWin, NULL, GTSL_Level, Illumination+128, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_ILLUM_NUM],BlockWin, NULL, GTIN_Number, Illumination, TAG_DONE,0);

	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_FOG],BlockWin, NULL, GTCB_Checked, (FogLighting ? 1 : 0), TAG_DONE,0);

	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_TYPE],BlockWin,NULL, GTCY_Active,(long)BlockType, TAG_DONE,0);

	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_ENEMYBLOCKER],BlockWin, NULL, GTCB_Checked, (EnemyBlocker ? TRUE : FALSE), TAG_DONE,0);

	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_SKYCEIL],BlockWin,NULL, GTCB_Checked,(long)SkyCeil, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_SOLIDWALL],BlockWin, NULL, GTCB_Checked, (long)SolidWall_fl, TAG_DONE,0);

	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E1_UNPEGUP],BlockWin, NULL, GTCB_Checked, UnpeggedUpE1, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E1_UNPEGLOW],BlockWin, NULL, GTCB_Checked, (UnpeggedLowE1 ? 1 : 0), TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E2_UNPEGUP],BlockWin, NULL, GTCB_Checked, UnpeggedUpE2, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E2_UNPEGLOW],BlockWin, NULL, GTCB_Checked, (UnpeggedLowE2 ? 1 : 0), TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E3_UNPEGUP],BlockWin, NULL, GTCB_Checked, UnpeggedUpE3, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E3_UNPEGLOW],BlockWin, NULL, GTCB_Checked, (UnpeggedLowE3 ? 1 : 0), TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E4_UNPEGUP],BlockWin, NULL, GTCB_Checked, UnpeggedUpE4, TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E4_UNPEGLOW],BlockWin, NULL, GTCB_Checked, (UnpeggedLowE4 ? 1 : 0), TAG_DONE,0);

	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E1_SWITCH],BlockWin, NULL, GTCB_Checked, (SwitchE1 ? 1 : 0), TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E2_SWITCH],BlockWin, NULL, GTCB_Checked, (SwitchE2 ? 1 : 0), TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E3_SWITCH],BlockWin, NULL, GTCB_Checked, (SwitchE3 ? 1 : 0), TAG_DONE,0);
	GT_SetGadgetAttrs(BlockWinGadgets[BLOCKWINGAD_E4_SWITCH],BlockWin, NULL, GTCB_Checked, (SwitchE4 ? 1 : 0), TAG_DONE,0);

	CurrBlockCode = bpun->BlockNumber;
	CurrBlockPun = bpun;

	DrawWhat = 1;
	SetMapWinTitle();
}



//*** Ottimizza l'occupazione di memoria della mappa
//*** eliminando blocchi e edges non usati.

void OptimizeMap() {

	register long	i,j;
	WORD			block, removed;
	struct Block	*bpun, *obpun, *nbpun;
	struct Edge		*epun, *oepun, *nepun;

	// Azzera flag nella EdgeList

	for(epun=EdgeList; epun!=NULL; epun=epun->Next)
		epun->Num = 0;

	// Azzera flag nella BlockList

	for(bpun=BlockList; bpun!=NULL; bpun=bpun->Next)
		bpun->Num = 0;

	// Scorre la mappa e segna i blocchi usati

	for(i=0; i<MAP_HEIGHT; i++) {
		for(j=0; j<MAP_WIDTH; j++) {
			block = MapBuffer[(i<<MAP_WIDTH_B) + j];
			block = (block>=0) ? block : -block;
			for(bpun=BlockList; bpun!=NULL; bpun=bpun->Next) {
				if(bpun->BlockNumber==block) {
					bpun->Num = 1;
					break;
				}
			}
		}
	}

	// Scorre BlockList ed elimina blocchi non usati

	removed = FALSE;
	LastBlock = 0;
	obpun = NULL;
	bpun = BlockList;
	while(bpun!=NULL) {
		if(bpun->Num==0) {
			nbpun=bpun->Next;
			if(obpun)
				obpun->Next=nbpun;
			else
				BlockList=nbpun;
			FreeMem(bpun,sizeof(struct Block));
			removed=TRUE;
			bpun=nbpun;
		} else {
			bpun->Num = LastBlock++;
			obpun = bpun;
			bpun=bpun->Next;
		}
	}

	// Scorre la BlockList e segna edge usati

	for(bpun=BlockList; bpun!=NULL; bpun=bpun->Next) {
		bpun->Edge1->Num = 1;
		bpun->Edge2->Num = 1;
		bpun->Edge3->Num = 1;
		bpun->Edge4->Num = 1;
	}

	// Scorre EdgeList ed elimina edges non usati

	LastEdge = 0;
	oepun = NULL;
	epun = EdgeList;
	while(epun!=NULL) {
		if(epun->Num==0) {
			nepun=epun->Next;
			if(oepun)
				oepun->Next=nepun;
			else
				EdgeList=nepun;
			FreeMem(epun,sizeof(struct Edge));
			epun=nepun;
		} else {
			epun->EdgeNumber = LastEdge++;
			oepun = epun;
			epun=epun->Next;
		}
	}

	if(removed) {		// Se sono stati rimossi blocchi
		// Scorre la mappa e rinumera i blocchi

		for(i=0; i<MAP_HEIGHT; i++) {
			for(j=0; j<MAP_WIDTH; j++) {
				block = MapBuffer[(i<<MAP_WIDTH_B) + j];
				if(block>0) {
					for(bpun=BlockList; bpun!=NULL; bpun=bpun->Next) {
						if(bpun->BlockNumber==block) {
							MapBuffer[(i<<MAP_WIDTH_B) + j] = bpun->Num;
							break;
						}
					}
				} else {
					block=-block;
					for(bpun=BlockList; bpun!=NULL; bpun=bpun->Next) {
						if(bpun->BlockNumber==block) {
							MapBuffer[(i<<MAP_WIDTH_B) + j] = -bpun->Num;
							break;
						}
					}
				}
			}
		}

		// Scorre la BlockList e rinumera blocchi

		for(bpun=BlockList; bpun!=NULL; bpun=bpun->Next)
			bpun->BlockNumber = bpun->Num;

	}

}


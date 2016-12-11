			RSRESET
Object.Next		RS.L	1
Object.HitFunction:	RS.L	1
Object.MoveFunction:	RS.L	1
Object.SizeX:		RS.W	1
Object.SizeY:		RS.W	1
Object.PosX:		RS.W	1
Object.PosY:		RS.W	1
Object.SpeedX:		RS.W	1
Object.SpeedY:		RS.W	1
Object.AccelX:		RS.W	1
Object.AccelXCount:	RS.W	1
Object.AccelY:		RS.W	1
Object.AccelYCount:	RS.W	1
Object.Weight:		RS.W	1
Object.SpriteData:	RS.W	1
Object.SpriteData2:	RS.W	1
Object.BlitData:	RS.L	1
Object.BlitMask:	RS.L	1
Object.Flags		RS.B	1	; Generic flags	0 - Use alt sprite for 1 frame
Object.Pad		RS.B	1
Object.SizeOf:		RS.W	0

OBJ_POSX_SHIFT		EQU	4
OBJ_POSY_SHIFT		EQU	4

OBJ_FLAG_ALT_SPRITE	EQU	0

OBJ_MAX_NUM		EQU	100


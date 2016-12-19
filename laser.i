			RSRESET
Laser.Next		RS.L	1
Laser.PosX:		RS.W	1
Laser.PosY:		RS.W	1
Laser.SpeedX:		RS.W	1
Laser.BlitData:		RS.L	1
Laser.Life		RS.B	1
Laser.Padding		RS.B	1
Laser.SizeOf		RS.B	0

LSR_SIZEX		EQU	16 << OBJ_POSX_SHIFT
LSR_MAX_NUM		EQU	64

LSR_SPEED		EQU	(8 << OBJ_POSX_SHIFT)
LSR_SPEED_SPREAD	EQU	(1 << OBJ_POSX_SHIFT)
LSR_LIFE		EQU	28
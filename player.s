			INCLUDE "graphics.i"
			INCLUDE "player.i"
			INCLUDE "laser.i"
			INCLUDE "objects.i"

			SECTION	DATA,DATA
PLY_AccelXTable:	DC.B	-5,-8,-10,-15,-20,-10,0,10,20,15,10,8,5

			CNOP	0,4
			XDEF	PLY_Player1
PLY_Player1:		DC.L	0
			DC.W	-100 << OBJ_POSX_SHIFT, 100 << OBJ_POSY_SHIFT
			DC.W	0,0
			DC.W	2
			DC.W	0,0
			DC.L	PlayerDataRight	;BlitData
			DC.B	0		;Fire
			DC.B	255		;Direction
			DC.B	4		;LaserSize
			DC.B	4		;LaserAutoFire

			SECTION	CODE,CODE


PLY_FireJoystick2:	BTST.B	#7,$BFE001
			BNE	.NoFire
			TST.B	(Player.Fire,A3)
			BNE	.FireBlocked

			; Set player firing flag
			MOVE.B	#1,(Player.Fire,A3)

			; Get player x position, adjust for laser, assume facing right 
			MOVE.W	(Player.PosX,A3),D0

			; Get player y position, adjust for laser
			MOVE.W	(Player.PosY,A3),D1
			ADD.W	#8 << OBJ_POSY_SHIFT,D1

			; Set laser speed, negate if moving left
			TST.B	(Player.Direction,A3)
			BNE	.FireRight

.FireLeft:		SUB.W	#9 << OBJ_POSX_SHIFT,D0
			MOVE.W	#-LSR_SPEED,D3

			; Add player speed to laser speed to get final laser speed
			MOVE.W	(Player.SpeedX,A3),D2
			ADD.W	D3,D2

			; Create laser objects
			MOVE.B	(Player.LaserSize,A3),D4
			EXT.W	D4
.FireLeftLoop:		MOVE.B  (Player.Direction,A3),D3
			BSR	LSR_Create
			ADD.W	#LSR_SPEED_SPREAD,D2
			DBRA	D4,.FireLeftLoop
			RTS

.FireRight:		ADD.W	#18 << OBJ_POSX_SHIFT,D0
			MOVE.W	#LSR_SPEED,D3

			; Add player speed to laser speed to get final laser speed
			MOVE.W	(Player.SpeedX,A3),D2
			ADD.W	D3,D2

			; Create laser objects
			MOVE.B	(Player.LaserSize,A3),D4
			EXT.W	D4
.FireRightLoop:		MOVE.B  (Player.Direction,A3),D3
			BSR	LSR_Create
			SUB.W	#LSR_SPEED_SPREAD,D2
			DBRA	D4,.FireRightLoop
			RTS

.NoFire:		; Not firing, clear flag
			CLR.B	(Player.Fire,A3)
			RTS

.FireBlocked:		ADD.B	#1,(Player.Fire,A3)
			MOVE.B	(Player.LaserAutoFire,A3),D0
			AND.B	D0,(Player.Fire,A3)
			RTS


*****************************************************************************
* Name
*   PLY_MoveJoystick2: Check for player movement
* Synopsis
*   PLY_MoveJoystick2(PlayerObject)
*                     A3
* Function
*   This function check the joystick for player movement and calculates the
*   new players horizontal and vertical speeds.
* Registers
*   D0-D1/A0/A3: corrupted
*****************************************************************************
PLY_MoveJoystick2:	MOVE.W	$DFF00C,D0
			MOVE.W	(Player.AccelXIndex,A3),D1
			BTST	#1,D0
			BEQ	.NotRight
			CMP.W	#6,D1
			BEQ	.DoneLeftRight
			ADD.W	#1,D1
			ST.B	(Player.Direction,A3)
			LEA	PlayerDataRight,A0
			MOVE.L	A0,(Player.BlitData,A3)
			BRA	.DoneLeftRight

.NotRight:		BTST	#9,D0
			BEQ	.NotLeft
			CMP.W	#-6,D1
			BEQ	.DoneLeftRight
			SUB.W	#1,D1
			CLR.B	(Player.Direction,A3)
			LEA	PlayerDataLeft,A0
			MOVE.L	A0,(Player.BlitData,A3)
			BRA	.DoneLeftRight

.NotLeft:		CLR.W	D1
.DoneLeftRight:		MOVE.W	D1,(Player.AccelXIndex,A3)

			MOVE.W	D0,D1
			LSR.W	#1,D1
			EOR.W	D1,D0

.CheckUpDown:		BTST	#0,D0
			BEQ	.NotUp
			MOVE.W	#3 << OBJ_POSY_SHIFT,D5
			RTS

.NotUp:			BTST	#8,D0
			BEQ	.NotDown
			MOVE.W	#-3 << OBJ_POSY_SHIFT,D5

.NotDown:		RTS



PLY_Friction:		TST.W	D0
			BPL	.IsPositive
			NEG.W	D0
			MOVE.W	D0,D1
			ADD.W	#63,D1
			LSR.W	#6,D1
			SUB.W	D1,D0
			NEG.W	D0
			RTS

.IsPositive:		MOVE.W	D0,D1
			ADD.W	#63,D1
			LSR.W	#6,D1
			SUB.W	D1,D0
			RTS


*****************************************************************************
* Name
*   PLY_MoveAll: Move all players in list
* Synopsis
*   PLY_MoveAll(ObjectList)
*               A3
* Function
*   This function moves all players in list
* Registers
*   D0-D5/A0/A3: corrupted
*****************************************************************************
			XDEF	PLY_MoveAll

PLY_MoveAll:		LEA	PLY_Player1,A3

			; Get player speed
			MOVEM.W	(Player.SpeedX,A3),D4-D5

			; Adjust speed for friction
			MOVE.W	D4,D0
			BSR	PLY_Friction
			MOVE.W	D0,D4
			MOVE.W	D5,D0
			BSR	PLY_Friction
			MOVE.W	D0,D5

			; Apply acceleration
			MOVE.W	(Player.AccelXIndex,A3),D0
			LEA	PLY_AccelXTable+6,A0
			MOVE.B	(A0,D0),D0
			EXT.W	D0
			ADD.W	D0,D4

			; Simulate gravity
			MOVE.W	(Player.Weight,A3),D0
			ADD.W	D0,D5

			; Check for player movement
			BSR 	PLY_MoveJoystick2

			; Get player position
			MOVEM.W	(Player.PosX,A3),D2-D3

			; Add SpeedX to PosX
			ADD.W	D4,D2	

			; Add SpeedY to PosY
			ADD.W	D5,D3

			; Check if hit top
			CMP.W	#18 << OBJ_POSY_SHIFT,D3
			BGE	.NotTop

			; Hit top, zero out vertical speed
			MOVE.W	#18 << OBJ_POSY_SHIFT,D3
			CLR.W	D5
.NotTop:
			; Check if hit bottom
			CMP.W	#180 << OBJ_POSY_SHIFT,D3
			BLE	.NotBottom

			; Hit bottom, reverse vertical speed to make player bounce
			MOVE.W	#180 << OBJ_POSY_SHIFT,D3		
			NEG.W	D5		
.NotBottom:
			; Store players's new position and speed
			MOVEM.W	D2-D5,(Player.PosX,A3)

			; Set world display position
			MOVE.W	(Player.PosX,A3),D0
			MOVE.W	(Player.SpeedX,A3),D1
			ADD.W	D1,D1
			ADD.W	D1,D1
			ADD.W	D1,D0
			SUB.W 	#((GFX_DISPLAY_WIDTH+GFX_DISPLAY_HIDE_LEFT+GFX_DISPLAY_HIDE_RIGHT-24)/2)<<OBJ_POSX_SHIFT,D0
			MOVE.W	D0,OBJ_WorldX

			; Check for player firing
			BSR 	PLY_FireJoystick2
			RTS


*****************************************************************************
* Name
*   PLY_DrawAll: Draw all players in list
* Synopsis
*   PLY_DrawAll(Bitplane, ObjectList, ClearList)
*               D6        A3          A5
* Function
*   This function draws all players in list
* Registers
*   ??: corrupted
*****************************************************************************
			XDEF	PLY_DrawAll

PLY_DrawAll:		LEA	PLY_Player1,A3

			; Initialise blitter 
			BSR	GFX_InitBlit32x

.Loop:			; Get object position
			MOVEM.W	(Player.PosX,A3),D1-D2
			
			; Check if object is not visible
			SUB.W	OBJ_WorldX,D1
			CMP.W	#(GFX_DISPLAY_HIDE_LEFT+GFX_DISPLAY_WIDTH+GFX_DISPLAY_HIDE_RIGHT-16)<<4,D1
			BCC	.Next

			; Mask out sub-pixel position bits
			AND.W	D5,D1 
			AND.W	D5,D2 

			; Blit object
			; D3 - BlitData
			; D4 - BlitMask
			; D1 - PosX << 4
			; D2 - PosY << 4
			; D0 - Height << 4
			; D6 - Bitplane
			MOVE.W	#10<<OBJ_POSY_SHIFT,D0
			MOVE.L	(Player.BlitData,A3),D3
			MOVE.L  D3,D4
			ADD.L	#160,D4
			BSR 	GFX_Blit32x

			; Get address of next object
			; Loop back if it is not 0
.Next:			MOVE.L	(Player.Next,A3),D7
			MOVE.L	D7,A3
			BNE	.Loop

.EndOfList:		BSR	GFX_FinaliseBlit32x
			RTS


			SECTION DATA, DATA_C
			CNOP	0,4
			XDEF	PlayerDataRight
PlayerDataRight:	INCBIN "output/shipr.raw"
			CNOP	0,4
			XDEF	PlayerDataLeft
PlayerDataLeft:		INCBIN "output/shipl.raw"

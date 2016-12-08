			INCLUDE "graphics.i"
			INCLUDE "laser.i"
			INCLUDE "player.i"
			INCLUDE "objects.i"

DEBUG_LASER_BOUND_BOX	EQU	0

			SECTION	DATA,DATA
LSR_Table:		DS.B	Laser.SizeOf*LSR_MAX_NUM
LSR_ActiveList:		DC.L	0
LSR_FreeList:		DC.L	0

LSR_Offset:		DC.W	0,1,2,4,6,8,10,13

			SECTION	CODE,CODE

			XDEF	LSR_Init
LSR_Init:		
			LEA	LSR_Table,A0
			CLR.L	LSR_ActiveList
			CLR.L	LSR_FreeList

			MOVE.W	#LSR_MAX_NUM-1,D0

.Loop:			MOVE.L	LSR_FreeList,(Laser.Next,A0)
			MOVE.L	A0,LSR_FreeList
			LEA	(Laser.SizeOf,A0),A0
			DBRA	D0,.Loop
			RTS


*****************************************************************************
* Name
*   LSR_MoveAll: Move all lasers in list
* Synopsis
*   LSR_MoveAll(ObjectList)
*               A3
* Function
*   This function moves all lasers in list
* Registers
*   D0-D4/A2-A3: corrupted
*****************************************************************************
			XDEF	LSR_MoveAll

LSR_MoveAll:		LEA	LSR_ActiveList,A2
.Loop:			MOVE.L	(A2),D0
			BEQ	.Exit

			MOVE.L	D0,A3
			MOVE.B	(Laser.Life,A3),D0
			BEQ	.Dead
			SUB.B	#1,D0
			MOVE.B	D0,(Laser.Life,A3)
			AND.B	#3,D0
			BNE	.NoUpdate
			ADD.L	#8,(Laser.BlitData,A3)
			
			; Update position offset
.NoUpdate:
			; Update laser position
			MOVEM.W	(Laser.PosX,A3),D2-D4
			ADD.W	D4,D2
			MOVE.W	D2,(Laser.PosX,A3)

			; Get address of next object in list
			LEA	(Laser.Next,A3),A2
			BRA	.Loop

.Exit:			RTS

.Dead:			; Get address of next laser in list
			MOVE.L	(Laser.Next,A3),D0

			; Set next pointer of previous laser
			MOVE.L	D0,(A2)

			; Add to free list
			MOVE.L	LSR_FreeList,(Laser.Next,A3)
			MOVE.L	A3,LSR_FreeList
			BRA	.Loop

; D0 - PosX
; D1 - PosY
; D2 - SpeedX
; D3 - Direction
			XDEF	LSR_Create
LSR_Create:
			TST.L	LSR_FreeList
			BEQ	.Exit
			MOVE.L	LSR_FreeList,A0

			MOVE.W	D0,(Laser.PosX,A0)
			MOVE.W	D1,(Laser.PosY,A0)
			MOVE.W	D2,(Laser.SpeedX,A0)
			MOVE.B	#LSR_LIFE,(Laser.Life,A0)

			; Set laser bit data according to laser direction
			MOVE.L	#LaserRightData,(Laser.BlitData,A0)
			TST.B	D3
			BNE	.LaserRight
			MOVE.L	#LaserLeftData,(Laser.BlitData,A0)
.LaserRight:
			; Update free list
			MOVE.L	(Laser.Next,A0),LSR_FreeList

			; Add to head of active list
			MOVE.L	LSR_ActiveList,(Laser.Next,A0)
			MOVE.L	A0,LSR_ActiveList
.Exit:			RTS


*****************************************************************************
* Name
*   LSR_DrawAll: Draw all lasers in list
* Synopsis
*   LSR_DrawAll(Bitplane, ClearList)
*               D5        A5
* Function
*   This function draws all lasers in list
* Registers
*   ??: corrupted
*****************************************************************************
			XDEF	LSR_DrawAll

LSR_DrawAll:		; Initialise blitter 
			BSR	GFX_InitBlit16x

			; Copy object list into D7, as blitting will corrupt A3
			MOVE.L	LSR_ActiveList,D7
.Loop:			BEQ	.EndOfList
			MOVE.L	D7,A3
			
			; Get object position
			MOVEM.W	(Laser.PosX,A3),D1-D2
			
			; Check if object is not visible
			SUB.W	OBJ_WorldX,D1
			CMP.W	#(GFX_DISPLAY_HIDE_LEFT+GFX_DISPLAY_WIDTH+GFX_DISPLAY_HIDE_RIGHT-16)<<4,D1
			BCC	.Next
			
			; Convert world coordinates into screen coordinates
			LSR.W	#OBJ_POSX_SHIFT,D1
			LSR.W	#OBJ_POSY_SHIFT,D2

			; Blit object
			MOVE.W	#(4<<6)|2,D0
			MOVE.L	D5,A0
			MOVE.L	(Laser.BlitData,A3),A1
			LEA	(128,A1),A2
			;BSR 	GFX_Blit
			MOVE.L	D7,A3

			; Get address of next object
			; Loop back if it is not 0
.Next:			MOVE.L	(Laser.Next,A3),D7
			BRA	.Loop

.Dead:			CLR.B	(Laser.Life,A3)
			MOVE.L	(Laser.Next,A3),D7
			BRA	.Loop

.EndOfList:		BSR	GFX_FinaliseBlit16x
			RTS


*****************************************************************************
* Name
*   LSR_CalcBoundBox: Calculate bounding box for all lasers (relative to player)
* Synopsis
*   BoxTL,BoxBR = LSR_CalcBoundBox(Box)
*   D0/D1,D2/D3                    A0
* Function
*   
* Registers
*   ??: corrupted
*****************************************************************************
			XDEF	LSR_CalcBoundBox
LSR_CalcBoundBox:	MOVE.L	LSR_ActiveList,D7
			BEQ	.ExitNoLaser
			MOVE.L	D7,A3

			; Get first laser position, centre on it
			MOVEM.W	(Laser.PosX,A3),D4/D6
			MOVEQ	#0,D5

			; Initialise bounding box
			MOVEQ	#0,D0
			MOVE.W	D6,D1
			MOVE.W	#LSR_SIZEX,D2
			MOVE.W	D6,D3

			; Get next laser in list, exit if no more
			MOVE.L	(Laser.Next,A3),D7
			BEQ	.Exit

.Loop:			; Get next laster position
			MOVE.L	D7,A3
			MOVEM.W	(Laser.PosX,A3),D5-D6
			
			; Adjust laser X position to be relative to first laser
			SUB.W	D4,D5

.CheckMinX:		CMP.W	D5,D0
			BLE	.CheckMaxX	; Jump if GE than min X
			MOVE.W	D5,D0		; Update min X
			BRA	.CheckMinY
.CheckMaxX:		ADD.W	#LSR_SIZEX,D5
			CMP.W	D5,D2
			BGE	.CheckMinY	; Jump if LE than max X
			MOVE.W	D5,D2		; Update max X
.CheckMinY:		CMP.W	D6,D1
			BLE	.CheckMaxY
			MOVE.W	D6,D1
			BRA	.CheckDone
.CheckMaxY:		CMP.W	D6,D3
			BGE	.CheckDone
			MOVE.W	D6,D3
.CheckDone:
			; Get address of next laser, loop back if not 0
			MOVE.L	(Laser.Next,A3),D7
			BNE	.Loop

.Exit:			; Adjust bounding box back to global coordinates
			ADD.W	D4,D0
			ADD.W	D4,D2

			; DEBUG: Position Alien1 and Alien2 at bounding box top/left and bottom/right 
			IFNE DEBUG_LASER_BOUND_BOX
			LEA	Alien1,A3
			MOVEM.W	D0-D1,(Object.PosX,A3)
			LEA	Alien2,A3
			SUB.W	#16<<OBJ_POSX_SHIFT,D2
			MOVEM.W	D2-D3,(Object.PosX,A3)
			ADD.W	#16<<OBJ_POSX_SHIFT,D2
			ENDIF
			RTS

.ExitNoLaser:		MOVEQ	#0,D1
			MOVEQ	#0,D3
			RTS


*****************************************************************************
* Name
*   LSR_CheckBoxCollision: Check if any laser is in object bounding box
* Synopsis
*   Hit, Laser = LSR_CheckBoxCollision(Object, BoxTL, BoxBR)	
*   !Z	 A0                            A3      D4/D5  D6/D7
* Function
*   This routine checks if any lasers are in the objects bounding box.
*   If a laser is within the objects bounding box the routine returns with
*   the Z flag cleared and A0 pointer to the laser structure, otherwise the
*   the Z flag is set.
* Registers
*   ??: corrupted
*****************************************************************************
			XDEF	LSR_CheckBoxCollision
LSR_CheckBoxCollision:	
			MOVE.L	LSR_ActiveList,D0
			BEQ	.Exit
			SUB	D4,D6
.Loop:			MOVE.L	D0,A0
			MOVEM.W	(Laser.PosX,A0),D0-D1
			SUB	D4,D0
			CMP.W	D1,D5
			BGT	.CheckDone
			CMP.W	D1,D7
			BLT	.CheckDone			
			CMP.W	D0,D6
			BLT	.CheckDone	
			ADD.W	#LSR_SIZEX,D0
			TST.W	D0
			BGT	.Exit
.CheckDone:		MOVE.L	(Laser.Next,A0),D0
			BNE	.Loop
.Exit:			RTS

			SECTION DATA, DATA_C
			CNOP	0,4
LaserRightData:		INCBIN "output/laserr.raw"
			CNOP	0,4
LaserLeftData:		INCBIN "output/laserl.raw"

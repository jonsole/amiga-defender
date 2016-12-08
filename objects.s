			INCLUDE "graphics.i"
			INCLUDE "objects.i"
			INCLUDE "player.i"
			
OBJ_FreeList:		DC.L	1
			XDEF	OBJ_WorldX
OBJ_WorldX:		DC.W	0
			SECTION	CODE,CODE

*****************************************************************************
* Name
*   OBJ_MoveAll: Move all objects in list
* Synopsis
*   OBJ_MoveAll(ObjectList)
*               D0
* Function
*   This function moves all objects in list according to speed and accleration 
* Registers
*   D0-D5/A3: corrupted
*****************************************************************************
			XDEF	OBJ_MoveAll

OBJ_MoveAll:		; Exit if pointer is 0
			TST.L	D0
			BEQ	.Exit

.MoveLoop:		; Copy pointer to A3
			MOVE.L	D0,A3

			; Apply acceleration
			MOVE.W	(Object.AccelXCount,A3),D0
			SUB.W	#1,D0
			BMI	.NoAccelX
			MOVE.W	D0,(Object.AccelXCount,A3)
			ADD.W	D0,(Object.SpeedX,A3)
.NoAccelX:

			MOVE.W	(Object.AccelYCount,A3),D0
			SUB.W	#1,D0
			BMI	.NoAccelY
			MOVE.W	D0,(Object.AccelYCount,A3)
			ADD.W	D0,(Object.SpeedY,A3)
.NoAccelY:

			; Get object position, speed
			MOVEM.W	(Object.PosX,A3),D0-D3

			; Simulate gravity
			MOVE.W	(Object.Weight,A3),D4
			ADD.W	D4,D3
			MOVE.W	D3,(Object.SpeedY,A3)

			; Add SpeedX to PosX
.MoveX:			ADD.W	D2,D0	

			; Add SpeedY to PosY, bounce if beyond top or bottom limits
.MoveY:			ADD.W	D3,D1
			CMP.W	#1<<OBJ_POSY_SHIFT,D1
			BCS	.BounceY
			CMP.W	#190<<OBJ_POSY_SHIFT,D1
			BCC	.BounceY

.MoveDone:		; Store object's new position
			MOVEM.W	D0-D1,(Object.PosX,A3)

			; Get address of next object in list
			MOVE.L	(Object.Next,A3),D0

			; Loop back if address is not 0
			BNE	.MoveLoop
.Exit:			RTS

.BounceY:		NEG.W	D3
			MOVE.W	D3,(Object.SpeedY,A3)
			BRA	.MoveDone








			XDEF	OBJ_SortAll
OBJ_SortAll:		
			; Copy list address into A1
			MOVE.L	A0,A1

			; Get first and second objects, exit if less than 2 objects
			MOVE.L	(A1),D1
			BEQ	.End
			MOVE.L	D1,A2
			MOVE.L	(Object.Next,A2),D1
			BEQ	.End
			MOVE.L	D1,A3	

			; Clear moved flag
			MOVEQ	#0,D0	

.Loop			; Compare vertical positions, don't swap if first is higher than second
			MOVE.W	(Object.PosY,A2),D1
			CMP.W	(Object.PosY,A3),D1
			BLE	.NoSwap

			; Swap objects around
			MOVE.L 	(Object.Next,A3),(Object.Next,A2) 
			MOVE.L 	A2,(Object.Next,A3)
			MOVE.L	A3,(A1)

			; Set moved flag
			MOVEQ	#1,D0

.NoSwap:		; Move along list
			LEA	(Object.Next,A2),A1
			MOVE.L	A3,A2
			MOVE.L	(Object.Next,A3),D1

			; Loop back if more objects in list
			MOVE.L	D1,A3
			BNE	.Loop

			; No more objects, check moved flag, exit if nothing moved
			; on this pass
			TST.W	D0
			BEQ	.End

			; Get first and second objects
			MOVE.L	A0,A1
			MOVE.L	(A1),A2
			MOVE.L	(Object.Next,A2),A3

			; Clear moved flag
			MOVEQ	#0,D0

			; Jump back for another pass
			BRA	.Loop
.End:			RTS


*****************************************************************************
* Name
*   OBJ_CheckBoxCollision: Check for objects within box
* Synopsis
*   Object, ObjectTL,ObjectBR = OBJ_CheckBoxCollision(ObjectList,BoxTL,BoxBR)
*   A3      D4-D5    D6-D7                            A3         D0-D1 D2-D3
* Function
*   This function checks if objects are within bounding box, if one if found
*   the function returns with A3 containing the address of the object, or 0
*   is no object within box.  Z flag is also set if no object with box.
* Registers
*   ???: corrupted
*****************************************************************************
			XDEF	OBJ_CheckBoxCollision

OBJ_CheckBoxCollision:	; Exit if pointer is 0
			MOVE.L	A3,D4
			BEQ	.Exit

			; Convert bounding box right to width
			SUB.W	D0,D2

.MoveLoop:		; Get object size & position
			MOVEM.W	(Object.SizeX,A3),D4-D7

			;D6/D7 = R2 left/top
			;0/D1 = R1 left/top
			;D2/D3 = R1 right/bottom

			; R2.top > R1.bottom
			CMP.W	D7,D3
			BLT	.NotIn

			; R2.bottom < R1.top
			ADD.W	D5,D7
			CMP.W	D7,D1
			BGT	.NotIn

			; Adjust R2.left relative to R1.left
			SUB.W	D0,D6

			; R2.left > R1.right
			CMP.W	D6,D2
			BLT	.NotIn

			; R2.right < R1.left
			ADD.W	D4,D6
			TST.W	D6
			BGT	.In

.NotIn:			; Get address of next object in list
			MOVE.L	(Object.Next,A3),D4
			MOVE.L	D4,A3

			; Loop back if address is not 0
			BNE	.MoveLoop

.Exit:			; Return with:
			;    Z - Set
			RTS

.In:			; Convert width back to bounding box right
			ADD.W	D0,D2

			; Adjust object right back to global coordinates 
			ADD.W	D0,D6

			; Clear Z flag
			MOVEQ	#1, D4

			; Get object top/left
			MOVEM.W	(Object.PosX,A3),D4-D5

			; Return with:
			;    A3 - Address of object
			;    D4/D5 - Object left/top position
			;    D6/D7 - Object right/bottom position
			;    Z - Cleared
			RTS


*****************************************************************************
* Name
*   OBJ_DrawAll: Draw all objects in list
* Synopsis
*   OBJ_DrawAll(Bitplane, ObjectList, CopperList, ClearList)
*               D6        A3          A4          A2
* Function
*   This function draws all objects in list
* Registers
*   ??: corrupted
*****************************************************************************
			XDEF	OBJ_DrawAll

OBJ_DrawAll:		; Initialise blitter and sprite queue
			BSR	GFX_InitBlit16x
			BSR	GFX_InitSprites
			;A5 = Position Table, D5 = Mask

.Loop:			; Get object position
			MOVEM.W	(Object.SizeY,A3),D0-D2
			
			; Check if object is not visible
			SUB.W	OBJ_WorldX,D1
			CMP.W	#(GFX_DISPLAY_HIDE_LEFT+GFX_DISPLAY_WIDTH+GFX_DISPLAY_HIDE_RIGHT-16)<<OBJ_POSX_SHIFT,D1
			BCC	.Next

			; Check if we should use alternate sprite data for this frame
			;BTST.B	#OBJ_FLAG_ALT_SPRITE,(Object.Flags,A3)
			;BEQ	.NoAlt
			;BCLR.B	#OBJ_FLAG_ALT_SPRITE,(Object.Flags,A3)
			;LEA	(4,A3),A3

.NoAlt:			; Mask out sub-pixel position bits
			AND.W	D5,D1 
			AND.W	D5,D2 
			AND.W	D5,D0
			
			; Add object to sprite queue, carry set if unable to queue
			MOVEM.L (Object.SpriteData,A3),D3-D4
			BSR	GFX_QueueSprite
			BCC	.Next
			; D0-D4/A0-A1/A4 changed

			; Blit object
			; D3 - BlitData
			; D4 - BlitMask
			; D1 - PosX << 4
			; D2 - PosY << 4
			; D0 - Height << 4
			; D6 - Bitplane
			MOVEM.L	(Object.BlitData,A3),D3-D4
			BSR 	GFX_Blit16x
			; D0-D2/D7/A1 changed
			
			; Get address of next object
			; Loop back if it is not 0
.Next:			MOVE.L	(Object.Next,A3),D7
			MOVE.L	D7,A3
			BNE	.Loop

.EndOfList:		BSR 	GFX_FinaliseSprites
			BSR	GFX_FinaliseBlit16x
			RTS


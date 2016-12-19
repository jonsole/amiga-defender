			INCLUDE "graphics.i"
			INCLUDE "objects.i"
			INCLUDE "player.i"
			
			SECTION BSS,BSS
OBJ_ActiveList:		DS.L	1
OBJ_DrawList:		DS.L	1
OBJ_FreeList:		DS.L	1
OBJ_Table:		DS.B	Object.SizeOf*OBJ_MAX_NUM

			XDEF	OBJ_WorldX
OBJ_WorldX:		DC.W	0

			SECTION	CODE,CODE

*****************************************************************************
* Name
*   OBJ_Init: Initialise object list 
* Synopsis
*   OBJ_Init()
* Function
*   This function intialise the global object list. 
* Registers
*   D0/A0: corrupted
*****************************************************************************
			XDEF	OBJ_Init
OBJ_Init:		LEA	OBJ_Table,A0
			CLR.L	OBJ_ActiveList
			CLR.L	OBJ_DrawList
			CLR.L	OBJ_FreeList

			MOVE.W	#OBJ_MAX_NUM-1,D0

.Loop:			MOVE.L	OBJ_FreeList,(Object.Next,A0)
			MOVE.L	A0,OBJ_FreeList
			LEA	(Object.SizeOf,A0),A0
			DBRA	D0,.Loop
			RTS

*****************************************************************************
* Name
*   OBJ_Create: Create object from free list 
* Synopsis
*   Object = OBJ_Create()
*   D0
* Function
*   This function create a new object from the free list. 
* Registers
*   D0/A0: corrupted
*****************************************************************************
			XDEF	OBJ_Create
OBJ_Create:		TST.L	OBJ_FreeList
			BEQ	.Exit
			MOVE.L	OBJ_FreeList,A0

			; Update free list
			MOVE.L	(Object.Next,A0),OBJ_FreeList

			; Add to head of active list
			MOVE.L	OBJ_ActiveList,(Object.Next,A0)
			MOVE.L	A0,OBJ_ActiveList
			MOVE.L	A0,D0
.Exit:			RTS


*****************************************************************************
* Name
*   OBJ_MoveAll: Move all objects in list
* Synopsis
*   OBJ_MoveAll()
* Function
*   This function moves all objects in list according to speed and accleration 
* Registers
*   D0-D5/A3: corrupted
*****************************************************************************
			XDEF	OBJ_MoveAll
OBJ_MoveAll:		MOVE.L	OBJ_ActiveList, D0
			BEQ	.Exit

.MoveLoop:		; Copy pointer to A3
			MOVE.L	D0,A3

			MOVE.L	(Object.MoveFunction,A3),A0
			JSR	(A0)

			; Get address of next object in list
			MOVE.L	(Object.Next,A3),D0

			; Loop back if address is not 0
			BNE	.MoveLoop
.Exit:			RTS


			XDEF	OBJ_AddToDrawList
OBJ_AddToDrawList:	LEA	OBJ_DrawList,A1
			MOVE.W	(Object.PosY,A0),D0

			MOVE.L	(A1),D1
			;BEQ	.End

			;MOVE.L	D1,A2
			;CMP.W	D0,(ObjectPosY,A2)

.End:			MOVE.L	D1,(Object.DrawNext,A0)
			MOVE.L	A0,(A1)
			RTS

			XDEF	OBJ_DefaultMove
OBJ_DefaultMove:        ; Apply acceleration
			MOVE.W	(Object.AccelXCount,A3),D0
			SUB.W	#1,D0
			BMI	.NoAccelX
			MOVE.W	D0,(Object.AccelXCount,A3)
			MOVE.W	(Object.AccelX,A3),D0
			ADD.W	D0,(Object.SpeedX,A3)
.NoAccelX:
			MOVE.W	(Object.AccelYCount,A3),D0
			SUB.W	#1,D0
			BMI	.NoAccelY
			MOVE.W	D0,(Object.AccelYCount,A3)
			MOVE.W	(Object.AccelY,A3),D0
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
			BCS	.MoveDone

.BounceY:		NEG.W	D3
			MOVE.W	D3,(Object.SpeedY,A3)
			MOVE.W	#190<<OBJ_POSY_SHIFT,D1

.MoveDone:		; Store object's new position
			MOVEM.W	D0-D1,(Object.PosX,A3)
			RTS

*****************************************************************************
* Name
*   OBJ_SortAll: Sort all objects in list by vertical position
* Synopsis
*   OBJ_SortAll()
* Function
*   This function sorts all object in the active list by ascending vertical
*   position. 
* Registers
*   D0-D1/A0-A3: corrupted
*****************************************************************************
			XDEF	OBJ_SortAll
OBJ_SortAll:		; Get list address into A0, A1
			LEA	OBJ_DrawList,A0
			MOVE.L	A0,A1

			; Get first and second objects, exit if less than 2 objects
			MOVE.L	(A1),D1
			BEQ	.End
			MOVE.L	D1,A2
			MOVE.L	(Object.DrawNext,A2),D1
			BEQ	.End
			MOVE.L	D1,A3	

			; Clear moved flag
			MOVEQ	#0,D0	

.Loop			; Compare vertical positions, don't swap if first is higher than second
			MOVE.W	(Object.PosY,A2),D1
			CMP.W	(Object.PosY,A3),D1
			BLE	.NoSwap

			; Swap objects around
			MOVE.L 	(Object.DrawNext,A3),(Object.DrawNext,A2) 
			MOVE.L 	A2,(Object.DrawNext,A3)
			MOVE.L	A3,(A1)

			; Set moved flag
			MOVEQ	#1,D0

.NoSwap:		; Move along list
			LEA	(Object.DrawNext,A2),A1
			MOVE.L	A3,A2
			MOVE.L	(Object.DrawNext,A3),D1

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
			MOVE.L	(Object.DrawNext,A2),A3

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
			XDEF	OBJ_CheckBoxCollisionInit
OBJ_CheckBoxCollisionInit:
			MOVE.L	OBJ_DrawList,D4
			RTS

			XDEF	OBJ_CheckBoxCollisionNext
OBJ_CheckBoxCollisionNext:		
			MOVE.L	(Object.DrawNext,A3),D4
			RTS

			XDEF	OBJ_CheckBoxCollision
OBJ_CheckBoxCollision:	MOVE.L	D4,A3

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
			MOVE.L	(Object.DrawNext,A3),D4
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

			MOVE.L	OBJ_DrawList,D7
			BEQ	.EndOfList

.Loop:			MOVE.L	D7,A3

			; Get object position
			MOVEM.W	(Object.SizeY,A3),D0-D2
			
			; Check if object is not visible
			SUB.W	OBJ_WorldX,D1
			CMP.W	#(GFX_DISPLAY_HIDE_LEFT+GFX_DISPLAY_WIDTH+GFX_DISPLAY_HIDE_RIGHT-16)<<OBJ_POSX_SHIFT,D1
			BCC	.Next

			; Mask out sub-pixel position bits
			AND.W	D5,D1 
			AND.W	D5,D2 
			AND.W	D5,D0
			
			; Check if we should use alternate sprite data for this frame
			BCLR.B	#OBJ_FLAG_ALT_SPRITE,(Object.Flags,A3)
			BEQ	.NoAlt

			; Add object to sprite queue, carry set if unable to queue
			MOVEM.W (Object.SpriteAltData,A3),D3-D4
			BSR	GFX_QueueSprite
			BCC	.Next
			MOVEM.L	(Object.BlitAltData,A3),D3-D4
			BSR 	GFX_Blit16x

			BRA	.Next

			; Add object to sprite queue, carry set if unable to queue
.NoAlt:			MOVEM.W (Object.SpriteData,A3),D3-D4
			BSR	GFX_QueueSprite
			BCC	.Next
			MOVEM.L	(Object.BlitData,A3),D3-D4
			BSR 	GFX_Blit16x
			
			; Get address of next object
			; Loop back if it is not 0
.Next:			MOVE.L	(Object.DrawNext,A3),D7
			BNE	.Loop

.EndOfList:		BSR 	GFX_FinaliseSprites
			BSR	GFX_FinaliseBlit16x
			RTS


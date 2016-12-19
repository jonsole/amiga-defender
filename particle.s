			INCLUDE "graphics.i"
			INCLUDE "objects.i"
                        INCLUDE "particle.i"

			SECTION BSS,BSS
PART_ActiveList:	DS.L	1
PART_FreeList:		DS.L	1
PART_Table:		DS.B	Particle.SizeOf*PART_MAX_NUM


                        SECTION CODE,CODE

                        XDEF    PART_Init
PART_Init:              LEA	PART_Table,A0
			CLR.L	PART_ActiveList
			CLR.L	PART_FreeList

			MOVE.W	#PART_MAX_NUM-1,D0

.Loop:			MOVE.L	PART_FreeList,(Particle.Next,A0)
			MOVE.L	A0,PART_FreeList
			LEA	(Particle.SizeOf,A0),A0
			DBRA	D0,.Loop
			RTS

                        XDEF    PART_Create
PART_Create:	        TST.L	PART_FreeList
			BEQ	.Exit
			MOVE.L	PART_FreeList,A1

			; Update free list
			MOVE.L	(Particle.Next,A1),PART_FreeList

			; Add to head of active list
			MOVE.L	PART_ActiveList,(Particle.Next,A1)
			MOVE.L	A1,PART_ActiveList
			MOVEQ	#1,D0
.Exit:			RTS


                        XDEF    PART_MoveAll
PART_MoveAll:		LEA	PART_ActiveList,A2
.Loop:  		MOVE.L  (A2),D0
                        BEQ     .Exit
			MOVE.L	D0,A3

			; Get object position, speed
			MOVEM.W	(Particle.PosX,A3),D0-D3

			; Simulate gravity
			MOVE.W	(Particle.Weight,A3),D4
			ADD.W	D4,D3
			MOVE.W	D3,(Particle.SpeedY,A3)

			; Add SpeedX to PosX
.MoveX:			ADD.W	D2,D0	

			; Add SpeedY to PosY, bounce if beyond top or bottom limits
.MoveY:			ADD.W	D3,D1
			CMP.W	#1<<OBJ_POSY_SHIFT,D1
			BCS	.BounceY
			CMP.W	#190<<OBJ_POSY_SHIFT,D1
			BCC	.BounceY
                        SUB.W   #1,(Particle.Life,A3)

.MoveDone:		BCS     .Dead

                        ; Store object's new position
			MOVEM.W	D0-D1,(Particle.PosX,A3)

			; Get address of next object in list
			LEA	(Particle.Next,A3),A2
			BRA	.Loop

.Exit:			RTS

.Dead:			; Get address of next particle in list
			MOVE.L	(Particle.Next,A3),D0

			; Set next pointer of previous particle
			MOVE.L	D0,(A2)

			; Add to free list
			MOVE.L	PART_FreeList,(Particle.Next,A3)
			MOVE.L	A3,PART_FreeList
			BRA	.Loop

.BounceY:		NEG.W	D3
			MOVE.W	D3,(Particle.SpeedY,A3)
			SUB.W   #20,(Particle.Life,A3)
                        BRA	.MoveDone




*****************************************************************************
* Name
*   PART_DrawAll: Draw all particles in list
* Synopsis
*   PART_DrawAll(Bitplane)
*                D6
* Function
*   This function draws all particles in list
* Registers
*   ??: corrupted
*****************************************************************************
GFX_PlotTable:		REPT	336
.Y:			SET	REPTN
.X:			SET 	REPTN
.HEIGHT:		SET	REPTN
			DC.W	(.Y * GFX_BITPLANE_BYTES_PER_STRIDE)	; Y offset
			DC.W	((.X >> 4) * 2)				; X offset
			DC.W	($C000 >> (.X & $0F))
			DC.W	0
			DC.W	0
			DC.W	0
			DC.W	0 ; spare
			DC.W	0 ; spare
			ENDR


			XDEF	PART_DrawAll
PART_DrawAll:		
			MOVE.L	PART_ActiveList,D7
			BEQ	.EndOfList

                        LEA	(GFX_PlotTable,PC),A1

.Loop:			MOVE.L	D7,A3

			; Get object position
			MOVEM.W	(Particle.PosX,A3),D0-D1
			
			; Check if object is not visible
			SUB.W	OBJ_WorldX,D0
			CMP.W	#(GFX_DISPLAY_HIDE_LEFT+GFX_DISPLAY_WIDTH+GFX_DISPLAY_HIDE_RIGHT-16)<<OBJ_POSX_SHIFT,D0
			BCC	.Next

        		; Mask out sub-pixel position bits
			AND.W	D5,D0
			AND.W	D5,D1

			; Convert X & Y positions into offsets and add to bitplane address
			MOVE.W	(2,A1,D0.W),D6          ; Set X offset
			ADD.W	(0,A1,D1.W),D6          ; Add Y offset

                        MOVE.W  (4,A1,D0.W),D2
			
                        MOVE.L  D6,A0
                        OR.W    D2,(A0)
                        ADD.W   #GFX_BITPLANE_BYTES_PER_STRIDE,A0
                        OR.W    D2,(A0)
                        
                        MOVE.L  D6,(A2)+

			; Loop back if it is not 0
.Next:			MOVE.L	(Object.Next,A3),D7
			BNE	.Loop

.EndOfList:		CLR.L   (A2)+
                        RTS     



                        XDEF    PART_ClearAll
PART_ClearAll:
.Loop:  		MOVE.L  (A2)+,D6
			BEQ	.EndOfList
                        MOVE.L  D6,A0
                        CLR.W   (A0)
                        ADD.W   #GFX_BITPLANE_BYTES_PER_STRIDE,A0
                        CLR.W   (A0)
                        BRA     .Loop

.EndOfList:		RTS

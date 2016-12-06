			INCLUDE	"include/custom.i"
			INCLUDE "graphics.i"
			INCLUDE "objects.i"
			INCLUDE "player.i"
			INCLUDE "laser.i"

			XREF	SYS_TakeOver

			SECTION	DATA,DATA

			XDEF	Alien1
Alien1:			DC.L	Alien2		; Next
			DC.L	Alien1Hit
			DC.L	Alien1Move
			DC.W	16,10,-200,50<<OBJ_POSY_SHIFT	; SizeX, SizeY, PosX, PosY
			DC.W	0, -12		; SpeedX, SpeedY
			DC.W	0, 0, 0, 0	; AccelX, AccelY
			DC.W	1		; Weight
			DC.L	Alien1Sprite, Alien1FlashSprite
			DC.L	Alien1Data, Alien1FlashData
			DC.B	0,0

			XDEF	Alien2
Alien2:			DC.L	0		; Next
			DC.L	Alien2Hit
			DC.L	Alien2Move
			DC.W	16,10,+200,70<<OBJ_POSY_SHIFT	; SizeX, SizeY, PosX, PosY
			DC.W	0, -12		; SpeedX, SpeedY
			DC.W	0, 0, 0, 0 	; AccelX, AccelY
			DC.W	2		; Weight
			DC.L	Alien2Sprite, Alien1FlashSprite
			DC.L	Alien2Data, Alien1FlashData
			DC.B	0,0

			SECTION BSS, BSS
APP_ClearList1:		DS.W	2000
APP_ClearList2:		DS.W	2000
APP_ClearList3:		DS.W	2000

APP_BitplaneMemory	DS.L	1
APP_CopperList		DS.L	1

APP_SoftwareIntHandler: DS.L	1

			XDEF	APP_ObjectList
APP_ObjectList:		DC.L	Alien1

			SECTION BSS_C,BSS_C
APP_CopperList1:	DS.W	100*16+2
APP_CopperList2:	DS.W	100*16+2
APP_CopperList3:	DS.W	100*16+2

			SECTION	CODE,CODE

APP_Start:              LEA     APP_Main,A0
                        BSR     SYS_TakeOver
                        MOVEQ   #0,D0
                        RTS

APP_Main:               ; Set interrupt1 vector
			LEA	APP_Interrupt1Handler,A0
			MOVEQ	#25,D0
			BSR	SYS_SetVector

			; Enable software interrupt
			MOVE.W	#INTENA_SET | INTENA_SOFT,(INTENA,A6)

			LEA	APP_VerticalBlankHandler,A0
			MOVE.L	A0,GFX_VerticalBlankHandler
			LEA	APP_SoftwareIntHandler1,A0
			MOVE.L	A0,APP_SoftwareIntHandler

			LEA	APP_CopperList1,A0
			MOVE.L	#$FFFFFFFE,(A0)
			LEA	APP_CopperList2,A0
			MOVE.L	#$FFFFFFFE,(A0)
			LEA	APP_CopperList3,A0
			MOVE.L	#$FFFFFFFE,(A0)
		
			; Initialise laser
			BSR	LSR_Init

			; Initialise BLIT clear lists
			CLR.L	APP_ClearList1
			CLR.L	APP_ClearList2
			CLR.L	APP_ClearList3

			; Set pointer to object list
			LEA	Alien1,A0
			MOVE.L	A0,APP_ObjectList

			; Initialise graphics subsystem, this will start vertical
			; blank interrupts
			BSR     GFX_Init

			; Initialise music player
			LEA	Module,A0
			SUB	A1,A1
			SUB	A2,A2
			MOVEQ	#0,D0
			BSR	P61_Init

.Loop:			; TODO: Alien AI code

			; Loop back if left mouse button not pressed
			BTST	#6,$BFE001
 			BNE	.Loop
			RTS


*****************************************************************************
APP_Interrupt1Handler:	MOVEM.L	D0-D7/A0-A6,-(SP)
			LEA	CUSTOM,A6

			; Get pending interrupts
			MOVE.W	(INTREQR,A6),D0

			; Check if software interrupt pending
			BTST	#INTREQ_SOFT_POS,D0
			BEQ	.NotSoft

			; Clear software interrupt
			MOVE.W	#INTREQ_SOFT,(INTREQ,A6)		

			; Call application software interrupt handler
			MOVE.L	APP_SoftwareIntHandler,A0
			JSR	(A0)
			MOVE.L	A0,APP_SoftwareIntHandler

.NotSoft:		MOVEM.L	(SP)+,D0-D7/A0-A6
			RTE


*****************************************************************************
APP_VerticalBlankHandler:
			; Save registers that we're changing (D0/A0/A6 saved for us)
			MOVEM.L	D1-D7/A1-A5,-(SP)

			; Setup copper and bitplane pointers
			MOVE.L	APP_BitplaneMemory,A1
			MOVE.L	APP_CopperList,A2
			BSR 	GFX_SetCopperBitplanes

			; Play music
			JSR	P61_Music

			; Generate software interrupt
			MOVE.W	#INTREQ_SET|INTREQ_SOFT,(INTREQ,A6)

			; Return with same vertical blank handler
			LEA	APP_VerticalBlankHandler,A0
			MOVEM.L	(SP)+,D1-D7/A1-A5
			RTS


*****************************************************************************
APP_SoftwareIntHandler1:
			; Clear objects in bitplane memory 1
			LEA	APP_ClearList1,A5
			BSR	APP_ClearObjects
			
			; Move objects
			BSR	APP_MoveObjects

			; Draw objects
			MOVE.L	APP_ObjectList,A3
			LEA	APP_CopperList1,A4
			LEA	APP_ClearList1,A5
			MOVE.L	#GFX_BitplaneMemory1,D5
			BSR	APP_DrawObjects

			; Store bitplane memory and copper list for next vertical blank
			MOVE.L	#GFX_BitplaneMemory1,APP_BitplaneMemory
			MOVE.L	#APP_CopperList1,APP_CopperList

			; Return with other software interrupt handler
			LEA	APP_SoftwareIntHandler2,A0
			RTS


*****************************************************************************
APP_SoftwareIntHandler2:
			; Clear objects in bitplane memory 2
			LEA	APP_ClearList2,A5
			BSR	APP_ClearObjects
			
			; Move objects
			BSR	APP_MoveObjects

			; Draw objects
			MOVE.L	APP_ObjectList,A3
			LEA	APP_CopperList2,A4
			LEA	APP_ClearList2,A5
			MOVE.L	#GFX_BitplaneMemory2,D5
			BSR	APP_DrawObjects

			; Store bitplane memory and copper list for next vertical blank
			MOVE.L	#GFX_BitplaneMemory2,APP_BitplaneMemory
			MOVE.L	#APP_CopperList2,APP_CopperList

			; Return with other software interrupt handler
			LEA	APP_SoftwareIntHandler3,A0
			RTS

*****************************************************************************
APP_SoftwareIntHandler3:
			; Clear objects in bitplane memory 3
			LEA	APP_ClearList3,A5
			BSR	APP_ClearObjects
			
			; Move objects
			BSR	APP_MoveObjects

			; Draw objects
			MOVE.L	APP_ObjectList,A3
			LEA	APP_CopperList3,A4
			LEA	APP_ClearList3,A5
			MOVE.L	#GFX_BitplaneMemory3,D5
			BSR	APP_DrawObjects

			; Store bitplane memory and copper list for next vertical blank
			MOVE.L	#GFX_BitplaneMemory3,APP_BitplaneMemory
			MOVE.L	#APP_CopperList3,APP_CopperList

			; Return with other software interrupt handler
			LEA	APP_SoftwareIntHandler1,A0
			RTS



*****************************************************************************
APP_ClearObjects:	; Clear Objects
			BSR	GFX_ClearList16x

			; Clear Player
			BSR	GFX_ClearList32x

			; Clear Lasers
			BSR	GFX_ClearList16x
			RTS


*****************************************************************************
APP_DrawObjects:	; Draw Objects
			MOVE.L	D5,-(SP)
			BSR	OBJ_DrawAll

			; Draw Player
			MOVE.L	(SP),D5
			BSR	PLY_DrawAll

			; Draw Lasers
			MOVE.L	(SP)+,D5
			BSR	LSR_DrawAll
			RTS


*****************************************************************************
APP_MoveObjects:	; Calculate bounding box around all lasers
			BSR	LSR_CalcBoundBox

			; Find objects within bounding box
			MOVE.L	APP_ObjectList,D4
.CheckLoop:		MOVE.L	D4,A3
			BSR	OBJ_CheckBoxCollision
			
			; Jump out of loop if no (more) objects within laser bounding box
			BEQ	.NoObj

			; Check if any lasers are actualling with in objects bounding box
			MOVEM.L	D0-D1,-(SP)
			BSR	LSR_CheckBoxCollision
			MOVEM.L	(SP)+,D0-D1
			BEQ	.NoCollision

			; Terminate laser on next move
			CLR.B	(Laser.Life,A0)

			; Set objects hit flag (will cause drawing of alternative sprite)
			BSET.B	#0,(Object.Flags,A3)

			; Call object hit function
			MOVE.L	(Object.HitFunction,A3),A1
			JSR	(A1)

.NoCollision:		; Continue check with next object
			MOVE.L	(Object.Next,A3),D4
			BNE	.CheckLoop

.NoObj:			; Move objects
			MOVE.L	APP_ObjectList,D0
			BSR	OBJ_MoveAll

			; Move lasers
			BSR	LSR_MoveAll

			; Move player (TODO: Pass in joystick bitmap)
			BSR	PLY_MoveAll

			; Sort objects
			LEA	APP_ObjectList,A0
			BSR	OBJ_SortAll

			RTS


Alien1Move:		MOVE.W	(Object.SpeedX,A3),D0
			SUB.W	#20,D0
			ASR.W	#7,D0
			SUB.W	D0,(Object.AccelX,A3)

			;MOVEQ	#10,D1
			;MOVE.W	(Object.PosY,A3),D0
			;MOVE.W	(Object.AccelY,A3),D1
			;ASL.W	#3,D1
			;ADD.W	D1,D0
			;SUB.W	#120<<OBJ_POSY_SHIFT,D0
			;NEG.W	D0
			;ASR.W	#4,D0
			;MOVE.W	D0,D1
.OK:			;MOVE.W	D1,(Object.AccelY,A3)
			;ADD.W	#2,(Object.SpeedY,A3)
			RTS

Alien1Hit:		; Push object
			MOVE.W	(Laser.SpeedX,A0),D0
			ASR.W	#2,D0
			ADD.W	D0,(Object.SpeedX,A3)
			RTS


Alien2Move:		MOVE.W	(Object.PosY,A3),D0
			MOVE.W	(Object.AccelY,A3),D1
			ASL.W	#2,D1
			ADD.W	D1,D0
			SUB.W	PLY_Player1+Player.PosY,D0
			NEG.W	D0
			ASR.W	#7,D0
			MOVE.W	D0,(Object.AccelY,A3)

			MOVE.W	(Object.PosX,A3),D0
			SUB.W	PLY_Player1+Player.PosX,D0
			NEG.W	D0
			ASR.W	#7,D0
			MOVE.W	D0,(Object.AccelX,A3)

			ADD.W	#2,(Object.SpeedY,A3)
			RTS

Alien2Hit:		RTS


			SECTION DATA, DATA_C
			XDEF	Alien1Data
			XDEF	Alien1FlashData
			XDEF	Alien2Data
			CNOP	0,4
Alien1Data:             INCBIN "output/alien1.raw"
Alien1FlashData:        INCBIN "output/alien1flash.raw"
Alien2Data:             INCBIN "output/alien2.raw"
			XDEF	Alien1Sprite
			XDEF	Alien1FlashSprite
			XDEF	Alien2Sprite
			CNOP	0,4
Alien1Sprite:           INCBIN "output/alien1.spr"
Alien1FlashSprite:      INCBIN "output/alien1flash.spr"
Alien2Sprite:           INCBIN "output/alien2.spr"

			CNOP	0,4
Module			INCBIN "assets/P61.sincx_-_noodlebrain.mod"

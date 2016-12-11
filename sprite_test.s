			INCLUDE	"include/custom.i"
			INCLUDE "graphics.i"
			INCLUDE "objects.i"
			INCLUDE "player.i"
			INCLUDE "laser.i"

			XREF	SYS_TakeOver

			SECTION	DATA,DATA


			SECTION BSS, BSS
APP_ClearList1:		DS.W	2000
APP_ClearList2:		DS.W	2000

APP_BitplaneMemory1	DS.L	1
APP_BitplaneMemory2	DS.L	1


APP_ObjectList:		DS.L	0


			SECTION BSS_C,BSS_C
APP_CopperList1:	DS.W	100*16+2
APP_CopperList2:	DS.W	100*16+2


			SECTION	CODE,CODE
APP_Start:              LEA     APP_Main,A0
                        BSR     SYS_TakeOver
                        MOVEQ   #0,D0
                        RTS

APP_Main:               ; Set interrupt1 vector
			;LEA	APP_Interrupt1Handler,A0
			;MOVEQ	#25,D0
			;BSR	SYS_SetVector

			; Enable software interrupt
			;MOVE.W	#INTENA_SET | INTENA_SOFT,(INTENA,A6)

			MOVE.L	#GFX_BITPLANE_BYTES_PER_STRIDE*GFX_BITPLANE_HEIGHT,D2
			BSR	GFX_AllocMemAlign64K
			MOVE.L	D0,APP_BitplaneMemory1
			MOVE.L	#GFX_BITPLANE_BYTES_PER_STRIDE*GFX_BITPLANE_HEIGHT,D2
			BSR	GFX_AllocMemAlign64K
			MOVE.L	D0,APP_BitplaneMemory2

			LEA	APP_VerticalBlankHandler1,A0
			MOVE.L	A0,GFX_VerticalBlankHandler

			LEA	APP_CopperList1,A0
			MOVE.L	#$FFFFFFFE,(A0)
			LEA	APP_CopperList2,A0
			MOVE.L	#$FFFFFFFE,(A0)
		
			; Initialise 
			BSR	OBJ_Init
			BSR	LSR_Init

			; Initialise BLIT clear lists
			CLR.L	APP_ClearList1
			CLR.L	APP_ClearList2

			BSR	OBJ_Create
			MOVE.L	D0,A0
			MOVE.L	#SpriteMove,(Object.MoveFunction,A0)
			MOVE.L	#SpriteHit,(Object.HitFunction,A0)
			MOVE.W	#16<<OBJ_POSX_SHIFT,(Object.SizeX,A0)
			MOVE.W	#10<<OBJ_POSY_SHIFT,(Object.SizeY,A0)
			MOVE.W	#0<<OBJ_POSX_SHIFT,(Object.PosX,A0)
			MOVE.W	#100<<OBJ_POSY_SHIFT,(Object.PosY,A0)
			MOVE.L	#Alien1Sprite,D0
			MOVE.W	D0,(Object.SpriteData,A0)
			ADD.W	#64,D0
			MOVE.W	D0,(Object.SpriteData2,A0)

			; Initialise graphics subsystem, this will start vertical
			; blank interrupts
			BSR     GFX_Init

.Loop:			; Loop back if left mouse button not pressed
			BTST	#6,$BFE001
 			BNE	.Loop
			RTS


*****************************************************************************
APP_VerticalBlankHandler1:
			; Save registers that we're changing (D0/A0/A6 saved for us)
			MOVEM.L	D1-D7/A1-A5,-(SP)

			; Store bitplane memory and copper list
			MOVE.L	APP_BitplaneMemory2,A1
			LEA	APP_CopperList2,A2
			BSR 	GFX_SetCopperBitplanes

			; Clear objects in bitplane memory 1
			LEA	APP_ClearList1,A2
			BSR	APP_ClearObjects
			
			; Move objects
			BSR	APP_MoveObjects

			; Draw objects
			MOVE.L	APP_BitplaneMemory1,D6
			MOVE.L	APP_ObjectList,A3
			LEA	APP_CopperList1,A4
			LEA	APP_ClearList1,A2
			BSR	APP_DrawObjects

			; Return with other vertical blank handler
			LEA	APP_VerticalBlankHandler2,A0
			MOVEM.L	(SP)+,D1-D7/A1-A5
			RTS


*****************************************************************************
APP_VerticalBlankHandler2:
			; Save registers that we're changing (D0/A0/A6 saved for us)
			MOVEM.L	D1-D7/A1-A5,-(SP)

			; Store bitplane memory and copper list
			MOVE.L	APP_BitplaneMemory1,A1
			LEA	APP_CopperList1,A2
			BSR 	GFX_SetCopperBitplanes

			; Clear objects in bitplane memory 2
			LEA	APP_ClearList2,A2
			BSR	APP_ClearObjects
			
			; Move objects
			BSR	APP_MoveObjects

			; Draw objects
			MOVE.L	APP_BitplaneMemory2,D6
			MOVE.L	APP_ObjectList,A3
			LEA	APP_CopperList2,A4
			LEA	APP_ClearList2,A2
			BSR	APP_DrawObjects

			; Return with other vertical blank handler
			LEA	APP_VerticalBlankHandler1,A0
			MOVEM.L	(SP)+,D1-D7/A1-A5
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
                        MOVE.W  #$0F00,(COLOR00,A6)
			BSR	OBJ_DrawAll
                        MOVE.W  #$0000,(COLOR00,A6)

 			; Draw player
                        MOVE.W  #$0F40,(COLOR00,A6)
			BSR	PLY_DrawAll
                        MOVE.W  #$0000,(COLOR00,A6)

			; Draw Lasers
                        MOVE.W  #$0F80,(COLOR00,A6)
			BSR	LSR_DrawAll
                        MOVE.W  #$0000,(COLOR00,A6)
			RTS


*****************************************************************************
APP_MoveObjects:	; Calculate bounding box around all lasers
			BSR	LSR_CalcBoundBox

			; Find objects within bounding box
			BSR	OBJ_CheckBoxCollisionInit
			BEQ	.NoObj
.CheckLoop:		BSR	OBJ_CheckBoxCollision
			
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
			BSR	OBJ_CheckBoxCollisionNext
			BNE	.CheckLoop

.NoObj:			; Move objects
			BSR	OBJ_MoveAll

			; Move lasers
			BSR	LSR_MoveAll

			; Move player (TODO: Pass in joystick bitmap)
			BSR	PLY_MoveAll

			; Sort objects
                        MOVE.W  #$0FF0,(COLOR00,A6)
			BSR	OBJ_SortAll
                        MOVE.W  #$0FF0,(COLOR00,A6)

			RTS


SpriteMove:             ;MOVE.W	(Object.SpeedX,A3),D0
			;SUB.W	#20,D0
			;ASR.W	#7,D0
			;SUB.W	D0,(Object.AccelX,A3)
			RTS

SpriteHit:		MOVE.W	(Laser.SpeedX,A0),D0
			ASR.W	#3,D0
			ADD.W	D0,(Object.SpeedX,A3)
			RTS

			SECTION DATA, DATA_C
			XDEF	SpriteData
			XDEF	Alien1Sprite
			XDEF	Alien1FlashSprite
			CNOP	0,4
SpriteData:		DC.W	0,0
Alien1Sprite:           INCBIN "output/alien1.spr"
Alien1FlashSprite:      INCBIN "output/alien1flash.spr"

			XDEF	BlitData
			XDEF	Alien1Data
			XDEF	Alien1FlashData
			CNOP	0,4
BlitData:
Alien1Data:             INCBIN "output/alien1.raw"
Alien1FlashData:        INCBIN "output/alien1flash.raw"

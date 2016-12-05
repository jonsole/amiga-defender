			INCLUDE	"include/custom.i"
			INCLUDE "include/copper.i"
			INCLUDE "graphics.i"

_LVOAllocVec		EQU	-684
_LVOFreeVec		EQU	-690
_LVOOpenLibrary		EQU	-552
_LVOCloseLibrary	EQU	-414
_LVOLoadView		EQU	-222
_LVOWaitTOF		EQU	-270
_LVOOwnBlitter		EQU	-456
_LVODisownBlitter	EQU	-462
_LVOWaitBlit		EQU	-228

			SECTION BSS,BSS

			XDEF	GFX_GfxBase
GFX_GfxBase		DS.L	1
GFX_GfxView		DS.L	1
GFX_Blit16x16List:	DS.W	2000

			SECTION	CODE,CODE

GFX_BlitterBusy:	DC.W	0
GFX_Blit16x16WritePtr:	DC.L	1
GFX_Blit16x16ReadPtr:	DC.L	1

			XDEF	GFX_VerticalBlankHandler
GFX_VerticalBlankHandler: DC.L	1

			XDEF	GFX_Obtain
GFX_Obtain:		MOVEM.L	A5-A6,-(SP)

			; Open graphics.library
			MOVE.L	4.W,A6
			LEA	GFX_Name,A1
			MOVEQ	#0,D0
			JSR	(_LVOOpenLibrary,A6)
			MOVE.L	D0,GFX_GfxBase
			BEQ.B	.ErrorNoLibrary
			MOVE.L	D0,A6

			; Save current view
			MOVE.L	(34,A6),GFX_GfxView

			; Clear view
			SUB.L	A1,A1
			JSR	(_LVOLoadView,A6)

			; Wait for 2 display periods
			JSR	(_LVOWaitTOF,A6)
			JSR	(_LVOWaitTOF,A6)

			; Grab ownership of Blitter
			JSR	(_LVOOwnBlitter,A6)
			JSR	(_LVOWaitBlit,A6)

			MOVEQ	#1,D0
			MOVEM.L	(SP)+,A5-A6
			RTS

.ErrorNoLibrary		MOVEQ	#0,D0
			MOVEM.L	(SP)+,A5-A6
			RTS
			
			XDEF	GFX_Release
GFX_Release		MOVEM.L	A5-A6,-(SP)

			; Release ownership of Blitter
			MOVE.L	GFX_GfxBase,A6
			JSR	(_LVODisownBlitter,A6)

			; Restore view
			MOVE.L	GFX_GfxView,A1
			JSR	(_LVOLoadView,A6)

			MOVEM.L	(SP)+,A5-A6
			RTS


			XDEF 	GFX_Init
GFX_Init:		; Set interrupt3 vector
			LEA	GFX_Interrupt3Handler,A0
			MOVEQ	#27,D0
			BSR	SYS_SetVector

			; Set pointer to copper list
			LEA	CUSTOM,A6
			MOVE.L	#GFX_CopperList,(COP1LCH,A6)

			; Enable Bitplane, Blitter and Copper DMA
			MOVE.W 	#(DMACON_SET|DMACON_DMAEN|DMACON_BPLEN|DMACON_COPEN|DMACON_BLTEN|DMACON_BLTPRI),(DMACON,A6)

			; Enable vertical blank interrupt 
			MOVE.W	#(INTENA_SET|INTENA_INTEN|INTENA_VERTB),(INTENA,A6)
			RTS

*****************************************************************************
* Name
*   GFX_SetCopperBitplanes: Set copper list for current displayed bitplanes
* Synopsis
*   GFX_SetCopperBitplanes(Bitplanes, Copperlist)
*                          A1         A2
* Function
*   This function updates the copper list to show the displayed bitplanes.
* Registers
*   D0-D1/A0-A1: corrupted
*****************************************************************************
			XDEF	GFX_SetCopperBitplanes

						
GFX_SetCopperBitplanes:	LEA	GFX_CopperBitplanes,A0
			ADD.W	#GFX_DISPLAY_HIDE_LEFT_BYTES,A1
			MOVEQ	#GFX_BITPLANE_DEPTH-1,D1
.BitplaneLoop:		MOVE.L	A1,D0
			SWAP	D0
			MOVE.W	D0,(2,A0)
			SWAP	D0
			MOVE.W	D0,(6,A0)
			ADD.W	#8,A0
			ADD.W	#GFX_BITPLANE_BYTES_PER_LINE,A1
			DBRA	D1,.BitplaneLoop
			MOVE.L	A2,(COP2LC,A6)
			RTS

*****************************************************************************
* Name
*   GFX_WaitTopOfFrame: Wait for top of frame
* Synopsis
*   GFX_WaitTopOfFrame(Custom)
*		       A6
* Function
*   This function busy waits until top of frame.
* Registers
*   D0: corrupted
*****************************************************************************
			XDEF	GFX_WaitTopOfFrame
GFX_WaitTopOfFrame:	MOVE.L	(VPOSR,A6),D0
			AND.L	#$0001FF00,D0
			CMP.L	#$00000800,D0
			BNE	GFX_WaitTopOfFrame
			RTS


GFX_SpritePosY		DC.W	0,0,0,0	

			XDEF	GFX_InitSprites
GFX_InitSprites:	LEA	(GFX_SpritePosY,PC),A0
			CLR.L	(A0)+
			CLR.L	(A0)
			RTS

			XDEF	GFX_FinaliseSprites
GFX_FinaliseSprites:	MOVE.L	#$FFFFFFFE,(A4)
			RTS


*****************************************************************************
* Name
*   GFX_QueueSprite: Queue sprite
* Synopsis
*   CopperList = GFX_Blit16x(Custom, Height, PosX, PosY, SpriteData, CopperList)
*   A4                       A6      D0      D1    D2    A1          A4
* Function
*   This function queues a sprite to be displayed
* Registers
*   D0-D3/A0: corrupted
*****************************************************************************
GFX_QUEUE_SPR_SETUP:	MACRO

			; Update postion table
			ADDI.W	#1,D0
			ADD.W	D2,D0		; Calculate PosYLast
			MOVE.W	D0,-(A0)

			; Convert positions into sprite positions
			ADD.W	#$80-16,D1	; Adjust PosX for display start to make hstart
			ADD.W	#$2B,D2		; Adjust PosY for display start to make vstart-1
			ADD.W	#$2B,D0		; Adjust PosYLast for display start to make vstop 

			; Write CWAITV vstart-1 to copperlist
			MOVE.B	D2,(A4)+
			MOVE.B 	#$01,(A4)+
			MOVE.W	#$FF00,(A4)+

			; Sprite starts one line later
			ADD.W	#1,D2	; Increment vstart

			; Calculate sprite position and control words
			CLR.B	D3
			LSL.W	#8,D2	; d2=vstart[7:0],00000000
			ADDX.B	D3,D3	; d3=000000000000000,vstart[8]			
			LSL.W	#8,D0	; d0=vstop[7:0],00000000
			ADDX.B	D3,D3   ; d3=00000000000000,vstart[8],vstop[8]
			LSR.W	#1,D1	; d1=00000000,hstart[8:1]
			ADDX.B	D3,D3   ; d3=0000000000000,vstart[8],vstop[8],hstart[0]
			MOVE.B	D1,D2	; d2=vstart[7:0],hstart[8:1]
			MOVE.B	D3,D0	; d0=vstop[7:0],00000,vstart[8],vstop[8],hstart[0]
			BSET	#7,D0	; Set attach bit
			
			ENDM

GFX_QUEUE_SPR_COPPER: 	MACRO

			; Write CMOVE.W SPRxPTL
			MOVE.L	A1,D1
			MOVE.W	#\2+2,(A4)+
			MOVE.W	D1,(A4)+
			MOVE.W	#\2,(A4)+
			SWAP	D1
			MOVE.W	D1,(A4)+

			; Write CMOVE.W	SPRxPTH
			ADD.W	#64,A1			
			MOVE.L	A1,D1
			MOVE.W	#\2+2+4,(A4)+
			MOVE.W	D1,(A4)+
			MOVE.W	#\2+4,(A4)+
			SWAP	D1
			MOVE.W	D1,(A4)+

			; Write CMOVE.W SPRxPOS to copperlist
			MOVE.W	#\1,(A4)+	; V7-V0 H8-H1
			MOVE.W	D2,(A4)+
			MOVE.W	#\1+8,(A4)+	; V7-V0 H8-H1
			MOVE.W	D2,(A4)+

			; Write CMOVE.W SPRxCTL to coppperlist
			MOVE.W	#\1+2,(A4)+
			MOVE.W	D0,(A4)+
			MOVE.W	#\1+2+8,(A4)+
			MOVE.W	D0,(A4)+

			ENDM



			XDEF	GFX_QueueSprite
GFX_QueueSprite:	LEA	(GFX_SpritePosY,PC),A0
			CMP.W	(A0)+,D2
			BHI	.UseSprite0
			CMP.W	(A0)+,D2
			BHI	.UseSprite1
			CMP.W	(A0)+,D2
			BHI	.UseSprite2
			CMP.W	(A0)+,D2
			BHI	.UseSprite3
			MOVEQ	#0,D0
			RTS

.UseSprite0:		GFX_QUEUE_SPR_SETUP
			GFX_QUEUE_SPR_COPPER SPR0POS,SPR0PT
			MOVEQ	#1,D0
			RTS

.UseSprite1:		GFX_QUEUE_SPR_SETUP
			GFX_QUEUE_SPR_COPPER SPR2POS,SPR2PT
			MOVEQ	#1,D0
			RTS

.UseSprite2:		GFX_QUEUE_SPR_SETUP
			GFX_QUEUE_SPR_COPPER SPR4POS,SPR4PT
			MOVEQ	#1,D0
			RTS

.UseSprite3:		GFX_QUEUE_SPR_SETUP
			GFX_QUEUE_SPR_COPPER SPR6POS,SPR6PT
			MOVEQ	#1,D0
			RTS

*****************************************************************************
* Name
*   GFX_InitBlit16x: Initialise hardware for 16 pixel wide blits
* Synopsis
*   GFX_InitBlit16x(Custom, ClearList)
*		    A6      A5
* Function
*   This function prepares for blitting a series of 16x blits.  It pre-loads
*   blitter register that do not change in between blits.
*****************************************************************************
			XDEF	GFX_InitBlit16x
GFX_InitBlit16x:	BTST.B  #6,(DMACONR,A6)
			BNE	GFX_InitBlit16x

			; Preset BLTxMOD registers, they don't change when blitting objects of the same size
			MOVE.W	#-2,(BLTAMOD,A6)
        		MOVE.W	#-2,(BLTBMOD,A6)
        		MOVE.W	#GFX_BITPLANE_BYTES_PER_LINE-4,(BLTDMOD,A6)
	        	MOVE.W	#GFX_BITPLANE_BYTES_PER_LINE-4,(BLTCMOD,A6)
			MOVE.L	#$FFFF0000,(BLTAFWM,A6)
			RTS

			XDEF	GFX_InitBlit32x
GFX_InitBlit32x:	BTST.B  #6,(DMACONR,A6)
			BNE	GFX_InitBlit32x

			; Preset BLTxMOD registers, they don't change when blitting objects of the same size
			MOVE.W	#-2,(BLTAMOD,A6)
        		MOVE.W	#-2,(BLTBMOD,A6)
        		MOVE.W	#GFX_BITPLANE_BYTES_PER_LINE-6,(BLTDMOD,A6)
	        	MOVE.W	#GFX_BITPLANE_BYTES_PER_LINE-6,(BLTCMOD,A6)
			MOVE.L	#$FFFF0000,(BLTAFWM,A6)
			RTS

			XDEF	GFX_FinaliseBlit16x
			XDEF	GFX_FinaliseBlit32x
GFX_FinaliseBlit32x:
GFX_FinaliseBlit16x:	CLR.W	(A5)+
			RTS



*****************************************************************************
* Name
*   GFX_Blit: Blit
* Synopsis
*   Dest,ClearList = GFX_Blit16x(Custom, BlitSize, PosX, PosY, Bitplane BlitData, BlitMask, ClearList)
*   A0   A5                      A6      D0        D1    D2    A0       A1        A2        A5
* Function
*   This function performs a blit.
* Registers
*   A0/A3/D1-D3: corrupted
*****************************************************************************
			XDEF	GFX_Blit
GFX_Blit:	        ; Convert Y position into offset in D2
			IF GFX_BITPLANE_BYTES_PER_STRIDE=256
			EXT.L	D2
			LSL.L   #8,D2
			ELSE
			MULU.W	#GFX_BITPLANE_BYTES_PER_STRIDE,D2
			ENDC

			; Shift lower 4 bits of X position into bits 15:12 of D1
		        ROR.W	#4,D1          
                        MOVE.W  D1,D3
        		AND.W	#$F000,D1
			
			; Mask out bits 15:12 to give word offset for X position in bits 11:0 of D4
	        	AND.W   #$0FFF,D3

			; Set BLTCPTH in A0
			; Calculate destination address by adding Y offset and X offset to base address               
                        ADD.W   D3,A0	; Add X offset...
                        ADD.W   D3,A0	; ...twice as it is word offset not byte offset
                        ADD.L   D2,A0	; Add Y offset

			; Set BLTDPTH in A3
			MOVE.L 	A0,A3

			; Set BLTCON0 and BLTCON1 in D1.L, start with shift in bits 15:12 of D1
			MOVE.W	D1,D2
			OR.W	#BLTCON0_USEA|BLTCON0_USEB|BLTCON0_USEC|BLTCON0_USED|$00CA,D1
			SWAP 	D1
			MOVE.W 	D2,D1

			; Save  BLTSIZE and BLTDPTH for clearing screen later
			MOVE.W	D0,(A5)+
			MOVE.L	A3,(A5)+

			; Check if blitter is free
			MOVE.W	#DMACON_SET|DMACON_BLTPRI,(DMACON,A6)
.WaitBlit:		BTST.B  #6,(DMACONR,A6)
			BNE	.WaitBlit

			; Program blitter
			MOVE.L	D1,(BLTCON0,A6)
			MOVEM.L A0-A3,(BLTCPTH,A6) ;A0->BLTCPT,A1->BLTBPT,A2->BLTAPT,A3->BLTDPT
			MOVE.W	D0,(BLTSIZE,A6)
			MOVE.W	#DMACON_BLTPRI,(DMACON,A6)
                        RTS

*****************************************************************************
* Name
*   GFX_ClearList16x: Clear blits
* Synopsis
*   GFX_ClearList16x(Custom, ClearList)
*		     A6      A5
* Function
*   This function clears blits as specified in ClearList.
*****************************************************************************
			XDEF	GFX_ClearList16x
GFX_ClearList16x:	BTST.B  #6,(DMACONR,A6)
			BNE	GFX_ClearList16x
			MOVE.W	#GFX_BITPLANE_BYTES_PER_LINE-4,(BLTDMOD,A6)
			MOVE.W	#0,(BLTCON1,A6)
			MOVE.W	#BLTCON0_USED,(BLTCON0,A6)
			MOVE.W	#DMACON_SET|DMACON_BLTPRI,(DMACON,A6)

			MOVE.W	(A5)+,D0
			BEQ	.EndOfList
.Loop			MOVE.L	(A5)+,A0

.WaitBlit:		BTST.B  #6,(DMACONR,A6)
			BNE	.WaitBlit

			MOVE.L	A0,(BLTDPTH,A6)
			MOVE.W	D0,(BLTSIZE,A6)

			; TODO: Clear next using CPU

			MOVE.W	(A5)+,D0
			BNE	.Loop
.EndOfList:		RTS

			XDEF	GFX_ClearList32x
GFX_ClearList32x:	BTST.B  #6,(DMACONR,A6)
			BNE	GFX_ClearList32x
			MOVE.W	#GFX_BITPLANE_BYTES_PER_LINE-6,(BLTDMOD,A6)
			MOVE.W	#0,(BLTCON1,A6)
			MOVE.W	#BLTCON0_USED,(BLTCON0,A6)
			MOVE.W	#DMACON_SET|DMACON_BLTPRI,(DMACON,A6)

			MOVE.W	(A5)+,D0
			BEQ	.EndOfList
.Loop			MOVE.L	(A5)+,A0

.WaitBlit:		BTST.B  #6,(DMACONR,A6)
			BNE	.WaitBlit

			MOVE.L	A0,(BLTDPTH,A6)
			MOVE.W	D0,(BLTSIZE,A6)

			; TODO: Clear next using CPU

			MOVE.W	(A5)+,D0
			BNE	.Loop
.EndOfList:		RTS



*****************************************************************************
* Name
*   GFX_Interrupt3Handler: 
* Synopsis
*   GFX_Interrupt3Handler()
* Functio
*   This function is the level 3 interrupt handler.  It handles blitter
*   interrupts which occur when the blitter has completed a blit.
*   This function checks the blitter list and loads the next blit if the
*   list is not empty.  If the list is empty, the blitter interrupt is
*   disabled.
*****************************************************************************
			XDEF	GFX_Interrupt3Handler

GFX_Interrupt3Handler:	; Save registers
			MOVEM.L	D0/A0/A6,-(SP)
			LEA	CUSTOM,A6

			; Get pending interrupts
			MOVE.W	(INTREQR,A6),D0

			; Check if vertical blank interrupt pending
			BTST	#INTREQ_VERTB_POS,D0
			BEQ	.NotVertB

			; Clear vertical blank interrupt
			MOVE.W	#INTREQ_VERTB,(INTREQ,A6)		

			; Call application vertical blank handler
			MOVE.L	GFX_VerticalBlankHandler,A0
			JSR	(A0)
			MOVE.L	A0,GFX_VerticalBlankHandler

.NotVertB:		; Restore registers and return from interrupt
			MOVEM.L	(SP)+,D0/A0/A6
			RTE

			SECTION	DATA,DATA

GFX_Name:		DC.B	'graphics.library',0


			SECTION GFX_BitplaneMemory,BSS_C

			CNOP	0,2
			XDEF	GFX_BitplaneMemory1
GFX_BitplaneMemory1	DS.B	GFX_BITPLANE_BYTES_PER_STRIDE*GFX_BITPLANE_HEIGHT
			CNOP	0,2
			XDEF	GFX_BitplaneMemory2
GFX_BitplaneMemory2	DS.B	GFX_BITPLANE_BYTES_PER_STRIDE*GFX_BITPLANE_HEIGHT

			SECTION	DATA,DATA_C

GFX_NullSprite:		DC.L	0

			CNOP	0,2
GFX_CopperList:		CMOVE.W	BPL1MOD,GFX_BITPLANE_BYTES_PER_STRIDE-GFX_DISPLAY_BYTES_PER_LINE
			CMOVE.W	BPL2MOD,GFX_BITPLANE_BYTES_PER_STRIDE-GFX_DISPLAY_BYTES_PER_LINE
			CMOVE.W	DDFSTRT,$0038
			CMOVE.W	DDFSTOP,$00D0
			CMOVE.W	DIWSTRT,$2C81
			CMOVE.W	DIWSTOP,$F4C1

GFX_CopperBitplanes:	CMOVE.L	BPL1PT,$0000
			CMOVE.L	BPL2PT,$0000
			CMOVE.L	BPL3PT,$0000
			CMOVE.L	BPL4PT,$0000
			CMOVE.L	BPL5PT,$0000

			; Clear sprite pointers
			CMOVE.L	SPR0PT,0
			CMOVE.L	SPR1PT,0
			CMOVE.L	SPR2PT,0
			CMOVE.L	SPR3PT,0
			CMOVE.L	SPR4PT,0
			CMOVE.L	SPR5PT,0
			CMOVE.L	SPR6PT,0
			CMOVE.L	SPR7PT,0

			CWAITV	40
			CMOVE.W	COLOR00,$0111

			CMOVE.W DMACON,DMACON_SET|DMACON_SPREN

			CWAITV	42

			CMOVE.W	COLOR16,$0111
			CMOVE.W	COLOR17,$0fff
			CMOVE.W	COLOR18,$0bbb
			CMOVE.W	COLOR19,$0888
			CMOVE.W	COLOR20,$0444
			CMOVE.W	COLOR21,$0f00
			CMOVE.W	COLOR22,$0f70
			CMOVE.W	COLOR23,$0fe0
			CMOVE.W	COLOR24,$00ff
			CMOVE.W	COLOR25,$0088
			CMOVE.W	COLOR26,$00f0
			CMOVE.W	COLOR27,$0090
			CMOVE.W	COLOR28,$0808
			CMOVE.W	COLOR29,$0f0f
			CMOVE.W	COLOR30,$0600
			CMOVE.W	COLOR31,$0f66

			CMOVE.W	BPLCON0,(7<<BPLCON0_BPU_POS)|BPLCON0_COLOR
			CMOVE.W	BPLCON1,$0000
			CMOVE.W	BPL5DAT,$FFFF
			CMOVE.W	BPL6DAT,$0000

			CWAIT 42,223,$FF,$FE
			
			CMOVE.W	COLOR00,$0500
			CMOVE.W	COLOR00,$0600
			CMOVE.W	COLOR00,$0700
			CMOVE.W	COLOR00,$0800
			CMOVE.W	COLOR00,$0900
			CMOVE.W	COLOR00,$0A00
			CMOVE.W	COLOR00,$0B00
			CMOVE.W	COLOR00,$0C00
			CMOVE.W	COLOR00,$0D00
			CMOVE.W	COLOR00,$0E00
			CMOVE.W	COLOR00,$0F00
			CMOVE.W	COLOR00,$0010
			CMOVE.W	COLOR00,$0020
			CMOVE.W	COLOR00,$0030
			CMOVE.W	COLOR00,$0040
			CMOVE.W	COLOR00,$0050
			;CMOVE.W	COLOR00,$0060
			;CMOVE.W	COLOR00,$0070
			;CMOVE.W	COLOR00,$0090
			;CMOVE.W	COLOR00,$00A0
			;CMOVE.W	COLOR00,$00B0
			;CMOVE.W	COLOR00,$00C0
			;CMOVE.W	COLOR00,$00D0
			;CMOVE.W	COLOR00,$00E0
			;CMOVE.W	COLOR00,$00F0
			CMOVE.W	COLOR00,$0000

			
			; Jump to copperlist 2
GFX_CopperJump:		CMOVE.W	COPJMP2,$0000
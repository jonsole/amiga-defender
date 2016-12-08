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
			LEA	(GFX_SpriteTable,PC),A5
			MOVEQ	#$FFFFFFF0,D5
			RTS

			XDEF	GFX_FinaliseSprites
GFX_FinaliseSprites:	MOVE.L	#$FFFFFFFE,(A4)
			RTS


*****************************************************************************
* Name
*   GFX_ADD_SPRITE: Add sprite to copper list
* Synopsis
*   GFX_ADD_SPRITE(Height, PosX, PosY, SpriteData, PositionTable, CopperList, Table, Mask)
*                  D0      D1    D2    D3          A1             A4          A5     D5
* Function
*   This macro adds a sprite to the copper list
* Registers
*   D0-D1/D3-D4/A1/A4: corrupted
*****************************************************************************
GFX_ADD_SPRITE: 	MACRO	; \1 - SPRxPT, \2 - SPRxPOS, \3 - COLOR00

			; Calc address of attached sprite
			MOVE.L	D3,D4
			ADD.L	#64,D4

			; Calculate PosYStop = PosY+Height
			ADD.W	D2,D0
			
			; D1 = PosX, D2 = PosY, D0 = PosYStop
			; Calculate SPRxPOS + SPRxCTL in D1 
			MOVE.L	(0,A5,D1.W),D1		;18
			OR.L	(4,A5,D2.W),D1		;14+6
			OR.L	(8,A5,D0.W),D1		;14+6

			; Write CWAITV vstart-1 to copperlist
			MOVE.L	(12,A5,D2.W),(A4)+	;26
			
			; DEBUG
			MOVE.W	#COLOR00,(A4)+
			MOVE.W	#\3,(A4)+

			; Advance PosYStop to next line
			SUB.W	D5,D0
			MOVE.W	D0,-(A1)	

			; Write CMOVE.W SPR0PTL,SPR1PTL
			MOVE.W	#\2+2,(A4)+
			MOVE.W	D3,(A4)+
			MOVE.W	#\2+2+4,(A4)+
			MOVE.W	D4,(A4)+

			; Write CMOVE.W SPR0PTH,SPR1PTH
			SWAP	D3		;4
			SWAP	D4		;4
			MOVE.W	#\2,(A4)+
			MOVE.W	D3,(A4)+
			MOVE.W	#\2+4,(A4)+
			MOVE.W	D4,(A4)+

			; Write CMOVE.W SPR0POS,SPR1PO
			MOVE.W	#\1,(A4)+
			MOVE.W	D1,(A4)+
			MOVE.W	#\1+8,(A4)+
			MOVE.W	D1,(A4)+
			
			; Write CMOVE.W SPR0CTL,SPR1CTL
			SWAP	D1
			MOVE.W	#\1+2,(A4)+
			MOVE.W	D1,(A4)+
			MOVE.W	#\1+10,(A4)+
			MOVE.W	D1,(A4)+

			; DEBUG
			MOVE.W	#COLOR00,(A4)+
			MOVE.W	#$0000,(A4)+

			; Return with C clear
			RTS
			ENDM


*****************************************************************************
* Name
*   GFX_QueueSprite: Queue sprite
* Synopsis
*   CopperList = GFX_Blit16x(Custom, Height, PosX, PosY, SpriteData, CopperList, Table, Mask)
*   A4                       A6      D0      D1    D2    D3          A4          A5     D5
* Function
*   This function queues a sprite to be displayed
* Registers
*   D0-D4/A0-A1/A4: corrupted
*****************************************************************************
			XDEF	GFX_QueueSprite
GFX_QueueSprite:	LEA	(GFX_SpritePosY,PC),A1	;8
			CMP.W	(A1)+,D2		;4+4
			BLO	.NotSprite1
			GFX_ADD_SPRITE SPR0POS,SPR0PT,$000F

.NotSprite1:		CMP.W	(A1)+,D2		;4+4
			BLO	.NotSprite2
			GFX_ADD_SPRITE SPR2POS,SPR2PT,$00FF

.NotSprite2:		CMP.W	(A1)+,D2		;4+4
			BLO	.NotSprite3
			GFX_ADD_SPRITE SPR4POS,SPR4PT,$0F00
			
.NotSprite3:		CMP.W	(A1)+,D2		;4+4
			BLO	.NotSprite4
			GFX_ADD_SPRITE SPR6POS,SPR6PT,$0F0F

.NotSprite4:		; Return with C set
			RTS

GFX_SpriteTable:	REPT	336

.X:			SET 	REPTN+$70
.YS:  			SET 	REPTN+$2C
.YE:  			SET 	REPTN+$2C
.YW:  			SET 	REPTN+$2B

			; X-Pos (SPRxCTL, SPRxPOS)
			DC.B	$00, $80 | (.X & $01) 
    			DC.B  	$00, (.X >> 1)

			; Y-start (SPRxCTL, SPRxPOS)
			DC.B	$00, $80 | ((.YS >> 6) & $04)
    			DC.B	(.YS & $FF), $00	; SPRxPOS

			; Y-end (SPRxCTL, SPRxPOS)
			DC.B	(.YE & $FF), $80 | ((.YE >> 7) & $02)
    			DC.B	$00, $00	

			; CWait
			DC.B	(.YW & $FF), $1F, $FF, $FE
 			ENDR


GFX_WAIT_BLIT:		MACRO
			BTST.B  #6,(DMACONR,A6)
			BEQ	.\@Done
			MOVE.W	#DMACON_SET|DMACON_BLTPRI,(DMACON,A6)
.\@Wait:		BTST.B  #6,(DMACONR,A6)
			BNE	.\@Wait
.\@Done:			
			ENDM


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
GFX_InitBlit16x:	GFX_WAIT_BLIT

			; Preset BLTxMOD registers, they don't change when blitting objects of the same size
			MOVE.W	#-2,(BLTAMOD,A6)
        		MOVE.W	#-2,(BLTBMOD,A6)
        		MOVE.W	#GFX_BITPLANE_BYTES_PER_LINE-4,(BLTDMOD,A6)
	        	MOVE.W	#GFX_BITPLANE_BYTES_PER_LINE-4,(BLTCMOD,A6)
			MOVE.L	#$FFFF0000,(BLTAFWM,A6)
			MOVEQ	#$FFFFFFF0,D5
			RTS


			XDEF	GFX_InitBlit32x
GFX_InitBlit32x:	GFX_WAIT_BLIT

			; Preset BLTxMOD registers, they don't change when blitting objects of the same size
			MOVE.W	#-2,(BLTAMOD,A6)
        		MOVE.W	#-2,(BLTBMOD,A6)
        		MOVE.W	#GFX_BITPLANE_BYTES_PER_LINE-6,(BLTDMOD,A6)
	        	MOVE.W	#GFX_BITPLANE_BYTES_PER_LINE-6,(BLTCMOD,A6)
			MOVE.L	#$FFFF0000,(BLTAFWM,A6)
			MOVEQ	#$FFFFFFF0,D5
			RTS

			XDEF	GFX_FinaliseBlit16x
			XDEF	GFX_FinaliseBlit32x
GFX_FinaliseBlit32x:
GFX_FinaliseBlit16x:	CLR.W	(A2)+
			RTS



GFX_BlitTable:		REPT	336
.Y:			SET	REPTN
.X:			SET 	REPTN
.HEIGHT:		SET	REPTN
			DC.L	(.Y * GFX_BITPLANE_BYTES_PER_STRIDE)	; Y offset
			DC.W	((.X >> 4) * 2)				; X offset
			DC.W	BLTCON0_USEA | BLTCON0_USEB | BLTCON0_USEC | BLTCON0_USED | $00CA | ((.X & $0F) << 12)  ; blitcon0
			DC.W	((.X & $0F) << 12) ; blitcon1
			DC.W	(((.HEIGHT * GFX_DISPLAY_DEPTH) & $3FF) << 6) | $0002  ; BLTSIZE x 16
			DC.W	(((.HEIGHT * GFX_DISPLAY_DEPTH) & $3FF) << 6) | $0003  ; BLTSIZE x 32
			DC.W	0 ; spare
			ENDR

*****************************************************************************
* Name
*   GFX_Blit: Blit
* Synopsis
*   Dest,ClearList = GFX_Blit16x(Custom, Height, PosX, PosY, Bitplane BlitData, BlitMask, ClearList)
*   A0   A2                      A6      D0      D1    D2    D6       D3        D4        A2
* Function
*   This function performs a blit.
* Registers
*   A1/D0-D2/D7: corrupted
*****************************************************************************
; Don't change A4-A6/D5

			XDEF	GFX_Blit16x
GFX_Blit16x:		LEA	(GFX_BlitTable,PC),A1

			; Convert X & Y positions into offsets and add to bitplane address
			MOVEQ	#0,D7
			MOVE.W	(4,A1,D1.W),D7
			ADD.L	(0,A1,D2.W),D7
			ADD.L	D6,D7
			; D2 = BLTCPT & BLTDPT

			; Set BLTCON0 and BLTCON1 in D1.L
			MOVE.L	(6,A1,D1.W),D1

			; Get BLTSIZE in D0
			MOVE.W	(10,A1,D0.W),D0

			; Copy BLTDPT in D7 to BLTAPT in D2
			MOVE.L 	D7,D2

			; Save BLTSIZE and BLTDPT for clearing screen later
			MOVE.W	D0,(A2)+
			MOVE.L	D7,(A2)+

			; Check if blitter is free
			GFX_WAIT_BLIT			

			; Program blitter
			MOVE.L	D1,(BLTCON0,A6)
			MOVEM.L D2/D3/D4/D7,(BLTCPTH,A6) ;D2->BLTCPT,D3->BLTBPT,D4->BLTAPT,D7->BLTDPT
			MOVE.W	#DMACON_BLTPRI,(DMACON,A6)
			MOVE.W	D0,(BLTSIZE,A6)
			RTS


			XDEF	GFX_Blit32x
GFX_Blit32x:	        LEA	(GFX_BlitTable,PC),A1

			; Convert X & Y positions into offsets and add to bitplane address
			MOVEQ	#0,D7
			MOVE.W	(4,A1,D1.W),D7
			ADD.L	(0,A1,D2.W),D7
			ADD.L	D6,D7
			; D2 = BLTCPT & BLTDPT

			; Set BLTCON0 and BLTCON1 in D1.L
			MOVE.L	(6,A1,D1.W),D1

			; Get BLTSIZE in D0
			MOVE.W	(12,A1,D0.W),D0

			; Copy BLTDPT in D7 to BLTAPT in D2
			MOVE.L 	D7,D2

			; Save BLTSIZE and BLTDPT for clearing screen later
			MOVE.W	D0,(A2)+
			MOVE.L	D7,(A2)+

			; Check if blitter is free
			GFX_WAIT_BLIT			

			; Program blitter
			MOVE.L	D1,(BLTCON0,A6)
			MOVEM.L D2/D3/D4/D7,(BLTCPTH,A6) ;D2->BLTCPT,D3->BLTBPT,D4->BLTAPT,D7->BLTDPT
			MOVE.W	#DMACON_BLTPRI,(DMACON,A6)
			MOVE.W	D0,(BLTSIZE,A6)
			RTS


*****************************************************************************
* Name
*   GFX_ClearList16x: Clear blits
* Synopsis
*   GFX_ClearList16x(Custom, ClearList)
*		     A6      A2
* Function
*   This function clears blits as specified in ClearList.
*****************************************************************************
			XDEF	GFX_ClearList16x
GFX_ClearList16x:	GFX_WAIT_BLIT			
			MOVE.W	#GFX_BITPLANE_BYTES_PER_LINE-4,(BLTDMOD,A6)
			MOVE.W	#0,(BLTCON1,A6)
			MOVE.W	#BLTCON0_USED,(BLTCON0,A6)
			MOVE.W	#DMACON_SET|DMACON_BLTPRI,(DMACON,A6)

			MOVE.W	(A2)+,D0
			BEQ	.EndOfList
.Loop			MOVE.L	(A2)+,A0

			GFX_WAIT_BLIT

			MOVE.L	A0,(BLTDPTH,A6)
			MOVE.W	D0,(BLTSIZE,A6)

			; TODO: Clear next using CPU

			MOVE.W	(A2)+,D0
			BNE	.Loop
.EndOfList:		RTS

			XDEF	GFX_ClearList32x
GFX_ClearList32x:	GFX_WAIT_BLIT
			MOVE.W	#GFX_BITPLANE_BYTES_PER_LINE-6,(BLTDMOD,A6)
			MOVE.W	#0,(BLTCON1,A6)
			MOVE.W	#BLTCON0_USED,(BLTCON0,A6)
			MOVE.W	#DMACON_SET|DMACON_BLTPRI,(DMACON,A6)

			MOVE.W	(A2)+,D0
			BEQ	.EndOfList
.Loop			MOVE.L	(A2)+,A0

			GFX_WAIT_BLIT

			MOVE.L	A0,(BLTDPTH,A6)
			MOVE.W	D0,(BLTSIZE,A6)

			; TODO: Clear next using CPU

			MOVE.W	(A2)+,D0
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
			CNOP	0,2
			XDEF	GFX_BitplaneMemory3
GFX_BitplaneMemory3	DS.B	GFX_BITPLANE_BYTES_PER_STRIDE*GFX_BITPLANE_HEIGHT

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
			CMOVE.W DMACON,DMACON_SET|DMACON_SPREN

			CWAITV	40

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
			CMOVE.W	COLOR00,$0888			
			; Jump to copperlist 2
GFX_CopperJump:		CMOVE.W	COPJMP2,$0000
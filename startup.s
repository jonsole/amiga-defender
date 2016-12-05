			INCLUDE	"include/Custom.i"

_LVOSupervisor		EQU	-30
			
			;XREF	DOS_Obtain
			;XREF	DOS_Release
			XREF	GFX_Obtain
			XREF	GFX_Release
			XREF	GFX_GfxBase

			SECTION	CODE,CODE

*****************************************************************************
* Name
*   SYS_TakeOver: Puts OS to sleep and runs specifed routine
* Synopsis
*   SYS_TakeOver(Code)
*            A0
* Function
*   This function shutsdown the OS and calls the specifed routine, when
*   the routine returns the OS is restarted.
* Registers
*   D0-D2/A0-A2/A6: corrupted
*****************************************************************************
			XDEF	SYS_TakeOver
SYS_TakeOver		
			; Save routine address
			MOVE.L	A0,-(SP)

			;BSR	DOS_Obtain
			BSR	GFX_Obtain

			; Get routine address back off stack
			MOVE.L	(SP)+,A2

			; Call routine in supervisor mode
			MOVE.L	4.W,A6
			LEA	(SYS_Supervisor,PC),A5
			JSR	(_LVOSupervisor,A6)

			BSR	GFX_Release
			;BSR	DOS_Release

			RTS

SYS_Supervisor		MOVEM.L D0-D7/A0-A6,-(SP)
			
			; Save INTENA, INTREQ, ADKCON & DMACONR, reset to known state
			LEA	CUSTOM,A6
			MOVE.W	(INTENAR,A6),-(SP)
			MOVE.W	#INTENA_ALL,(INTENA,A6)
			MOVE.W	(INTREQR,A6),-(SP)
			MOVE.W	#INTREQ_ALL,(INTREQ,A6)
			MOVE.W	(ADKCONR,A6),-(SP)
			MOVE.W	#ADKCON_ALL,(ADKCON,A6)
			MOVE.W	(DMACONR,A6),-(SP)
			MOVE.W	#DMACON_ALL,(DMACON,A6)

			; Save copperlist pointers
			MOVE.L	GFX_GfxBase,A0
			MOVE.L	(38,A0),-(SP)
			MOVE.L	(50,A0),-(SP)

			; Save vectors
			SUB.L	A0,A0
			LEA	SYS_Vectors,A1
			MOVEQ	#64-1,D0
.SaveVectorLoop:	MOVE.L	(A0)+,(A1)+
			DBRA	D0,.SaveVectorLoop

			; Jump to user specified routine
			JSR	(A2)

			; Reset INTENA, INTREQ, ADKCON & DMACONR to known state
			LEA	CUSTOM,A6
			MOVE.W	#DMACON_ALL,(DMACON,A6)
			MOVE.W	#ADKCON_ALL,(ADKCON,A6)
			MOVE.W	#INTREQ_ALL,(INTREQ,A6)
			MOVE.W	#INTENA_ALL,(INTENA,A6)

			; Restore vectors
			SUB.L	A0,A0
			LEA	SYS_Vectors,A1
			MOVEQ	#64-1,D0
.RestoreVectorLoop:	MOVE.L	(A1)+,(A0)+
			DBRA	D0,.RestoreVectorLoop

			; Restore copperlist pointers
			MOVE.L	(SP)+,(COP2LCH,A6)
			MOVE.L	(SP)+,(COP1LCH,A6)

			; Restore INTENA, INTREQ, ADKCON & DMACONR
			MOVE.W	(SP)+,D0
			ORI.W	#DMACON_SET,D0
			MOVE.W	D0,(DMACON,A6)		
			MOVE.W	(SP)+,D0
			ORI.W	#ADKCON_SET,D0
			MOVE.W	D0,(ADKCON,A6)
			MOVE.W	(SP)+,D0
			ORI.W	#INTREQ_SET,D0
			MOVE.W	D0,(INTREQ,A6)
			MOVE.W	(SP)+,D0
			ORI.W	#INTENA_SET,D0
			MOVE.W	D0,(INTENA,A6)

			; Return back to user mode
			MOVEM.L (SP)+,D0-D7/A0-A6
			RTE

			XDEF	SYS_SetVector
SYS_SetVector:		ADD.W	D0,D0
			ADD.W	D0,D0
			MOVE.W	D0,A1
			MOVE.L	A0,(A1)
			RTS

			SECTION	BSS,BSS
SYS_Vectors:		DS.L	64


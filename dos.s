_LVOAllocVec		EQU	-684
_LVOFreeVec		EQU	-690
_LVOOpenLibrary		EQU	-552
_LVOCloseLibrary	EQU	-414
_LVOLockDosList		EQU	-654
_LVOUnlockDosList	EQU	-660
_LVONextDosEntry	EQU	-690
_LVODoPkt		EQU	-240

			SECTION BSS,BSS
DOS_DOSBase		DS.L	1
DOS_DOSLock		DS.L	1
DOS_DOSDeviceListPtr	DS.L	1

			RSRESET
DEVS_DOSDeviceNextPtr	RS.L	1
DEVS_DOSEntryPtr	RS.L	1
DEVS_SizeOf		RS.B	0

			SECTION	CODE,CODE

			XDEF	DOS_Obtain
DOS_Obtain		MOVEM.L	D2-D3/A2/A5-A6,-(SP)

			; Open dos.library
			LEA	DOSName,A1
			MOVEQ	#37,D0
			JSR	(_LVOOpenLibrary,A6)
			MOVE.L	D0,DOS_DOSBase
			BEQ.B	.ErrorNoLibrary

			MOVE.L	D0,A6
			MOVEQ	#9,D1
			JSR	(_LVOLockDosList,A6)
			MOVE.L	D0,DOS_DOSLock
			MOVE.L	D0,D3
			LEA	DOS_DOSDeviceListPtr,A2
.Loop1			MOVE.L	D3,D1
			MOVEQ	#9,D2
			JSR	(_LVONextDosEntry,A6)
			MOVE.L	D0,D3
			BEQ.B	.Skip4
			MOVE.L	4.W,A6
			MOVEQ	#DEVS_SizeOf,D0
			MOVE.L	#65536,D1
			JSR	(_LVOAllocVec,A6)
			MOVE.L	D0,(DEVS_DOSDeviceNextPtr,A2)
			BEQ.B	.ErrorNoMemory
			MOVE.L	D0,A2
			MOVE.L	D3,A0
			MOVE.L	(8,A0),(DEVS_DOSEntryPtr,A2)
			MOVE.L	DOS_DOSBase,A6
			BRA.B	.Loop1	
.Skip4			MOVE.L	DOS_DOSDeviceListPtr,D0
.Loop2			BEQ.B	.Skip5
			MOVE.L	D0,A2
			MOVE.L	(DEVS_DOSEntryPtr,A2),D1
			BEQ.B	.Skip6
			MOVE.L	#31,D2
			MOVEQ	#-1,D3
			JSR	(_LVODoPkt,A6)
.Skip6			MOVE.L	(DEVS_DOSDeviceNextPtr,A2),D0
			BRA.B	.Loop2	
.Skip5			MOVEQ	#1,D0
			MOVEM.L	(SP)+,D2-D3/A2/A5-A6
			RTS
.ErrorNoMemory		MOVEM.L	(SP)+,D2-D3/A2/A5-A6
			BRA.B	DOS_Release
.ErrorNoLibrary		MOVEQ	#0,D0
			MOVEM.L	(SP)+,D2-D3/A2/A5-A6
			RTS

			XDEF	DOS_Release			
DOS_Release		MOVEM.L	D2-D3/A2/A5-A6,-(SP)
			MOVE.L	DOS_DOSDeviceListPtr,D2
			BEQ.B	.Skip1
.Loop1			MOVE.L	D2,A2
			MOVE.L	(DEVS_DOSEntryPtr,A2),D1
			BEQ.B	.Skip2
			MOVE.L	DOS_DOSBase,A6
			MOVE.L	#31,D2
			MOVEQ	#0,D3
			JSR	(_LVODoPkt,A6)
.Skip2			MOVE.L	(DEVS_DOSDeviceNextPtr,A2),D2
			MOVE.L	4.W,A6
			MOVE.L	A2,A1
			JSR	(_LVOFreeVec,A6)
			TST.L	D2
			BNE.B	.Loop1
.Skip1			MOVE.L	DOS_DOSBase,A6
			MOVEQ	#9,D1
			JSR	(_LVOUnlockDosList,A6)
			MOVE.L	A6,A1
			MOVE.L	4.W,A6
			JSR	(_LVOCloseLibrary,A6)
			MOVEM.L	(SP)+,D2-D3/A2/A5-A6
			RTS
			
			SECTION	DATA,DATA
DOSName			DC.B	'dos.library',0
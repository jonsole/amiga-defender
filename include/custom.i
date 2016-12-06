*
* Custom chips hardware registers
*
* Written by Frank Wille in 2013.
*
* I, the copyright holder of this work, hereby release it into the
* public domain. This applies worldwide.
*

CUSTOM		equ	$dff000

BLTDDAT		equ	$000
DMACONR		equ	$002
DMACONR_BBUSY		equ (1<<14)
DMACONR_BBUSY_POS	equ (14)
DMACONR_BZERO		equ (1<<13)
DMACONR_BLTPRI		equ (1<<10)
DMACONR_DMAEN		equ (1<<9)
DMACONR_BPLEN		equ (1<<8)
DMACONR_COPEN		equ (1<<7)
DMACONR_BLTEN		equ (1<<6)
DMACONR_SPREN		equ (1<<5)
DMACONR_DSKEN		equ (1<<4)
DMACONR_AUD3EN		equ (1<<3)
DMACONR_AUD2EN		equ (1<<2)
DMACONR_AUD1EN		equ (1<<1)
DMACONR_AUD0EN		equ (1<<0)


VPOSR		equ	$004
VHPOSR		equ	$006
DSKDATR		equ	$008
JOY0DAT		equ	$00a
JOY1DAT		equ	$00c
CLXDAT		equ	$00e

ADKCONR		equ	$010
ADKCONR_PRECOMP_NONE	equ (0<<13)
ADKCONR_PRECOMP_140	equ (1<<13)
ADKCONR_PRECOMP_280	equ (2<<13)
ADKCONR_PRECOMP_560	equ (3<<13)
ADKCONR_PRECOMP_POS	equ 13
ADKCONR_PRECOMP_MSK	equ (3<<13)
ADKCONR_MFMPREC_MFM	equ (1<<12)
ADKCONR_MFMPREC_GCR	equ (0<<12)
ADKCONR_UARTBRK		equ (1<<11)
ADKCONR_WORDSYNC	equ (1<<10)

POT0DAT		equ	$012
POT1DAT		equ	$014
POTGOR		equ	$016
SERDATR		equ	$018
DSKBYTR		equ	$01a
INTENAR		equ	$01c
INTREQR		equ	$01e
DSKPT		equ	$020
DSKPTH		equ	$020
DSKPTL		equ	$022
DSKLEN		equ	$024
DSKDAT		equ	$026
REFPTR		equ	$028
VPOSW		equ	$02a
VHPOSW		equ	$02c
COPCON		equ	$02e
SERDAT		equ	$030
SERPER		equ	$032
POTGO		equ	$034
JOYTEST		equ	$036
STREQU		equ	$038
STRVBL		equ	$03a
STRHOR		equ	$03c
STRLONG		equ	$03e

BLTCON0		equ	$040
BLTCON0_ASH_POS 	equ     12
BLTCON0_USEA   		equ     (1<<11)
BLTCON0_USEB    	equ     (1<<10)
BLTCON0_USEC    	equ     (1<<9)
BLTCON0_USED    	equ     (1<<8)
BLTCON0_LF_POS  	equ     0
BLTCON0_LF_MSK  	equ     $FF 

BLTCON1		equ	$042
BLTCON1_BSH_POS 	equ     12
BLTCON1_DOFF    	equ     (1<<7)
BLTCON1_EFE     	equ     (1<<4)
BLTCON1_IFE     	equ     (1<<3)
BLTCON1_FCI     	equ     (1<<2)
BLTCON1_DESC    	equ     (1<<1)
BLTCON1_LINE    	equ     (1<<0)

BLTAFWM		equ	$044
BLTALWM		equ	$046
BLTCPT		equ	$048
BLTCPTH		equ	$048
BLTCPTL		equ	$04a
BLTBPT		equ	$04c
BLTBPTH		equ	$04c
BLTBPTL		equ	$04e
BLTAPT		equ	$050
BLTAPTH		equ	$050
BLTAPTL		equ	$052
BLTDPT		equ	$054
BLTDPTH		equ	$054
BLTDPTL		equ	$056
BLTSIZE		equ	$058
BLTCMOD		equ	$060
BLTBMOD		equ	$062
BLTAMOD		equ	$064
BLTDMOD		equ	$066
BLTCDAT		equ	$070
BLTBDAT		equ	$072
BLTADAT		equ	$074
DSKSYNC		equ	$07e
COP1LC		equ	$080
COP1LCH		equ	$080
COP1LCL		equ	$082
COP2LC		equ	$084
COP2LCH		equ	$084
COP2LCL		equ	$086
COPJMP1		equ	$088
COPJMP2		equ	$08a
COPINS		equ	$08c
DIWSTRT		equ	$08e
DIWSTOP		equ	$090
DDFSTRT		equ	$092
DDFSTOP		equ	$094

DMACON		equ	$096
DMACON_SET		equ (1<<15)
DMACON_BLTPRI		equ (1<<10)
DMACON_DMAEN		equ (1<<9)
DMACON_BPLEN		equ (1<<8)
DMACON_COPEN		equ (1<<7)
DMACON_BLTEN		equ (1<<6)
DMACON_SPREN		equ (1<<5)
DMACON_DSKEN		equ (1<<4)
DMACON_AUD3EN		equ (1<<3)
DMACON_AUD2EN		equ (1<<2)
DMACON_AUD1EN		equ (1<<1)
DMACON_AUD0EN		equ (1<<0)
DMACON_ALL		equ $7fff

CLXCON		equ	$098

INTENA		equ	$09a
INTENA_SET		equ (1<<15)
INTENA_INTEN		equ (1<<14)
INTENA_EXTER		equ (1<<13)
INTENA_DSKSYN		equ (1<<12)
INTENA_RBF		equ (1<<11)
INTENA_AUD3		equ (1<<10)
INTENA_AUD2		equ (1<<9)
INTENA_AUD1		equ (1<<8)
INTENA_AUD0		equ (1<<7)
INTENA_BLIT		equ (1<<6)
INTENA_BLIT_POS		equ 6
INTENA_VERTB		equ (1<<5)
INTENA_VERTB_POS	equ 5
INTENA_COPER		equ (1<<4)
INTENA_PORTS		equ (1<<3)
INTENA_SOFT		equ (1<<2)
INTENA_SOFT_POS		equ 2
INTENA_DSKBLK		equ (1<<1)
INTENA_TBE		equ (1<<0)
INTENA_ALL		equ $7fff

INTREQ		equ	$09c
INTREQ_SET		equ (1<<15)
INTREQ_BLIT		equ (1<<6)
INTREQ_BLIT_POS		equ 6
INTREQ_VERTB		equ (1<<5)
INTREQ_VERTB_POS	equ 5
INTREQ_COPER		equ (1<<4)
INTREQ_COPER_POS	equ 4
INTREQ_SOFT		equ (1<<2)
INTREQ_SOFT_POS		equ 2
INTREQ_ALL		equ $7fff

ADKCON		equ	$09e
ADKCON_SET              equ (1<<15)
ADKCON_PRECOMP_NONE     equ (0<<13)
ADKCON_PRECOMP_140      equ (1<<13)
ADKCON_PRECOMP_280      equ (2<<13)
ADKCON_PRECOMP_560      equ (3<<13)
ADKCON_MFMPREC_MFM      equ (1<<12)
ADKCON_MFMPREC_GCR      equ (0<<12)
ADKCON_UARTBRK          equ (1<<11)
ADKCON_WORDSYNC         equ (1<<10)
ADKCON_ALL		equ $7FFF

AUD0LC		equ	$0a0
AUD0LCH		equ	$0a0
AUD0LCL		equ	$0a2
AUD0LEN		equ	$0a4
AUD0PER		equ	$0a6
AUD0VOL		equ	$0a8
AUD0DAT		equ	$0aa
AUD1LC		equ	$0b0
AUD1LCH		equ	$0b0
AUD1LCL		equ	$0b2
AUD1LEN		equ	$0b4
AUD1PER		equ	$0b6
AUD1VOL		equ	$0b8
AUD1DAT		equ	$0ba
AUD2LC		equ	$0c0
AUD2LCH		equ	$0c0
AUD2LCL		equ	$0c2
AUD2LEN		equ	$0c4
AUD2PER		equ	$0c6
AUD2VOL		equ	$0c8
AUD2DAT		equ	$0ca
AUD3LC		equ	$0d0
AUD3LCH		equ	$0d0
AUD3LCL		equ	$0d2
AUD3LEN		equ	$0d4
AUD3PER		equ	$0d6
AUD3VOL		equ	$0d8
AUD3DAT		equ	$0da
BPL1PT		equ	$0e0
BPL1PTH		equ	$0e0
BPL1PTL		equ	$0e2
BPL2PT		equ	$0e4
BPL2PTH		equ	$0e4
BPL2PTL		equ	$0e6
BPL3PT		equ	$0e8
BPL3PTH		equ	$0e8
BPL3PTL		equ	$0ea
BPL4PT		equ	$0ec
BPL4PTH		equ	$0ec
BPL4PTL		equ	$0ee
BPL5PT		equ	$0f0
BPL5PTH		equ	$0f0
BPL5PTL		equ	$0f2
BPL6PT		equ	$0f4
BPL6PTH		equ	$0f4
BPL6PTL		equ	$0f6

BPLCON0		equ	$100

BPLCON0_HIRES		equ (1<<15)
BPLCON0_BPU2		equ (1<<14)
BPLCON0_BPU1		equ (1<<13)
BPLCON0_BPU0		equ (1<<12)
BPLCON0_BPU_POS		equ 12
BPLCON0_HOMOD		equ (1<<11)
BPLCON0_DBLPF		equ (1<<10)
BPLCON0_COLOR		equ (1<<9)
BPLCON0_GAUD		equ (1<<8)
BPLCON0_LPEN		equ (1<<3)
BPLCON0_LACE		equ (1<<2)
BPLCON0_ERSY		equ (1<<1)

BPLCON1		equ	$102
BPLCON2		equ	$104
BPL1MOD		equ	$108
BPL2MOD		equ	$10a
BPL1DAT		equ	$110
BPL2DAT		equ	$112
BPL3DAT		equ	$114
BPL4DAT		equ	$116
BPL5DAT		equ	$118
BPL6DAT		equ	$11a
SPR0PT		equ	$120
SPR0PTH		equ	$120
SPR0PTL		equ	$122
SPR1PT		equ	$124
SPR1PTH		equ	$124
SPR1PTL		equ	$126
SPR2PT		equ	$128
SPR2PTH		equ	$128
SPR2PTL		equ	$12a
SPR3PT		equ	$12c
SPR3PTH		equ	$12c
SPR3PTL		equ	$12e
SPR4PT		equ	$130
SPR4PTH		equ	$130
SPR4PTL		equ	$132
SPR5PT		equ	$134
SPR5PTH		equ	$134
SPR5PTL		equ	$136
SPR6PT		equ	$138
SPR6PTH		equ	$138
SPR6PTL		equ	$13a
SPR7PT		equ	$13c
SPR7PTH		equ	$13c
SPR7PTL		equ	$13e
SPR0POS		equ	$140
SPR0CTL		equ	$142
SPR0DATA	equ	$144
SPR0DATB	equ	$146
SPR1POS		equ	$148
SPR1CTL		equ	$14a
SPR1DATA	equ	$14c
SPR1DATB	equ	$14e
SPR2POS		equ	$150
SPR2CTL		equ	$152
SPR2DATA	equ	$154
SPR2DATB	equ	$156
SPR3POS		equ	$158
SPR3CTL		equ	$15a
SPR3DATA	equ	$15c
SPR3DATB	equ	$15e
SPR4POS		equ	$160
SPR4CTL		equ	$162
SPR4DATA	equ	$164
SPR4DATB	equ	$166
SPR5POS		equ	$168
SPR5CTL		equ	$16a
SPR5DATA	equ	$16c
SPR5DATB	equ	$16e
SPR6POS		equ	$170
SPR6CTL		equ	$172
SPR6DATA	equ	$174
SPR6DATB	equ	$176
SPR7POS		equ	$178
SPR7CTL		equ	$17a
SPR7DATA	equ	$17c
SPR7DATB	equ	$17e
COLOR00		equ	$180
COLOR01		equ	$182
COLOR02		equ	$184
COLOR03		equ	$186
COLOR04		equ	$188
COLOR05		equ	$18a
COLOR06		equ	$18c
COLOR07		equ	$18e
COLOR08		equ	$190
COLOR09		equ	$192
COLOR10		equ	$194
COLOR11		equ	$196
COLOR12		equ	$198
COLOR13		equ	$19a
COLOR14		equ	$19c
COLOR15		equ	$19e
COLOR16		equ	$1a0
COLOR17		equ	$1a2
COLOR18		equ	$1a4
COLOR19		equ	$1a6
COLOR20		equ	$1a8
COLOR21		equ	$1aa
COLOR22		equ	$1ac
COLOR23		equ	$1ae
COLOR24		equ	$1b0
COLOR25		equ	$1b2
COLOR26		equ	$1b4
COLOR27		equ	$1b6
COLOR28		equ	$1b8
COLOR29		equ	$1ba
COLOR30		equ	$1bc
COLOR31		equ	$1be
HTOTAL		equ	$1c0
HSSTOP		equ	$1c2
HBSTRT		equ	$1c4
HBSTOP		equ	$1c6
VTOTAL		equ	$1c8
VSSTOP		equ	$1ca
VBSTRT		equ	$1cc
VBSTOP		equ	$1ce
SPRHSTRT	equ	$1d0
SPRHSTOP	equ	$1d2
BPLHSTRT	equ	$1d4
BPLHSTOP	equ	$1d6
HHPOSW		equ	$1d8
HHPOSR		equ	$1da
BEAMCON0	equ	$1dc
HSSTRT		equ	$1de
VSSTRT		equ	$1e0
HCENTER		equ	$1e2
DIWHIGH		equ	$1e4
BPLHMOD		equ	$1e6
SPRHPT		equ	$1e8
SPRHPTH		equ	$1e8
SPRHPTL		equ	$1ea
BPLHPT		equ	$1ec
BPLHPTH		equ	$1ec
BPLHPTL		equ	$1ee
FMODE		equ	$1fc
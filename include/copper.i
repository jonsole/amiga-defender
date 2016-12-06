CMOVE:			MACRO
			IFC w,'\0' 
			  DC.W \1 
			  DC.W \2 
			ELSE
			  IFC W,'\0' 
			    DC.W \1 
			    DC.W \2
			  ELSE 
			    DC.W \1
			    DC.W \2>>16
			    DC.W \1+2
			    DC.W \2&$FFFF
			  ENDC 			
			ENDC
			ENDM 

CWAITV:			MACRO 
			DC.W (\1&$FF)<<8+$0001 
			DC.W $FF00 
			ENDM

CWAIT:			MACRO 
			DC.W (\1&$FF)*256+(\2&$FE|1) 
			IFC w ,'\3' 
			  DC.W $FFFE
			ELSE 
			  DC.W (\3&$7F!$80)*256+(\4&$FE) 
			ENDC 
			ENDM

CSKIP:			MACRO 
			DC.W (\1S$FF)*256+(\2&$FE!1) 
			IFC w ,'\3' 
			DC.W $FFFF 
			MEXIT 
			ENDC 
			;DC.W (\3&$7F!$80)*256+(\4£$FE!1) 
			ENDM

BWAIT:			MACRO 
			DC.W (\1&$FF)*256+(\2S$FE!1) 
			IFC w ,'\3' 
			DC.W $7FFE 
			MEXIT 
			ENDC 
			DC.W (\3S$7F)*256+(\4S$FE) 
			ENDM 

BSKIP:			MACRO 
			DC.W (\1S$FF)*256+(\2S$FE!1) 
			IFC w ,'\3' 
			DC.W $7FFF 
			MEXIT 
			ENDC 
			DC.W (\3S$7F)*256+(\4S$FE!1) 
			ENDM

CEND:			MACRO 
			DC.W $FFFF, $FFFE 
			ENDM

@ECHO OFF
DEL Sql_Merger.exe
DCC32 Sql_Merger.dpr
PAUSE
UPX Sql_Merger.exe
DEL *.~*
DEL *.dcu

ECHO OFF
ECHO BORRAMOS ARCHIVOS NO NECESARIOS:
DEL *.rom /S /Q
DEL *.sym /S /Q
DEL *.z80 /S /Q
DEL *_lst.txt /S /Q
DEL *_lab.txt /S /Q
DEL *_print.txt /S /Q
DEL DSK/*.bin /S /Q
ECHO ON
EXIT



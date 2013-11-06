#For the linux exploit use 32-bit gcc
CC=gcc -m32
#Cross compile Windows exploit using wine and MinGW
W32CC=/opt/wine/drive_c/MinGW/bin/gcc.exe 

all: ability_appe ability_appe_win

ability_appe: ability_appe.c
	$(CC) -o ability_appe ability_appe.c

ability_appe_win: ability_appe_win.c
	$(W32CC) -o ability_appe_win ability_appe_win.c -l wsock32


clean:
	rm -f ability_appe ability_appe_win

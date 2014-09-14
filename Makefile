all:
	mkdir -p bin
	gdc src/main.d deimos/ncurses/* -lncursesw -o bin/test

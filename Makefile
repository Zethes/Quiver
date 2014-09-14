all:
	mkdir -p bin
	gdc src/main.d src/world/tile.d src/world/tiles/wall.d deimos/ncurses/* -lncursesw -o bin/test

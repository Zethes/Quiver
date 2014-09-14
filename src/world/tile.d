module world.tile;

enum TileIds
{
	WALL
};

class Tile
{
	this(TileIds id, int x, int y) 
	{
		this.id = id;
		this.x = x;
		this.y = y;
	}

	char GetSymbol() 
	{
		return '?';
	}

	@property TileIds Id() { return id; }
	@property int X() { return x; }
	@property int Y() { return y; }
private:
	TileIds id;
	int x, y;
};

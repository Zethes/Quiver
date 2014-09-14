module world.tile;

class Tile
{
	this(int id, int x, int y) 
	{
		this->id = id;
		this->x = x;
		this->y = y;
	}

	char GetSymbol() 
	{
		return '?';
	}

	@property int Id() { return id; }
	@property int X() { return x; }
	@property int Y() { return y; }
private:
	int id;
	int x, y;
};

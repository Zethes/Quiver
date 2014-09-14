module world.tiles.wall;
import world.tile;

class Wall : Tile
{
	this(int x, int y)
	{
		super(TileIds.WALL, x, y);
	}

	override char GetSymbol() 
	{
		return '#';
	}
}

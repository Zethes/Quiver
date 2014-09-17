module world.tiles.walkable;
import world.tile;

class Walkable : Tile
{
    this(int x, int y)
    {
        super(TileIds.WALKABLE, x, y);
    }

    override char GetSymbol() 
    {
        return ' ';
    }
}

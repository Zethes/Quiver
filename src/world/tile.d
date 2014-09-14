module world.tile;

enum TileIds
{
    WALKABLE,
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

    abstract char GetSymbol() 
    {
        return ' ';
    }

    @property TileIds Id() { return id; }
    @property int X() { return x; }
    @property int Y() { return y; }
private:
    TileIds id;
    int x, y;
};

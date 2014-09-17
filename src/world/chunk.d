module world.chunk;
import world.tile;
import world.tiles.walkable;

const int CHUNK_WIDTH = 256;
const int CHUNK_HEIGHT = CHUNK_WIDTH;

class Chunk
{
    this(int id)
    {
        this.id = id;
    }

    void ClearChunk()
    {
        for (int y = 0; y < CHUNK_HEIGHT; ++y)
        {
            for (int x = 0; x < CHUNK_WIDTH; ++x)
            {
                tiles[y][x] = new Walkable(x, y);
            }
        }
    }

    @property int Id() { return id; }
    @property int GetSymbol(int x, int y) 
    { 
        return tiles[y][x].GetSymbol(); 
    }
    @property Tile[CHUNK_HEIGHT][CHUNK_WIDTH] Tiles()
    {
        return tiles;
    }
private:
    int id;
    Tile tiles[CHUNK_HEIGHT][CHUNK_WIDTH];
}

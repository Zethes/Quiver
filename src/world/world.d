module world.world;
import world.tile;
import world.chunk;
import util.vector;

enum AdjacentChunks
{
    TOP_LEFT = 0,
    TOP,
    TOP_RIGHT,
    LEFT,
    CENTER,
    RIGHT,
    BOTTOM_LEFT,
    BOTTOM,
    BOTTOM_RIGHT
};

class World
{
    this() 
    {
        loadedCenter.x = loadedCenter.y = 0;
    }

    void LoadChunk(int slot, int id)
    {
        if (slot < AdjacentChunks.TOP_LEFT || 
                slot > AdjacentChunks.BOTTOM_RIGHT)
            return;

        loadedChunks[slot] = new Chunk(id);
        loadedChunks[slot].ClearChunk();

        //Todo: Loading chunks
    }

    VectorI ChunkOffset(int adj)
    {
        // Adjust the vector based on parent.
        int ax = 0, ay = 0;
        switch (adj) 
        {
            case AdjacentChunks.TOP_LEFT:
                ax = 0;
                ay = 0;
                break;
            case AdjacentChunks.TOP:
                ax = CHUNK_WIDTH;
                ay = 0;
                break;
            case AdjacentChunks.TOP_RIGHT:
                ax = CHUNK_WIDTH * 2;
                ay = 0;
                break;
            case AdjacentChunks.LEFT:
                ax = 0;
                ay = CHUNK_HEIGHT;
                break;
            case AdjacentChunks.CENTER:
                ax = CHUNK_WIDTH;
                ay = CHUNK_HEIGHT;
                break;
            case AdjacentChunks.RIGHT:
                ax = CHUNK_WIDTH * 2;
                ay = CHUNK_HEIGHT;
                break;
            case AdjacentChunks.BOTTOM_LEFT:
                ax = 0;
                ay = CHUNK_HEIGHT * 2;
                break;
            case AdjacentChunks.BOTTOM:
                ax = CHUNK_WIDTH;
                ay = CHUNK_HEIGHT * 2;
                break;
            case AdjacentChunks.BOTTOM_RIGHT:
                ax = CHUNK_WIDTH * 2;
                ay = CHUNK_HEIGHT * 2;
                break;
        };

        VectorI offset;
        offset.x = ax + CHUNK_WIDTH + (CHUNK_WIDTH/2);
        offset.y = ay + CHUNK_HEIGHT + (CHUNK_HEIGHT/2);
        return offset;
    }

    VectorI WorldToLocal(VectorI world)
    {
        VectorI local;
        local.x = world.x % CHUNK_WIDTH;
        local.y = world.y % CHUNK_HEIGHT;
        return local;
    }

    Chunk WorldToChunk(VectorI world)
    {
        // Is the chunk loaded?
        VectorI dx;
        dx.x = std.math.abs(loadedCenter.x - world.x);
        dx.y = std.math.abs(loadedCenter.y - world.y);
        if (dx.x > CHUNK_WIDTH + (CHUNK_WIDTH/2) ||
                dx.y > CHUNK_HEIGHT + (CHUNK_HEIGHT/2)) 
            return null;

        // It's in a neighbor's chunk.
        foreach (i, chunk; loadedChunks)
        {
            VectorI offset = ChunkOffset(cast(int)i);
            if (std.math.abs(offset.x) <= CHUNK_WIDTH &&
                    std.math.abs(offset.y) <= CHUNK_HEIGHT)
                return chunk;
        }

        return null;
    }
    
    VectorI LocalToWorld(VectorI local, int chunk_id) 
    {
        // Find our chunk
        foreach (i, chunk; loadedChunks)
        {
            if (chunk.Id == chunk_id) 
            {
                VectorI world = loadedCenter;
                VectorI offset = ChunkOffset(cast(int)i);
                world.x += offset.x + local.x;
                world.y += offset.y + local.y;
                return world;
            }
        }
   
        VectorI err;
        err.x = err.y = -1;
        return err;
    }
private:
    VectorI loadedCenter;
    Chunk loadedChunks[9];
}

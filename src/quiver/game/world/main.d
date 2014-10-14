module quiver.game.world.main;

import quiver.game.world.chunk;
import quiver.game.world.generator;
import Render = render;
import util.log;
import util.vector;

class World
{

    this()
    {
        assert(_chunkSize.x == _chunkSize.y, "Chunks must be square.");
    }

    void getTiles(VectorI position, VectorI size, Render.Block[] blocks)
    {
        Chunk[] relevantChunks;
        for (int w = 0; w < size.x; w++)
        {
            for (int h = 0; h < size.y; h++)
            {
                VectorI currentPosition = position + VectorI(w, h);
                Chunk chunk = getChunkAt(currentPosition);
                VectorI relativePosition = currentPosition - chunk.position;
                blocks[w + size.x * h] = chunk.getBlock(relativePosition);

                bool found = false;
                foreach (relChunk; relevantChunks)
                {
                    if (relChunk == chunk)
                    {
                        found = true;
                        break;
                    }
                }

                if (!found)
                {
                    relevantChunks ~= chunk;
                }
            }
        }

        foreach (relChunk; relevantChunks)
        {
            foreach (entity; relChunk.entities)
            {
                VectorI entPos = entity.position;
                assert(relChunk.positionInChunk(entPos));
                if (entPos.x >= position.x && entPos.y >= position.y)
                {
                    if (entPos.x < (position.x + size.x) && entPos.y < (position.y + size.y))
                    {
                        blocks[entPos.x + size.x * entPos.y] = entity.getBlock();
                    }
                }
            }
        }
    }

    Chunk getChunkAt(VectorI position)
    {
        VectorI basePosition = (position / _chunkSize.x) * _chunkSize.x;
        Chunk* chunkQuery = basePosition in _chunkPositionMap;
        if (chunkQuery is null)
        {
            return loadChunk(position);
        }
        else
        {
            return *chunkQuery;
        }
    }

    Chunk loadChunk(VectorI position)
    {
        assert((position in _chunkPositionMap) is null);
        VectorI basePosition = (position / _chunkSize.x) * _chunkSize.x;
        Chunk chunk = new Chunk(basePosition, _chunkSize);
        chunk.generate(new WorldGenerator);
        _loadedChunks ~= chunk;
        _chunkPositionMap[basePosition] = chunk;
        return chunk;
    }

private:

    //VectorI _chunkSize = VectorI(256, 256);
    VectorI _chunkSize = VectorI(8, 8);
    Chunk[] _loadedChunks;
    Chunk[VectorI] _chunkPositionMap;

}

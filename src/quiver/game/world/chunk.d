module quiver.game.world.chunk;

import quiver.game.entity.base;
import quiver.game.world.generator;
import Render = render;
import std.random;
import util.log;
import util.vector;

class Chunk
{

    this(VectorI position, VectorI size)
    {
        _position = position;
        _size = size;
        _blocks = new Render.Block[size.product()];
    }

    void generate(WorldGenerator worldGen)
    {
        worldGen.generate(_position, _size, _blocks);
    }

    Render.Block getBlock(VectorI position) const
    {
        assert(position.x < _size.x && position.x >= 0);
        assert(position.y < _size.y && position.y >= 0);
        return _blocks[position.x + _size.x * position.y];
    }

    bool positionInChunk(VectorI position)
    {
        position = position - _position;
        return ((position.x < _size.x && position.x >= 0 && position.y < _size.y && position.y >= 0));
    }

    void addEntity(Entity entity)
    {
        _entities ~= entity;
    }

    void removeEntity(Entity entity)
    {
        size_t index = size_t.max;
        foreach (size_t i, e; _entities)
        {
            if (entity == e)
            {
                index = i;
            }
        }

        if (index != size_t.max)
        {
            _entities = _entities[0 .. index] ~ _entities[index + 1 .. $];
        }
    }

    @property VectorI position() const
    {
        return _position;
    }

    @property VectorI size() const
    {
        return _size;
    }

    @property ref Entity[] entities()
    {
        return _entities;
    }

private:

    VectorI _position;
    VectorI _size;
    Render.Block[] _blocks;
    Entity[] _entities;

}

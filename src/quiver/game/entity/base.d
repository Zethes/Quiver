module quiver.game.entity.base;

import quiver.game.world;
import Render = render;
import util.log;
import util.vector;

class Entity
{

    this(World world, VectorI position)
    {
        _world = world;
        _chunk = world.getChunkAt(position);
        _position = position;
    }

    void tick()
    {
    }

    Render.Block getBlock() const
    {
        return Render.Block('?', Render.WHITE_ON_BLACK);
    }

    void relocate()
    {
        if (!_chunk.positionInChunk(_position))
        {
            _chunk.removeEntity(this);
            _chunk = _world.getChunkAt(_position);
            _chunk.addEntity(this);
        }
    }

    @property VectorI position() const
    {
        return _position;
    }

    @property void position(VectorI position)
    {
        _position = position;
        relocate();
    }

    @property Chunk chunk()
    {
        return _chunk;
    }

    @property World world()
    {
        return _world;
    }

    void move(VectorI direction)
    {
        if (direction == VectorI(0, 0)) return;
        assert(direction.y != 0 || (direction.x == -1 || direction.x == 1));
        assert(direction.x != 0 || (direction.y == -1 || direction.y == 1));

        VectorI newPosition = _position + direction;

        bool cancel = false;
        if (newPosition.x <= 0 || newPosition.y <= 0)
        {
            cancel = true;
        }

        Render.Block block = _world.getBlockAt(newPosition);
        if (block.character == '*')
        {
            cancel = true;
        }

        if (!cancel)
        {
            _position = newPosition;
            relocate();
        }
    }

protected:

    World _world;
    Chunk _chunk;

    VectorI _position;

}

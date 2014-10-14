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

    int key;
    void tick()
    {
        if (key == 'j')
        {
            _position.y += 1;
        }
        if (key == 'k')
        {
            _position.y -= 1;
        }
        if (key == 'h')
        {
            _position.x -= 1;
        }
        if (key == 'l')
        {
            _position.x += 1;
        }
        key = -1;
        relocate();
    }

    Render.Block getBlock() const
    {
        return Render.Block('@', Render.CYAN_ON_BLACK);
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

private:

    World _world;
    Chunk _chunk;

    VectorI _position;

}

module quiver.game.entity.manager;

import quiver.game.entity.base;
import quiver.game.world.chunk;
import quiver.game.world.main;
import util.vector;

class EntityManager
{

    Entity createEntity(World world, VectorI position)
    {
        Entity entity = new Entity(world, position);
        _entities ~= entity;

        Chunk chunk = world.getChunkAt(position);
        chunk.addEntity(entity);

        return entity;
    }

    void tick()
    {
        foreach (entity; _entities)
        {
            entity.tick();
        }
    }

private:

    Entity[] _entities;

}

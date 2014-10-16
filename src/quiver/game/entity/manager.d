module quiver.game.entity.manager;

import quiver.game.entity.base;
import quiver.game.entity.mob;
import quiver.game.entity.player;
import quiver.game.world.chunk;
import quiver.game.world.main;
import util.vector;

class EntityManager
{

    PlayerEntity createPlayer(World world, VectorI position)
    {
        return createEntity(new PlayerEntity(world, position));
    }

    MobEntity createMob(World world, VectorI position)
    {
        return createEntity(new MobEntity(world, position));
    }

    void removeEntity(Entity entity)
    {
        foreach (size_t index, e; _entities)
        {
            if (e == entity)
            {
                entity.chunk.removeEntity(entity);
                _entities = _entities[0 .. index] ~ _entities[index + 1 .. $];
                break;
            }
        }
    }

    void tick()
    {
        foreach (entity; _entities)
        {
            entity.tick();
        }
    }

private:

    T createEntity(T)(T entity)
    {
        _entities ~= entity;

        Chunk chunk = entity.world.getChunkAt(entity.position);
        chunk.addEntity(entity);

        return entity;
    }

    Entity[] _entities;

}

module quiver.game.entity.mob;

import quiver.game.entity.base;
import quiver.game.world;
import Render = render;
import std.random;
import util.vector;

class MobEntity : Entity
{

    this(World world, VectorI position)
    {
        super(world, position);
    }

    override void tick()
    {
        switch (uniform!"[]"(1, 4))
        {
            case 1:
            move(VectorI(1, 0));
            break;
            case 2:
            move(VectorI(-1, 0));
            break;
            case 3:
            move(VectorI(0, 1));
            break;
            case 4:
            move(VectorI(0, -1));
            break;
            default:
                assert(0);
        }
        relocate();
    }

    override Render.Block getBlock() const
    {
        return Render.Block('b', Render.RED_ON_BLACK);
    }

}

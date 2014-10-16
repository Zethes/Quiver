module quiver.game.entity.player;

import quiver.game.entity.base;
import quiver.game.world;
import util.vector;

class PlayerEntity : Entity
{

    this(World world, VectorI position)
    {
        super(world, position);
    }

    int key;
    override void tick()
    {
        if (key == 'j')
        {
            move(VectorI(0, 1));
        }
        if (key == 'k')
        {
            move(VectorI(0, -1));
        }
        if (key == 'h')
        {
            move(VectorI(-1, 0));
        }
        if (key == 'l')
        {
            move(VectorI(1, 0));
        }
        key = -1;
    }

    override Render.Block getBlock() const
    {
        return Render.Block('@', Render.CYAN_ON_BLACK);
    }

    @property bool ready() const
    {
        return key != -1;
    }

}

module quiver.game.world.generator;

import Render = render;
import std.random;
import util.vector;

class WorldGenerator
{

    void generate(VectorI position, VectorI size, Render.Block[] blocks)
    {
        for (int i = 0, e = size.product(); i < e; i++)
        {
            if (uniform!"[]"(1, 1000) < 990)
            {
                blocks[i] = Render.Block('`', Render.GREEN_ON_BLACK);
            }
            else
            {
                blocks[i] = Render.Block('*', Render.WHITE_ON_BLACK);
            }
            /*if ((i % 2) == 0)
            {
                blocks[i] = Render.Block('|', Render.CYAN_ON_BLACK);
            }*/
        }
    }

}

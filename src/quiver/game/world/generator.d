module quiver.game.world.generator;

import Render = render;
import std.random;
import util.vector;

class WorldGenerator
{

    void generate(VectorI position, VectorI size, Render.Block[] blocks)
    {
        for (int h = 0; h < size.y; h++)
        {
            for (int w = 0; w < size.x; w++)
            {
                VectorI location = position + VectorI(w, h);

                if (uniform!"[]"(1, 1000) < 990 && location.x < 150 && location.y < 25)
                {
                    blocks[w + size.x * h] = Render.Block('`', Render.GREEN_ON_BLACK);
                }
                else
                {
                    blocks[w + size.x * h] = Render.Block('*', Render.WHITE_ON_BLACK);
                }
            }
        }
    }

}

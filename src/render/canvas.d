module render.canvas;
import deimos.ncurses.ncurses;
import render.screen;
import std.algorithm;
import std.conv;
import std.math;
import std.stdio;
import util.vector;

mixin(Screen._colorMixin);

struct Block
{
    static const char defaultCharacter = '~';
    static const byte defaultColor = GREEN_ON_BLACK;

    char character = defaultCharacter;
    byte color = defaultColor;

    this(char character, byte color)
    {
        this.character = character;
        this.color = color;
    }

    void reset()
    {
        character = defaultCharacter;
        color = defaultColor;
    }
}

class Canvas
{

    /////////////////
    // Constructor //
    /////////////////

    this(int width, int height)
    {
        resize(width, height);
    }

    //////////////
    // Resizing //
    //////////////

    void resize(int width, int height)
    {
        if (width == _width && height == _height)
        {
            return;
        }

        Block[] oldData = _data;

        _data = new Block[width * height];

        // Copy old canvas data over
        for (int x = 0; x < min(_width, width); x++)
        {
            for (int y = 0; y < min(_height, height); y++)
            {
                _data[x + width * y] = oldData[x + _width * y];
            }
        }

        _width = width;
        _height = height;
    }

    void resize(const VectorI size)
    {
        resize(size.x, size.y);
    }

    /////////////////
    // Canvas Data //
    /////////////////

    ref Block at(int x, int y)
    {
        assert(x >= 0 && y >= 0 && x < _width && y < _height,
               "Cannot get canvas point (" ~ to!string(VectorI(x, y)) ~ ") for canvas size (" ~ to!string(size) ~ ")!");

        return _data[x + width * y];
    }

    ref Block at(VectorI pos)
    {
        return at(pos.x, pos.y);
    }

    /////////////////////
    // Size Properties //
    /////////////////////

    @property int width() const
    {
        return _width;
    }

    @property void width(int width)
    {
        resize(width, _height);
    }

    @property int height() const
    {
        return _height;
    }

    @property void height(int height)
    {
        resize(_width, height);
    }

    @property VectorI size() const
    {
        return VectorI(width, height);
    }

    @property void size(const VectorI value)
    {
        resize(value);
    }

private:

    int _width, _height;
    Block[] _data;
}

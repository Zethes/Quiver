module render.canvas;
import deimos.ncurses.ncurses;
import render.screen;
import render.colors;
import std.algorithm;
import std.conv;
import std.math;
import std.stdio;
import util.vector;

struct Block
{
    static const char defaultCharacter = ' ';
    static const ubyte defaultColor = BLACK_ON_BLACK;

    char character = defaultCharacter;
    ubyte color = defaultColor;

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

    this(VectorI size)
    {
        resize(size);
    }

    //////////////
    // Resizing //
    //////////////

    void resize(VectorI size)
    {
        if (size.x == _width && size.y == _height)
        {
            return;
        }

        Block[] oldData = _data;

        _data = new Block[size.x * size.y];

        // Copy old canvas data over
        for (int x = 0; x < min(_width, size.x); x++)
        {
            for (int y = 0; y < min(_height, size.y); y++)
            {
                _data[x + size.x * y] = oldData[x + _width * y];
            }
        }

        _width = size.x;
        _height = size.y;
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
        resize(VectorI(width, _height));
    }

    @property int height() const
    {
        return _height;
    }

    @property void height(int height)
    {
        resize(VectorI(_width, height));
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

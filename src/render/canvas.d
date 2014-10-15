module render.canvas;
import deimos.ncurses.ncurses;
import render.screen;
import render.colors;
import std.algorithm;
import std.conv;
import std.math;
import std.stdio;
import util.log;
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

    Block at(int x, int y)
    {
        assert(x >= 0 && y >= 0 && x < _width && y < _height,
               "Cannot get canvas point (" ~ to!string(VectorI(x, y)) ~ ") for canvas size (" ~ to!string(size) ~ ")!");

        return _data[x + width * y];
    }

    Block at(VectorI pos)
    {
        return at(pos.x, pos.y);
    }

    void set(int x, int y, Block block)
    {
        if (_data[x + width * y] != block)
        {
            _data[x + width * y] = block;

            if (!dirty)
            {
                _dirtyTopLeft = VectorI(x, y);
                _dirtyBottomRight = VectorI(x + 1, y + 1);
            }
            else
            {
                if (_dirtyTopLeft.x > x)
                {
                    _dirtyTopLeft.x = x;
                }
                if (_dirtyTopLeft.y > y)
                {
                    _dirtyTopLeft.y = y;
                }
                if (_dirtyBottomRight.x < x + 1)
                {
                    _dirtyBottomRight.x = x + 1;
                }
                if (_dirtyBottomRight.y < y + 1)
                {
                    _dirtyBottomRight.y = y + 1;
                }
            }
        }
    }

    void set(VectorI pos, Block block)
    {
        set(pos.x, pos.y, block);
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

    ///////////////////
    // Dirty & Clean //
    ///////////////////

    void dirtyAll()
    {
        _dirtyTopLeft = VectorI(0, 0);
        _dirtyBottomRight = VectorI(_width, _height);
    }

    void clean()
    {
        _dirtyTopLeft = VectorI(-1, -1);
        _dirtyBottomRight = VectorI(-1, -1);
    }

    @property bool dirty() const
    {
        return _dirtyTopLeft.x != -1 && _dirtyTopLeft.y != -1 && _dirtyBottomRight.x != -1 && _dirtyBottomRight.y != -1;
    }

    @property VectorI dirtyTopLeft()
    {
        return _dirtyTopLeft;
    }

    @property VectorI dirtyBottomRight()
    {
        return VectorI(min(_width, _dirtyBottomRight.x), min(_height, _dirtyBottomRight.y));
    }

private:

    int _width, _height;
    Block[] _data;
    VectorI _dirtyTopLeft;
    VectorI _dirtyBottomRight;

}

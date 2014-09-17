module render.canvas;
import deimos.ncurses.ncurses;
import std.algorithm;
import std.conv;
import std.math;
import std.stdio;
import util.vector;

class Canvas
{
    this(int width, int height)
    {
        resize(width, height);
    }

    void resize(int width, int height)
    {
        if (width == _width && height == _height)
        {
            return;
        }

        char[] oldData = _data;

        _data = new char[width * height];
        _data[0 .. width * height] = ' ';

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

    ref char at(int x, int y)
    {
        assert(x >= 0 && y >= 0 && x < _width && y < _height,
               "Cannot get canvas point (" ~ to!string(VectorI(x, y)) ~ ") for canvas size (" ~ to!string(size) ~ ")!");

        return _data[x + width * y];
    }

    ref char at(VectorI pos)
    {
        return at(pos.x, pos.y);
    }

    @property int width()
    {
        return _width;
    }

    @property void width(int width)
    {
        resize(width, _height);
    }

    @property int height()
    {
        return _height;
    }

    @property void height(int height)
    {
        resize(_width, height);
    }

    @property VectorI size()
    {
        return VectorI(width, height);
    }

    @property void size(const VectorI value)
    {
        resize(value);
    }

private:

    int _width, _height;
    char[] _data;
}

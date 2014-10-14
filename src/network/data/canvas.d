module network.data.canvas;

import network.data.core;
import render.canvas;
import std.algorithm;
import std.conv;
import util.log;
import util.vector;

class CanvasData : Data
{

    this()
    {
        super(DataType.CANVAS);

        _canvas = new Canvas(VectorI(10, 10));
        _rawData = new Block[_canvas.size.product()];
        updateCanvas();

        if (!_client)
        {
            width = 10;
            height = 10;
        }
    }

    override void processProperties()
    {
        bool update = (width != _canvas.width) || (height != _canvas.height);

        if (update)
        {
            uint oldWidth = _canvas.width;
            uint oldHeight = _canvas.height;

            _canvas.width = width;
            _canvas.height = height;

            Block[] oldData = _rawData;
            _rawData = new Block[_canvas.size.product()];

            for (int x = 0; x < min(oldWidth, width); x++)
            {
                for (int y = 0; y < min(oldHeight, height); y++)
                {
                    _rawData[x + width * y] = oldData[x + oldWidth * y];
                }
            }

            if (!_client)
            {
                _dirty = true;
            }
        }
    }

    override ubyte[] getUpdateData()
    {
        if (_dirty)
        {
            _dirty = false;

            return getRaw();
        }
        else
        {
            return null;
        }
    }

    override void updateData(ubyte[] raw)
    {
        assert(raw.length == _canvas.size.product() * Block.sizeof);
        _rawData = cast(Block[])raw;
        updateCanvas();
    }

    override ubyte[] getRaw()
    {
        return cast(ubyte[])_rawData;
    }

    Block at(uint x, uint y) const
    {
        return _rawData[x + _canvas.width * y];
    }

    void set(uint x, uint y, Block block)
    {
        if (x < width && y < height) // TODO: assert (but not for now)
        {
            if (_canvas.at(x, y) != block)
            {
                _canvas.at(x, y) = block;
                _rawData[x + _canvas.width * y] = block;
                _dirty = true;
            }
        }
    }

    @property Canvas canvas()
    {
        return _canvas;
    }

    @property uint width() const
    {
        return getProperty(0);
    }

    @property void width(uint value)
    {
        assert(value > 0, "Canvas width cannot be " ~ to!string(value));
        assert(value < int.max, "Canvas width cannot be " ~ to!string(value));
        setProperty(0, value);
    }

    @property uint height() const
    {
        return getProperty(1);
    }

    @property void height(uint value)
    {
        assert(value > 0, "Canvas height cannot be " ~ to!string(value));
        assert(value < int.max, "Canvas height cannot be " ~ to!string(value));
        setProperty(1, value);
    }

    @property VectorI size() const
    {
        return VectorI(width, height);
    }

private:

    Block[] _rawData;
    Canvas _canvas;

    bool _dirty = false;

    void updateCanvas()
    {
        for (int w = 0; w < _canvas.width; w++)
        {
            for (int h = 0; h < _canvas.height; h++)
            {
                _canvas.at(w, h) = at(w, h);
            }
        }
    }

}

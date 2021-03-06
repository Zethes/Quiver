module network.data.canvas;

import network.data.core;
import render;
import std.algorithm;
import std.conv;
import util.log;
import util.vector;

class CanvasData : Data
{

    // NOTE: this is not a union because it causes an internal compiler error in GDC 4.8.2
    private struct DataHeader
    {
        union
        {
            struct
            {
                VectorI topLeft = VectorI(-1, -1);
                VectorI bottomRight = VectorI(-1, -1);
            }
            ubyte[VectorI.sizeof * 2] rawData;
        }
    }

    this(bool client = false)
    {
        super(DataType.CANVAS, client);

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
                dirtyAll();
            }
        }
    }

    override ubyte[] getUpdateData()
    {
        if (dirty)
        {
            DataHeader header;
            header.topLeft = canvas.dirtyTopLeft;
            header.bottomRight = canvas.dirtyBottomRight;

            // Calculate size of data
            VectorI difference = header.bottomRight - header.topLeft;
            size_t dataSize = difference.product() * Block.sizeof;

            ubyte[] data = new ubyte[DataHeader.sizeof + dataSize];
            data[0 .. DataHeader.sizeof] = header.rawData;

            // Append sub-data
            int width = _canvas.width;
            for (int w = 0; w < difference.x; w++)
            {
                for (int h = 0; h < difference.y; h++)
                {
                    size_t index1 = DataHeader.sizeof + (w + difference.x * h) * Block.sizeof;
                    size_t index2 = (w + header.topLeft.x) + width * (h + header.topLeft.y);
                    data[index1 .. index1 + Block.sizeof] = cast(ubyte[])_rawData[index2 .. index2 + 1];
                }
            }

            clean();
            return data;
        }
        else
        {
            return null;
        }
    }

    override void updateData(ubyte[] raw)
    {
        // Get header
        assert(raw.length >= DataHeader.sizeof);
        DataHeader header;
        header.rawData = raw[0 .. DataHeader.sizeof];

        // Calculate size of data
        VectorI difference = header.bottomRight - header.topLeft;
        size_t dataSize = difference.product() * Block.sizeof;
        assert(raw.length == DataHeader.sizeof + dataSize, to!string(raw.length) ~ " - " ~ to!string(DataHeader.sizeof + dataSize));

        // Update data
        Block[] blocks = cast(Block[])raw[DataHeader.sizeof .. $];
        if (dataSize == _canvas.size.product() * Block.sizeof)
        {
            // Update entire data
            _rawData = blocks;
        }
        else
        {
            // Update sub-data
            int width = _canvas.width;
            size_t index = 0;
            for (int h = header.topLeft.y; h < header.bottomRight.y; h++)
            {
                for (int w = header.topLeft.x; w < header.bottomRight.x; w++)
                {
                    if (header.topLeft.x == 0)
                    {
                        _rawData[w + width * h] = blocks[(w - header.topLeft.x) + header.bottomRight.x * (h - header.topLeft.y)];
                    }
                    else
                    {
                        _rawData[w + width * h] = blocks[index++];
                    }
                }
            }
        }
        updateCanvas();
    }

    override ubyte[] getRaw()
    {
        DataHeader header;
        header.topLeft = VectorI(0, 0);
        header.bottomRight = size;

        ubyte[] data = new ubyte[DataHeader.sizeof + _rawData.length * Block.sizeof];
        data[0 .. DataHeader.sizeof] = header.rawData;
        data[DataHeader.sizeof .. $] = cast(ubyte[])_rawData;
        return data;
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
                _canvas.set(x, y, block);
                _rawData[x + _canvas.width * y] = block;
            }
        }
    }

    void dirtyAll()
    {
        _canvas.dirtyAll();
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

    @property bool dirty() const
    {
        return _canvas.dirty;
    }

private:

    Block[] _rawData;
    Canvas _canvas;

    void updateCanvas()
    {
        for (int w = 0; w < _canvas.width; w++)
        {
            for (int h = 0; h < _canvas.height; h++)
            {
                _canvas.set(w, h, at(w, h));
            }
        }
    }

    void clean()
    {
        _canvas.clean();
    }

}

module network.data.generic;

import network.data.core;
import std.conv;
import util.log;

class GenericData : Data
{

    struct NetData
    {
        int x = 5;
    }

    this(bool client = false)
    {
        super(DataType.GENERIC, client);
    }

    this(ubyte[] raw, bool client = false)
    {
        super(DataType.GENERIC, client);

        assert(raw.length == NetData.sizeof);
        data = *(cast(NetData*)raw.ptr);
    }

    override ubyte[] getUpdateData()
    {
        if (dirty)
        {
            dirty = false;
            return pack(data);
        }
        else
        {
            return null;
        }
    }

    override void updateData(ubyte[] raw)
    {
        assert(raw.length == NetData.sizeof);
        data = *(cast(NetData*)raw.ptr);
    }

    override ubyte[] getRaw()
    {
        return pack(data);
    }

    @property int x() const
    {
        return data.x;
    }

    @property void x(int value)
    {
        if (data.x != value)
        {
            data.x = value;
            dirty = true;
        }
    }

    @property uint length() const
    {
        return getProperty(0);
    }

    @property void length(uint value)
    {
        assert(value < int.max, "Length cannot be " ~ to!string(value));
        setProperty(0, value);
    }

private:

    bool dirty = false;
    NetData data;

}

module network.messaging;

import std.conv;
import util.log;

class PacketBase
{

    this(size_t dataLength)
    {
        _data = new ubyte[dataLength];
    }

    this(ubyte[] data)
    {
        assert(data.length >= PacketHeader.sizeof, "Data too small (" ~ .to!string(data.length) ~ ")");

        _data = data;
    }

    this(T)(T data)
        if (is(typeof(data.header) == PacketHeader))
    {
        assert((cast(void*)&data) == (cast(void*)&data.header));

        _data = new ubyte[data.sizeof];
        for (size_t i = 0; i < data.sizeof; i++)
        {
            _data[i] = (cast(ubyte*)&data)[i];
        }
    }

    void append(ubyte[] data)
    {
        _data ~= data;
    }

    @property PacketHeader* header()
    {
        return (cast(PacketHeader*)_data);
    }

    @property size_t length() const
    {
        return _data.length;
    }

    @property ref ubyte[] rawData()
    {
        return _data;
    }

    @property ushort from() const
    {
        return _from;
    }

    @property void from(ushort value)
    {
        _from = value;
    }

    @property ushort to() const
    {
        return _to;
    }

    @property void to(ushort value)
    {
        _to = value;
    }

    @property bool exclude() const
    {
        return _exclude;
    }

    @property void exclude(bool value)
    {
        _exclude = value;
    }

    @property uint toGroup() const
    {
        return _toGroup;
    }

    @property void toGroup(uint value)
    {
        _toGroup = value;
    }

    ubyte[] getExtra(size_t start)
    {
        assert(start < _data.length);
        return _data[start .. $];
    }

    ubyte[] getExtra(T)()
        if (is(T == struct))
    {
        return PacketBase.getExtra(T.sizeof);
    }

protected:

    ushort _from = ushort.max;
    ushort _to = ushort.max;
    bool _exclude = false;
    uint _toGroup = uint.max;
    ubyte[] _data;

}

class Packet(T) : PacketBase
{

    this(size_t dataLength)
    {
        super(dataLength);
    }

    alias Data = T;

    @property ref Data data()
    {
        return *(cast(Data*)_data);
    }

}

struct PacketHeader
{
    ubyte magic1 = 'Q';
    ubyte magic2 = 'v';
    ubyte magic3 = 'e';
    ubyte magic4 = 'r';
    ushort core = ushort.max;
    ushort packet = ushort.max;
    ushort length = ushort.max;

    void swap()
    {
        // TODO: endian swapping
    }

    string toString() const
    {
        string result;
        result ~= "Magic  : " ~ magic1 ~ magic2 ~ magic3 ~ magic4 ~ "\n";
        result ~= "Core   : " ~ .to!string(core) ~ "\n";
        result ~= "Packet : " ~ .to!string(packet) ~ "\n";
        result ~= "Length : " ~ .to!string(length) ~ "\n";
        return result;
    }
}

class PacketQueue
{

    void queue(T)(T packet)
        if (is(typeof(packet.header) == PacketHeader*) && is(typeof(packet.data.header) == PacketHeader))
    {
        // TODO: endian swapping
        if (false)
        {
            packet.data.swap(true);
        }

        packet.header.length = to!ushort(packet._data.length);
        _outbox ~= packet;
    }

    void queue(T)(T packet, ubyte[] extra)
        if (is(typeof(packet.header) == PacketHeader*) && is(typeof(packet.data.header) == PacketHeader))
    {
        // TODO: endian swapping
        if (false)
        {
            packet.data.swap(true);
        }

        packet.header.length = to!ushort(packet._data.length + extra.length);
        packet.rawData ~= extra;
        _outbox ~= packet;
    }

    @property ref PacketBase[] outbox()
    {
        return _outbox;
    }

    @property ref PacketBase[] inbox()
    {
        return _inbox;
    }

private:

    PacketBase[] _outbox;
    PacketBase[] _inbox;

}

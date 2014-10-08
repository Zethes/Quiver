module network.messaging;

import network.core;
import std.conv;
import util.log;

enum RouteType
{
    Auto,
    Connection,
    AllConnections,
    AllConnectionsExcept,
    Server,
    Client,
    AllClients,
    AllClientsExcept,
    ClientGroup
}

class Route
{

    static PacketRoute automatic = PacketRoute(RouteType.Auto);
    static PacketRoute connection = PacketRoute(RouteType.Connection);
    static PacketRoute allConnections = PacketRoute(RouteType.AllConnections);
    static PacketRoute server = PacketRoute(RouteType.Server);
    static PacketRoute allClients = PacketRoute(RouteType.AllClients);

    static PacketRoute allConnectionsExcept(ushort index)
    {
        return PacketRoute(RouteType.AllConnectionsExcept, index);
    }

    static PacketRoute client(ushort index)
    {
        return PacketRoute(RouteType.Client, index);
    }

    static PacketRoute allClientsExcept(ushort index)
    {
        return PacketRoute(RouteType.AllClientsExcept, index);
    }

    static PacketRoute clientGroup(ushort index)
    {
        return PacketRoute(RouteType.ClientGroup, index);
    }

}

class Packet
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

    @property ushort fromConnection() const
    {
        return _fromConnection;
    }

    @property void fromConnection(ushort value)
    {
        _fromConnection = value;
    }

    void addConnection(ushort connection)
    {
        _connectionList ~= connection;
    }

    @property ushort[] connectionList()
    {
        return _connectionList;
    }

    ubyte[] getExtra(size_t start)
    {
        assert(start < _data.length);
        return _data[start .. $];
    }

    ubyte[] getExtra(T)()
        if (is(T == struct))
    {
        return Packet.getExtra(T.sizeof);
    }

    @property bool routed() const // TODO: remove this
    {
        return false;
    }

    @property bool allowDuplicate() const
    {
        return false;
    }

    @property void allowDuplicate(bool value)
    {
    }

    @property bool optimizeDuplicates() const
    {
        return false;
    }

    @property void optimizeDuplicates(bool value)
    {
    }

    @property bool trace() const
    {
        return false;
    }

    @property void trace(bool value)
    {
    }

protected:

    ushort _fromConnection = ushort.max;
    ushort _toConnection = ushort.max;
    ushort[] _connectionList = null;
    bool _exclude = false;
    ubyte[] _data;

}

class PacketDefinition(T) : Packet
{

    static const string constructor = "this(Core core, ushort packet = ushort.max){super(core, packet);}";

    alias Data = T;

    this(Core core, ushort packet = ushort.max)
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;
        _core = core;
        header.packet = packet;
    }

    @property ref Data data()
    {
        return *(cast(Data*)_data);
    }

    void route(T1, T2)(T1 from, T2 to)
    {
        header.from = .to!PacketRoute(from);
        header.to = .to!PacketRoute(to);
        _routedFrom = true;
        _routedTo = true;
    }

    void respond(Packet other)
    {
        header.from = other.header.to;
        header.to = other.header.from;
        _routedFrom = true;
        _routedTo = true;
    }

    void routeFrom(T1)(T1 from)
    {
        header.from = .to!PacketRoute(from);
        _routedFrom = true;
    }

    void routeFrom(T1 : Packet)(T1 other)
    {
        header.from = other.header.to;
        _routedFrom = true;
    }

    void routeTo(T1)(T1 to)
    {
        header.from = .to!PacketRoute(from);
        header.to = .to!PacketRoute(to);
        _routedFrom = true;
        _routedTo = true;
    }

    void routeTo(T1 : Packet)(T1 other)
    {
        header.to = other.header.from;
        _routedTo = true;
    }

    void send()
    {
        assert(_core !is null);
        assert(routed, "The packet was not routed.");
        assert(!_sent, "Packet already sent.");
        verify();

        _sent = true;
        _core.packetQueue.queue(this);
    }

    void send(ubyte[] extra)
    {
        assert(_core !is null);
        assert(routed, "The packet was not routed.");
        assert(!_sent, "Packet already sent.");
        verify();

        _sent = true;
        _core.packetQueue.queue(this, extra);
    }

    void verify()
    {
    }

    override @property bool routed() const // TODO: remove this
    {
        return _routedFrom && _routedTo;
    }

    override @property bool allowDuplicate() const
    {
        return _allowDuplicate;
    }

    override @property void allowDuplicate(bool value)
    {
        _allowDuplicate = value;
    }

    override @property bool optimizeDuplicates() const
    {
        return _optimizeDuplicates;
    }

    override @property void optimizeDuplicates(bool value)
    {
        _optimizeDuplicates = value;
    }

    override @property bool trace() const
    {
        return _trace;
    }

    override @property void trace(bool value)
    {
        _trace = value;
    }

private:

    Core _core;
    bool _routedFrom = false;
    bool _routedTo = false;
    bool _sent = false;
    bool _allowDuplicate = false;
    bool _optimizeDuplicates = false;
    bool _trace = false;

}

struct PacketRoute
{

    RouteType type = RouteType.Auto;
    ushort index = ushort.max;

    this(RouteType route)
    {
        type = route;
    }

    this(RouteType route, ushort index)
    {
        this.type = route;
        this.index = index;
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

    PacketRoute to;
    PacketRoute from;

    void swap()
    {
        // TODO: endian swapping
    }

    string toString() const
    {
        string result;
        result ~= "PacketHeader(Magic: " ~ magic1 ~ magic2 ~ magic3 ~ magic4 ~ ", ";
        result ~= "Core: " ~ .to!string(core) ~ ", ";
        result ~= "Packet: " ~ .to!string(packet) ~ ", ";
        result ~= "Length: " ~ .to!string(length) ~ ")";
        return result;
    }
}

class PacketQueue
{

    void queue(T)(T packet)
        if (is(typeof(packet.header) == PacketHeader*) && is(typeof(packet.data.header) == PacketHeader))
    {
        assert(packet._sent, "Calling queue directly is deprecated, please use Packet.send().");

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
        assert(packet._sent, "Calling queue directly is deprecated, please use Packet.send(extra).");

        // TODO: endian swapping
        if (false)
        {
            packet.data.swap(true);
        }

        packet.header.length = to!ushort(packet._data.length + extra.length);
        packet.rawData ~= extra;
        _outbox ~= packet;
    }

    @property ref auto outbox()
    {
        return _outbox;
    }

    @property ref auto inbox()
    {
        return _inbox;
    }

private:

    Packet[] _outbox;
    Packet[] _inbox;

}

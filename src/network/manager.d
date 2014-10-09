module network.manager;

import network.action.core;
import network.action.listener;
import network.client.core;
import network.client.listener;
import network.connection;
import network.core;
import network.data.core;
import network.messaging;
import network.packetfactory;
import render.screen;
import settings;
import std.algorithm;
import std.conv;
import std.range;
import util.log;

enum ManagerType
{
    Server = 0,
    Client = 1
}

abstract class ManagerBase
{

    this(ManagerType type)
    {
        _type = type;

        _clientCore = new ClientCore;
        _dataCore = new DataCore(_clientCore);
        _actionCore = new ActionCore;

        _packetFactory = new PacketFactory(this);

        ushort index = 0;
        foreach (core; _cores)
        {
            core.setManagerType(type, index++);
        }

        ClientListener dcListener = _dataCore.createClientListener();
        _clientCore.addListener(dcListener);
    }

    void initCores(ManagerSettings settings)
    {
    }

    void init()
    {
    }

    void update()
    {
    }

    void updateBase()
    {
    }

    void shutdown()
    {
        foreach (core; _cores)
        {
            core.shutdown();
        }

        foreach (connection; _connections)
        {
            if (connection !is null)
            {
                connection.shutdown();
                connection = null;
            }
        }
    }

    ushort getConnectionCount()
    {
        return 0;
    }

    Connection getConnection(ushort index)
    {
        return null;
    }

    Connection getLocalConnection()
    {
        return null;
    }

    @property ClientCore clientCore()
    {
        return _clientCore;
    }

    @property DataCore dataCore()
    {
        return _dataCore;
    }

    @property ActionCore actionCore()
    {
        return _actionCore;
    }


    @property PacketFactory packetFactory()
    {
        return _packetFactory;
    }

    Packet[] receivePackets()
    {
        return null;
    }

    @property bool ready()
    {
        foreach (core; _cores)
        {
            if (!core.ready)
            {
                return false;
            }
        }
        return true;
    }

    ushort getFreeConnection()
    {
        return ushort.max;
    }

    void routePacket(Packet packet)
    {
        PacketHeader* header = packet.header;
        assert(packet.fromConnection != ushort.max);

        // Route to the correct core
        Core toCore;
        assert(header.core < _cores.length, "Core cannot be " ~ to!string(header.core));
        toCore = _cores[header.core];

        // Verify packet before sending
        assert(verifyPacket(packet));

        // Add to inbox
        toCore.packetQueue.inbox ~= packet;
    }

    bool verifyPacket(ref Packet packet)
    {
        bool isServer = _type == ManagerType.Server;
        bool isClient = _type == ManagerType.Client;

        assert(packet.header.from.type != RouteType.Auto);

        if (isServer)
        {
            assert(packet.header.from.type != RouteType.Server);
        }
        if (isClient)
        {
            assert(packet.header.from.type != RouteType.Connection);
        }

        if (packet.header.from.type == RouteType.Connection)
        {
            packet.header.from.index = packet.fromConnection;
        }

        foreach (core; _cores)
        {
            if (!core.verifyPacket(packet))
            {
                return false;
            }
        }
        return true;
    }

    bool applyRouting(ref Packet packet)
    {
        bool isServer = _type == ManagerType.Server;
        bool isClient = _type == ManagerType.Client;

        assert(packet.header.to.type != RouteType.Auto);

        // Bit of a sanity check, any automatic routing should not have an index
        if (packet.header.from.type == RouteType.Auto)
        {
            assert(packet.header.from.index == ushort.max);
        }

        if (packet.header.from.type == RouteType.Auto)
        {
            if (_type == ManagerType.Server)
            {
                packet.header.from.type = RouteType.Server;
                if (packet.trace) log("|   Resolving automatic routing to server");
            }
            else if (_type == ManagerType.Client)
            {
                packet.header.from.type = RouteType.Connection;
                if (packet.trace) log("|   Resolving automatic routing to connection");
            }
            else
            {
                assert(0);
            }
        }

        if (packet.header.to.type == RouteType.Connection)
        {
            packet.addConnection(packet.header.to.index);
            if (packet.trace) log("|   Routing directly to connection: ", packet.header.to.index);
        }

        if (packet.header.to.type == RouteType.AllConnections)
        {
            if (packet.trace) log("|   Routing to all connections");
            for (ushort i = 0, count = getConnectionCount(); i < count; i++)
            {
                Connection connection = getConnection(i);
                if (connection !is null)
                {
                    packet.addConnection(i);
                }
            }
        }

        if (packet.header.to.type == RouteType.AllConnectionsExcept)
        {
            if (packet.trace) log("|   Routing to all connections except ", packet.header.to.index);
            for (ushort i = 0, count = getConnectionCount(); i < count; i++)
            {
                Connection connection = getConnection(i);
                if (connection !is null && i != packet.header.to.index)
                {
                    packet.addConnection(i);
                }
            }
        }

        if (packet.header.to.type == RouteType.Server)
        {
            if (packet.trace) log("|   Routing to server");
            packet.addConnection(0);
        }

        foreach (core; _cores)
        {
            if (!core.applyRouting(packet))
            {
                return false;
            }
        }

        // Sanity checks
        if (packet.header.from.type == RouteType.Server)
        {
            assert(isServer);
        }
        if (packet.header.from.type == RouteType.Connection ||
            packet.header.from.type == RouteType.Client)
        {
            assert(isClient);
        }
        if (packet.header.to.type == RouteType.Connection ||
            packet.header.to.type == RouteType.Client)
        {
            assert(isServer);
        }
        if (packet.header.to.type == RouteType.Server)
        {
            assert(isClient);
        }

        return true;
    }

    PacketRoute applyRoutingTo(PacketRoute old, ushort connection, ushort duplicate)
    {
        PacketRoute route = old;
        foreach (core; _cores)
        {
            core.applyRoutingTo(route, connection, duplicate);
        }
        return route;
    }

    void sendMessage(Core fromCore, Packet packet)
    {
        PacketHeader* header = packet.header;

        // Apply routing
        if (packet.trace) log("| Performing routing...");
        assert(applyRouting(packet), "Routing failed.");

        // Verify cores send to themselves
        // This also verifies the core ID's are correct
        assert(header.core == fromCore.id);

        // Assert that a packet's ID is not invalid
        assert(header.packet != ushort.max);

        if (packet.trace) log("| About to send, ", packet.allowDuplicate ? "allowing duplicates" : "asserting no duplicates", "...");
        Connection toConnection;
        PacketRoute oldTo = packet.header.to;
        ushort duplicate = 0;
        ushort last = ushort.max;
        auto list = packet.connectionList.sort;
        foreach (i; list)
        {
            toConnection = getConnection(i);
            assert(toConnection !is null, packet.header.toString());
            if (toConnection !is null)
            {
                if (i == last)
                {
                    duplicate++;
                    assert(packet.allowDuplicate || packet.optimizeDuplicates);
                }
                else
                {
                    duplicate = 0;
                }
                last = i;
                packet.header.to = applyRoutingTo(oldTo, i, duplicate);
                if (duplicate == 0 || !packet.optimizeDuplicates)
                {
                    toConnection.send(packet.rawData);
                    if (packet.trace) log("| Sent to connection ", i);
                }
                else if (duplicate != 0 && packet.trace)
                {
                    log("| Optimizing multiple sends to ", i);
                }
            }
        }
    }

    void processInbox()
    {
        // Receive network messages
        Packet[] packets = receivePackets();
        foreach (Packet packet; packets)
        {
            routePacket(packet);
        }

        foreach (core; _cores)
        {
            core.processInbox();
        }
    }

    void processOutbox()
    {
        // Send messages
        foreach (ushort coreID, core; _cores)
        {
            PacketQueue queue = core.packetQueue;
            foreach (Packet packet; queue.outbox)
            {
                // Ensure cores send to themselves
                packet.header.core = coreID;

                if (packet.trace) log("Sending Packet ", *(cast(void**)&packet), " (", packet.header.toString(), ")...");
                sendMessage(core, packet);
                if (packet.trace) log("Packet ", *(cast(void**)&packet), " sent!");
            }
            queue.outbox.length = 0;
        }
    }

protected:

    ManagerType _type;

    union
    {
        struct
        {
            ClientCore _clientCore;
            DataCore _dataCore;
            ActionCore _actionCore;
        }
        Core[3] _cores;
    }

    Connection[] _connections;
    Connection _listener;

    PacketFactory _packetFactory;

}


class Manager(ManagerType type) : ManagerBase
{

    static const bool isServer = type == type.Server;
    static const bool isClient = type == type.Client;

    invariant()
    {
        static if (isClient)
        {
            // The client should only ever have one connection
            assert(_connections.length == 1);
        }
    }

    this()
    {
        super(type);

        if (isClient)
        {
            // The client only has one connection (with the server)
            _connections.length = 1;
        }
    }

    static if (type == ManagerType.Client)
    {

        void connect(string host, ushort port)
        {
            log("Connecting to ", host, ":", port, "...");
            _connections[0] = new Connection(0);
            assert(_connections[0].connect(host, port), "Failed to connect to " ~ host ~ ":" ~ to!string(port));
            log("Connected!");
        }

    }
    else
    {

        bool listen(ushort port)
        {
            assert(!_listener);
            log("Binding to port...");
            _listener = new Connection(ushort.max);
            if (_listener.listen(port))
            {
                log("Listening on port ", port, "!");
                return true;
            }
            _listener = null;
            log("Failed to listen on port ", port, ".");
            return false;
        }

        void setMaxConnections(ushort count)
        {
            assert(count != 0);

            foreach (connection; _connections)
            {
                assert(!connection);
            }

            _connections.length = count;
        }

    }

    void connect(ManagerBase other)
    {
        ushort index = getFreeConnection();
        ushort otherIndex = other.getFreeConnection();
        assert(index != ushort.max);
        assert(otherIndex != ushort.max);

        Connection.makeLocalConnection(_connections[index], index, other._connections[otherIndex], otherIndex);
    }

    override void init()
    {
    }

    override void initCores(ManagerSettings settings)
    {
        foreach (core; _cores)
        {
            core.init(settings);
        }
    }

    private bool _lastReady = false;
    override void update()
    {
        static if (isServer)
        {
            if (_listener)
            {
                // Accept new connections
                ushort index = getFreeConnection();
                Connection newConnection = _listener.accept(index);

                if (newConnection)
                {
                    // Server full, kick client
                    if (index == ushort.max)
                    {
                        assert(0, "TODO: kick when server is full");
                    }
                    else
                    {
                        _connections[index] = newConnection;
                    }
                }
            }
        }

        foreach (core; _cores)
        {
            core.update();
        }

        if (ready && !_lastReady)
        {
            init();
            _lastReady = true;
        }
    }

    override ushort getConnectionCount()
    {
        return to!ushort(_connections.length);
    }

    override Connection getConnection(ushort index)
    {
        if (index < _connections.length)
        {
            return _connections[index];
        }
        else
        {
            return null;
        }
    }

    override Connection getLocalConnection()
    {
        foreach (connection; _connections)
        {
            if (connection && connection.local)
            {
                return connection;
            }
        }
        return null;
    }

    override ushort getFreeConnection()
    {
        ushort index = ushort.max;
        for (ushort i = 0; i < _connections.length; i++)
        {
            if (_connections[i] is null)
            {
                index = i;
                break;
            }
        }
        return index;
    }

    override Packet[] receivePackets()
    {
        // A resulting list of packets
        Packet[] data = null;

        // Iterate over all the active connections
        for (ushort i = 0; i < _connections.length; i++)
        {

            // Get the current connection object
            Connection con = _connections[i];
            if (con)
            {
                // Receive all packets from the socket
                while (con.receive())
                {
                }

                if (con.connected)
                {
                    while (con.packetData.length >= PacketHeader.sizeof)
                    {
                        // Check magic data
                        for (int j = 0; j < con.packetData.length && j < 4; j++)
                        {
                            switch (j)
                            {
                                case 0: assert(con.packetData[j] == 'Q', "Bad magic"); break;
                                case 1: assert(con.packetData[j] == 'v', "Bad magic"); break;
                                case 2: assert(con.packetData[j] == 'e', "Bad magic"); break;
                                case 3: assert(con.packetData[j] == 'r', "Bad magic"); break;
                                default: break;
                            }
                        }
                        PacketHeader* header = cast(PacketHeader*)con.packetData;
                        if (header.length <= con.packetData.length)
                        {
                            Packet newPacket = new Packet(con.packetData[0 .. header.length].dup);
                            newPacket.fromConnection = con.id;
                            data ~= newPacket;
                            con.packetData = con.packetData[header.length .. $];
                        }
                        else
                        {
                            break;
                        }
                    }
                }
                else
                {
                    static if (isServer)
                    {
                        foreach (core; _cores)
                        {
                            core.connectionDied(i);
                        }
                        _connections[i] = null;
                    }
                    static if (isClient)
                    {
                        assert(0, "TODO: properly disconnect");
                    }
                }
            }
        }

        return data;
    }

}

alias GameManager = Manager!(ManagerType.Server);
alias ClientManager = Manager!(ManagerType.Client);

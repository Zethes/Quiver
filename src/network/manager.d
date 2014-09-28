module network.manager;

import network.action.core;
import network.action.listener;
import network.client.core;
import network.client.listener;
import network.connection;
import network.core;
import network.data.core;
import network.messaging;
import render.screen;
import settings;
import std.algorithm;
import std.conv;
import std.range;
import util.log;

enum ManagerType
{
    SERVER = 0,
    CLIENT = 1
}

class ClientGroup
{

    @property uint index() const
    {
        return _index;
    }

    @property size_t size() const
    {
        return _list.length;
    }

    ushort[] clientArray()
    {
        return _list.dup;
    }

    void appendClient(ushort client)
    {
        if (!assumeSorted(_list).contains(client))
        {
            _list ~= client;
            sort(_list);
        }
    }

    void removeClient(ushort index)
    {
        for (size_t i = 0; i < _list.length; i++)
        {
            if (_list[i] == index)
            {
                _list = remove(_list, i);
                break;
            }
        }
    }

private:

    uint _index;

    this(uint index)
    {
        _index = index;
    }

    ushort[] _list;

}

class GroupController
{

    this(ManagerBase parent, uint* counter)
    {
        _parent = parent;
        _counter = counter;
    }

    ClientGroup createGroup()
    {
        uint index = (*_counter)++;
        ClientGroup group = new ClientGroup(index);
        _parent._groups[index] = group;
        return group;
    }

    void clientDied(ushort index)
    {
        foreach (value; _parent._groups.values)
        {
            value.removeClient(index);
        }
    }

private:

    ManagerBase _parent;
    uint* _counter;

}


abstract class ManagerBase
{

    this(ManagerType type)
    {
        _clientCore = new ClientCore;
        _dataCore = new DataCore;
        _actionCore = new ActionCore;

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

    @property GroupController groupController()
    {
        return _groupController;
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
        assert(packet.from != ushort.max);

        // Route to the correct core
        Core toCore;
        assert(header.core < _cores.length, "Core cannot be " ~ to!string(header.core));
        toCore = _cores[header.core];

        // Add to inbox
        toCore.packetQueue.inbox ~= packet;
    }

    void sendMessage(Core fromCore, Packet packet)
    {
        PacketHeader* header = packet.header;

        // Client always sends to their one connection (the server)
        if (fromCore.isClient && packet.to == ushort.max)
        {
            packet.to = 0;
        }

        // Ensure cores send to themselves
        header.core = fromCore.id;

        // Get the connection to send to
        Connection toConnection = getConnection(packet.to);

        // Find group
        bool doFilter = false;
        ushort[] filter = null;
        if (packet.toGroup != uint.max)
        {
            ClientGroup* group = packet.toGroup in _groups;
            if (group)
            {
                doFilter = true;
                filter = group.clientArray;
            }
        }

        if (packet.exclude || packet.to == ushort.max)
        {
            for (ushort i = 0; i < getConnectionCount(); i++)
            {
                if (!doFilter || assumeSorted(filter).contains(i))
                {
                    toConnection = getConnection(i);
                    if (toConnection && i != packet.to)
                    {
                        toConnection.send(packet.rawData);
                    }
                }
            }
        }
        else
        {
            toConnection.send(packet.rawData);
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
        foreach (core; _cores)
        {
            PacketQueue queue = core.packetQueue;
            foreach (Packet packet; queue.outbox)
            {
                sendMessage(core, packet);
            }
            queue.outbox.length = 0;
        }
    }

protected:

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
    GroupController _groupController;

    Connection[] _connections;
    Connection _listener;

    ClientGroup[uint] _groups;
    uint _nextGroupIndex;

}


class Manager(ManagerType type) : ManagerBase
{

    static const bool isServer = type == type.SERVER;
    static const bool isClient = type == type.CLIENT;

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

    static if (type == ManagerType.CLIENT)
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
        _groupController = new GroupController(this, &_nextGroupIndex);

        foreach (core; _cores)
        {
            core.setControllers(_groupController);
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
        for (ushort i = 0; i < index; i++)
        {
            if (!_connections[i])
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
                            newPacket.from = con.id;
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
                        ushort[] clients = clientCore.getClientsByConnection(i);
                        foreach (client; clients)
                        {
                            groupController.clientDied(client);
                        }

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

alias GameManager = Manager!(ManagerType.SERVER);
alias ClientManager = Manager!(ManagerType.CLIENT);

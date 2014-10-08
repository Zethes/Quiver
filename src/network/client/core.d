module network.client.core;

import network.client.listener;
import network.core;
import network.messaging;
import settings;
import std.algorithm;
import std.conv;
import std.range;
import util.log;

class Client
{
    this(char[] name, ushort index, ushort connection = ushort.max)
    {
        _name = new char[name.length];
        _index = index;
        for (int i = 0; i < name.length; i++)
        {
            _name[i] = name[i];
        }
        _connection = connection;
    }

    @property const(char[]) name() const
    {
        return _name;
    }

    @property ushort index() const
    {
        return _index;
    }

    @property ushort connection() const
    {
        return _connection;
    }

    auto opCast(PacketRoute)()
    {
        return PacketRoute(RouteType.Client, _index);
    }

private:

    char[] _name;
    ushort _index;
    ushort _connection;

}

class ClientGroup
{

    @property ushort index() const
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
            _list = _list.sort;
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

    bool hasClient(ushort client)
    {
        return assumeSorted(_list).contains(client);
    }

    auto opCast(PacketRoute)() const
    {
        return PacketRoute(RouteType.ClientGroup, _index);
    }

private:

    ushort _index;

    this(ushort index)
    {
        _index = index;
    }

    ushort[] _list;

}

class ClientCore : Core
{

    override void init(ManagerSettings settings)
    {
        if (isClient)
        {
            auto packet = newInit();
            packet.route(Route.connection, Route.server);
            packet.send();
        }
        else
        {
            maxClients = settings.client.maxClients;
            _ready = true;
        }
    }

    private auto newInit()
    {
        return new PacketInit(this, PACKET_INIT);
    }

    private auto newInitResponse()
    {
        return new PacketInitResponse(this, PACKET_INIT_RESPONSE);
    }

    auto newClientRegister()
    {
        return new PacketRegister(this, PACKET_REGISTER);
    }

    auto newClientRegisterResponse()
    {
        return new PacketRegisterResponse(this, PACKET_REGISTER_RESPONSE);
    }

    auto newClientJoin()
    {
        return new PacketClientJoin(this, PACKET_CLIENT_JOIN);
    }

    auto newClientLeft()
    {
        return new PacketClientLeft(this, PACKET_CLIENT_LEFT);
    }

    override @property bool ready()
    {
        return _ready;
    }

    void registerClient(string name) // TODO: deprecate this
    {
        assert(isClient);

        auto packet = newClientRegister();
        assert(name.length <= packet.data.name.length);

        packet.route(Route.connection, Route.server);
        packet.data.nameLength = cast(ubyte)name.length;
        packet.data.name[0 .. name.length] = name;
        packet.send();
    }

    @property ushort maxClients() const
    {
        return cast(ushort)_clients.length;
    }

    @property void maxClients(ushort value)
    {
        foreach (client; _clients)
        {
            assert(!client, "Cannot change max clients while clients are connected.");
        }

        _clients.length = value;
    }

    ushort getNextSlot()
    {
        ushort index = ushort.max;
        for (ushort i = 0; i < maxClients; i++)
        {
            if (!_clients[i])
            {
                index = i;
                break;
            }
        }
        return index;
    }

    override void connectionDied(ushort index)
    {
        assert(isServer);

        ushort[] deadClients = getClientsByConnection(index);
        foreach (client; deadClients)
        {
            clientDied(client);
        }
    }

    void clientDied(ushort index)
    {
        foreach (value; _groups.values)
        {
            value.removeClient(index);
        }

        foreach (ushort i, client; _clients)
        {
            if (client !is null)
            {
                if (_clients[i].connection == index)
                {
                    auto left = newClientLeft();
                    left.route(Route.server, Route.allConnectionsExcept(index));
                    left.data.index = index;
                    left.send();

                    ClientLeftEvent event;
                    event.index = index;
                    _listen.fire!"onClientLeft"(event);

                    _clients[i] = null;
                }
            }
        }
    }

    ushort[] getClientsByConnection(ushort index)
    {
        assert(isServer);

        ushort[] clients = null;
        for (ushort i = 0; i < _clients.length; i++)
        {
            if (_clients[i])
            {
                if (_clients[i].connection == index)
                {
                    clients ~= i;
                }
            }
        }
        return clients;
    }

    override void processPacket(Packet packet)
    {
        switch (packet.header.packet)
        {
            case PACKET_INIT:
                assert(packet.length == PacketInit.Data.sizeof);
                processPacket(packet, *(cast(PacketInit.Data*)packet.rawData));
                break;
            case PACKET_INIT_RESPONSE:
                assert(packet.length == PacketInitResponse.Data.sizeof);
                processPacket(packet, *(cast(PacketInitResponse.Data*)packet.rawData));
                break;
            case PACKET_REGISTER:
                assert(packet.length == PacketRegister.Data.sizeof);
                processPacket(packet, *(cast(PacketRegister.Data*)packet.rawData));
                break;
            case PACKET_REGISTER_RESPONSE:
                assert(packet.length == PacketRegisterResponse.Data.sizeof);
                processPacket(packet, *(cast(PacketRegisterResponse.Data*)packet.rawData));
                break;
            case PACKET_CLIENT_JOIN:
                assert(packet.length == PacketClientJoin.Data.sizeof);
                processPacket(packet, *(cast(PacketClientJoin.Data*)packet.rawData));
                break;
            case PACKET_CLIENT_LEFT:
                assert(packet.length == PacketClientLeft.Data.sizeof);
                processPacket(packet, *(cast(PacketClientLeft.Data*)packet.rawData));
                break;
            default:
                assert(0);
        }
    }

    void processPacket(Packet packet, PacketInit.Data data)
    {
        assert(isServer);

        auto response = newInitResponse();
        response.respond(packet);
        response.data.maxClients = maxClients;
        response.send();

        for (ushort i = 0; i < _clients.length; i++)
        {
            if (_clients[i])
            {
                auto join = newClientJoin();
                join.respond(packet);
                join.data.index = i;
                join.data.nameLength = cast(ubyte)_clients[i].name.length;
                join.data.name[0 .. _clients[i].name.length] = _clients[i].name;
                join.data.existing = true;
                join.send();
            }
        }
    }

    void processPacket(Packet packet, PacketInitResponse.Data data)
    {
        assert(isClient);

        maxClients = data.maxClients;

        _ready = true;
    }

    void processPacket(Packet packet, PacketRegister.Data data)
    {
        assert(isServer);

        auto response = newClientRegisterResponse();
        response.respond(packet);

        ushort index = getNextSlot();
        char[] acceptedName;
        if (index != ushort.max)
        {
            acceptedName = data.name[0 .. data.nameLength];
            acceptedName ~= " ";
            acceptedName ~= to!string(index + 1);

            response.data.accepted = true;
            _clients[index] = new Client(acceptedName, index, packet.fromConnection);
            response.data.nameLength = cast(ubyte)acceptedName.length;
            response.data.name[0 .. acceptedName.length] = acceptedName;
        }
        else
        {
            response.data.accepted = false;
        }

        response.data.index = index;
        response.send();

        // tell everyone else about this
        if (index != ushort.max)
        {
            auto join = newClientJoin();
            join.route(Route.server, Route.allConnectionsExcept(packet.fromConnection));
            join.data.index = index;
            join.data.nameLength = cast(ubyte)acceptedName.length;
            join.data.name[0 .. acceptedName.length] = acceptedName[0 .. acceptedName.length];
            join.data.existing = false;
            join.send();

            ClientJoinEvent event;
            event.index = index;
            event.existing = false;
            _listen.fire!"onClientJoin"(event);
        }
    }

    void processPacket(Packet packet, PacketRegisterResponse.Data data)
    {
        assert(isClient);

        if (data.accepted)
        {
            _clients[data.index] = new Client(data.name[0 .. data.nameLength], data.index);
        }

        ClientRegisteredEvent event;
        event.index = data.index;
        event.accepted = data.accepted;
        _listen.fire!"onClientRegistered"(event);
    }

    void processPacket(Packet packet, PacketClientJoin.Data data)
    {
        _clients[data.index] = new Client(data.name[0 .. data.nameLength], data.index);

        ClientJoinEvent event;
        event.index = data.index;
        event.existing = data.existing;
        _listen.fire!"onClientJoin"(event);
    }

    void processPacket(Packet packet, PacketClientLeft.Data data)
    {
        ClientLeftEvent event;
        event.index = data.index;
        _listen.fire!"onClientLeft"(event);

        _clients[data.index] = null;
    }

    override bool verifyPacket(ref Packet packet)
    {
        assert(packet.header.from.type != RouteType.AllClients);
        assert(packet.header.from.type != RouteType.AllClientsExcept);
        assert(packet.header.from.type != RouteType.ClientGroup);

        if (packet.header.from.type == RouteType.Client)
        {
            Client client = getClient(packet.header.from.index);
            if (client !is null)
            {
                // Verify that the connection sending this owns the client they claim to control
                if (client.connection != packet.fromConnection)
                {
                    return false;
                }
            }
            else
            {
                return false;
            }
        }
        return true;
    }

    override bool applyRouting(ref Packet packet)
    {
        if (isServer)
        {
            if (packet.header.to.type == RouteType.Client)
            {
                if (packet.trace) log("|   Routing directly to client: ", packet.header.to.index);
                Client client = getClient(packet.header.to.index);
                assert(client !is null);
                packet.addConnection(client.connection);
                if (packet.trace) log("|     Client: ", packet.header.to.index, ", Connection: ", client.connection);
            }

            if (packet.header.to.type == RouteType.AllClients)
            {
                if (packet.trace) log("|   Routing to all clients...");
                assert(packet.header.to.index == ushort.max);
                foreach (client; _clients)
                {
                    if (client !is null)
                    {
                        packet.addConnection(client.connection);
                        if (packet.trace) log("|     Client: ", client.index, ", Connection: ", client.connection);
                    }
                }
            }

            if (packet.header.to.type == RouteType.AllClientsExcept)
            {
                if (packet.trace) log("|   Routing to all clients except", packet.header.to.index, "...");
                assert(packet.header.to.index != ushort.max);
                foreach (client; _clients)
                {
                    if (client !is null && client.index != packet.header.to.index)
                    {
                        packet.addConnection(client.connection);
                        if (packet.trace) log("|     Client: ", client.index, ", Connection: ", client.connection);
                    }
                }
            }

            if (packet.header.to.type == RouteType.ClientGroup)
            {
                if (packet.trace) log("|   Routing to all client group ", packet.header.to.index, "...");
                assert(packet.header.to.index != ushort.max);
                ClientGroup* group = packet.header.to.index in _groups;
                assert(group !is null);
                foreach (client; group.clientArray)
                {
                    Client clientObj = getClient(client);
                    assert(clientObj !is null);
                    packet.addConnection(clientObj.connection);
                    if (packet.trace) log("|     Client: ", client, ", Connection: ", clientObj.connection);
                }
            }
        }
        else
        {
            // A client cannot send to another client, must go through server
            assert(packet.header.to.type != RouteType.Client);
            assert(packet.header.to.type != RouteType.AllClients);
            assert(packet.header.to.type != RouteType.AllClientsExcept);
            assert(packet.header.to.type != RouteType.ClientGroup);
        }
        return true;
    }

    override void applyRoutingTo(ref PacketRoute route, ushort connection, ushort duplicate)
    {
        if (route.type == RouteType.ClientGroup)
        {
            // Get clients from the connection
            ushort[] clients = getClientsByConnection(connection);

            // Get the client group
            ClientGroup group = _groups[route.index];
            assert(group !is null);

            // Determine which of these connections are in the client group
            ushort[] candidates = null;
            foreach (client; clients)
            {
                if (group.hasClient(client))
                {
                    candidates ~= client;
                }
            }

            route = PacketRoute(RouteType.Client, candidates[duplicate]);
        }
    }

    @property string connectedClients()
    {
        string result = "";
        foreach (client; _clients)
        {
            if (client)
            {
                result ~= client.name ~ "\n";
            }
        }
        return result;
    }

    Client getClient(ushort index)
    {
        return _clients[index];
    }

    void addListener(ClientListener listener)
    {
        _listen.addListener(listener);
    }

    void removeListener(ClientListener listener)
    {
        _listen.removeListener(listener);
    }

    ClientGroup createGroup()
    {
        ushort index = _nextGroupIndex++;
        ClientGroup group = new ClientGroup(index);
        _groups[index] = group;
        return group;
    }

    void removeGroupClient(ushort index)
    {
        foreach (value; _groups.values)
        {
            value.removeClient(index);
        }
    }

private:

    bool _ready = false;
    Client[] _clients;

    ListenManager!ClientListener _listen;

    ClientGroup[ushort] _groups;
    ushort _nextGroupIndex;

}

enum
{
    PACKET_INIT,
    PACKET_INIT_RESPONSE,
    PACKET_REGISTER,
    PACKET_REGISTER_RESPONSE,
    PACKET_CLIENT_JOIN,
    PACKET_CLIENT_LEFT
}

struct PacketInitData
{

    PacketHeader header;

    void swap(bool swapHeader)
    {
        if (swapHeader)
        {
            header.swap();
        }

        // TODO: endian swapping
    }
}
alias PacketInit = PacketDefinition!PacketInitData;

struct PacketInitResponseData
{

    PacketHeader header;
    ushort maxClients;

    void swap(bool swapHeader)
    {
        if (swapHeader)
        {
            header.swap();
        }

        // TODO: endian swapping
    }

}
alias PacketInitResponse = PacketDefinition!PacketInitResponseData;

struct PacketRegisterData
{

    PacketHeader header;
    ubyte nameLength;
    char[32] name;

    void swap(bool swapHeader)
    {
        if (swapHeader)
        {
            header.swap();
        }

        // TODO: endian swapping
    }

}
alias PacketRegister = PacketDefinition!PacketRegisterData;

struct PacketRegisterResponseData
{

    PacketHeader header;
    bool accepted;
    ushort index;
    ubyte nameLength;
    char[32] name;

    void swap(bool swapHeader)
    {
        if (swapHeader)
        {
            header.swap();
        }

        // TODO: endian swapping
    }

}
alias PacketRegisterResponse = PacketDefinition!PacketRegisterResponseData;

struct PacketClientJoinData
{

    PacketHeader header;
    ushort index;
    ubyte nameLength;
    char[32] name;
    bool existing;

    void swap(bool swapHeader)
    {
        if (swapHeader)
        {
            header.swap();
        }

        // TODO: endian swapping
    }

}
alias PacketClientJoin = PacketDefinition!PacketClientJoinData;

struct PacketClientLeftData
{

    PacketHeader header;
    ushort index;

    void swap(bool swapHeader)
    {
        if (swapHeader)
        {
            header.swap();
        }

        // TODO: endian swapping
    }

}
alias PacketClientLeft = PacketDefinition!PacketClientLeftData;

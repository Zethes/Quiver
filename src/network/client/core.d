module network.client.core;

import network.client.listener;
import network.core;
import network.messaging;
import settings;
import std.conv;
import util.log;

class Client
{
    this(char[] name, ushort connection = ushort.max)
    {
        _name = new char[name.length];
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

    @property ushort connection() const
    {
        return _connection;
    }

private:

    char[] _name;
    ushort _connection;

}

class ClientCore : Core
{

    override void init(ManagerSettings settings)
    {
        if (isClient)
        {
            auto packet = new PacketInit;
            packetQueue.queue(packet);
        }
        else
        {
            maxClients = settings.client.maxClients;
            _ready = true;
        }
    }

    override @property bool ready()
    {
        return _ready;
    }

    void registerClient(string name)
    {
        assert(isClient);

        auto packet = new PacketRegister;
        assert(name.length <= packet.data.name.length);

        packet.data.nameLength = cast(ubyte)name.length;
        packet.data.name[0 .. name.length] = name;
        packetQueue.queue(packet);
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

        for (ushort i = 0; i < _clients.length; i++)
        {
            if (_clients[i])
            {
                if (_clients[i].connection == index)
                {
                    auto left = new PacketClientLeft;
                    left.data.index = index;
                    packetQueue.queue(left);

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

    override void processPacket(PacketBase packet)
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
                break;
        }
    }

    void processPacket(PacketBase packet, PacketInit.Data data)
    {
        assert(isServer);

        auto response = new PacketInitResponse(packet.from);
        response.data.maxClients = maxClients;
        packetQueue.queue(response);

        for (ushort i = 0; i < _clients.length; i++)
        {
            if (_clients[i])
            {
                auto join = new PacketClientJoin(packet.from);
                join.data.index = i;
                join.data.nameLength = cast(ubyte)_clients[i].name.length;
                join.data.name[0 .. _clients[i].name.length] = _clients[i].name;
                join.data.existing = true;
                packetQueue.queue(join);
            }
        }
    }

    void processPacket(PacketBase packet, PacketInitResponse.Data data)
    {
        assert(isClient);

        maxClients = data.maxClients;

        _ready = true;
    }

    void processPacket(PacketBase packet, PacketRegister.Data data)
    {
        assert(isServer);

        auto response = new PacketRegisterResponse(packet.from);

        ushort index = getNextSlot();
        char[] acceptedName;
        if (index != ushort.max)
        {
            acceptedName = data.name[0 .. data.nameLength];
            acceptedName ~= " ";
            acceptedName ~= to!string(index + 1);

            response.data.accepted = true;
            _clients[index] = new Client(acceptedName, packet.from);
            response.data.nameLength = cast(ubyte)acceptedName.length;
            response.data.name[0 .. acceptedName.length] = acceptedName;
        }
        else
        {
            response.data.accepted = false;
        }

        response.data.index = index;
        packetQueue.queue(response);

        // tell everyone else about this
        if (index != ushort.max)
        {
            auto join = new PacketClientJoin(packet.from);
            join._exclude = true;
            join.data.index = index;
            join.data.nameLength = cast(ubyte)acceptedName.length;
            join.data.name[0 .. acceptedName.length] = acceptedName[0 .. acceptedName.length];
            join.data.existing = false;
            packetQueue.queue(join);

            ClientJoinEvent event;
            event.index = index;
            event.existing = false;
            _listen.fire!"onClientJoin"(event);
        }
    }

    void processPacket(PacketBase packet, PacketRegisterResponse.Data data)
    {
        assert(isClient);

        if (data.accepted)
        {
            _clients[data.index] = new Client(data.name[0 .. data.nameLength]);
        }

        ClientRegisteredEvent event;
        event.index = data.index;
        event.accepted = data.accepted;
        _listen.fire!"onClientRegistered"(event);
    }

    void processPacket(PacketBase packet, PacketClientJoin.Data data)
    {
        _clients[data.index] = new Client(data.name[0 .. data.nameLength]);

        ClientJoinEvent event;
        event.index = data.index;
        event.existing = data.existing;
        _listen.fire!"onClientJoin"(event);
    }

    void processPacket(PacketBase packet, PacketClientLeft.Data data)
    {
        ClientLeftEvent event;
        event.index = data.index;
        _listen.fire!"onClientLeft"(event);

        _clients[data.index] = null;
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

private:

    bool _ready = false;
    Client[] _clients;

    ListenManager!ClientListener _listen;

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

class PacketInit : Packet!PacketInitData
{

    this()
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_INIT;
    }

}

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

class PacketInitResponse : Packet!PacketInitResponseData
{

    this(ushort to)
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_INIT_RESPONSE;
        _to = to;
    }

}

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

class PacketRegister : Packet!PacketRegisterData
{

    this()
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_REGISTER;
    }

}

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

class PacketRegisterResponse : Packet!PacketRegisterResponseData
{

    this(ushort to)
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_REGISTER_RESPONSE;
        _to = to;
    }

}

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

class PacketClientJoin : Packet!PacketClientJoinData
{

    this(ushort to)
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_CLIENT_JOIN;
        _to = to;
    }

}

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

class PacketClientLeft : Packet!PacketClientLeftData
{

    this()
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_CLIENT_LEFT;
    }

}

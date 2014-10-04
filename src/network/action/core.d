module network.action.core;

import network.action.listener;
import network.core;
import network.messaging;
import settings;
import util.log;

class ActionCore : Core
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
            _ready = true;
        }
    }

    void ping(uint unique, ushort to = ushort.max)
    {
        auto packet = new PacketActionPing;
        packet.to = to;
        packet.data.unique = unique;
        packetQueue.queue(packet);
    }

    void sendKey(int key)
    {
        assert(isClient);

        auto packet = new PacketActionKey;
        packet.data.key = key;
        packetQueue.queue(packet);
    }

    override @property bool ready()
    {
        return _ready;
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
            case PACKET_ACTION_PING:
                assert(packet.length == PacketActionPing.Data.sizeof);
                processPacket(packet, *(cast(PacketActionPing.Data*)packet.rawData));
                break;
            case PACKET_ACTION_KEY:
                assert(packet.length == PacketActionKey.Data.sizeof);
                processPacket(packet, *(cast(PacketActionKey.Data*)packet.rawData));
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
        packetQueue.queue(response);
    }

    void processPacket(PacketBase packet, PacketInitResponse.Data data)
    {
        assert(isClient);

        _ready = true;
    }

    void processPacket(PacketBase packet, PacketActionPing.Data data)
    {
        if (data.pong)
        {
            ActionPongEvent event;
            event.unique = data.unique;
            _listen.fire!"onActionPong"(event);

            if (event.repeat)
            {
                auto ping = new PacketActionPing;
                ping.to = packet.from;
                ping.data.unique = data.unique;
                packetQueue.queue(ping);
            }
        }
        else
        {
            ActionPingEvent event;
            event.unique = data.unique;
            _listen.fire!"onActionPing"(event);

            if (!event.cancel)
            {
                auto pong = new PacketActionPing;
                pong.to = packet.from;
                pong.data.unique = data.unique;
                pong.data.pong = true;
                packetQueue.queue(pong);
            }
        }
    }

    void processPacket(PacketBase packet, PacketActionKey.Data data)
    {
        assert(isServer);

        ActionKeyEvent event;
        event.client = packet.from;
        event.key = data.key;
        _listen.fire!"onActionKey"(event);
    }

    override void update()
    {
    }

    void addListener(ActionListener listener)
    {
        _listen.addListener(listener);
    }

    void removeListener(ActionListener listener)
    {
        _listen.removeListener(listener);
    }

private:

    bool _ready = false;

    ListenManager!ActionListener _listen;

}

enum
{
    PACKET_INIT          = 0,
    PACKET_INIT_RESPONSE = 1,
    PACKET_ACTION_PING   = 2,
    PACKET_ACTION_KEY    = 3
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

struct PacketActionPingData
{

    PacketHeader header;
    uint unique = uint.max;
    bool pong = false;

    void swap(bool swapHeader)
    {
        if (swapHeader)
        {
            header.swap();
        }

        // TODO: endian swapping
    }

}

class PacketActionPing : Packet!PacketActionPingData
{

    this()
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_ACTION_PING;
    }

}

struct PacketActionKeyData
{

    PacketHeader header;
    int key;

    void swap(bool swapHeader)
    {
        if (swapHeader)
        {
            header.swap();
        }

        // TODO: endian swapping
    }

}

class PacketActionKey : Packet!PacketActionKeyData
{

    this()
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_ACTION_KEY;
    }

}

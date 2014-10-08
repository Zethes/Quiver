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
            auto packet = newInit();
            packet.route(Route.connection, Route.server);
            packet.send();
        }
        else
        {
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

    auto newActionPing()
    {
        return new PacketActionPing(this, PACKET_ACTION_PING);
    }

    auto newActionKey()
    {
        return new PacketActionKey(this, PACKET_ACTION_KEY);
    }

    override @property bool ready()
    {
        return _ready;
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
        }
    }

    void processPacket(Packet packet, PacketInit.Data data)
    {
        assert(isServer);

        auto response = newInitResponse();
        response.respond(packet);
        response.send();
    }

    void processPacket(Packet packet, PacketInitResponse.Data data)
    {
        assert(isClient);

        _ready = true;
    }

    void processPacket(Packet packet, PacketActionPing.Data data)
    {
        if (data.pong)
        {
            ActionPongEvent event;
            event.unique = data.unique;
            _listen.fire!"onActionPong"(event);

            if (event.repeat)
            {
                auto ping = newActionPing();
                ping.respond(packet);
                ping.data.unique = data.unique;
                ping.send();
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
                auto pong = newActionPing();
                pong.respond(packet);
                pong.data.unique = data.unique;
                pong.data.pong = true;
                pong.send();
            }
        }
    }

    void processPacket(Packet packet, PacketActionKey.Data data)
    {
        assert(isServer);
        assert(data.header.from.type == RouteType.Client);

        ActionKeyEvent event;
        event.client = data.header.from.index;
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

private enum
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
alias PacketInit = PacketDefinition!PacketInitData;

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
alias PacketInitResponse = PacketDefinition!PacketInitResponseData;

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
alias PacketActionPing = PacketDefinition!PacketActionPingData;

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
alias PacketActionKey = PacketDefinition!PacketActionKeyData;

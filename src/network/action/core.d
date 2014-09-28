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
            case PACKET_ACTION_KEY:
                assert(packet.length == PacketActionKey.Data.sizeof);
                processPacket(packet, *(cast(PacketActionKey.Data*)packet.rawData));
                break;
            default:
                assert(0);
                break;
        }
    }

    void processPacket(Packet packet, PacketInit.Data data)
    {
        assert(isServer);

        auto response = new PacketInitResponse(packet.from);
        packetQueue.queue(response);
    }

    void processPacket(Packet packet, PacketInitResponse.Data data)
    {
        assert(isClient);

        _ready = true;
    }

    void processPacket(Packet packet, PacketActionKey.Data data)
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
    PACKET_ACTION_KEY    = 2
}

class PacketInit : Packet
{

    this()
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_INIT;
    }

    struct Data
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

    @property ref Data data()
    {
        return *(cast(Data*)_data);
    }

}

class PacketInitResponse : Packet
{
    this(ushort to)
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_INIT_RESPONSE;
        _to = to;
    }

    struct Data
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

    @property ref Data data()
    {
        return *(cast(Data*)_data);
    }

}

class PacketActionKey : Packet
{
    this()
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_ACTION_KEY;
    }

    struct Data
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

    @property ref Data data()
    {
        return *(cast(Data*)_data);
    }

}

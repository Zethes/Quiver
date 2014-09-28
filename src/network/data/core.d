module network.data.core;

import network.client.listener;
import network.control;
import network.core;
import network.data.canvas;
import network.data.generic;
import network.data.listener;
import network.manager : ClientGroup;
import network.messaging;
import settings;
import std.conv;
import util.log;

enum DataType
{
    GENERIC,
    CANVAS
}

abstract class Data
{

    this(DataType type)
    {
        _type = type;
    }

    void processProperties()
    {
    }

    ubyte[] getUpdateData()
    {
        return null;
    }

    void updateData(ubyte[] raw)
    {
    }

    ubyte[] getRaw()
    {
        return null;
    }

    @property DataType type() const
    {
        return _type;
    }

protected:

    int[uint] _properties; // actual property
    int[uint] _queueProperties; // client-request property
    uint[] _dirtyProperties;
    bool _client;

    ubyte[] pack(T...)(T params)
    {
        ubyte[] result = null;
        foreach (param; params)
        {
            result ~= (cast(ubyte*)&param)[0 .. param.sizeof];
        }
        return result;
    }

    int getProperty(uint index) const
    {
        const(int*) value = index in _properties;
        if (value !is null)
        {
            return *value;
        }
        else
        {
            return int.min;
        }
    }

    void setProperty(uint index, int value, bool dirty = true)
    {
        if (_client && dirty)
        {
            int* valueQuery = index in _queueProperties;
            if (valueQuery !is null)
            {
                if (*valueQuery != value)
                {
                    *valueQuery = value;
                    _dirtyProperties ~= index;
                }
            }
            else
            {
                _queueProperties[index] = value;
                _dirtyProperties ~= index;
            }
        }
        else
        {
            int* valueQuery = index in _properties;
            if (valueQuery !is null)
            {
                if (*valueQuery != value)
                {
                    *valueQuery = value;
                    if (_client)
                    {
                        _queueProperties[index] = value;
                    }
                    if (dirty)
                    {
                        _dirtyProperties ~= index;
                    }
                }
            }
            else
            {
                _properties[index] = value;
                if (_client)
                {
                    _queueProperties[index] = value;
                }
                _dirtyProperties ~= index;
                if (dirty)
                {
                    _dirtyProperties ~= index;
                }
            }
        }
    }

private:

    DataType _type;
    ClientGroup _clients;
}

// Note: this class is here as it might be useful in the future
// right now it's empty tho......
private class DataClientListener : ClientListener
{

    this(DataCore core)
    {
        _core = core;
    }

    override void onClientJoin(ref ClientJoinEvent event)
    {
    }

    override void onClientLeft(ref ClientLeftEvent event)
    {
    }

private:

    DataCore _core;

}

class DataCore : Core
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

    ClientListener createClientListener()
    {
        return new DataClientListener(this);
    }

    void registerData(string name, Data data)
    {
        assert(isServer);
        log("Registering data: \"", name, "\"");

        data._client = false;

        assert ((name in _dataNames) is null);
        uint index = _nextData++;
        _dataNames[name] = index;
        _dataMap[index] = data;
        data._clients = groupController.createGroup();
    }

    void freeData(string name)
    {
        assert(isServer);

        assert ((name in _dataNames) !is null);
        log("Freeing data: \"", name, "\"");
        _dataMap.remove(_dataNames[name]);
        _dataNames.remove(name);
    }

    void requestData(string name)
    {
        PacketRequest packet = new PacketRequest;
        assert(name.length <= packet.data.name.length);

        packet.data.nameLength = to!ubyte(name.length);
        packet.data.name[0 .. name.length] = name.dup;
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
            case PACKET_REQUEST:
                assert(packet.length == PacketRequest.Data.sizeof);
                processPacket(packet, *(cast(PacketRequest.Data*)packet.rawData));
                break;
            case PACKET_REQUEST_RESPONSE:
                assert(packet.length == PacketRequestResponse.Data.sizeof);
                processPacket(packet, *(cast(PacketRequestResponse.Data*)packet.rawData));
                break;
            case PACKET_DATA_UPDATE:
                assert(packet.length >= PacketDataUpdate.Data.sizeof);
                processPacket(packet, *(cast(PacketDataUpdate.Data*)packet.rawData), packet.getExtra!(PacketDataUpdate.Data)());
                break;
            case PACKET_DATA_PROPERTY:
                assert(packet.length == PacketDataProperty.Data.sizeof);
                processPacket(packet, *(cast(PacketDataProperty.Data*)packet.rawData));
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

    void processPacket(Packet packet, PacketRequest.Data data)
    {
        assert(isServer);
        assert(data.nameLength <= data.name.length);

        auto response = new PacketRequestResponse(packet.from);

        char[] name = data.name[0 .. data.nameLength];
        response.data.nameLength = data.nameLength;
        response.data.name = data.name.dup;
        uint* dataIndex = name in _dataNames;
        if (dataIndex !is null)
        {
            Data dataObject = _dataMap[*dataIndex];
            response.data.accepted = true;
            response.data.index = *dataIndex;
            response.data.type = dataObject.type;
            dataObject._clients.appendClient(packet.from);
            packetQueue.queue(response);

            foreach (key, value; dataObject._properties)
            {
                auto packet = new PacketDataProperty(packet.from, false);
                packet.data.index = *dataIndex;
                packet.data.property = key;
                packet.data.value = value;
                packetQueue.queue(packet);
            }

            auto dataPacket = new PacketDataUpdate(dataObject._clients.index);
            dataPacket.data.index = *dataIndex;
            ubyte[] raw = dataObject.getRaw();
            assert(raw !is null);
            assert(raw.length <= ushort.max);
            dataPacket.data.dataLength = cast(ushort)raw.length;
            packetQueue.queue(dataPacket, raw);
        }
        else
        {
            response.data.accepted = false;
            response.data.index = uint.max;
            packetQueue.queue(response);
        }
    }

    void processPacket(Packet packet, PacketRequestResponse.Data data)
    {
        assert(isClient);

        string name = data.name[0 .. data.nameLength].dup;

        Data newData;
        if (data.accepted)
        {
            switch (data.type)
            {
                case DataType.GENERIC:
                    newData = new GenericData;
                    break;
                case DataType.CANVAS:
                    newData = new CanvasData;
                    break;
                default:
                    assert(0);
                    break;
            }
            newData._client = true;
            _dataNames[name] = data.index;
            _dataMap[data.index] = newData;
        }

        DataResponseEvent event;
        event.name = cast(string)name;
        event.accepted = data.accepted;
        event.index = data.index;
        _listen.fire!"onDataResponse"(event);
    }

    void processPacket(Packet packet, PacketDataUpdate.Data data, ubyte[] leftover)
    {
        assert(isClient);
        assert(packet.header.length == PacketDataUpdate.Data.sizeof + data.dataLength);

        Data* dataObject = data.index in _dataMap;
        assert(dataObject !is null);
        dataObject.processProperties();
        dataObject.updateData(leftover);
    }

    void processPacket(Packet packet, PacketDataProperty.Data data)
    {
        Data* dataObject = data.index in _dataMap;
        assert(dataObject !is null);
        if (isServer)
        {
            dataObject.setProperty(data.property, data.value, true);
        }
        else
        {
            dataObject.setProperty(data.property, data.value, false);
        }
    }

    override void update()
    {
        if (isServer)
        {
            foreach (key, dataObject; _dataMap)
            {
                foreach (property; dataObject._dirtyProperties)
                {
                    auto packet = new PacketDataProperty(dataObject._clients.index, true);
                    packet.data.index = key;
                    packet.data.property = property;
                    packet.data.value = dataObject.getProperty(property);
                    packetQueue.queue(packet);
                }

                dataObject._dirtyProperties.length = 0;

                dataObject.processProperties();

                ubyte[] data = dataObject.getUpdateData();
                if (data !is null)
                {
                    auto packet = new PacketDataUpdate(dataObject._clients.index);
                    packet.data.index = key;
                    assert(data.length <= ushort.max);
                    packet.data.dataLength = cast(ushort)data.length;
                    packetQueue.queue(packet, data);
                }
            }
        }
        else if (isClient)
        {
            foreach (key, dataObject; _dataMap)
            {
                foreach (property; dataObject._dirtyProperties)
                {
                    auto packet = new PacketDataProperty(0, false);
                    packet.data.index = key;
                    packet.data.property = property;
                    packet.data.value = dataObject._queueProperties[property];
                    packetQueue.queue(packet);
                }

                dataObject._dirtyProperties.length = 0;
            }
        }
    }

    GenericData getGenericData(uint index)
    {
        Data data = _dataMap[index];
        assert(data.type == DataType.GENERIC);
        return cast(GenericData)_dataMap[index];
    }

    CanvasData getCanvasData(uint index)
    {
        Data data = _dataMap[index];
        assert(data.type == DataType.CANVAS);
        return cast(CanvasData)_dataMap[index];
    }

    void addListener(DataListener listener)
    {
        _listen.addListener(listener);
    }

    void removeListener(DataListener listener)
    {
        _listen.removeListener(listener);
    }

private:

    bool _ready = false;

    uint _nextData = 0;
    Data[uint] _dataMap;
    uint[string] _dataNames;

    ListenManager!DataListener _listen;

    DataClientListener _clientListener;

}

enum
{
    PACKET_INIT             = 0,
    PACKET_INIT_RESPONSE    = 1,
    PACKET_REQUEST          = 2,
    PACKET_REQUEST_RESPONSE = 3,
    PACKET_DATA_UPDATE      = 4,
    PACKET_DATA_PROPERTY    = 5
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

class PacketRequest : Packet
{

    this()
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_REQUEST;
    }

    struct Data
    {

        PacketHeader header;
        size_t nameLength;
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

    @property ref Data data()
    {
        return *(cast(Data*)_data);
    }

}

class PacketRequestResponse : Packet
{

    this(ushort to)
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_REQUEST_RESPONSE;
        _to = to;
    }

    struct Data
    {

        PacketHeader header;
        size_t nameLength;
        char[32] name;
        bool accepted;
        uint index;
        DataType type;

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

class PacketDataUpdate : Packet
{

    this(uint to)
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_DATA_UPDATE;
        _toGroup = to;
    }

    struct Data
    {

        PacketHeader header;
        uint index;
        ushort dataLength;

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

class PacketDataProperty : Packet
{

    this(uint to, bool group)
    {
        super(Data.sizeof);
        *(cast(Data*)_data) = Data.init;

        header.packet = PACKET_DATA_PROPERTY;
        if (group)
        {
            _toGroup = to;
        }
        else
        {
            _to = .to!ushort(to);
        }
    }

    struct Data
    {

        PacketHeader header;
        uint index;
        uint property;
        int value;

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

module network.core;

import network.manager;
import network.messaging;
import settings;
import std.algorithm;

abstract class Core
{

    this()
    {
        _packetQueue = new PacketQueue;
    }

    void setControllers(GroupController groupController)
    {
        _groupController = groupController;
    }

    void init(ManagerSettings settings)
    {
    }

    @property bool ready()
    {
        return false;
    }

    void setManagerType(ManagerType type, ushort id)
    {
        _managerType = type;
        _id = id;
    }

    @property PacketQueue packetQueue()
    {
        return _packetQueue;
    }

    @property bool isServer() const
    {
        return _managerType == ManagerType.SERVER;
    }

    @property bool isClient() const
    {
        return _managerType == ManagerType.CLIENT;
    }

    @property ushort id() const
    {
        return _id;
    }

    @property GroupController groupController()
    {
        return _groupController;
    }

    void connectionDied(ushort index)
    {
    }

    void processInbox()
    {
        foreach (Packet packet; packetQueue.inbox)
        {
            // Get packet header
            PacketHeader header = *(cast(PacketHeader*)packet.rawData);

            // Process
            processPacket(packet);
        }
        packetQueue.inbox.length = 0;
    }

    void processPacket(Packet packet)
    {
    }

    void update()
    {
    }

private:

    PacketQueue _packetQueue;

    ManagerType _managerType;
    ushort _id;

    GroupController _groupController;

}

struct ListenManager(Interface)
{

    void fire(string func, T)(T event)
    {
        foreach (listener; _listeners)
        {
            mixin("listener." ~ func ~ "(event);");
        }
    }

    void addListener(Interface listener)
    {
        _listeners ~= listener;
    }

    void removeListener(Interface listener)
    {
        for (size_t i = 0; i < _listeners.length; i++)
        {
            if (_listeners[i] == listener)
            {
                _listeners = remove(_listeners, i);
            }
        }
    }

private:

    Interface[] _listeners;

}

module network.action.listener;

struct ActionPingEvent
{
    uint unique;
    bool cancel = false;
}

struct ActionPongEvent
{
    ushort client;
    uint unique;
    bool repeat = false;
}

struct ActionKeyEvent
{
    ushort client;
    int key;
}

struct ActionFixedEvent
{
    ushort client;
    ubyte[4] data;
}

abstract class ActionListener
{
    void onActionPing(ref ActionPingEvent event)
    {
    }

    void onActionPong(ref ActionPongEvent event)
    {
    }

    void onActionKey(ref ActionKeyEvent event)
    {
    }

    void onActionFixed(ref ActionFixedEvent event)
    {
    }
}

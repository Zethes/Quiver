module network.action.listener;

struct ActionPingEvent
{
    uint unique;
    bool cancel = false;
}

struct ActionPongEvent
{
    uint unique;
    bool repeat = false;
}

struct ActionKeyEvent
{
    ushort client;
    int key;
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
}

module network.client.listener;

struct ClientJoinEvent
{
    ushort index;
    bool existing;
}

struct ClientLeftEvent
{
    ushort index;
}

struct ClientRegisteredEvent
{
    ushort index;
    bool accepted;
}

abstract class ClientListener
{
    void onClientJoin(ref ClientJoinEvent event)
    {
    }

    void onClientLeft(ref ClientLeftEvent event)
    {
    }

    void onClientRegistered(ref ClientRegisteredEvent event)
    {
    }
}

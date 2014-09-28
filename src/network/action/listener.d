module network.action.listener;

struct ActionKeyEvent
{
    ushort client;
    int key;
}

abstract class ActionListener
{
    void onActionKey(ref ActionKeyEvent event)
    {
    }
}

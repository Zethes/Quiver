module network.data.listener;

struct DataResponseEvent
{
    ushort client;
    string name;
    bool accepted;
    uint index;
}

abstract class DataListener
{

    void onDataResponse(ref DataResponseEvent event)
    {
    }

}

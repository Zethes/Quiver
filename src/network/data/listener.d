module network.data.listener;

struct DataResponseEvent
{
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

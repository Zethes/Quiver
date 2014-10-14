module network.packetfactory;

import network.manager;

class PacketFactory
{

    this(ManagerBase manager)
    {
        _manager = manager;
    }

    auto newActionFixed()
    {
        return _manager.actionCore.newActionFixed();
    }

    auto newActionPing()
    {
        return _manager.actionCore.newActionPing();
    }

    auto newActionKey()
    {
        return _manager.actionCore.newActionKey();
    }

    auto newClientRegister()
    {
        return _manager.clientCore.newClientRegister();
    }

    auto newDataRequest()
    {
        return _manager.dataCore.newDataRequest();
    }

private:

    ManagerBase _manager;

}

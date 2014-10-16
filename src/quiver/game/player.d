module quiver.game.player;

import quiver.game.network : NetworkData = PlayerNetworkData;
import quiver.game.entity.player;

class Player
{

    this(ushort index, NetworkData networkData)
    {
        _index = index;
        _networkData = networkData;
    }

    ////////////////
    // Properties //
    ////////////////

    @property ushort index() const
    {
        return _index;
    }

    @property inout(NetworkData) networkData() inout
    {
        return _networkData;
    }

    @property ref PlayerEntity entity()
    {
        return _entity;
    }

    @property bool ready() const
    {
        return _entity.ready;
    }

private:

    ushort _index;
    uint _world;

    PlayerEntity _entity;

    NetworkData _networkData;

}

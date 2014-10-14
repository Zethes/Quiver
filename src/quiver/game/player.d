module quiver.game.player;

import quiver.game.network : NetworkData = PlayerNetworkData;
import quiver.game.entity.base;

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

    @property ref Entity entity()
    {
        return _entity;
    }

private:

    ushort _index;
    uint _world;

    Entity _entity;

    NetworkData _networkData;

}

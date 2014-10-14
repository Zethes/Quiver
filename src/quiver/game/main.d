module quiver.game.main;

import Net = network;
import render;
import quiver.game.entity.manager;
import quiver.game.network;
import quiver.game.player;
import quiver.game.world;
import std.conv;
import std.datetime;
import util.log;
import util.vector;

class Game
{

    ////////////////////
    // Initialization //
    ////////////////////

    this()
    {
        _network = new Network(this);
        _entityManager = new EntityManager;
    }

    void init()
    {
        _players = new Player[network.maxPlayers];

        _timer.start();
    }

    void listen(ushort port)
    {
        assert(!_listening);
        _listening = true;

        network.listen(port);
    }

    //////////////
    // Updating //
    //////////////

    void update()
    {
        if (_timer.peek().to!("seconds", float)() >= 0.1f)
        {
            network.preTick();
            entityManager.tick();
            network.sendData();
            _timer.reset();
        }
    }

    ////////////////////////
    // Internal Interface //
    ////////////////////////

    void addPlayer(Player player)
    {
        _players[player.index] = player;
        _connectedPlayers ~= player;
    }

    void removePlayer(ushort index)
    {
        _players[index] = null;
        foreach (ushort i, player; _connectedPlayers)
        {
            if (player.index == index)
            {
                _connectedPlayers = _connectedPlayers[0 .. i] ~ _connectedPlayers[i + 1 .. $];
                break;
            }
        }
    }

    ////////////////////////
    // External Interface //
    ////////////////////////

    Player getPlayer(ushort index)
    {
        return _players[index];
    }

    private World overWorld;
    World getWorld()
    {
        if (overWorld is null)
        {
            overWorld = new World;
        }
        return overWorld;
    }

    ////////////////
    // Properties //
    ////////////////

    @property inout(Player[]) connectedPlayers() inout
    {
        return _connectedPlayers;
    }

    @property inout(EntityManager) entityManager() inout
    {
        return _entityManager;
    }

    @property inout(Network) network() inout
    {
        return _network;
    }

private:

    StopWatch _timer;

    Network _network;
    EntityManager _entityManager;
    bool _listening = false;

    Player[] _players;
    Player[] _connectedPlayers;

}

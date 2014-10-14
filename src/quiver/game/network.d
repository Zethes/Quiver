module quiver.game.network;

import Net = network;
import quiver.game.main;
import quiver.game.player;
import quiver.game.world;
import Render = render;
import std.conv;
import std.random;
import util.log;
import util.vector;

class Network
{

    ////////////////////
    // Initialization //
    ////////////////////

    this(Game game)
    {
        _game = game;

        _manager = new Net.GameManager;

        manager.actionCore.addListener(new ActionListener(this));
        manager.clientCore.addListener(new ClientListener(this));

        _timer = new Net.GenericData;
        manager.dataCore.registerData("timer", _timer);
    }

    void listen(ushort port)
    {
        _manager.listen(port);
    }

    //////////////
    // Updating //
    //////////////

    void preTick()
    {
        auto testPacket = packetFactory.newActionFixed();
        testPacket.route(Net.Route.server, Net.Route.allClients);
        testPacket.type = 1;
        testPacket.send();
    }

    void sendData()
    {
        static ubyte col = 0;
        col = (col + 1) % 256;
        foreach (player; _game.connectedPlayers)
        {
            World world = _game.getWorld();
            Net.CanvasData canvas = player.networkData.canvas;

            VectorI size = canvas.size;
            Render.Block[] blocks = new Render.Block[size.product()];
            world.getTiles(VectorI(0, 0), size, blocks);

            for (int w = 0; w < size.x; w++)
            {
                for (int h = 0; h < size.y; h++)
                {
                    canvas.set(w, h, blocks[w + size.x * h]);
                }
            }
        }
    }

    ////////////////
    // Properties //
    ////////////////

    @property Net.GameManager manager()
    {
        return _manager;
    }

    @property ushort maxConnections() const
    {
        return _manager.maxConnections;
    }

    @property void maxConnections(ushort value)
    {
        _manager.maxConnections = value;
    }

    @property ushort maxPlayers() const
    {
        return _manager.clientCore.maxClients;
    }

    @property inout(Net.PacketFactory) packetFactory() inout
    {
        return _manager.packetFactory;
    }

private:

    Game _game;

    Net.GameManager _manager;
    Net.PacketFactory _packetFactory;

    Net.GenericData _timer;

}

private class ActionListener : Net.ActionListener
{

    Network network;
    Net.GameManager manager;

    this(Network network)
    {
        this.network = network;
        manager = network.manager;
    }

    override void onActionKey(ref Net.ActionKeyEvent event)
    {
        Player player = network._game.getPlayer(event.client);
        player.entity.key = event.key;
    }

}

private class ClientListener : Net.ClientListener
{

    Network network;
    Net.GameManager manager;

    this(Network network)
    {
        this.network = network;
        manager = network.manager;
    }

    override void onClientJoin(ref Net.ClientJoinEvent event)
    {

        // Grab the client that just joined
        auto client = manager.clientCore.getClient(event.index);

        // Print a message to the log
        log("[Game] Player \"", client.name, "\" joined.");

        // Create the player's canvas
        Net.CanvasData canvas = new Net.CanvasData;
        manager.dataCore.registerData("client" ~ to!string(event.index) ~ ".canvas", canvas);
        canvas.width = 1;
        canvas.height = 1;

        // Create the player's inventory
        Net.GenericData inventory = new Net.GenericData;
        manager.dataCore.registerData("client" ~ to!string(event.index) ~ ".inventory", inventory);

        // Store off the network data for the player
        PlayerNetworkData netData;
        netData.client = client;
        netData.canvas = canvas;
        netData.inventory = inventory;

        // Create the player in the game
        Player player = new Player(event.index, netData);
        network._game.addPlayer(player);

        // Create the player entity
        player.entity = network._game.entityManager.createEntity(network._game.getWorld(), VectorI(uniform!"[]"(0, 10), uniform!"[]"(0, 10)));

    }

    override void onClientLeft(ref Net.ClientLeftEvent event)
    {
        // Grab the client that is leaving
        auto client = manager.clientCore.getClient(event.index);

        // Print a message to the log
        log("[Game] Player \"", client.name, "\" left.");

        // Free the user's data
        manager.dataCore.freeData("client" ~ to!string(event.index) ~ ".canvas");
        manager.dataCore.freeData("client" ~ to!string(event.index) ~ ".inventory");

        // Remove from player list
        network._game.removePlayer(event.index);
    }

}

struct PlayerNetworkData
{
    Net.Client client;
    Net.CanvasData canvas;
    Net.GenericData inventory;
}

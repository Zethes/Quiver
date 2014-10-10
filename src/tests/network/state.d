/+

Quiver Network Stress Test

The purpose of this test is to ensure the networking code routing rules are behaving properly. The
test will create a server and five client managers. The first client manager will connect locally
(no socket is created in this case) and the other four will connect over localhost. Each client
manager will register a random number of players ("clients"). At the same time, the server will
create five data pools.  Once the clients and the data pools have been registered, the clients
will each request access to random data pools and wait until each request has been accepted. Once
all of that is said and done, the server will infrequently update the data pools and send the
changes to each client that is interested.

+/

module tests.network.state;

import Net = network;
import settings;
import std.conv;
import std.random;
import util.log;
import util.statemachine;

private Mt19937 rng;
private State state;
private uint stage = 0;
private uint lastStage = uint.max;
private Client clientManagers[5];
Net.GenericData randomJunk[5];

// Misc junk
private size_t clientCount = 0;
private size_t dataCount = 0;

enum Stage
{
    NotReady,
    Register,
    RegisterData,
    UpdateDate
}

bool firstFrame()
{
    return stage != lastStage;
}

class Game : Net.GameManager
{

    this()
    {
        // Add listeners
        clientCore.addListener(new ClientListener!true(this));
        dataCore.addListener(new DataListener!true(this));
    }

    void process()
    {
        switch (stage)
        {
            case Stage.Register:
            {
                if (firstFrame())
                {
                    foreach (size_t i, ref junk; randomJunk)
                    {
                        junk = new Net.GenericData;
                        junk.length = 0;
                        dataCore.registerData("junk" ~ to!string(i), junk);
                    }
                }
                break;
            }
            case Stage.RegisterData:
            {
                // do nothing
                break;
            }
            case Stage.UpdateDate:
            {
                static uint delay = 0;
                delay = (delay + 1) % 50;
                if (delay == 0)
                {
                    foreach (size_t i, ref junk; randomJunk)
                    {
                        junk.x = junk.x + uniform!"[]"(0, 30, rng);
                        junk.length = junk.length + uniform!"[]"(0, 30, rng);
                    }
                }
                break;
            }
            default: assert(0);
        }
    }

}

class Client : Net.ClientManager
{

    static const size_t maxClients = 4;
    Net.Client[] clients;
    Net.Client[ushort] clientMap;
    uint delay = 0;
    Net.GenericData[] junk;
    ushort[] junkClient;
    string[] junkName;
    size_t index;

    this()
    {
        // Add listeners
        clientCore.addListener(new ClientListener!false(this));
        dataCore.addListener(new DataListener!false(this));
    }

    void process()
    {
        switch (stage)
        {
            case Stage.Register:
            {
                if (firstFrame())
                {
                    ulong num = uniform!"[]"(1, maxClients, rng);
                    for (ulong i = 0; i < num; i++)
                    {
                        auto register = packetFactory.newClientRegister();
                        register.route(Net.Route.connection, Net.Route.server);
                        register.data.name[0 .. 6] = "Client";
                        register.data.nameLength = 6;
                        register.send();
                        clientCount++;
                    }
                }
                break;
            }
            case Stage.RegisterData:
            {
                if (firstFrame())
                {
                    foreach (client; clients)
                    {
                        foreach (size_t j, junk; randomJunk)
                        {
                            if (uniform!"[]"(0, 100, rng) < 40)
                            {
                                string name = "junk" ~ to!string(j);

                                auto request = packetFactory.newDataRequest();
                                assert(name.length <= request.data.name.length);
                                log(client.name, " is requesting ", name);
                                dataCount++;

                                request.route(client, Net.Route.server);
                                request.data.nameLength = to!ubyte(name.length);
                                request.data.name[0 .. name.length] = name.dup;
                                request.send();
                            }
                        }
                    }
                }
                break;
            }
            case Stage.UpdateDate:
            {
                delay = (delay + 1) % 50;
                string data = "JUNK: ";
                if (delay == 0)
                {
                    foreach (size_t i, j; junk)
                    {
                        data ~= " ";
                        data ~= to!string(clientCore.getClient(junkClient[i]).name);
                        data ~= "\t";
                        data ~= junkName[i];
                        data ~= "\t";
                        data ~= to!string(j.x);
                        data ~= "\t";
                        data ~= to!string(j.length);
                        data ~= "\t";
                    }
                    log(data);
                }
                break;
            }
            default: assert(0);
        }
    }

}

class NetworkTestState : State
{

    Net.Control netControl;
    Game game;

    void enter()
    {
        state = this;

        log("Hello!");
        netControl = new Net.Control;

        // Seed the rng
        rng.seed(30948203);
        //rng.seed(30948204);

        // Create server
        game = new Game;
        netControl.registerManager(game);
        game.setMaxConnections(clientManagers.length);
        game.listen(1234);

        // Create clients
        foreach (i, ref client; clientManagers)
        {
            client = new Client;
            client.index = i;
            netControl.registerManager(client);

            if (i == 0)
            {
                // Connect the two managers
                client.connect(game);
            }
            else
            {
                // Connect over sockets
                client.connect("127.0.0.1", 1234);
            }
        }

        // Initiate the cores
        ManagerSettings managerSettings;
        managerSettings.client.maxClients = clientManagers[0].maxClients * clientManagers.length;
        netControl.initCores(managerSettings);
    }

    void update()
    {
        netControl.update();

        if (netControl.ready && stage == Stage.NotReady)
        {
            log("Ready!");
            stage++;
        }

        if (stage != Stage.NotReady)
        {
            game.process();
            foreach (ulong i, clientMgr; clientManagers)
            {
                clientMgr.process();
            }
        }

        lastStage = stage;
    }

    void exit()
    {
    }

}

private class ClientListener(bool server) : Net.ClientListener
{

    private static const bool isServer = server;
    private static const bool isClient = !server;

    Net.ManagerBase manager;

    this(Net.ManagerBase manager)
    {
        this.manager = manager;
    }

    @property Game game()
    {
        assert(isServer);
        return cast(Game)manager;
    }

    @property Client client()
    {
        assert(isClient);
        return cast(Client)manager;
    }

    override void onClientJoin(ref Net.ClientJoinEvent event)
    {
        auto client = manager.clientCore.getClient(event.index);

        if (!event.existing && isServer)
        {
            log("[Game] Player \"", client.name, "\" joined.");
        }
    }

    override void onClientLeft(ref Net.ClientLeftEvent event)
    {
        auto client = manager.clientCore.getClient(event.index);

        if (isServer)
        {
            log("[Game] Player \"", client.name, "\" left.");
        }
    }

    override void onClientRegistered(ref Net.ClientRegisteredEvent event)
    {
        if (event.accepted)
        {
            assert(stage == Stage.Register);

            client.clients ~= client.clientCore.getClient(event.index);
            client.clientMap[event.index] = client.clientCore.getClient(event.index);

            static size_t clientTally = 0;
            clientTally++;
            if (clientTally == clientCount)
            {
                stage++;
            }
        }
        else
        {
            assert(0, "Player registration denied.");
        }
    }

}

private class DataListener(bool server) : Net.DataListener
{

    private static const bool isServer = server;
    private static const bool isClient = !server;

    Net.ManagerBase manager;

    this(Net.ManagerBase manager)
    {
        this.manager = manager;
    }

    @property Game game()
    {
        assert(isServer);
        return cast(Game)manager;
    }

    @property Client client()
    {
        assert(isClient);
        return cast(Client)manager;
    }

    override void onDataResponse(ref Net.DataResponseEvent event)
    {
        assert(isClient);
        if (event.accepted)
        {
            log(client.clientMap[event.client].name, " was granted ", event.name);
            client.junk ~= client.dataCore.getGenericData(event.index);
            client.junkClient ~= event.client;
            client.junkName ~= event.name;

            static size_t dataTally = 0;
            dataTally++;
            if (dataTally == dataCount)
            {
                stage++;
            }
        }
        else
        {
            assert(0, "Failed to register data " ~ event.name);
        }
    }

}

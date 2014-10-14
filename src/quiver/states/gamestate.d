module quiver.states.gamestate;

import Net = network;
import quiver.client;
import quiver.game;
import render.screen;
import settings;
import util.log;
import util.statemachine;

struct GameSettings
{
    string host = "";
    ushort port = 0;
    bool server = false;
    bool client = false;
    ushort maxConnections = 16;
}

class GameState : State
{
    this(StateMachine fsm, Screen screen, GameSettings settings)
    {
        _fsm = fsm;
        _screen = screen;
        _settings = settings;
    }

    void enter()
    {
        bool server = _settings.server;
        bool client = _settings.client;
        assert(server || client);

        _netControl = new Net.Control;

        if (server)
        {
            _game = new Game;
            _netControl.registerManager(_game.network.manager);
            _game.network.maxConnections = _settings.maxConnections;
            _game.listen(_settings.port);
        }
        if (client)
        {
            _client = new QuiverClient(_screen);
            _netControl.registerManager(_client);
            if (!server)
            {
                _client.connect(_settings.host, _settings.port);
            }
        }

        if (server && client)
        {
            _client.connect(_game.network.manager);
        }

        ManagerSettings managerSettings;
        managerSettings.client.maxClients = 10;
        _netControl.initCores(managerSettings);

        if (_game !is null)
        {
            _game.init();
        }
    }

    void update()
    {
        static bool ready = false;
        if (!ready && _netControl.ready)
        {
            log("READY! :)");
            ready = true;
        }
        _netControl.update();
        if (_game !is null)
        {
            _game.update();
        }
    }

    void exit()
    {
        if (_netControl)
        {
            _netControl.shutdown();
        }
    }

private:

    Net.Control _netControl;

    Game _game;
    QuiverClient _client;

    GameSettings _settings;

    StateMachine _fsm;
    Screen _screen;

}

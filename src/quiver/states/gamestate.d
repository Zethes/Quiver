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
            _game = new QuiverGame;
            _netControl.registerManager(_game);
            _game.setMaxConnections(_settings.maxConnections);
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
            _client.connect(_game);
        }

        ManagerSettings managerSettings;
        managerSettings.client.maxClients = 10;
        _netControl.initCores(managerSettings);
    }

    void update()
    {
        static bool ready = false;
        if (!ready && _netControl.ready)
        {
            log("READY! :)");
            //_netControl.initManagers();
            ready = true;
        }
        _netControl.update();
    }

    void exit()
    {
    }

private:

    Net.Control _netControl;

    QuiverGame _game;
    QuiverClient _client;

    GameSettings _settings;

    StateMachine _fsm;
    Screen _screen;

}

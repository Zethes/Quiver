module quiver.game;

import game.game;
import Net = network;
import render.canvas;
import std.conv;
import util.log;
import util.vector;

class ActionListener : Net.ActionListener
{
    this(QuiverGame game)
    {
        _game = game;
    }

    override void onActionKey(ref Net.ActionKeyEvent event)
    {
        Player player = _game._players[event.client];

        switch (event.key)
        {
            case 'j':
                player.position = player.position + VectorI(0, 1);
                break;
            case 'k':
                player.position = player.position + VectorI(0, -1);
                break;
            case 'h':
                player.position = player.position + VectorI(-1, 0);
                break;
            case 'l':
                player.position = player.position + VectorI(1, 0);
                break;
            default:
                break;
        }
    }

private:

    QuiverGame _game;

}

private class ClientListener : Net.ClientListener
{

    this(QuiverGame game)
    {
        _game = game;
    }

    override void onClientJoin(ref Net.ClientJoinEvent event)
    {
        auto client = _game.clientCore.getClient(event.index);

        if (!event.existing)
        {
            log("[Game] Player \"", client.name, "\" joined.");
        }

        Net.CanvasData canvas = new Net.CanvasData;
        _game.dataCore.registerData("client" ~ to!string(event.index) ~ ".canvas", canvas);
        canvas.width = 200;
        canvas.height = 50;

        Net.GenericData inventory = new Net.GenericData;
        _game.dataCore.registerData("client" ~ to!string(event.index) ~ ".inventory", inventory);

        _game._players[event.index] = new Player(event.index, canvas, inventory, _game);
    }

    override void onClientLeft(ref Net.ClientLeftEvent event)
    {
        auto client = _game.clientCore.getClient(event.index);

        log("[Game] Player \"", client.name, "\" left.");

        _game.dataCore.freeData("client" ~ to!string(event.index) ~ ".canvas");
        _game.dataCore.freeData("client" ~ to!string(event.index) ~ ".inventory");

        _game._players[event.index] = null;
    }

private:

    QuiverGame _game;

}

class Player
{

    this(ushort index, Net.CanvasData canvas, Net.GenericData inventory, QuiverGame game)
    {
        _index = index;
        _canvas = canvas;
        _inventory = inventory;
        _game = game;
    }

    private int delay = 0;
    private int x = 0;
    void update()
    {
        string res = "Hello player " ~ to!string(_index);


        for (uint w = 0; w < _canvas.width; w++)
        {
            for (uint h = 0; h < _canvas.height; h++)
            {
                _canvas.set(w, h, Block.init);
            }
        }

        for (int i = 0; i < res.length; i++)
        {
            _canvas.set(i, 0, Block(res[i], WHITE_ON_BLACK));
        }

        foreach (player; _game._players)
        {
            if (player !is null)
            {
                if (player == this)
                {
                    _canvas.set(player.position.x, player.position.y, Block('@', YELLOW_ON_BLACK));
                }
                else
                {
                    _canvas.set(player.position.x, player.position.y, Block('@', CYAN_ON_BLACK));
                }
            }
        }
    }

    @property VectorI position() const
    {
        return _position;
    }

    @property void position(VectorI value)
    {
        _position = value;
    }

private:

    ushort _index;
    Net.CanvasData _canvas;
    Net.GenericData _inventory;
    VectorI _position;

    QuiverGame _game;

}

class QuiverGame : Net.GameManager
{

    override void init()
    {
        _actionListener = new ActionListener(this);
        _actionCore.addListener(_actionListener);

        _clientListener = new ClientListener(this);
        _clientCore.addListener(_clientListener);

        _timer = new Net.GenericData;
        dataCore.registerData("timer", _timer);

        _players = new Player[clientCore.maxClients];
    }

    override void update()
    {
        super.update();

        if (ready)
        {
            assert(_timer !is null);

            static int delay = 0;
            delay = (delay + 1) % 50;
            if (delay == 0)
            {
                _timer.x = _timer.x + 1;
            }

            foreach (player; _players)
            {
                if (player !is null)
                {
                    player.update();
                }
            }
        }
    }

private:

    ActionListener _actionListener;
    ClientListener _clientListener;

    Net.GenericData _timer = null;
    Player[] _players;

}

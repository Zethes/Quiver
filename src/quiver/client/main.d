module quiver.client.main;
import quiver.ui;

import Net = network;
import render.canvas;
import render.screen;
import settings;
import std.conv;
import util.log;
import util.vector;

private class ActionListener : Net.ActionListener
{

    this(QuiverClient client)
    {
        _client = client;
    }

    override void onActionFixed(ref Net.ActionFixedEvent event)
    {
    }

private:

    QuiverClient _client;

}

private class ClientListener : Net.ClientListener
{

    this(QuiverClient client)
    {
        _client = client;
    }

    override void onClientRegistered(ref Net.ClientRegisteredEvent event)
    {
        if (event.accepted)
        {
            _client._index = event.index;
            _client._me = _client._clientCore.getClient(_client._index);

            auto request = _client.packetFactory.newDataRequest();
            request.route(_client._me, Net.Route.server);
            request.setName("timer");
            request.send();

            request = _client.packetFactory.newDataRequest();
            request.route(_client._me, Net.Route.server);
            request.setName("client" ~ to!string(event.index) ~ ".canvas");
            request.send();

            request = _client.packetFactory.newDataRequest();
            request.route(_client._me, Net.Route.server);
            request.setName("client" ~ to!string(event.index) ~ ".inventory");
            request.send();
        }
        else
        {
            assert(0, "Player registration denied.");
        }
    }

private:

    QuiverClient _client;

}

private class DataListener : Net.DataListener
{

    this(QuiverClient client)
    {
        _client = client;
    }

    override void onDataResponse(ref Net.DataResponseEvent event)
    {
        if (event.accepted)
        {
            if (event.name == "timer")
            {
                _client._timerData = _client.dataCore.getGenericData(event.index);
            }
            else if (event.name == "client" ~ to!string(_client._index) ~ ".canvas")
            {
                _client._canvasData = _client.dataCore.getCanvasData(event.index);
            }
            else if (event.name == "client" ~ to!string(_client._index) ~ ".inventory")
            {
                _client._inventoryData = _client.dataCore.getGenericData(event.index);
            }
        }
        else
        {
            assert(0, "Failed to register data " ~ event.name);
        }
    }

private:

    QuiverClient _client;

}

class QuiverClient : Net.ClientManager
{

    this(Screen screen)
    {
        _actionListener = new ActionListener(this);
        _actionCore.addListener(_actionListener);

        _clientListener = new ClientListener(this);
        _clientCore.addListener(_clientListener);

        _dataListener = new DataListener(this);
        _dataCore.addListener(_dataListener);

        _screen = screen;
        _canvas = new Canvas(VectorI(10, 10));
    }

    override void init()
    {
        clientCore.registerClient("Player");
        UI.register("Chat", new ChatWindow(_screen.mainWindow.size));

        (cast(ChatWindow)UI.getWindow("Chat")).addMessage(ChatMessageTypes.clientMessage, "Loading...");
    }

    override void update()
    {
        super.update();

        if (!ready)
        {
            _screen.mainWindow.clear();
            _screen.mainWindow.print("Loading...");
            _screen.mainWindow.refresh();
            _screen.update();
        }
        else
        {
            static bool first = true;
            if (_me !is null && first)
            {
                auto ping = packetFactory.newActionPing();
                ping.route(_me, Net.Route.server);
                ping.data.unique = 5;
                ping.send();
                first = false;
            }

            int key;
            while (_screen.getKey(key))
            {
                if (key == 'q')
                {
                    global.running = false;
                }
                else
                {
                    if (_me)
                    {
                        auto packet = packetFactory.newActionKey();
                        packet.route(_me, Net.Route.server);
                        packet.data.key = key;
                        packet.send();
                    }
                }
            }
            _screen.mainWindow.clear();
            /*_screen.mainWindow.print("timer: ");
            if (_inventoryData !is null)
            {
                _screen.mainWindow.print(_timerData.x);
            }
            _screen.mainWindow.print("\n");
            _screen.mainWindow.print("in-game :)\n");
            _screen.mainWindow.print(clientCore.connectedClients);*/
            if (_canvasData !is null)
            {
                _screen.mainWindow.print(_canvasData.canvas);

                _canvasData.width = _screen.mainWindow.size.x;
                _canvasData.height = _screen.mainWindow.size.y;

            }

            _screen.mainWindow.refresh();
            UI.draw(_screen.mainWindow.size);
            _screen.update();
        }
    }

private:

    ActionListener _actionListener;
    ClientListener _clientListener;
    DataListener _dataListener;

    ushort _index;
    Screen _screen;
    Canvas _canvas;
    Net.Client _me;

    Net.GenericData _timerData = null;
    Net.CanvasData _canvasData = null;
    Net.GenericData _inventoryData = null;

}

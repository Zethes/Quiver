module game.game;

/*import network;
import util.log;

class GameManager : Manager
{

    this()
    {
        super(ManagerType.SERVER);
    }

    bool listen(ushort port)
    {
        assert(!_server);
        log("Binding to port...");
        _server = new Connection(ushort.max);
        if (_server.listen(port))
        {
            log("Listening on port ", port, "!");
            return true;
        }
        _server = null;
        log("Failed to listen on port ", port, ".");
        return false;
    }

    void setMaxConnections(ushort count)
    {
        assert(count != 0);

        foreach (connection; _connections)
        {
            assert(!connection);
        }

        _connections.length = count;
    }

    ushort getFreeConnection()
    {
        ushort index = ushort.max;
        for (ushort i = 0; i < index; i++)
        {
            if (!_connections[i])
            {
                index = i;
                break;
            }
        }
        return index;
    }

    void acceptLocal()
    {
        ushort index = getFreeConnection();

        assert(index != ushort.max);

        _connections[index] = Connection.newLocal(0);
    }

    override ushort getConnectionCount()
    {
        return cast(ushort)_connections.length;
    }

    override Connection getConnection(ushort index)
    {
        if (index < _connections.length)
        {
            return _connections[index];
        }
        else
        {
            return null;
        }
    }

    override Connection getLocalConnection()
    {
        foreach (connection; _connections)
        {
            if (connection && connection.local)
            {
                return connection;
            }
        }
        return null;
    }

    override ubyte[][] receivePackets()
    {
        ubyte[][] data;

        for (ushort i = 0; i < _connections.length; i++)
        {
            Connection con = _connections[i];
            if (con)
            {
                while (con.receive())
                {
                }

                if (con.connected)
                {
                    for (int j = 0; j < con.packetData.length && j < 4; j++)
                    {
                        switch (j)
                        {
                            case 0:
                                assert(con.packetData[j] == 'Q');
                                break;
                            case 1:
                                assert(con.packetData[j] == 'v');
                                break;
                            case 2:
                                assert(con.packetData[j] == 'e');
                                break;
                            case 3:
                                assert(con.packetData[j] == 'r');
                                break;
                            default:
                                break;
                        }
                    }
                    while (con.packetData.length >= PacketHeader.sizeof)
                    {
                        PacketHeader* header = cast(PacketHeader*)con.packetData;
                        if (header.length <= con.packetData.length)
                        {
                            assert(header.from == ushort.max);
                            header.from = con.id;
                            data ~= con.packetData[0 .. header.length];
                            con.packetData = con.packetData[header.length .. $];
                        }
                        else
                        {
                            break;
                        }
                    }
                }
                else
                {
                    ushort[] clients = clientCore.getClientsByConnection(i);
                    foreach (client; clients)
                    {
                        groupController.clientDied(client);
                    }

                    foreach (core; _cores)
                    {
                        core.connectionDied(i);
                    }
                    _connections[i] = null;
                }
            }
        }

        return data;
    }

    override void init()
    {
    }

    override void update()
    {
    }

    override void updateBase()
    {
        if (_server)
        {
            // Accept new connections
            ushort index = getFreeConnection();
            Connection newConnection = _server.accept(index);

            if (newConnection)
            {
                // Server full, kick client
                if (index == ushort.max)
                {
                    assert(0, "TODO: kick when server is full");
                }
                else
                {
                    _connections[index] = newConnection;
                }
            }
        }
    }

private:

    Connection[] _connections;
    Connection _server;

}*/

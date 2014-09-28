module client.client;

/*import network;
import settings;
import std.conv;
import util.log;

class ClientManager : Manager
{

    this()
    {
        super(ManagerType.CLIENT);
    }

    void connectLocal()
    {
        _connection = Connection.newLocal(0);
    }

    void connect(string host, ushort port)
    {
        log("Connecting to ", host, ":", port, "...");
        _connection = new Connection(0);
        assert(_connection.connect(host, port), "Failed to connect to " ~ host ~ ":" ~ to!string(port));
        log("Connected!");
    }

    override ushort getConnectionCount()
    {
        return 1;
    }

    override Connection getConnection(ushort index)
    {
        if (index == 0)
        {
            return _connection;
        }
        else
        {
            return null;
        }
    }

    override Connection getLocalConnection()
    {
        if (_connection.local)
        {
            return _connection;
        }
        else
        {
            return null;
        }
    }

    override ubyte[][] receivePackets()
    {
        ubyte[][] data;

        if (!_connection.local)
        {
            while (_connection.receive())
            {
            }

            while (_connection.packetData.length >= PacketHeader.sizeof)
            {
                PacketHeader* header = cast(PacketHeader*)_connection.packetData;
                if (header.length <= _connection.packetData.length)
                {
                    header.from = 0;
                    data ~= _connection.packetData[0 .. header.length];
                    _connection.packetData = _connection.packetData[header.length .. $];
                }
                else
                {
                    break;
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
    }

private:

    Connection _connection;

}*/

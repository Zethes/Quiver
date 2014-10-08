module network.connection;

import std.socket;
import network.control;
import util.log;

class Connection
{

    static void makeLocalConnection(out Connection con1, ushort id1, out Connection con2, ushort id2)
    {
        con1 = new Connection(id1);
        con2 = new Connection(id2);
        con1._other = con2;
        con1._local = true;
        con2._other = con1;
        con2._local = true;
    }

    this(ushort id)
    {
        _local = false;
        _id = id;
        _connected = false;
    }

    @property bool local() const
    {
        return _local;
    }

    @property ushort id() const
    {
        return _id;
    }

    bool connect(string host, ushort port)
    {
        try
        {
            _socket = new TcpSocket;
            _socket.connect(new InternetAddress(host, port));
            _socket.blocking = false;
            _connected = true;
            return true;
        }
        catch (SocketException e)
        {
            return false;
        }
    }

    bool listen(ushort port)
    {
        try
        {
            _socket = new TcpSocket;
            _socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
            _socket.bind(new InternetAddress(port));
            _socket.listen(20);
            _socket.blocking = false;
            _connected = true;
            return true;
        }
        catch (SocketException e)
        {
            return false;
        }
    }

    void send(ubyte[] packet)
    {
        if (_local)
        {
            _other._packetData ~= packet;
        }
        else
        {
            _socket.send(packet);
        }
    }

    bool receive()
    {
        if (!_local)
        {
            assert(_socket);
            try
            {
                static ubyte[1024] data;
                ptrdiff_t size = _socket.receive(data);
                if (size == 0)
                {
                    _connected = false;
                    return false;
                }
                if (size == Socket.ERROR)
                {
                    return false;
                }
                _packetData ~= data[0 .. size];
                return true;
            }
            catch (SocketException e)
            {
                return false;
            }
        }
        return false;
    }

    Connection accept(ushort index)
    {
        try
        {
            Socket newSocket = _socket.accept();
            newSocket.blocking = false;
            return new Connection(newSocket, index);
        }
        catch
        {
            return null;
        }
    }

    void shutdown()
    {
        if (_connected && _socket !is null)
        {
            _socket.shutdown(SocketShutdown.BOTH);
            _socket.close();
            _socket = null;
        }
        _local = false;
        _connected = false;
    }

    @property ref ubyte[] packetData()
    {
        return _packetData;
    }

    @property bool connected() const
    {
        return _connected || _local;
    }

    @property Connection other()
    {
        return _other;
    }

private:

    this(Socket socket, ushort id)
    {
        _local = false;
        _socket = socket;
        _id = id;
        _connected = true;
    }

    bool _local;
    Connection _other;
    Socket _socket = null;
    ushort _id;
    ubyte[] _packetData;
    bool _connected;

}

module settings;
import std.stdio;

import util.log;

struct Settings
{
    bool running = true;
    bool error = false;

    bool serverOnly = false;
    bool clientOnly = false;

    void parseCommandLine(string[] argv)
    {
        for (size_t i = 1; i < argv.length; i++)
        {
            if (argv[i] == "-server")
            {
                serverOnly = true;
            }
            else if (argv[i] == "-client")
            {
                clientOnly = true;
            }
            else if (argv[i] == "--help" || argv[i] == "-h")
            {
                writeln("usage: ", argv[0], " [options]");
                writeln("Options:");
                writeln("-server \t\t run a dedicated server.");
                writeln("-client \t\t run a client only.");
                error = true;
            }
            else
            {
                log("Unknown command line argument: ", argv[i]);
                error = true;
            }
        }
    }
}

struct ManagerSettings
{
    struct Client
    {
        ushort maxClients = 16;
    }

    Client client;
}

Settings global;

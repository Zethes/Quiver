module settings;

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

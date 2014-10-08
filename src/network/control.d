module network.control;

import network.client.core;
import network.connection;
import network.core;
import network.data.core;
import network.manager;
import network.messaging;
import render.screen;
import settings;
import std.algorithm;
import std.conv;
import std.range;
import util.log;

class Control
{

    void registerManager(ManagerBase manager)
    {
        _managers ~= manager;
    }

    void initCores(ManagerSettings settings)
    {
        foreach (manager; _managers)
        {
            manager.initCores(settings);
        }
    }

    void update()
    {
        // Receive & process messages
        foreach (manager; _managers)
        {
            manager.processInbox();
        }

        // Update managers
        foreach (manager; _managers)
        {
            manager.update();
        }

        // Send messages
        foreach (manager; _managers)
        {
            manager.processOutbox();
        }
    }

    @property bool ready()
    {
        foreach (manager; _managers)
        {
            if (!manager.ready)
            {
                return false;
            }
        }
        return true;
    }

    void shutdown()
    {
        foreach (manager; _managers)
        {
            manager.shutdown();
        }
    }

private:

    ManagerBase[] _managers;

}

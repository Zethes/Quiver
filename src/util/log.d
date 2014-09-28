module util.log;

import settings;
import std.conv;
import std.file;
import std.stdio;
import std.string;

private static string logFile = "quiver.log";

void newLog()
{
    if (global.clientOnly)
    {
        logFile = "quiverclient.log";
    }

    try
    {
        std.file.remove(logFile);
    }
    catch
    {
    }
}

void log(T...)(T params)
{
    foreach (param; params)
    {
        if (global.serverOnly)
        {
            write(param);
        }
        append(logFile, to!string(param));
    }
    if (global.serverOnly)
    {
        writeln();
    }
    append(logFile, "\n");
}

import core.thread;
import render.screen;
import render.colors;
import settings;
import quiver.states.menustate;
import std.stdio;
import util.log;
import util.statemachine;

int main(string[] argv)
{
    // Process command line arguments
    global.parseCommandLine(argv);
    if (global.error)
        return 1;

    // Setup logging
    newLog();
    log("Welcome to Quiver!");

    // Initialize screen pointer outside try-catch so that it can be closed on an exception
    Screen screen = null;

    if (global.devToolColors)
    {
        try 
        {
            screen = new Screen;
            Colors.drawPallete(screen.mainWindow);
            screen.update();
            while (true) {}
            screen.close();
            return 0;
        }
        catch (Exception e)
        {
            writeln(e);
            return -1;
        }
    }

    // Setup master try/catch for unhandled exceptions/errors
    try
    {
        // Setup screens if we're not a dedicated server
        if (!global.serverOnly)
        {
            screen = new Screen;
        }

        // Create finite state machine
        StateMachine fsm;
        fsm = new StateMachine;

        // Enter menu
        fsm.enterState(new MenuState(fsm, screen));

        // Main game loop
        while (global.running)
        {
            fsm.update();
            Thread.sleep(dur!("msecs")(16));
        }

        return 0;
    }
    catch (Error e)
    {
        // Close ncurses so that the error message will print to stdout
        if (screen)
        {
            screen.close();
        }

        // Print error and quit
        writeln(e);
        return -1;
    }
    catch (Exception e)
    {
        // Close ncurses so that the exception message will print to stdout
        if (screen)
        {
            screen.close();
        }

        // Print exception and quit
        writeln(e);
        return -1;
    }
}

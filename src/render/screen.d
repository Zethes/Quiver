module render.screen;
import core.thread;
import deimos.ncurses.ncurses;
import render.window;
import std.container;
import std.string;
import util.vector;

class Screen
{
    this()
    {
        initNCurses();
    }

    ~this()
    {
        cleanup();
    }

    Window getMainWindow()
    {
        return mainWindow;
    }

    bool getKey(ref int key)
    {
        int ch = getch();
        if (ch == ERR)
        {
            return false;
        }
        else
        {
            key = ch;
            return true;
        }
    }

private:

    Window mainWindow;

    void initNCurses()
    {
        mainWindow = new Window(initscr());
        timeout(0);
        noecho();
        curs_set(0);
    }

    void cleanup()
    {
        endwin();
    }
}

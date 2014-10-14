module render.screen;

import core.thread;
import deimos.ncurses.ncurses;
import render.window;
import render.colors;
import std.container;
import std.conv;
import std.string;
import util.vector;

class Screen
{

    /////////////////
    // Constructor //
    /////////////////

    this()
    {
        initNCurses();
        Colors.initColors();
    }

    /////////////
    // Cleanup //
    /////////////

    ~this()
    {
        close();
    }

    void close()
    {
        endwin();
    }

    ////////////////
    // Properties //
    ////////////////

    @property ref Window mainWindow()
    {
        return _mainWindow;
    }

    ///////////
    // Input //
    ///////////

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

    /////////////////////////
    // Screen Manipulation //
    /////////////////////////

    void update()
    {
        doupdate();
    }

private:

    ///////////////////////
    // Private Variables //
    ///////////////////////

    Window _mainWindow;

    ////////////////////
    // Initialization //
    ///////////////////

    void initNCurses()
    {
        mainWindow = new Window(initscr());
        start_color();
        timeout(0);
        noecho();
        curs_set(0);
    }

}

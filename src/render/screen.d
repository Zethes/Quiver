module render.screen;
import core.thread;
import deimos.ncurses.ncurses;
import render.window;
import std.container;
import std.conv;
import std.string;
import util.vector;

private const short colors[] =
[
    COLOR_BLACK,
    COLOR_WHITE,
    COLOR_RED,
    COLOR_GREEN,
    COLOR_YELLOW,
    COLOR_BLUE,
    COLOR_MAGENTA,
    COLOR_CYAN
];

private const string colorNames[] =
[
    "BLACK",
    "WHITE",
    "RED",
    "GREEN",
    "YELLOW",
    "BLUE",
    "MAGENTA",
    "CYAN"
];

static assert(colors.length == colorNames.length);

class Screen
{

    static string _colorMixin()
    {
        string result = "";
        short pair = 1;
        for (short i = 0; i < colors.length; i++)
        {
            for (short j = 0; j < colors.length; j++)
            {
                result ~= "enum " ~ colorNames[(j + 1) % colors.length] ~ "_ON_" ~ colorNames[i] ~ " = " ~ to!string(pair++) ~ ";\n";
            }
        }
        return result;
    }

    /////////////////
    // Constructor //
    /////////////////

    this()
    {
        initNCurses();
        initColors();
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

    void initColors()
    {
        short pair = 1;
        for (short i = 0; i < colors.length; i++)
        {
            for (short j = 0; j < colors.length; j++)
            {
                init_pair(pair++, colors[(j + 1) % colors.length], colors[i]);
            }
        }
    }
}

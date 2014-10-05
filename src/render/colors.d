module render.colors;
import deimos.ncurses.ncurses;
import std.string;
import std.conv;
import util.log;

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

class Colors
{
    static int numberOfColors()
    {
        return tigetnum(cast(char*)"colors"); 
    }

    static void initColors()
    {
        log("Console supports ", numberOfColors(), " colors");

        short pair = 1;
        for (short i = 0; i < colors.length; i++)
        {
            for (short j = 0; j < colors.length; j++)
            {
                init_pair(pair++, colors[(j + 1) % colors.length], colors[i]);
            }
        }
    }

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


};

mixin(Colors._colorMixin);

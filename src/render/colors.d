module render.colors;
import deimos.ncurses.ncurses;
import render.window;
import std.string;
import std.conv;
import std.exception;
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
        log("Constant says it supports ", COLORS, " colors");
        use_default_colors();

        short pair = 1;
        for (short i = 0; i < colors.length; i++)
        {
            for (short j = 0; j < colors.length; j++)
            {
                init_pair(pair++, colors[(j + 1) % colors.length], colors[i]);
            }
        }
    }

    static void setColor(ushort c)
    {
        // TODO: 256 colors?
        attron(COLOR_PAIR(c)); 
    }

    static void unsetColor(ushort c)
    {
        attroff(COLOR_PAIR(c));
    }

    static void setColor(Window w, ushort c)
    {
        if (w is null || w.handle is null)
        {
            throw new Exception("Failed to set the color of window");
        }

        wattron(w.handle, COLOR_PAIR(cast(byte)c));
    }

    static void unsetColor(Window w, ushort c)
    {
        if (w is null || w.handle is null)
        {
            throw new Exception("Failed to unset the color of window");
        }

        wattroff(w.handle, COLOR_PAIR(cast(byte)c));
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

    // Developer tool:
    static void drawPallete(Window win)
    {
        win.clear();
        win.print("        ");
        for (int i = 0; i < colors.length; ++i)
        {
            win.print(colorNames[(i+1) % colors.length]);
            win.print(" ");
        }
        win.print("\n");
        ushort pair = 1;
        for (int i = 0; i < colors.length; ++i)
        {
            win.print(colorNames[i]);
            for (ulong j = colorNames[i].length; j < colors.length; ++j) win.print(" ");
            for (int j = 0; j < colors.length; ++j)
            {
                for (ulong k = 0; k < colorNames[(j+1) % colors.length].length; ++k) win.print("-", pair);
                pair += 1;
                win.print(" ");
            }
            win.print("\n");
        }
        win.refresh();
    }
};

mixin(Colors._colorMixin);

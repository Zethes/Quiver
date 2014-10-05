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
    static short numberOfColors()
    {
        return cast(short)tigetnum(cast(char*)"colors"); 
    }

    static void initColors()
    {
        log("Console supports ", numberOfColors(), " colors");
        use_default_colors();

        short pair = 1;
        for (short i = 0; i < numberOfColors(); ++i)
        {
            for (short j = 0; j < numberOfColors(); ++j)
            {
                if (i < colors.length && j < colors.length)
                    init_pair(pair++, colors[(j+1) % colors.length], colors[i]);
                else
                    init_pair(pair++, i, j);
            }
        }
    }

    //RGB (1 - 1000)
    static void changeColor(ushort id, ushort r, ushort g, ushort b)
    {
        init_color(id, r, g, b);
    }

    static void setColor(ushort c)
    {
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

        wattron(w.handle, COLOR_PAIR(c));
    }

    static void unsetColor(Window w, ushort c)
    {
        if (w is null || w.handle is null)
        {
            throw new Exception("Failed to unset the color of window");
        }

        wattroff(w.handle, COLOR_PAIR(c));
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
        if (numberOfColors() > 8)
        {
            win.clear();
            ushort n = 0;
            for (int i = 0; i < numberOfColors(); i += 8)
            {
                for (int j = 0; j < 8; ++j)
                {
                    win.print(format("%x\t", n), n++);
                }
                win.print("\n");
            }
            win.refresh();
            return;
        }

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

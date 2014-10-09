module quiver.ui.main;

import render;
import util.vector;
import util.log;

class UI
{
    static register(string name, Window window)
    {
        windows ~= window;
        windowNames ~= name;
    }

    static Window getWindow(string name)
    {
        foreach (i, win; windows)
        {
            if (name == windowNames[i])
            {
                return win;
            }
        }

        return null;
    }

    static draw(VectorI screenSize)
    {
        foreach (i, win; windows)
        {
            win.clear();
            win.addBorder();
            win.print(VectorI(1,0), windowNames[i]);
            win.draw();
            win.refresh();
        }
    }

private:
    static Window[] windows;
    static string[] windowNames;
};


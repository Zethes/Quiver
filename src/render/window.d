module render.window;
import deimos.ncurses.ncurses;
import render.canvas;
import std.string;
import util.vector;

class Window
{
    this(VectorI position, int width, int height)
    {
        handle = newwin(height, width, position.x, position.y);
        box(handle, 0, 0);
        refresh();
    }

    this(WINDOW* handle)
    {
        this.handle = handle;
    }

    void clear()
    {
        wmove(handle, 0, 0);

        char[] text = new char[size.product()];
        text[] = ' ';

        print(text);

        wmove(handle, 0, 0);
    }

    void move(VectorI pos)
    {
        wmove(handle, pos.y, pos.x);
    }

    void print(T)(T object)
    {
        wprintw(handle, toStringz(format("%s", object)));
    }

    void print(T : Canvas)(T canvas)
    {
        for (int h = 0; h < canvas.height; h++)
        {
            for (int w = 0; w < canvas.width; w++)
            {
                print(canvas.at(w, h));
            }
            if (getcurx(handle) != 0)
            {
                print('\n');
            }
        }
    }

    void refresh()
    {
        wrefresh(handle);
    }

    @property VectorI size() const
    {
        VectorI size;
        getmaxyx(cast(WINDOW*)handle, size.y, size.x);
        size.x++;
        size.y++;
        return size;
    }
private:
    WINDOW* handle;
}

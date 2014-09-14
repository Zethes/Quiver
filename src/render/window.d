module render.window;
import deimos.ncurses.ncurses;
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
        wclear(handle);
    }

    void move(VectorI pos)
    {
        wmove(handle, pos.y, pos.x);
    }

    void print(T)(T object)
    {
        wprintw(handle, toStringz(format("%s", object)));
    }

    void refresh()
    {
        wrefresh(handle);
    }

    VectorI getSize()
    {
        VectorI size;
        getmaxyx(handle, size.y, size.x);
        return size;
    }
private:
    WINDOW* handle;
}

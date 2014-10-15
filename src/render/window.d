module render.window;
import deimos.ncurses.ncurses;
import render.canvas;
import render.colors;
import std.conv;
import std.string;
import util.log;
import util.vector;

class Window
{
    this(VectorI position, VectorI size)
    {
        _create(position, size);
    }

    this(WINDOW* handle)
    {
        _handle = handle;
    }

    ~this()
    {
        _free();
    }

    void clear()
    {
        if (_expectedSize.x != 0 && _expectedSize.y != 0 && size != _expectedSize)
        {
            size = _expectedSize;
        }

        wmove(_handle, 0, 0);

        char[] text = new char[size.product()];
        text[] = ' ';

        print(text);

        wmove(_handle, 0, 0);
    }

    void move(VectorI pos)
    {
        wmove(_handle, pos.y, pos.x);
    }

    void print(T)(VectorI position, T object, ushort color = WHITE_ON_BLACK)
    {
        move(position);
        print(object, color);
    }

    void print(T)(T object, ushort color = WHITE_ON_BLACK)
    {
        Colors.setColor(this, color);
        wprintw(_handle, toStringz(format("%s", object)));
        Colors.unsetColor(this, color);
    }

    void print(T : Canvas)(VectorI position, T canvas)
    {
        move(position);
        print(canvas);
    }

    void print(T : Canvas)(T canvas)
    {
        VectorI startCursor = cursor;
        move(canvas.dirtyTopLeft);
        for (int h = canvas.dirtyTopLeft.y; h < canvas.dirtyBottomRight.y; h++)
        {
            size_t pos = getcurx(_handle);
            for (int w = canvas.dirtyTopLeft.x; w < canvas.dirtyBottomRight.x; w++)
            {
                if (pos++ < size.x)
                {
                    Block block = canvas.at(w, h);
                    print(block.character, block.color);
                }
                else
                {
                    break;
                }
            }
            if (getcurx(_handle) != 0)
            {
                move(startCursor + VectorI(canvas.dirtyTopLeft.x, h + 1));
            }
        }
        move(canvas.size - VectorI(1, 1));
    }

    void addBorder()
    {
        //wborder(_handle, '|', '|', '-', '-', '+', '+', '+', '+');
        box(_handle, 0, 0);
    }

    void refresh()
    {
        wnoutrefresh(_handle);
    }

    @property VectorI size() const
    {
        VectorI size;
        getmaxyx(cast(WINDOW*)_handle, size.y, size.x);
        size.x++;
        size.y++;
        return size;
    }

    @property void size(const VectorI size)
    {
        VectorI oldPosition = position;
        _free();
        _create(oldPosition, size);
    }

    @property VectorI position() const
    {
        VectorI position;
        getbegyx(cast(WINDOW*)_handle, position.y, position.x);
        return position;
    }

    @property void position(const VectorI pos)
    {
        VectorI oldSize = size;
        _free();
        _create(pos, oldSize);
    }

    void resize(const VectorI pos, const VectorI size)
    {
        wresize(_handle, size.y, size.x);
        mvwin(_handle, pos.y, pos.x);
    }

    @property VectorI cursor() const
    {
        VectorI result;
        getyx(cast(WINDOW*)_handle, result.y, result.x);
        return result;
    }

    @property void cursor(VectorI cursor)
    {
        wmove(_handle, cursor.y, cursor.x);
    }

    @property WINDOW* handle() { return _handle; }

    void draw()
    {
    }

private:

    WINDOW* _handle;
    VectorI _expectedSize;

    void _create(VectorI position, VectorI size)
    {
        _handle = newwin(size.y, size.x, position.y, position.x);
        refresh();
        _expectedSize = size;
    }

    void _free()
    {
        delwin(_handle);
        _handle = null;
    }

}

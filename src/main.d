import std.stdio;
import deimos.ncurses.ncurses;

int main(string[] argv)
{
    WINDOW* win = initscr();
    printw("Hello world!");
    wrefresh(win);
    wgetch(win);
    endwin();

    return 0;
}

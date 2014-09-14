import std.stdio;
import deimos.ncurses.ncurses;

int main(string[] argv)
{
    WINDOW* win = initscr();
    printw("Hello world!");
    wrefresh(win);
    int ch = getch();
    while (true){}
    endwin();

    return 0;
}

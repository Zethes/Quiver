import std.stdio;
import core.thread;
import render.canvas;
import render.screen;
import render.window;
import util.vector;

int main(string[] argv)
{
    Screen screen = null;
    try
    {
        screen = new Screen;
        Window window = screen.getMainWindow();
        Window childWindow = new Window(VectorI(5, 5), 15, 3);

        // Create canvas
        Canvas canvas = new Canvas(3, 3);
        VectorI pos = VectorI(2, 2);
        canvas.at(pos) = '@';

        // Main loop
        bool running = true;
        while (running)
        {
            // Resize canvas (no-op if already that size)
            canvas.resize(window.size.x, window.size.y);

            // Do input
            int key;
            while (screen.getKey(key))
            {
                if (key == 'q')
                {
                    running = false;
                }
                if (key == 'h')
                {
                    canvas.at(pos) = ' ';
                    pos.x -= 1;
                    canvas.at(pos) = '@';
                }
                if (key == 'j')
                {
                    canvas.at(pos) = ' ';
                    pos.y += 1;
                    canvas.at(pos) = '@';
                }
                if (key == 'k')
                {
                    canvas.at(pos) = ' ';
                    pos.y -= 1;
                    canvas.at(pos) = '@';
                }
                if (key == 'l')
                {
                    canvas.at(pos) = ' ';
                    pos.x += 1;
                    canvas.at(pos) = '@';
                }
            }

            // Draw main window
            window.move(VectorI(0, 0));
            window.print(canvas);

            // Draw child window
            childWindow.clear();
            childWindow.print("test window with a lot of text in it!");

            // Refresh screen
            window.refresh();
            childWindow.refresh();

            // Sleep for 16 milliseconds
            Thread.sleep(dur!("msecs")(1));
        }

        return 0;
    }
    catch (Error e)
    {
        if (screen)
        {
            screen.cleanup();
        }

        writeln(e);
        return -1;
    }
}

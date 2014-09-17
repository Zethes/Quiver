import std.conv;
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
        // Initialize the screen (ncurses) and grab the main window
        screen = new Screen;
        Window window = screen.mainWindow;

        // Create a child window
        Window childWindow = new Window(VectorI(1, 1), 18, 3);

        // Create canvas
        Canvas canvas = new Canvas(50, 50);
        VectorI pos = VectorI(8, 6);
        canvas.at(pos).character = '@';
        canvas.at(pos).color = YELLOW_ON_BLACK;

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
                canvas.at(pos).reset();
                if (key == 'q')
                {
                    running = false;
                }
                if (key == 'h')
                {
                    pos.x -= 1;
                }
                if (key == 'j')
                {
                    pos.y += 1;
                }
                if (key == 'k')
                {
                    pos.y -= 1;
                }
                if (key == 'l')
                {
                    pos.x += 1;
                }
                pos.clamp(VectorI(0, 0), window.size - VectorI.one);
                canvas.at(pos).character = '@';
                canvas.at(pos).color = YELLOW_ON_BLACK;
            }

            // Print color table
            for (int i = 0; i < 8; i++)
            {
                for (int j = 0; j < 8; j++)
                {
                    canvas.at(j + 20, i + 20).character = 'W';
                    canvas.at(j + 20, i + 20).color = cast(byte)(i + 8 * j + 1);
                }
            }

            // Draw main window
            window.move(VectorI(0, 0));
            window.print(canvas);

            // Draw child window
            childWindow.clear();
            childWindow.print("welcome to quiver!move with hjkl!\npress q to quit!");

            // Refresh screen
            window.refresh();
            childWindow.refresh();

            // Sleep for 16 milliseconds
            Thread.sleep(dur!("msecs")(16));
        }

        return 0;
    }
    catch (Error e)
    {
        // Close ncurses so that the error message will print to stdout
        if (screen)
        {
            screen.close();
        }

        // Print error and quit
        writeln(e);
        return -1;
    }
}

import std.stdio;
import core.thread;
import render.screen;
import render.window;
import util.vector;

int main(string[] argv)
{
    Screen screen = new Screen;
    Window window = screen.getMainWindow();

    // Main loop
    bool running = true;
    while (running)
    {
        // Do input
        int key;
        while (screen.getKey(key))
        {
            if (key == 'q')
            {
                running = false;
            }
        }

        // Draw window
        VectorI screenSize = window.getSize();
        window.clear();
        window.print("Welcome to Quiver v0.01!\n");
        window.print("Screen size: " ~ screenSize.toString());
        window.move(screenSize);
        window.refresh();

        // Sleep for 16 milliseconds
        Thread.sleep(dur!("msecs")(16));
    }

    return 0;
}

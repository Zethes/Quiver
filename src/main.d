import std.stdio;
import core.thread;
import render.screen;
import render.window;
import util.vector;

int main(string[] argv)
{
    Screen screen = new Screen;
    Window window = screen.getMainWindow();
    Window childWindow = new Window(VectorI(5, 5), 15, 3);

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

        // Draw main window
        VectorI screenSize = window.getSize();
        window.clear();
        window.print("Welcome to Quiver v0.01!\n");
        window.print("Screen size: " ~ screenSize.toString());

        // Draw child window
        childWindow.clear();
        childWindow.print("test window with a lot of text in it!");

        window.refresh();
        childWindow.refresh();

        // Sleep for 16 milliseconds
        Thread.sleep(dur!("msecs")(16));
    }

    return 0;
}

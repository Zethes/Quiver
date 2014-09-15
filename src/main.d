import std.stdio;
import core.thread;
import render.canvas;
import render.screen;
import render.window;
import util.vector;

int main(string[] argv)
{
    Screen screen = new Screen;
    Window window = screen.getMainWindow();
    Window childWindow = new Window(VectorI(5, 5), 15, 3);

    // Create canvas
    Canvas canvas = new Canvas(15, 3);
    VectorI pos = VectorI(2, 2);
    canvas.at(pos) = '@';

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

        // Resize canvas (no-op if already that size)
        canvas.resize(window.getSize().x, window.getSize().y);

        // Draw main window
        VectorI screenSize = window.getSize();
        window.move(VectorI(0, 0));
        window.print(canvas);

        // Draw child window
        childWindow.clear();
        childWindow.print("test window with a lot of text in it!");

        window.refresh();
        childWindow.refresh();

        // Sleep for 16 milliseconds
        Thread.sleep(dur!("msecs")(100));
    }

    return 0;
}

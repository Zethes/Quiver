module quiver.states.menustate;

import render.screen;
import settings;
import quiver.states.gamestate;
import util.statemachine;

class MenuState : State
{

    this(StateMachine fsm, Screen screen)
    {
        _fsm = fsm;
        _screen = screen;
    }

    ~this()
    {
    }

    void enter()
    {
    }

    void update()
    {
        int key;
        while (_screen.getKey(key))
        {
            if (key == 'q')
            {
                global.running = false;
            }
            else if (key == 'h')
            {
                GameSettings settings;
                settings.port = 1333;
                settings.server = true;
                settings.client = true;
                _fsm.enterState(new GameState(_fsm, _screen, settings));
            }
            else if (key == 'c')
            {
                GameSettings settings;
                settings.host = "127.0.0.1";
                settings.port = 1333;
                settings.client = true;
                _fsm.enterState(new GameState(_fsm, _screen, settings));
            }
        }
        _screen.mainWindow.clear();
        _screen.mainWindow.print("Quiver!\n\nPress h to host a game.\nPress c to join a game.\nPress q to quit.");
        _screen.mainWindow.refresh();
        _screen.update();
    }

    void exit()
    {
    }

private:

    StateMachine _fsm;
    Screen _screen;

}

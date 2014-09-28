module util.statemachine;

interface State
{
    void enter();
    void update();
    void exit();
}

class StateMachine
{

    this()
    {
        _state = null;
        _nextState = null;
    }

    void enterState(State state)
    {
        _nextState = state;
    }

    void update()
    {
        if (_nextState)
        {
            if (_state)
            {
                _state.exit();
            }
            _state = _nextState;
            _state.enter();
            _nextState = null;
        }
        if (_state)
        {
            _state.update();
        }
    }

private:

    State _state;
    State _nextState;

}

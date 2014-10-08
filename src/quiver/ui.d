module quiver.ui;
import render.window;
import render.screen;
import render.canvas;
import render.colors;
import util.vector;
import util.log;

class UI
{
    static register(string name, Window window)
    {
        windows ~= window;
        windowNames ~= name;
    }

    static Window getWindow(string name)
    {
        foreach (i, win; windows)
        {
            if (name == windowNames[i])
            {
                return win;
            }
        }

        return null;
    }

    static draw(VectorI screenSize)
    {
        foreach (i, win; windows)
        {
            win.clear();
            win.addBorder();
            win.print(VectorI(1,0), windowNames[i]);
            win.draw();
            win.refresh();
        }
    }

private:
    static Window[] windows;
    static string[] windowNames;
};

enum ChatMessageTypes
{
    clientMessage,
};

class ChatWindow : Window
{
    this(VectorI screenSize, int maxMsgs = 1024)
    {
        this.maxMsgs = maxMsgs;
        resize(screenSize);
        super(pos, size);
    }

    void resize(VectorI screenSize)
    {
        //TODO dynamic this shit.
        size = VectorI(screenSize.x, 7);
        pos = VectorI(0, screenSize.y - size.y);
        super.resize(pos, size);
    }
    
    void addMessage(ChatMessageTypes type, string msg)
    {
        messages ~= msg;
        types ~= type;

        if (messages.length > maxMsgs) {
            
        }
    }

    override void draw()
    {
        auto msgPos = VectorI(1,1);
        
        //TODO: last X messages.
        for (auto i = 0; i < messages.length; ++i)
        {
            string msg = messages[i];

            byte color = WHITE_ON_BLACK;
            switch (types[i])
            {
                case ChatMessageTypes.clientMessage: 
                    color = YELLOW_ON_BLACK;
                    break;
                default:
                    color = WHITE_ON_BLACK;
                    break;
            }

            print(msgPos, msg, color);
            msgPos.y++;

            if (msg.length >= size.x-2)
                msgPos.y++;

            if (msgPos.y >= size.y - 1)
                break;
        }
    }
private:
    VectorI pos, size;
    string[] messages;
    int maxMsgs;
    ChatMessageTypes[] types;
};

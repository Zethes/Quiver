module util.vector;
import std.string;

struct Vector(T)
{
    T x = 0;
    T y = 0;

    string toString() const
    {
        return format("%s, %s", x, y);
    }

    T product()
    {
        return x * y;
    }
}

alias VectorI = Vector!(int);
alias VectorF = Vector!(float);

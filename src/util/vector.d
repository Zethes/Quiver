module util.vector;
import std.string;
import std.traits;

struct Vector(T)
{
    static const Vector!T one;

    static this()
    {
        one = Vector!T(1);
    }

    T x = 0;
    T y = 0;

    this(T value)
    {
        x = y = value;
    }

    this(T x, T y)
    {
        this.x = x;
        this.y = y;
    }

    Vector!T opBinary(string op)(const Vector!T rhs) const
    {
        static if (op == "+")
        {
            return Vector!T(x + rhs.x, y + rhs.y);
        }
        else static if(op == "-")
        {
            return Vector!T(x - rhs.x, y - rhs.y);
        }
        else
        {
            static assert(false, "Operator " ~ op ~ " not implemented.");
        }
    }

    Vector!T opBinary(string op)(const T rhs) const
        if (isNumeric!T)
    {
        static if (op == "*")
        {
            return Vector!T(x * rhs, y * rhs);
        }
        else static if(op == "/")
        {
            return Vector!T(x / rhs, y / rhs);
        }
        else
        {
            static assert(false, "Operator " ~ op ~ " not implemented.");
        }
    }

    ref Vector!T opOpAssign(string op)(const Vector!T rhs)
    {
        this = opBinary!op(rhs);
        return this;
    }

    string toString() const
    {
        return format("%s, %s", x, y);
    }

    T product()
    {
        return x * y;
    }

    void clamp(Vector!T min, Vector!T max)
    {
        if (x < min.x) x = min.x;
        if (y < min.y) y = min.y;
        if (x > max.x) x = max.x;
        if (y > max.y) y = max.y;
    }
}

alias VectorI = Vector!(int);
alias VectorF = Vector!(float);

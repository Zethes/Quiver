module util.math;

import util.vector;

Vector!T clamp(T)(const Vector!T value, const Vector!T a, const Vector!T b)
{
    Vector!T result = value;
    result.clamp(a, b);
    return result;
}

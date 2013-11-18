import pack;
import algorithm : Equal, AllEqual;

template Seq(T ...)
{
    alias Seq = T;
}

template I(A ...)
{
    static if(A.length == 1)
    {
	alias I = A[0];
    }
    else
    {
	alias I = A;
    }
}


//These don't belong here:
//  Where should they go? std.meta.typeops?
//  std.traits?

template hasType(alias A, T)
{
    static if(is(typeof(A) == T))
    {
        enum hasType = true;
    }
    else
    {
	enum hasType = false;
    }
}

template hasType(T)
{
    template _hasType(alias A)
    {
	enum _hasType = hasType!(A, T);
    }
    alias hasType = _hasType;
}

template canBe(alias A, T)
{
    static if(is(typeof(A) : T))
    {
	enum canBe = true;
    }
    else
    {
	enum canBe = false;
    }
}

template canBe(T)
{
    template _canBe(alias A)
    {
	enum _canBe = canBe!(A, T);
    }
    alias canBe = _canBe;
}

template stringOf(alias T)
{
    enum stringOf = T.stringof;
}

template stringOf(T ...)
if(T.length == 1)
{
    enum stringOf = (T[0]).stringof;
}


template MakeArrayType(T)
{
    mixin(`alias MakeArrayType = ` ~ T.stringof ~ "[];");
}

template MakePointerType(T)
{
    mixin(`alias MakePointerType = ` ~ T.stringof ~ "*;");
}

//what even are ref types? you can get one using
//std.traits.parameterTypeTuple
/+
template MakeRefType(T)
{
    mixin(`alias MakeRefType = ` ~ "ref " ~ __traits(identifier, T) ~ ";");
}
+/

alias Reverse(TList ...) = Retro!(Pack!TList).Unpack;

unittest
{
    static assert(is(Reverse!() == Seq!()));
    static assert((Reverse!(1) == Seq!(1)));
    static assert(is(Reverse!(int) == Seq!(int)));
    static assert(AllEqual!(Pack!(Reverse!(1, int)), Pack!(int, 1)));
    static assert(Equal!(Pack!(Reverse!(Pack, Unpack)), Pack!(Seq!(Unpack, Pack))));
}

unittest
{
    alias Types = Seq!(int, long, long, int, float);

    alias TL = Reverse!(Types);
    static assert(is(TL == Seq!(float, int, long, long, int)));
}

/**
 * With the builtin alias declaration, you cannot declare
 * aliases of, for example, literal values. You can alias anything
 * including literal values via this template.
 */
// symbols and literal values
template Alias(alias a)
{
    static if (__traits(compiles, { alias x = a; }))
        alias Alias = a;
    else static if (__traits(compiles, { enum x = a; }))
        enum Alias = a;
    else
        static assert(0, "Cannot alias " ~ a.stringof);
}
// types and tuples
template Alias(a...)
{
    alias Alias = a;
}

unittest
{
    enum abc = 1;
    static assert(__traits(compiles, { alias a = Alias!(123); }));
    static assert(__traits(compiles, { alias a = Alias!(abc); }));
    static assert(__traits(compiles, { alias a = Alias!(int); }));
    static assert(__traits(compiles, { alias a = Alias!(1,abc,int); }));
}

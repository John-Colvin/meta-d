import algorithm;
import seq;

/**
 * Confines a tuple within a template.
 */
struct Pack(T...)
{
    alias isSame = Equal;
    alias T Unpack;

    // For convenience. NOT GOOD. pass single pack and break
    template equals(U...)
    {
        static if (T.length == U.length)
        {
            static if (T.length == 0)
                enum equals = true;
            else
                enum equals = isSame!(T[0], U[0]) &&
                    Pack!(T[1 .. $]).equals!(U[1 .. $]);
        }
        else
        {
            enum equals = false;
        }
    }

    enum length = T.length;

    //include other operations as template members?
    //must have free templates as well for functional work.
    //Which will contain the implementation?
}

unittest
{
    static assert( Pack!(1, int, "abc").equals!(1, int, "abc"));
    static assert(!Pack!(1, int, "abc").equals!(1, int, "cba"));
}

template isPack(TList ...)
{
    static if(TList.length == 1 &&
	      is(Pack!(TList[0].Unpack) == TList[0]))
    {
	enum isPack = true;
    }
    else
    {
	enum isPack = false;
    }
}

unittest
{
    alias a = Pack!(int, 1);
    static assert(isPack!a);
    alias b = Seq!(int, 1);
    static assert(!isPack!b);
}


//Is it really right/necessary to have alias A??
template Unpack(alias A)
    if(isPack!A)
{
    alias Unpack = A.Unpack;
}

unittest
{
    static assert(Unpack!(Pack!(1,2)) == Seq!(1,2));
}

template Empty(T)
    if(isPack!T)
{
    static if(T.length == 0)
    {
	enum Empty = true;
    }
    else
    {   
	enum Empty = false;
    }
}

unittest
{
    static assert(Empty!(Pack!()));
    static assert(!Empty!(Pack!1));
}

template hasLength(size_t len, T)
    if(isPack!T)
{
    static if(T.length == len)
    {
	enum hasLength = true;
    }
    else
    {   
	enum hasLength = false;
    }
}

unittest
{
    static assert(hasLength!(2, Pack!(0,1)));
}

template hasLength(size_t len)
{
    template _hasLength(T)
    {
	enum _hasLength = hasLength!(len, T);
    }
    alias hasLength = _hasLength;
}

template Slice(P, size_t i0, size_t i1)
    if(isPack!P)
{
    alias Slice = Pack!(P.Unpack[i0 .. i1]);
}

template Index(P, size_t i)
    if(isPack!P)
{
    alias Index = Alias!(P.Unpack[i]);
}

template Index(size_t i)
{
    template _Index(P)
	if(isPack!P)
    {
	alias _Index = Index!(P, i);
    }
    alias Index = _Index;
}

template Index(P)
    if(isPack!P)
{
    template _Index(size_t n)
    {
	alias _Index = Index!(P, n);
    }
    alias Index = _Index;
}

template Chain(T ...)
    if(All!(isPack, Pack!T))
{
    alias Chain = Map!(Unpack, Pack!T);
}

unittest
{
    static assert(is(Chain!(Pack!(1,2,3), Pack!(4,5,6)) == Pack!(1,2,3,4,5,6)));
    static assert(is(Chain!(Pack!(1,2,3), Pack!()) == Pack!(1,2,3)));
}

//what if front is enum?
template Front(T)
    if(isPack!T)
{
    static if(__traits(compiles, { alias Front = T.Unpack[0]; }))
    {
	alias Front = T.Unpack[0];
    }
    else
    {
	enum Front = T.Unpack[0];
    }
}

unittest
{
    static assert(Front!(Pack!(1,2,3)) == 1);
    static assert(is(Front!(Pack!(int, long)) == int));
}

/**
 * Get the last element of a Pack.
 */
template Back(A)
    if(isPack!A)
{
    static if(__traits(compiles, { alias Back = T.Unpack[0]; }))
    {
	alias Back = A.Unpack[$-1];
    }
    else
    {
        enum Back = A.Unpack[$-1];
    }
}

unittest
{
    static assert(Back!(Pack!(1,2,3)) == 3);
    static assert(is(Back!(Pack!(int, long)) == long));
}

/**
 * Results in the given Pack minus it's head. Returns an empty Pack when given
 * an input length <= 1
 */
template Tail(A)
    if(isPack!A)
{
    static if(A.length == 0)
    {
        alias Tail = Pack!();
    }
    alias Tail = Slice!(A, 1, A.length);
}

unittest
{
    static assert(is(Tail!(Pack!(short, int, long)) == Pack!(int, long)));
}


/**
 * Reverses a given $(D Pack)
 */
template Retro(TList)
    if(isPack!TList)
{
//    pragma(msg, Retro);
    static if (TList.length <= 1)
    {
        alias Retro = TList;
    }
    else
    {
        alias Retro =
            Chain!(
                Retro!(Pack!(TList.Unpack[$/2 ..  $ ])),
                Retro!(Pack!(TList.Unpack[ 0  .. $/2])));
    }
}

///
unittest
{
    alias Types = Pack!(int, long, long, int, float);

    alias TL = Retro!(Types);
    static assert(is(TL == Pack!(float, int, long, long, int)));
}


template Stride(TList, size_t n)
    if(isPack!TList)
{
    static assert(n != 0, "n cannot be 0");
    static if(n == 1)
    {
	alias Stride = TList;
    }
    else static if(n >= TList.length)
    {
	alias Stride = Front!TList;
    }
    else
    {
	alias Stride = Pack!(Front!TList, Stride!(TList.Unpack[n .. $]).Unpack);
    }
}


template RoundRobin(Packs ...)
    if(All!(isPack, Packs))
{
    alias RoundRobin = Pack!(Map!(Unpack, Zip!(Packs)));
}


template Radial(P, size_t index = P.length / 2)
    if(isPack!P)
{
    alias Radial = RoundRobin!(Retro!(Slice!(P, 0, index+1)),
			       Slice!(P, index+1, P.length));
}


template Take(P, size_t n)
    if(isPack!P)
{
    alias Take = Slice!(P, 0, n);
}


template Drop(P, size_t n)
    if(isPack!P)
{
    alias Drop = Slice!(P, n, P.length);
}


template DropBack(P, size_t n)
    if(isPack!P)
{
    alias DropBack = Slice!(P, 0, P.length - n);
}


/**
 * Repeats A n times.
 * If only a size is passed, Repeat results in a template that is pre-set to 
 * repeat it's arguments n times
 */
template Repeat(alias A, size_t n)
{
    static if(n == 0)
    {
        alias Repeat = Pack!();
    }
    else
    {
        alias Repeat = Pack!(A, Repeat!(A, n-1).Unpack);
    }
}
template Repeat(A, size_t n)
{
    static if(n == 0)
    {
        alias Repeat = Pack!();
    }
    else
    {
        alias Repeat = Pack!(A, Repeat!(A, n-1).Unpack);
    }
}

///
unittest
{
    static assert(Repeat!(5,4) == Pack!(4,4,4,4,4));
    static assert(is(Repeat!(2, int, uint) == Seq!(int, uint, int, uint)));
}

template Repeat(size_t n)
{
    template _Repeat(T ...)
    {
        alias _Repeat = Repeat!(n, T);
    }
    alias Repeat = _Repeat;
}


template Cycle(P, size_t n)
    if(isPack!P)
{
    static if(n == 0)
    {
        alias Cycle = Pack!();
    }
    else
    {
        alias Cycle = Chain!(P, Cycle!(P, n-1));
    }
}


template Sequence(alias F, size_t length, State ...)
{
    alias Sequence = SequenceImpl!(F, length, State.length, Pack!(State));
}

private template SequenceImpl(alias F, size_t length, size_t stateLength, State)
{
    static if(length == State.length)
    {
	alias SequenceImpl = State;
    }
    else
    {
	alias newState = Chain!(State, Pack!(F!(State[$ - stateLength .. $])));
	alias SequenceImpl = SequenceImpl!(F, length, stateLength, newState);
    }
}

/++
This template will generate a type tuple of values over a range.
This is can particularly useful when a static $(D foreach) is desired.

The range starts at $(D begin), and is increment by $(D step) until the value $(D end) has
been reached. $(D begin) defaults to $(D 0), and $(D step) defaults to $(D 1).

The range returned by Iota can be expanded upon with $(XREF typetuple,TypeTuple).

See also $(XREF range,iota).
+/
template Iota(alias end)
{
    alias E = typeof(end);
    alias Iota = IotaImpl!(E, 0, end, 1);
}
///ditto
template Iota(alias begin, alias end)
{
    alias E = CommonType!(typeof(begin), typeof(end));
    alias Iota = IotaImpl!(E, begin, end, 1);
}
///ditto
template Iota(alias begin, alias end, alias step)
{
    alias E = CommonType!(typeof(begin), typeof(end), typeof(step));
    alias Iota = IotaImpl!(E, begin, end, step);
}

private template IotaImpl(E, E begin, E end, E step)
{
    static if (!isScalarType!E)
    {
        static assert(0, "Iota: parameters must be scalar types.");
    }
    else static if (step > 0 && begin + step >= end)
    {
        static if (begin < end)
            alias IotaImpl = TypeTuple!begin;
        else
            alias IotaImpl = TypeTuple!();
    }
    else static if (step < 0 && begin + step <= end)
    {
        static if (begin > end)
            alias IotaImpl = TypeTuple!begin;
        else
            alias IotaImpl = TypeTuple!();
    }
    else static if (begin == end)
    {
        alias IotaImpl = TypeTuple!();
    }
    else static if (step)
    {
        enum newbeg = begin + step;
        enum mid1 = step + (end - newbeg) / 2;
        enum mid = begin + mid1 - (mid1 % step);
        alias IotaImpl = TypeTuple!(.IotaImpl!(E, begin, mid, step), .IotaImpl!(E, mid, end, step));
    }
    else
    {
        static assert(0, "step must be non-0 for begin != end");
    }
}

unittest
{
    static assert(Iota!(0).length == 0);

    int[] a;
    foreach (n; Iota!5)
        a ~= n;
    assert(a == [0, 1, 2, 3, 4]);

    a.length = 0;
    foreach (n; Iota!(-5))
        a ~= n;
    assert(a.length == 0);

    a.length = 0;
    foreach (n; Iota!(4, 7))
        a ~= n;
    assert(a == [4, 5, 6]);

    a.length = 0;
    foreach (n; Iota!(-1, 4))
        a ~= n;
    assert(a == [-1, 0, 1, 2, 3]);

    a.length = 0;
    foreach (n; Iota!(4, 2))
        a ~= n;
    assert(a.length == 0);

    a.length = 0;
    foreach (n; Iota!(0, 10, 2))
        a ~= n;
    assert(a == [0, 2, 4, 6, 8]);

    a.length = 0;
    foreach (n; Iota!(3, 15, 3))
        a ~= n;
    assert(a == [3, 6, 9, 12]);

    a.length = 0;
    foreach (n; Iota!(15, 3, 1))
        a ~= n;
    assert(a.length == 0);

    a.length = 0;
    foreach (n; Iota!(10, 0, -1))
        a ~= n;
    assert(a == [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);

    a.length = 0;
    foreach (n; Iota!(15, 3, -2))
        a ~= n;
    assert(a == [15, 13, 11, 9, 7, 5]);

    a.length = 0;
    foreach(n; Iota!(0, -5, -1))
        a ~= n;
    assert(a == [0, -1, -2, -3, -4]);

    foreach_reverse(n; Iota!(-4, 1))
    assert(a == [0, -1, -2, -3, -4]);

    static assert(!is(typeof( Iota!(15, 3, 0) ))); // stride = 0 statically
}

unittest
{
    auto foo1()
    {
        double[] ret;
        foreach(n; Iota!(0.5, 3))
            ret ~= n;
        return ret;
    }
    auto foo2()
    {
        double[] ret;
        foreach(j, n; TypeTuple!(Iota!(0, 1, 0.25), 1))
            ret ~= n;
        return ret;
    }
    auto foo3()
    {
        double[] ret;
        foreach(j, n; TypeTuple!(Iota!(1, 0, -0.25), 0))
            ret ~= n;
        return ret;
    }
    auto foo4()
    {
        string ret;
        foreach(n; Iota!('a', 'g'))
            ret ~= n;
        return ret;
    }
    static assert(foo1() == [0.5, 1.5, 2.5]);
    static assert(foo2() == [0, 0.25, 0.5, 0.75, 1]);
    static assert(foo3() == [1, 0.75, 0.5, 0.25, 0]);
    static assert(foo4() == "abcdef");
}


template Transversal(PoP, size_t n)
    if(isPack!PoP && All!(PoP, isPack))
{
    alias Transversal = Map!(Index!(n), PoP);
}

template FrontTransversal(PoP)
    if(isPack!PoP && All!(PoP, isPack))
{
    alias FrontTransversal = Map!(Front, PoP);
}


template Indexed(Source, Indices)
    if(isPack!Source && isPack!Indices)
//should check if indexes are valid type
{
    alias Indexed = Map!(Index!Source, Indices);
}


template Chunks(Source, size_t chunkSize)
    if(isPack!Source)
{
    static if(chunkSize >= Source.length)
    {
	alias Chunks = Pack!(Source);
    }
    else
    {
	alias Chunks = Pack!(Slice!(Source, 0, chunkSize),
			     Chunks!(Slice!(Source, chunkSize, Source.length), chunkSize).Unpack);
    }
}

template Appender(T)
{
    template _Appender(Q)
	if(isPack!T)
    {
        alias _Appender = Pack!(Q.Unpack, T);
    }
    alias Appender = _Appender;
}

template Prepender(T)
{
    template _Prepender(Q)
	if(isPack!T)
    {
        alias _Prepender = Pack!(T, Q.Unpack);
    }
    alias Prepender = _Prepender;
}

template Concat(A, B)
    if(isPack!A && isPack!B)
{
    alias Concat = Pack!(A.Unpack, B.Unpack);
}

template Concat(Packs ...)
    if(All!(isPack, Pack!Packs) && Packs.length > 2)
{
    alias Concat = Concat!(Packs[0], Concat!(Packs[1 .. $]));
}

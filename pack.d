import algorithm : Equal;
import seq;

/**
 * Confines a tuple within a template.
 */
struct Pack(T...)
{
    alias isSame = Equal;
    alias T Unpack;

    // For convenience
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

    //include other operations as template members?
    //must have free templates as well for functional work.
    //Which will contain the implementation
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


//Is it really right to have alias A??
template Unpack(alias A)
    if(isPack!A)
{
    alias Unpack = A.Unpack;
}

unittest
{
    static assert(Unpack!(Pack!(1,2)) == Seq!(1,2));
}

template isEmptyPack(T)
    if(isPack!T)
{
    enum isEmptyPack = isEmptySeq!(T.Unpack);
}

template packHasLength(size_t len, T)
    if(isPack!T)
{
    enum packHasLength = seqHasLength!(len, T.Unpack);
}

template packHasLength(size_t len)
{
    template _packHasLength(T)
    {
	enum _packHasLength = packHasLength!(len, T);
    }
    alias packHasLength = _packHasLength;
}


template appendPacks(T ...)
    if(All!(isPack, T))
{
    alias appendPacks = Pack!(Map!(Unpack, T));
}

unittest
{
    static assert(is(appendPacks!(Pack!(1,2,3), Pack!(4,5,6)) == Pack!(1,2,3,4,5,6)));
}

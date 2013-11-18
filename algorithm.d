import seq;
import pack;
import functional;
import std.traits;

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


/**
 * Returns the index of the first occurrence of type T in the
 * sequence of zero or more types TList.
 * If not found, -1 is returned.
 */
template IndexOf(T, TList)
    if(isPack!TList)
{
    enum IndexOf = genericIndexOf!(T, TList.Unpack).index;
}

/// Ditto
template IndexOf(alias T, TList)
    if(isPack!TList)
{
    enum IndexOf = genericIndexOf!(T, TList.Unpack).index;
}

///
unittest
{
    import std.stdio;

    void foo()
    {
        writefln("The index of long is %s",
                 IndexOf!(long, Pack!(int, long, double)));
        // prints: The index of long is 1
    }
}

// [internal]
private template genericIndexOf(args...)
    if (args.length >= 1)
{
    alias Alias!(args[0]) e;
    alias   args[1 .. $]  tuple;

    static if (tuple.length)
    {
        alias head = Alias!(tuple[0]);
        alias tail = tuple[1 .. $];

        alias isSame = Equal;
        static if (isSame!(e, head))
        {
            enum index = 0;
        }
        else
        {
            enum next  = genericIndexOf!(e, tail).index;
            enum index = (next == -1) ? -1 : 1 + next;
        }
    }
    else
    {
        enum index = -1;
    }
}

unittest
{
    static assert(IndexOf!( byte, Pack!(byte, short, int, long)) ==  0);
    static assert(IndexOf!(short, Pack!(byte, short, int, long)) ==  1);
    static assert(IndexOf!(  int, Pack!(byte, short, int, long)) ==  2);
    static assert(IndexOf!( long, Pack!(byte, short, int, long)) ==  3);
    static assert(IndexOf!( char, Pack!(byte, short, int, long)) == -1);
    static assert(IndexOf!(   -1, Pack!(byte, short, int, long)) == -1);

    static assert(IndexOf!("abc", Pack!("abc", "def", "ghi", "jkl")) ==  0);
    static assert(IndexOf!("def", Pack!("abc", "def", "ghi", "jkl")) ==  1);
    static assert(IndexOf!("ghi", Pack!("abc", "def", "ghi", "jkl")) ==  2);
    static assert(IndexOf!("jkl", Pack!("abc", "def", "ghi", "jkl")) ==  3);
    static assert(IndexOf!("mno", Pack!("abc", "def", "ghi", "jkl")) == -1);
    static assert(IndexOf!( void, Pack!("abc", "def", "ghi", "jkl")) == -1);

    static assert(IndexOf!(void, Pack!(0, "void", void) == 2));
    static assert(IndexOf!("void", Pack!(0, void, "void") == 2));
}

/**
Evaluates to $(D Seq!(F!(T[0]), F!(T[1]), ..., F!(T[$ - 1]))).
 */
template Map(alias F, TL)
    if(isPack!TL)
{
    static if (TL.length == 0)
    {
        alias Map = Pack!();
    }
    else static if (TL.length == 1)
    {
        alias Map = Pack!(F!(Index!(TL, 0)));
    }
    else
    {
        alias Map = Pack!(
	    Map!(F, Slice!(TL, 0, TL.length/2)),
	    Map!(F, Slice!(TL, TL.length/2, TL.length));
    }
}

///
unittest
{
    alias TL = Map!(Unqual, Pack!(int, const int, immutable int));
    static assert(is(TL == Pack!(int, int, int)));
}

unittest
{
    // empty
    alias Empty = Map!(Unqual);
    static assert(Empty.length == 0);

    // single
    alias Single = Map!(Unqual, Pack!(const int));
    static assert(is(Single == Pack!int));
}

/**
Tests whether all given items satisfy a template predicate, i.e. evaluates to
$(D F!(T[0]) && F!(T[1]) && ... && F!(T[$ - 1])).

Evaluation is $(I not) short-circuited if a false result is encountered; the
template predicate must be instantiable with all the given items.
 */
template All(alias F, T)
    if(isPack!(T))
{
    static if (T.length == 0)
    {
        enum All = true;
    }
    else static if (T.length == 1)
    {
        enum All = F!(Index!(T, 0));
    }
    else
    {
        enum All =
            All!(F, Slice!(T, 0, T.length/2)) &&
            All!(F, Slice!(TL, TL.length/2, TL.length));
    }
}

///
unittest
{
    static assert(!All!(isIntegral, Pack!(int, double)));
    static assert( All!(isIntegral, Pack!(int, long)));
}

/**
Tests whether all given items satisfy a template predicate, i.e. evaluates to
$(D F!(T[0]) || F!(T[1]) || ... || F!(T[$ - 1])).

Evaluation is $(I not) short-circuited if a true result is encountered; the
template predicate must be instantiable with all the given items.
 */
template Any(alias F, T)
    if(isPack!T)
{
    static if(T.length == 0)
    {
        enum Any = false;
    }
    else static if (T.length == 1)
    {
        enum Any = F!(T.Unpack[0]);
    }
    else
    {
        enum Any =
            Any!(F, T.Unpack[ 0  .. $/2]) ||
            Any!(F, T.Unpack[$/2 ..  $ ]);
    }
}

///
unittest
{
    static assert(!Any!(isIntegral, Pack!(string, double)));
    static assert( Any!(isIntegral, Pack!(int, double)));
}

/**
 * Filters a $(D Seq) using a template predicate. Returns a
 * $(D Seq) of the elements which satisfy the predicate.
 */
template Filter(alias pred, TL)
    if(isPack!TL)
{
    alias TList = TL.Unpack; //for native indexing

    static if (TList.length == 0)
    {
        alias Filter = Pack!();
    }
    else static if (TList.length == 1)
    {
        static if (pred!(TList[0]))
	{
            alias Filter = Pack!(TList[0]);
	}
        else
	{
            alias Filter = Pack!();
	}
    }
    else
    {
        alias Filter =
            appendPacks!(
                Filter!(pred, TList[ 0  .. $/2]),
                Filter!(pred, TList[$/2 ..  $ ]));
    }
}

template Filter(alias pred, TList...)
{
    alias Filter = Filter!(pred, Pack!TList);
}

///
unittest
{
    alias Types1 = Pack!(string, wstring, dchar[], char[], dstring, int);
    alias TL1 = Filter!(isNarrowString, Types1);
    static assert(is(TL1 == Pack!(string, wstring, char[])));

    alias Types2 = Pack!(int, byte, ubyte, dstring, dchar, uint, ulong);
    alias TL2 = Filter!(isUnsigned, Types2);
    static assert(is(TL2 == Pack!(ubyte, uint, ulong)));
}

unittest
{
    static assert(is(Filter!(isPointer, Pack!(int, void*, char[], int*)) == Pack!(void*, int*)));
    static assert(is(Filter!isPointer == Seq!()));
}

/**
 * Reduce for Packs.
 */
    template Reduce(alias F, alias Seed, T = Pack!())
    if(isPack!T)
{
    static if(T.length == 0)
    {
        alias Reduce = Seed;
    }
    else
    {
        alias Reduce = ReduceImpl!(F, Pack!(Seed, T.Unpack));
    }
}

///
unittest
{
    template Add(alias A, alias B)
    {
        enum Add = A + B;
    }
    static assert(Reduce!(Add, 0, Pack!(1, 2, 3)) == 6);

    static assert(Reduce!(Add, 1) == 1);

    static assert(Reduce!(Add, 4, Pack!(3, 2)) == 9);
}

private template ReduceImpl(alias F, T)
    if(isPack!T)
{
    static if(T.length == 1)
    {
        //pragma(msg, T);
        alias ReduceImpl = T.Unpack[0];
    }
    else
    {
        alias ReduceImpl =
	    ReduceImpl!(F, Pack!(F!(T.Unpack[0], T.Unpack[1]), T.Unpack[2 .. $]));
    }
}

/**
 * Swaps the front elements of two Packed Seqs. The result is a Seq of the two Packs after the operation.
 */
template SwapFront(A, B)
    if(isPack!A && isPack!B)
{
    alias SwapFront = Seq!(Pack!(B.Unpack[0], A.Unpack[1 .. $]), Pack!(A.Unpack[0], B.Unpack[1 .. $]));
}

///
unittest
{
    static assert(is(SwapFront!(Pack!(1,2,3), Pack!(3,2,1)) == Seq!(Pack!(3,2,3), Pack!(1,2,1))));

    alias types = Seq!(Pack!(short, int, long), Pack!(ushort, uint, ulong));
    static assert(is(SwapFront!(SwapFront!types) == types));

    static assert(is(SwapFront!(Pack!(1),Pack!(2)) == Seq!(Pack!(2),Pack!(1))));
}


/+
template Split(TL, Sep)
    if(isPack!TL)
{
    alias Split = 
}

template SplitImpl(
+/

/**
 * Zip for Packs. Results in a Seq containing a Pack for the first elements
 * of the passed Packs, a Pack for the second elements etc.
 */
template Zip(Sets ...)
    if(All!(isPack, Sets))
{
    
    static if(Sets.length == 0)
    {
        alias Zip = Pack!();
    }
    else
    {        
        static if(Any!(isEmptyPack, Sets))
        {
            alias Zip = Repeat!(Sets.length, Pack!());
        }
        else static if(Any!(packHasLength!(1), Sets))
        {
            alias Zip = Pack!(Map!(Front, Sets));
        }
        else
        {
            alias Zip = Pack!(Pack!(Map!(Front, Sets)),
                                   Zip!(Map!(Tail, Sets)));
        }
    }
}

unittest
{
    //SHOULD TEST EMPTY PACK CASE


    static assert(is(Zip!(Pack!(short, int, long), Pack!(2,4,8)) == Seq!(Pack!(short, 2), Pack!(int, 4), Pack!(long, 8))));
}

//Would be really great to have a half-space cartesian product

/**
 * The cartesian product for Packs. Imagine a pack is a range and look at 
 * std.algorithm.cartesianProduct
 */
template CartesianProduct(A, B)
    if(isPack!A && isPack!B)
{
    template _Impl(T)
    {
        alias _Impl = Zip!(A, Pack!(Repeat!(A.Unpack.length, T)));
    }
    template _Impl(alias T) //alias overload for non-types...
    {
        alias _Impl = Zip!(A, Pack!(Repeat!(A.Unpack.length, T)));
    }
    alias CartesianProduct = Map!(_Impl, B.Unpack);
}

unittest
{
    static assert(is(CartesianProduct!(Pack!(short, int, long), Pack!(float, double)) == 
                      Seq!(Pack!(short, float),  Pack!(int, float),  Pack!(long, float),
                                 Pack!(short, double), Pack!(int, double), Pack!(long, double))));
    
    static assert(is(CartesianProduct!(Pack!(1), Pack!(2)) == Seq!(Pack!(1,2))));
    //pragma(msg, CartesianProduct!(Pack!(float, double), Pack!(char, wchar, dchar)));

    static assert(is(CartesianProduct!(Pack!(1), Pack!(int)) == Seq!(Pack!(1,int))));
    static assert(is(CartesianProduct!(Pack!(1,2), Pack!(int, double)) ==
                     Seq!(Pack!(1, int), Pack!(2, int), Pack!(1, double), Pack!(2, double))));
}

template CartesianProduct(A ...)
    if(A.length > 2 && All!(isPack, A))
{
    template denest(T)
    {
        alias denest = Pack!(T.Unpack[0], T.Unpack[1].Unpack);
    }
    alias CartesianProduct = Map!(denest, CartesianProduct!(A[0], Pack!(CartesianProduct!(A[1 .. $]))));
}

unittest
{
    static assert(is(CartesianProduct!(Pack!(short, int, long), Pack!(float, double), Pack!(char, wchar, dchar)) ==
                     Seq!(Pack!(short, float,  char),  Pack!(int, float,  char),  Pack!(long, float,  char),
                                Pack!(short, double, char),  Pack!(int, double, char),  Pack!(long, double, char),
                                Pack!(short, float,  wchar), Pack!(int, float,  wchar), Pack!(long, float,  wchar),
                                Pack!(short, double, wchar), Pack!(int, double, wchar), Pack!(long, double, wchar),
                                Pack!(short, float,  dchar), Pack!(int, float,  dchar), Pack!(long, float,  dchar),
                                Pack!(short, double, dchar), Pack!(int, double, dchar), Pack!(long, double, dchar))));

    static assert(is(CartesianProduct!(Pack!(short), Pack!(float), Pack!(char), Pack!(ushort)) ==
                     Seq!(Pack!(short, float, char, ushort))));

    static assert(is(CartesianProduct!(Pack!(1,2), Pack!(int, float), Pack!(long, double)) ==
                     Seq!(Pack!(1, int,   long),   Pack!(2, int,   long),
                                Pack!(1, float, long),   Pack!(2, float, long),
                                Pack!(1, int,   double), Pack!(2, int,   double),
                                Pack!(1, float, double), Pack!(2, float, double))));
}

template CartesianProduct(A)
{
    alias CartesianProduct = Map!(Pack, A.Unpack);
}

template CartesianProduct()
{
    alias CartesianProduct = I!();
}

//LAST HERE

template Appender(T ...)
{
    template _Appender(Q ...)
    {
        alias _Appender = I!(Q,T);
    }
    alias Appender = _Appender;
}

template Prepender(T ...)
{
    template _Prepender(Q ...)
    {
        alias _Prepender = I!(T, Q);
    }
    alias Prepender = _Prepender;
}

template Contains(T, TL ...)
{
    static if(IndexOf!(T, TL) != -1)
    {
        enum Contains = true;
    }
    else
    {
        enum Contains = false;
    }
}

//alias overload
template Contains(alias T, TL ...)
{
    static if(IndexOf!(T, TL) != -1)
    {
        enum Contains = true;
    }
    else
    {
        enum Contains = false;
    }
}

unittest
{
    static assert(Contains!(int, Seq!(long, 3, int, float)));
    static assert(Contains!(3, Seq!(1,2,3,4,5)));
    static assert(!Contains!(long, Seq!(4,3,2,1)));
}

template isElementOf(TL ...)
{
    template _isElementOf(Q...)
        if(Q.length == 1)
    {
        alias T = Q;
        alias _isElementOf = Contains!(T, TL);
    }
    alias isElementOf = _isElementOf;
}

template Difference(A, B)
    if(isPack!A && isPack!B)
{
    alias Difference = Filter!(templateNot!(isElementOf!(B.Unpack)), A.Unpack);
}

unittest
{
    alias a = Pack!(1, 2, 4, int , 7, 9);
    alias b = Pack!(0, 1, 2, 4, 7, 8);
    static assert(AllEqual!(Pack!(Difference!(a,b)), Pack!(int, 9)));
}


//super inefficient...
template SymmetricDifference(A, B)
    if(isPack!A && isPack!B)
{
    alias SymmetricDifference = Seq!(Difference!(A,B), Difference!(B,A));
}

unittest
{
    alias a = Pack!(1, 2, 4, int , 7, 9);
    alias b = Pack!(0, 1, 2, 4, 7, 8);
    static assert(UnorderedEquivalent!(Pack!(SymmetricDifference!(a,b)), Pack!(0, int, 8, 9)));
}

template Intersection(TL ...)
if(TL.length > 2 && All!(isPack, TL))
{
    alias Intersection = Intersection!(TL[0], Pack!(Intersection!(TL[1 .. $])));
}

template Intersection(A, B)
if(isPack!A, isPack!B)
{
    alias Intersection = Filter!(isElementOf!(A.Unpack), B.Unpack);
}

unittest
{
    alias a = Pack!(1, 2, 4, int , 7, 9);
    alias b = Pack!(0, 1, 2, 4, 7, 8);
    alias c = Pack!(0, 1, 4, 5, 7, 8);

    static assert(AllEqual!(Pack!(Intersection!(a, a)), a));
    static assert(AllEqual!(Pack!(Intersection!(a, b)), Pack!(1, 2, 4, 7)));
    static assert(AllEqual!(Pack!(Intersection!(a, b, c)), Pack!(1, 4, 7)));
}

/+
template Equal(A, B)
{
    static if(__traits(compiles, A == B) && A == B)
    {
        enum Equal = true;
    }
    else static if(__traits(compiles, is(A == B)) && is(A == B))
    {
        enum Equal = true;
    }
    else
    {
        enum Equal = false;
    }
}

template Equal(alias A, B)
{
    static if(__traits(compiles, A == B) && A == B)
    {
        enum Equal = true;
    }
    else static if(__traits(compiles, is(A == B)) && is(A == B))
    {
        enum Equal = true;
    }
    else
    {
        enum Equal = false;
    }
}

template Equal(A, alias B)
{
    static if(__traits(compiles, A == B) && A == B)
    {
        enum Equal = true;
    }
    else static if(__traits(compiles, is(A == B)) && is(A == B))
    {
        enum Equal = true;
    }
    else
    {
        enum Equal = false;
    }
}

template Equal(alias A, alias B)
{
    static if(__traits(compiles, A == B) && A == B)
    {
        enum Equal = true;
    }
    else static if(__traits(compiles, is(A == B)) && is(A == B))
    {
        enum Equal = true;
    }
    else
    {
        enum Equal = false;
    }
}
+/

/**
 * Returns true if a and b are the same thing, or false if
 * not. Both a and b can be types, literals, or symbols.
 *
 * How:                     When:
 *      is(a == b)        - both are types
 *        a == b          - both are literals (true literals, enums)
 * __traits(isSame, a, b) - other cases (variables, functions,
 *                          templates, etc.)
 */
private template isSame(ab...)
    if (ab.length == 2)
{
    static if (__traits(compiles, expectType!(ab[0]),
                                  expectType!(ab[1])))
    {
        enum isSame = is(ab[0] == ab[1]);
    }
    else static if (!__traits(compiles, expectType!(ab[0])) &&
                    !__traits(compiles, expectType!(ab[1])) &&
                     __traits(compiles, expectBool!(ab[0] == ab[1])))
    {
        static if (!__traits(compiles, &ab[0]) ||
                   !__traits(compiles, &ab[1]))
            enum isSame = (ab[0] == ab[1]);
        else
            enum isSame = __traits(isSame, ab[0], ab[1]);
    }
    else
    {
        enum isSame = __traits(isSame, ab[0], ab[1]);
    }
}
private template expectType(T) {}
private template expectBool(bool b) {}

//Undecided on name yet
alias Equal = isSame;

unittest
{
    static assert(Equal!(1, 1));
    static assert(!Equal!(0, 1));
    enum a = 1;
    static assert(Equal!(1, a));
    static assert(Equal!(a, 1));
    static assert(!Equal!(a, 0));
    static assert(!Equal!(0, a));
    
    static assert(!Equal!(int, 1));
    static assert(!Equal!(int, a));
    static assert(!Equal!(1, int));
    static assert(!Equal!(a, int));

    static assert(Equal!(int, int));
    static assert(!Equal!(float, int));
}

//unittests from std.typetuple.isSame
unittest
{
    alias isSame = Equal;
    static assert( isSame!(int, int));
    static assert(!isSame!(int, short));

    enum a = 1, b = 1, c = 2, s = "a", t = "a";
    static assert( isSame!(1, 1));
    static assert( isSame!(a, 1));
    static assert( isSame!(a, b));
    static assert(!isSame!(b, c));
    static assert( isSame!("a", "a"));
    static assert( isSame!(s, "a"));
    static assert( isSame!(s, t));
    static assert(!isSame!(1, "1"));
    static assert(!isSame!(a, "a"));
    static assert( isSame!(isSame, isSame));
    static assert(!isSame!(isSame, a));

    static assert(!isSame!(byte, a));
    static assert(!isSame!(short, isSame));
    static assert(!isSame!(a, int));
    static assert(!isSame!(long, isSame));

    static immutable X = 1, Y = 1, Z = 2;
    static assert( isSame!(X, X));
    static assert(!isSame!(X, Y));
    static assert(!isSame!(Y, Z));

    int  foo();
    int  bar();
    real baz(int);
    static assert( isSame!(foo, foo));
    static assert(!isSame!(foo, bar));
    static assert(!isSame!(bar, baz));
    static assert( isSame!(baz, baz));
    static assert(!isSame!(foo, 0));

    int  x, y;
    real z;
    static assert( isSame!(x, x));
    static assert(!isSame!(x, y));
    static assert(!isSame!(y, z));
    static assert( isSame!(z, z));
    static assert(!isSame!(x, 0));
}

template AllEqual(A, B)
if(isPack!A && isPack!B && A.Unpack.length == B.Unpack.length)
{
    static if(A.Unpack.length == 0)
    {
        enum AllEqual = true;
    }
    else
    {
        enum AllEqual = !(Filter!(Pipe!(Unpack, templateNot!Equal), Zip!(A, B)).length);
    }
}

unittest
{
    static assert(AllEqual!(Pack!(), Pack!()));
    static assert(AllEqual!(Pack!(1,2,int), Pack!(1,2,int)));
    static assert(!AllEqual!(Pack!(1,float,int), Pack!(1,2,int)));
    static assert(!AllEqual!(Pack!(1,3,int), Pack!(1,2,float)));
}


template UnorderedEquivalent(A, B)
{
    enum UnorderedEquivalent = !(SymmetricDifference!(A, B).length);
}

unittest
{
    static assert(UnorderedEquivalent!(Pack!(5,2,4,int,Pack!(3, double)),
                                       Pack!(4,Pack!(3, double),2,int,5)));
    static assert(!UnorderedEquivalent!(Pack!(5,2,4,int,Pack!(3, double)),
                                        Pack!(4,Pack!(3, float),2,int,5)));
}

/**
 * Find the number of elements in TL that satisfy Pred.
 */
template Count(alias Pred, TL)
    if(isPack!TL)
{
    enum Count = Filter!(Pred, TL).length;
}
enum Count(alias Pred, TL ...) = Count!(Pred, Pack!TL);

//enum CountUntil(alias Pred, H, N) = 

template StartsWith(alias Pred, TL, T)
    if(isPack!TL && !isPack!T)
{
    static if(Pred!(Front!TL, L))
    {
        enum StartsWith = true;
    }
    else
    {
	enum StartsWith = false;
    }
}

template StartsWith(alias Pred, TL, T)
    if(isPack!TL && isPack!T)
{
    static if(TL.length == 0)
    {
	
    }
    else
    {
	enum StartsWith = StartsWith!(Pred, TL, Front!T) &&
	    StartsWith!(Tail!TL, Tail!TL);
    }
}

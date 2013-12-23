/**
More advanced functionality is easily
obtained by wrapping a $(D Seq) in a Pack and making use of the tools in the
rest of the $(meta) package. Alternatively, $(Seq) is entirely backwards
compatible with $(D std.typetuple.TypeTuple) and therefore all existing tools
can be used.
*/
module meta.seq;

import meta.pack;
import meta.algorithm : Equal, AllEqual;

/**
 * Creates a sequence out of a template argument list of zero or more symbols.
 */
template Seq(T ...)
{
    alias Seq = T;
}

///
unittest
{
    alias TL = Seq!(int, double);

    int foo(TL td)  // same as int foo(int, double);
    {
        return td[0] + cast(int)td[1];
    }
}

///
unittest
{
    alias TL = Seq!(int, double);

    alias Types = Seq!(TL, char);
    static assert(is(Types == Seq!(int, double, char)));
}

/**
 * The identity operation on a template argument list. If only one symbol is 
 * passed then the result is just that value. Otherwise it is a $(D Seq) of 
 * the passed values.
 */
template I(A ...)
{
    static if(A.length == 1)
    {   //can't alias everything...
	alias I = Alias!(A[0]);
    }
    else
    {
	alias I = A;
    }
}


//These don't belong here:
//  Where should they go? std.meta.typeops?
//  std.traits?

/**
 * Template wrapper for $(D is(typeof(A) == T))
 */
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

/**
 * Results in a template that checks for a match with type $(D T)
 * when passed the single argument $(D A)
 */
alias hasType(T) = PartialApply!(.hasType, 1, T);

/**
 * Template wrapper for $(D is(typeof(A) : T))
 */
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

/**
 * Results in a template that checks for implicitly convertibility to type
 * $(D T) when passed the single argument $(D A)
 */
template canBe(T)
{
    template canBe(alias A)
    {
	enum canBe = canBe!(A, T);
    }
}

/**
 * Template wrapper for $(D T.stringof)
 */
template stringOf(alias T)
{
    enum stringOf = T.stringof;
}
/// ditto
template stringOf(T ...)
if(T.length == 1)
{
    enum stringOf = (T[0]).stringof;
}

/**
 * When passed a type $(D T), results in $(D T[]) 
 */
template MakeArrayType(T)
{
    mixin(`alias MakeArrayType = ` ~ T.stringof ~ "[];");
}

/**
 * When passed a type $(D T), results in $(D T*) 
 */
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

/**
 * Reverses a given $(D Seq)
 */
alias Reverse(TList ...) = Retro!(Pack!TList).Unpack;

unittest
{
    static assert(is(Reverse!() == Seq!()));
    static assert((Reverse!(1) == Seq!(1)));
    static assert(is(Reverse!(int) == Seq!(int)));
    static assert(AllEqual!(Pack!(Reverse!(1, int)), Pack!(int, 1)));
    static assert(Equal!(Pack!(Reverse!(Pack, Unpack)),
			 Pack!(Seq!(Unpack, Pack))));
}
///
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

module meta.functional;

import meta.seq;
import meta.pack;
import meta.algorithm;
import std.traits;

/**
 * Applies the binary op to the passed parameters
 */
template templateBinaryOp(string op)
{
    template templateBinaryOp(alias A, alias B)
    {
	mixin("enum templateBinaryOp = A " ~ op ~ " B;");
    }
}

template templateUnaryOp(string op)
{
    template templateUnaryOp(alias A)
    {
	mixin("enum templateUnaryOp = " ~ op ~ "A;");
    }
}

/**
 * Negates the passed template predicate.
 */
template templateNot(alias pred)
{
    template templateNot(T...)
    {
        enum templateNot = !pred!T;
    }
}

///
unittest
{
    alias isNoPointer = templateNot!isPointer;
    static assert(!isNoPointer!(int*));
    static assert(All!(isNoPointer, Pack!(string, char, float)));
}

unittest
{
    foreach (T; Seq!(int, Map, 42))
    {
        static assert(!Instantiate!(templateNot!testAlways, T));
        static assert(Instantiate!(templateNot!testNever, T));
    }
}


/**
 * Combines several template predicates using logical AND, i.e. constructs a new
 * predicate which evaluates to true for a given input T if and only if all of
 * the passed predicates are true for T.
 *
 * The predicates are evaluated from left to right, aborting evaluation in a
 * short-cut manner if a false result is encountered, in which case the latter
 * instantiations do not need to compile.
 */
template templateAnd(Preds...)
{
    template templateAnd(T...)
    {
        static if (Preds.length == 0)
        {
            enum templateAnd = true;
        }
        else
        {
            static if (Instantiate!(Preds[0], T))
                alias Instantiate!(.templateAnd!(Preds[1 .. $]), T) templateAnd;
            else
                enum templateAnd = false;
        }
    }
}

///
unittest
{
    alias storesNegativeNumbers = templateAnd!(isNumeric, templateNot!isUnsigned);
    static assert(storesNegativeNumbers!int);
    static assert(!storesNegativeNumbers!string && !storesNegativeNumbers!uint);

    // An empty list of predicates always yields true.
    alias alwaysTrue = templateAnd!();
    static assert(alwaysTrue!int);
}

unittest
{
    foreach (T; Seq!(int, Map, 42))
    {
        static assert( Instantiate!(templateAnd!(), T));
        static assert( Instantiate!(templateAnd!(testAlways), T));
        static assert( Instantiate!(templateAnd!(testAlways, testAlways), T));
        static assert(!Instantiate!(templateAnd!(testNever), T));
        static assert(!Instantiate!(templateAnd!(testAlways, testNever), T));
        static assert(!Instantiate!(templateAnd!(testNever, testAlways), T));

        static assert(!Instantiate!(templateAnd!(testNever, testError), T));
        static assert(!is(typeof(Instantiate!(templateAnd!(testAlways, testError), T))));
    }
}


/**
 * Combines several template predicates using logical OR, i.e. constructs a new
 * predicate which evaluates to true for a given input T if and only at least
 * one of the passed predicates is true for T.
 *
 * The predicates are evaluated from left to right, aborting evaluation in a
 * short-cut manner if a true result is encountered, in which case the latter
 * instantiations do not need to compile.
 */
template templateOr(Preds...)
{
    template templateOr(T...)
    {
        static if (Preds.length == 0)
        {
            enum templateOr = false;
        }
        else
        {
            static if (Instantiate!(Preds[0], T))
                enum templateOr = true;
            else
                alias Instantiate!(.templateOr!(Preds[1 .. $]), T) templateOr;
        }
    }
}

///
unittest
{
    alias isPtrOrUnsigned = templateOr!(isPointer, isUnsigned);
    static assert( isPtrOrUnsigned!uint &&  isPtrOrUnsigned!(short*));
    static assert(!isPtrOrUnsigned!int  && !isPtrOrUnsigned!(string));

    // An empty list of predicates never yields true.
    alias alwaysFalse = templateOr!();
    static assert(!alwaysFalse!int);
}

unittest
{
    foreach (T; Seq!(int, Map, 42))
    {
        static assert( Instantiate!(templateOr!(testAlways), T));
        static assert( Instantiate!(templateOr!(testAlways, testAlways), T));
        static assert( Instantiate!(templateOr!(testAlways, testNever), T));
        static assert( Instantiate!(templateOr!(testNever, testAlways), T));
        static assert(!Instantiate!(templateOr!(), T));
        static assert(!Instantiate!(templateOr!(testNever), T));

        static assert( Instantiate!(templateOr!(testAlways, testError), T));
        static assert( Instantiate!(templateOr!(testNever, testAlways, testError), T));
        // DMD @@BUG@@: Assertion fails for int, seems like a error gagging
        // problem. The bug goes away when removing some of the other template
        // instantiations in the module.
        // static assert(!is(typeof(Instantiate!(templateOr!(testNever, testError), T))));
    }
}


// Used in template predicate unit tests below.
private version (unittest)
{
    template testAlways(T...)
    {
        enum testAlways = true;
    }

    template testNever(T...)
    {
        enum testNever = false;
    }

    template testError(T...)
    {
        static assert(false, "Should never be instantiated.");
    }
}


template PartialApply(alias T, uint argLoc, Arg ...)
    if(Arg.length == 1)
{
    template PartialApply(L ...)
    {
	alias PartialApply = T!(L[0 .. argLoc], Arg, L[argLoc .. $]);
    }
}

version(unittest)
{
    template _hasLength(size_t len, T)
	if(isPack!T)
    {
	static if(T.length == len)
	{
	    enum _hasLength = true;
	}
	else
	{   
	    enum _hasLength = false;
	}
    }
    alias _hasLength(size_t len) = PartialApply!(._hasLength, 0, len);
}

unittest
{
    alias hl3 = _hasLength!3;
    static if(isPack!hl3){} //check for 11553
    alias P = Pack!(1,3,5);
    static assert(hl3!P);
}

//Introduce template lambdas as a DSL?


/**
 * Creates a chain of templates to be applied one after the other.
 * This is the equivalent of std.functional.compose but for templates
 */
template Compose(F ...)
    if(F.length > 2)
{
    alias Compose = Compose!(F[0 .. $-2], Compose!(F[$-2 .. $]));
}

template Compose(F ...)
    if(F.length <= 2)
{
//    pragma(msg, Pack!F);
    static if(F.length == 0)
    {
	alias Compose = I;
    }
    else static if(F.length == 1)
    {
	alias Compose = F;
    }
    else
    {
	alias Compose = Stage!F;
    }
}

private template Stage(F...)
{
    template Stage(T ...)
    {
	alias F_0 = F[0];
	alias F_1 = F[1];
	alias Stage = F_0!(F_1!T);
    }
}

/**
 * Compose, but reversed. This means the templates are passed in the same
 * order they are applied. see std.functional.pipe
 */
template Pipe(F ...)
{
    alias Pipe = Compose!(Reverse!F);
}

unittest
{
    alias second = Compose!(Front, Tail, Pack);
//    pragma(msg, Pack!second);
//    pragma(msg, second!(short, int, long));
    static assert(is(second!(short, int, long) == int));

    alias blah = Pipe!(Pack, Unpack);
    static assert(blah!(1) == Seq!1);

    alias secondP = Pipe!(Pack, Tail, Front);
    static assert(is(secondP!(short, int, long) == int));

    alias Foo = Pipe!(Pack, Tail, Tail);
    static assert(is(Foo!(1,2,3,4) == Pack!(3,4)));
}

template Adjoin(F ...)
    if(F.length >= 2)
{
    template Adjoin(T ...)
    {
	alias t = I!T; //strip Seq if length == 1
	alias Adjoin = Apply!(t, F);
    }
}

template Apply(T, Fs ...)
    if(Fs.length > 0)
{
    alias f = Fs[0];
    static if(Fs.length == 1)
    {
	alias Apply = f!T;
    }
    else
    {
	alias Apply = Seq!(f!T, Apply!(T, Fs[1 .. $]));
    }
}

template ReverseArgs(alias F)
{
    template ReverseArgs(T ...)
    {
	alias ReverseArgs = F!(Reverse!(T));
    }
}

/*
* Instantiates the given template with the given list of parameters.
*
* Used to work around syntactic limitations of D with regard to instantiating
* a template from a type tuple (e.g. T[0]!(...) is not valid) or a template
* returning another template (e.g. Foo!(Bar)!(Baz) is not allowed).
*/
// TODO: Consider publicly exposing this, maybe even if only for better
// understandability of error messages.
private template Instantiate(alias Template, Params...)
{
    alias Template!Params Instantiate;
}


template Select(alias Pred, T ...)
    if(!hasType!(Pred, bool) && T.length == 2)
{
    static if(Pred!(T[0], T[1]))
    {
	alias Select = Alias!(T[0]);
    }
    else
    {
	alias Select = Alias!(T[1]);
    }
}

template Select(alias Pred)
{
    template Select(T ...)
	if(T.length == 2)
    {
	alias Select = .Select!(Pred, T);
    }
}

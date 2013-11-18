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
    import std.traits;

    alias isNoPointer = templateNot!isPointer;
    static assert(!isNoPointer!(int*));
    static assert(allSatisfy!(isNoPointer, string, char, float));
}

unittest
{
    foreach (T; TypeTuple!(int, staticMap, 42))
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
    foreach (T; TypeTuple!(int, staticMap, 42))
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
    foreach (T; TypeTuple!(int, staticMap, 42))
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




//THIS DOESNT WORK FOR EVERYTHING
template templCurry(alias T, alias Arg)
{
    template Curried(L ...)
    {
	alias Curried = T!(Arg, L);
    }
    alias templCurry = Curried;
}

//Introduce template lambdas as a DSL


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
//	pragma(msg, "F_0 = " ~ __traits(identifier, F[0]));
//	pragma(msg, "F_1 = " ~ __traits(identifier, F[1]));
//	pragma(msg, "");
	/+
	template Apply(T ...)
	{
	    alias F_0 = F[0];
	    alias F_1 = F[1];
	    alias Apply = F_0!(F_1!T);
	}
	alias Compose = Apply;+/
	alias Compose = Stage!F;
    }
}

private template Stage(F...)
{
    template _Stage(T ...)
    {
	alias F_0 = F[0];
	alias F_1 = F[1];
	alias _Stage = F_0!(F_1!T);
    }
    alias Stage = _Stage;
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
    alias second = Compose!(Front, Tail);
    static assert(is(second!(short, int, long) == int));

    alias blah = Pipe!(Pack, Unpack);
    static assert(blah!(1) == Seq!1);

    alias secondP = Pipe!(Tail, Front);
    static assert(is(secondP!(short, int, long) == int));

    alias Foo = Pipe!(Tail, Tail, Pack);
    static assert(is(Foo!(1,2,3,4) == Pack!(3,4)));
}

template Adjoin(F ...)
    if(F.length >= 2)
{
    template _Adjoin(T ...)
    {
	alias t = I!t; //strip Seq if length == 1
	alias _Adjoin = Apply!(t, F);
    }
    alias Adjoin = _Adjoin;
}


template Apply(T, Fs ...)
    if(!isPack!(T) && !Any!(isPack, Fs) && Fs.length > 0)
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
    template _ReverseArgs(T ...)
    {
	alias _ReverseArgs = F!(Reverse!(T));
    }
}

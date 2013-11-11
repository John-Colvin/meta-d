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

template isEmptySeq(T ...)
{
    enum isEmptySeq = seqHasLength!(0, T);
}

template seqHasLength(size_t len, T ...)
{
    static if(T.length == len)
    {
	enum seqHasLength = true;
    }
    else
    {
	enum seqHasLength = false;
    }
}

template seqHasLength(size_t len)
{
    template _seqHasLength(T)
    {
	enum _seqHasLength = seqHasLength!(len, T);
    }
    alias seqHasLength = _seqHasLength;
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

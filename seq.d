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

module meta;

/**
A quite of tools for creating a manipulating compile-time aggregrates.
The package is split in to 4 sections: $(D meta.pack), $(D meta.seq),
$(D meta.functional) and $(D meta.algorithm).

$(D meta.pack) privdes $(D Pack), a compile-time aggregate contained within a 
type. Along with said definition, a large proportion of the functionality found
in $(D std.range) is implemented as compile-time manipulation of $(D Pack)s,
including $(Zip), $(Retro) etc. $(D Pack) is the recommended aggregate for any
non-trivial manipulations.

$(D meta.seq) contains the definition of an auto-expanding aggregate called
$(D Seq) (standing for sequence). This is a replacement for the $(D TypeTuple)
template found in $(D std.typetuple). A very few basic tools are provided for
directly manipulating $(D Seq) aggregates.

$(D meta.functional) is a port of $(D std.functional) to meta-programming with
$(Pack)s. Of particular interest is $(Pipe) and $(PartialApply).

$(D meta.algorithm) is a near-complete port of $(std.algorithm) for use at
compile time for manipulating $(D Packs).
 */
public import meta.seq;
public import meta.pack;
public import meta.functional;
public import meta.algorithm;

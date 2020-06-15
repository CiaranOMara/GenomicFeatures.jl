# GenomicInterval
# ========
#
# Base interval types and utilities.
#
# This file is a part of BioJulia.
# License is MIT: https://github.com/BioJulia/Bio.jl/blob/master/LICENSE.md

abstract type AbstractGenomicInterval{T} <: IntervalTrees.AbstractInterval{Int64} end

"""
    GenomicInterval{T} <: AbstractGenomicInterval{T}

A genomic interval specifies interval with some associated metadata.
The first three fields (`seqname`, `first`, and `last`) are mandatory arguments when constructing the [`Interval`](@ref Interval) object.

# Fields
- `seqname::String`: the sequence name associated with the interval.
- `first::Int64`: the leftmost position.
- `last::Int64`: the rightmost position.
- `strand::Strand`: the [`strand`](@ref Strand).
- `metadata::T`
"""
struct GenomicInterval{T} <: AbstractGenomicInterval{T}
    seqname::String
    first::Int64
    last::Int64
    strand::Strand
    metadata::T
end

function GenomicInterval(seqname::AbstractString, first::Integer, last::Integer, strand::Union{Strand,Char}=STRAND_BOTH, metadata::T=nothing) where T
    return GenomicInterval{T}(seqname, first, last, strand, metadata)
end

function GenomicInterval(seqname::AbstractString, range::UnitRange{R}, strand::Union{Strand,Char}=STRAND_BOTH, metadata::T=nothing) where {T,R<:Integer}
    return GenomicInterval{T}(seqname, first(range), last(range), strand, metadata)
end


"""
    GenomicInterval{T}(data)

The returned data is converted to GenomicInterval{T} if there is an implemented [`Base.convert`](https://docs.julialang.org/en/v1/base/base/#Base.convert) function for the type of data.
This method provides a useful hook for converting custom types to GenomicInterval{T}.
"""
function GenomicInterval{T}(data) :: GenomicInterval{T} where T
    return data #Note: the returned data is converted to GenomicInterval{T}.
end

function BioGenerics.seqname(i::GenomicInterval)
    return i.seqname
end

function BioGenerics.metadata(i::GenomicInterval)
    return i.metadata
end

function strand(i::GenomicInterval)
    return i.strand
end

"""
    leftposition(i::GenomicInterval)

Return the leftmost position of `i`.
"""
function BioGenerics.leftposition(i::GenomicInterval)
    return i.first
end

"""
    rightposition(i::GenomicInterval)

Return the rightmost position of `i`.
"""
function BioGenerics.rightposition(i::GenomicInterval)
    return i.last
end

IntervalTrees.first(i::GenomicInterval) = leftposition(i)
IntervalTrees.last(i::GenomicInterval) = rightposition(i)

function Base.isless(a::GenomicInterval, b::GenomicInterval, seqname_isless::Function=isless)
    a_seqname = seqname(a)
    b_seqname = seqname(b)

    if a_seqname != b_seqname
        return seqname_isless(a_seqname, b_seqname)
    end

    a_leftposition = leftposition(a)
    b_leftposition = leftposition(b)

    if a_leftposition != b_leftposition
        return a_leftposition < b_leftposition
    end

    a_rightposition = rightposition(a)
    b_rightposition = rightposition(b)

    if a_rightposition != b_rightposition
        return a_rightposition < b_rightposition
    end

    a_strand = strand(a)
    b_strand = strand(b)

    if a_strand != b_strand
        return a_strand < b_strand
    end

    return false
end

"""
Check if two intervals are well ordered.

`GenomicIntervals` are considered well ordered if seqname(a) <= seqname(b) and leftposition(a) <= leftposition(b).
"""
function isordered(a::GenomicInterval, b::GenomicInterval, seqname_isless::Function=isless)

    a_seqname = seqname(a)
    b_seqname = seqname(b)

    if a_seqname != b_seqname
        return seqname_isless(a_seqname, b_seqname)
    end

    a_leftposition = leftposition(a)
    b_leftposition = leftposition(b)

    if a_leftposition != b_leftposition
        return a_leftposition < b_leftposition
    end

    return true
end

"""
Return true if interval `a` entirely precedes `b`.
"""
function precedes(a::GenomicInterval, b::GenomicInterval, seqname_isless::Function=isless)
    return (rightposition(a) < leftposition(b) && seqname(a) == seqname(b)) || seqname_isless(seqname(a), seqname(b))::Bool
end

function Base.:(==)(a::GenomicInterval, b::GenomicInterval)
    return seqname(a)       == seqname(b) &&
           leftposition(a)  == leftposition(b) &&
           rightposition(a) == rightposition(b) &&
           strand(a)        == strand(b) &&
           metadata(a)      == metadata(b)
end

"Return true if interval `a` overlaps interval `b`, with no consideration to strand"
function BioGenerics.isoverlapping(a::GenomicInterval, b::GenomicInterval)
    return leftposition(a) <= rightposition(b) &&
           leftposition(b) <= rightposition(a) &&
           seqname(a)      == seqname(b)
end

function Base.show(io::IO, i::GenomicInterval)
    if get(io, :compact, false)
        print(io, seqname(i), ":", leftposition(i), "-", rightposition(i), "  ", strand(i), "  ", metadata(i) === nothing ? "nothing" : metadata(i))
    else
        println(io, summary(i), ':')
        println(io, "  sequence name: ", seqname(i))
        println(io, "  leftmost position: ", leftposition(i))
        println(io, "  rightmost position: ", rightposition(i))
        println(io, "  strand: ", strand(i))
          print(io, "  metadata: ", metadata(i) === nothing ? "nothing" : metadata(i))
    end
end

function intervaltype(::Type{I}) where {I<:GenomicInterval}
    return I
end

function intervaltype(::Base.HasShape{0}, ::Type{T}) where T
    return GenomicInterval{T}
end

function intervaltype(::Union{<:Base.HasShape, Base.HasLength, Base.SizeUnknown}, el)
    return intervaltype(eltype(el))
end

function intervaltype(::Type{T}) where T
    return intervaltype(Base.IteratorSize(T), T)
end

function intervaltype(el)
    return intervaltype(typeof(el))
end

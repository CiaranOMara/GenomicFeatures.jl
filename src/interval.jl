# Interval
# ========
#
# Base interval types and utilities.
#
# This file is a part of BioJulia.
# License is MIT: https://github.com/BioJulia/Bio.jl/blob/master/LICENSE.md

# Note, just to be clear: this shadows IntervalTrees.Interval
"""
    struct Interval{T} <: IntervalTrees.AbstractInterval{Int64}

The first three fields (`seqname`, `first`, and `last`) are mandatory arguments when constructing the [`Interval`](@ref Interval) object.

# Fields
- `seqname::String`: the sequence name associated with the interval.
- `first::Int64`: the leftmost position.
- `last::Int64`: the rightmost position.
- `strand::Strand`: the [`strand`](@ref Strand).
- `metadata::T`
"""
struct Interval{T} <: IntervalTrees.AbstractInterval{Int64}
    seqname::String
    first::Int64
    last::Int64
    strand::Strand
    metadata::T
end

function Interval(seqname::AbstractString, first::Integer, last::Integer, strand::Union{Strand,Char}=STRAND_BOTH, metadata=nothing)
    return Interval{typeof(metadata)}(seqname, first, last, strand, metadata)
end

function Interval(seqname::AbstractString, range::UnitRange{T}, strand::Union{Strand,Char}=STRAND_BOTH, metadata=nothing) where T<:Integer
    return Interval{typeof(metadata)}(seqname, first(range), last(range), strand, metadata)
end


"""
    Interval{T}(data)

The returned data is converted to Interval{T} if there is an implemented [`Base.convert`](https://docs.julialang.org/en/v1/base/base/#Base.convert) function for the type of data.
This method provides a useful hook for converting custom types to Interval{T}.
"""
function Interval{T}(data) :: Interval{T} where T
    return data #Note: the returned data is converted to Interval{T}.
end

function BioGenerics.seqname(i::Interval)
    return i.seqname
end

function BioGenerics.metadata(i::Interval)
    return i.metadata
end

function strand(i::Interval)
    return i.strand
end

"""
    leftposition(i::Interval)

Return the leftmost position of `i`.
"""
function BioGenerics.leftposition(i::Interval)
    return i.first
end

"""
    rightposition(i::Interval)

Return the rightmost position of `i`.
"""
function BioGenerics.rightposition(i::Interval)
    return i.last
end

IntervalTrees.first(i::Interval) = i.first
IntervalTrees.last(i::Interval) = i.last

function Base.isless(a::Interval{T}, b::Interval{T}, seqname_isless::Function=isless) where T
    if a.seqname != b.seqname
        return seqname_isless(a.seqname, b.seqname)::Bool
    end

    if a.first != b.first
        return a.first < b.first
    end

    if a.last != b.last
        return a.last < b.last
    end

    if a.strand != b.strand
        return a.strand < b.strand
    end

    return false
end

"""
Check if two intervals are well ordered.

Intervals are considered well ordered if a.seqname <= b.seqnamend and a.first <= b.first.
"""
function isordered(a::Interval{T}, b::Interval{T}, seqname_isless::Function=isless) where T
    if a.seqname != b.seqname
        return seqname_isless(a.seqname, b.seqname)::Bool
    end

    if a.first != b.first
        return a.first < b.first
    end

    return true
end

"""
Return true if interval `a` entirely precedes `b`.
"""
function precedes(a::Interval{T}, b::Interval{T}, seqname_isless::Function=isless) where T
    return (a.last < b.first && a.seqname == b.seqname) || seqname_isless(a.seqname, b.seqname)::Bool
end

function Base.:(==)(a::Interval{T}, b::Interval{T}) where T
    return a.seqname  == b.seqname &&
           a.first    == b.first &&
           a.last     == b.last &&
           a.strand   == b.strand &&
           a.metadata == b.metadata
end

"Return true if interval `a` overlaps interval `b`, with no consideration to strand"
function BioGenerics.isoverlapping(a::Interval{S}, b::Interval{T}) where {S, T}
    return a.first <= b.last && b.first <= a.last && a.seqname == b.seqname
end

function Base.show(io::IO, i::Interval)
    if get(io, :compact, false)
        print(io, i.seqname, ":", i.first, "-", i.last, "  ", i.strand, "  ", i.metadata === nothing ? "nothing" : i.metadata)
    else
        println(io, summary(i), ':')
        println(io, "  sequence name: ", i.seqname)
        println(io, "  leftmost position: ", i.first)
        println(io, "  rightmost position: ", i.last)
        println(io, "  strand: ", i.strand)
          print(io, "  metadata: ",
            i.metadata === nothing ? "nothing" : i.metadata)
    end
end

function metadatatype(::Type{T}) where T
    return _metadatatype(eltype(T))
end

function metadatatype(x::Any)
    return metadatatype(typeof(x))
end

function _metadatatype(::Type{Interval{T}}) where T
    return T
end

function _metadatatype(::Type{T}) where T
    return T
end

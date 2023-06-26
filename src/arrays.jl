# A type representing the dimensions of a quantity, with each
# field giving the power of the corresponding dimension. For
# example, the dimensions of velocity are `Dimensions(length=1, time=-1)`.
# Each of the 7 dimensions are stored using the type `R`,
# which is by default a rational number.

# # Fields

# - `length`: length dimension (i.e., meters^(length))
# - `mass`: mass dimension (i.e., kg^(mass))
# - `time`: time dimension (i.e., s^(time))
# - `current`: current dimension (i.e., A^(current))
# - `temperature`: temperature dimension (i.e., K^(temperature))
# - `luminosity`: luminosity dimension (i.e., cd^(luminosity))
# - `amount`: amount dimension (i.e., mol^(amount))

# # Constructors

# - `Dimensions(args...)`: Pass all the dimensions as arguments. `R` is set to `DEFAULT_DIM_BASE_TYPE`.
# - `Dimensions(; kws...)`: Pass a subset of dimensions as keyword arguments. `R` is set to `DEFAULT_DIM_BASE_TYPE`.
# - `Dimensions(::Type{R}; kws...)` or `Dimensions{R}(; kws...)`: Pass a subset of dimensions as keyword arguments, with the output type set to `Dimensions{R}`.
# - `Dimensions{R}()`: Create a dimensionless object typed as `Dimensions{R}`.
# - `Dimensions{R}(d::Dimensions)`: Copy the dimensions from another `Dimensions` object, with the output type set to `Dimensions{R}`.

"""
    QuantityArray{T,N,D,V}

An array of quantities with value `value` of type `V` and dimensions `dimensions` of type `D` (
which are shared across all elements of the array). This is a subtype of `AbstractArray{T,N}`,
and so can be used in most places where a normal array would be used. The one caveat to note
is that while `getindex` returns `::Quantity`, `setindex!` expects a `::T`. This is done to
avoid unnecessary dimension checks. This is not performed automatically so that the user
is forced to be aware of it.

# Fields

- `value`: The underlying array of values.
- `dimensions`: The dimensions of the array.

# Constructors

- `QuantityArray(value::AbstractArray, dimensions::AbstractDimensions)`: Create a `QuantityArray` with value `value` and dimensions `dimensions`.
- `QuantityArray(value::AbstractArray, quantity::Quantity)`: Create a `QuantityArray` with value `value` and dimensions inferred 
   with `dimension(quantity)`. This is so that you can easily create an array with the units module, like so:
   ```julia
   julia> A = QuantityArray(randn(32), 1u"m")
   ```
- `QuantityArray(v::AbstractArray{<:AbstractQuantity})`: Create a `QuantityArray` from an array of quantities. This means the following
  syntax works:
  ```julia
  julia> A = QuantityArray(randn(32) .* 1u"km/s")
  ```
"""
struct QuantityArray{T,N,D<:AbstractDimensions,V<:AbstractArray{T,N}} <: AbstractArray{T,N}
    value::V
    dimensions::D
end

# Construct with a Quantity (easier, as you can use the units):
QuantityArray(v::AbstractArray, q::Quantity) = QuantityArray(v .* ustrip(q), dimension(q))
QuantityArray(v::QA) where {Q<:AbstractQuantity,QA<:AbstractArray{Q}} = QuantityArray(ustrip.(v), dimension(first(v)))
# TODO: Should this check that the dimensions are the same?

ustrip(A::QuantityArray) = A.value
dimension(A::QuantityArray) = A.dimensions

array_type(::Type{Q}) where {T,N,D,V,Q<:QuantityArray{T,N,D,V}} = V

# One field:
for f in (:size, :length, :axes)
    @eval Base.$f(A::QuantityArray) = $f(ustrip(A))
end

Base.getindex(A::QuantityArray, i...) = Quantity(getindex(ustrip(A), i...), dimension(A))
Base.setindex!(A::QuantityArray, v, i...) = setindex!(ustrip(A), v, i...)
Base.setindex!(::QuantityArray, ::Quantity, i...) = error("Cannot set a Quantity into a QuantityArray, you must `ustrip` it first. You can use `dimension(A) == dimension(v)` to verify that the dimensions match. This is not done automatically as it would be slow.")

Base.IndexStyle(::Type{Q}) where {Q<:QuantityArray} = IndexStyle(array_type(Q))
Base.similar(A::QuantityArray, args...) = QuantityArray(similar(ustrip(A), args...), dimension(A))
module dcv.core.utils;

/*
 * Module for various utilities used throughout the library.
 * 
 * v0.1 norm:
 * unknown - each new utility should be implemented on the fly - as it's needed by other modules?
 */

private import std.experimental.ndslice;
private import std.traits;
private import std.meta : allSatisfy;
private import std.range : lockstep;
private import std.algorithm.iteration : reduce;

/// Convenience method to return an empty slice - used mainly as default argument in functions in library.
static Slice!(N, V*) emptySlice(size_t N, V)() pure @safe nothrow { return Slice!(N, V*)(); }

/**
 * Take another typed Slice. Type conversion for the Slice object.
 * 
 * params:
 * inslice = Input slice, to be converted to the O type.
 * 
 * return:
 * Return a slice with newly allocated data of type O, with same
 * shape as input slice.
 */
static Slice!(N, O*) asType(O, V, size_t N)(Slice!(N, V*) inslice) {
	static if (__traits(compiles, cast(O)V.init)) {
		auto other = new O[inslice.shape.reduce!"a*b"].sliced(inslice.shape);
		foreach(e, ref a; lockstep(inslice.byElement, other.byElement)) {
			a = cast(O)e;
		}
		return other;
	} else {
		static assert(0, "Type " ~ V.stringof ~ " is not convertible to type " ~ O.stringof ~ ".");
	}
}

/**
 * Clip value by it's value range.
 * 
 * params:
 * v = input value, of the input type
 * 
 * return:
 * Clipped value of the output type.
 */
static T clip(T, V)(V v) 
if (isNumeric!V && isNumeric!T)
{
	import std.traits : isFloatingPoint;
	static if (is(T == V)) {
		return v;
	} else static if (isFloatingPoint!T || T.sizeof >= 8) {
		return cast(T)v;
	} else {
		if (v <= T.min)
			return T.min;
		else if (v >= T.max)
			return T.max;
		return cast(T)v;
	}
}

template isBoundaryCondition(alias bc) {
	import std.typetuple;
	alias Indices = TypeTuple!(int, int);
	alias bct = bc!(2, float, Indices);
	static if (isCallable!(bct) && 
		is(Parameters!bct[0] == Slice!(2, float*)) &&
		is(Parameters!bct[1] == int) &&
		is(Parameters!bct[2] == int) &&
		is(ReturnType!bct == float))
	{
		enum bool isBoundaryCondition = true;
	} else {
		enum bool isBoundaryCondition = false;
	}
}

//! No boundary condition test.
ref T nobc(size_t N, T, Indices...)(ref Slice!(N, T*) slice, Indices indices) 
if (allSameType!Indices && allSatisfy!(isIntegral, Indices))
{
	static assert (indices.length == N, "Invalid index dimension");
	return slice[indices];
}

//! Neumann's boundary condition test
ref T neumann(size_t N, T, Indices...)(ref Slice!(N, T*) slice, Indices indices) 
if (allSameType!Indices && allSatisfy!(isIntegral, Indices))
{
	static assert (indices.length == N, "Invalid index dimension");
	return slice.bcImpl!_neumann(indices);
}

//! Periodic boundary condition test
ref T periodic(size_t N, T, Indices...)(ref Slice!(N, T*) slice, Indices indices)
if (allSameType!Indices && allSatisfy!(isIntegral, Indices))
{
	static assert (indices.length == N, "Invalid index dimension");
	return slice.bcImpl!_periodic(indices);
}

//! Symmetric boundary condition test
ref T symmetric(size_t N, T, Indices...)(ref Slice!(N, T*) slice, Indices indices)
if (allSameType!Indices && allSatisfy!(isIntegral, Indices))
{
	static assert (indices.length == N, "Invalid index dimension");
	return slice.bcImpl!_symmetric(indices);
}

template BoundaryConditionTest(size_t N, T, Indices...) {
alias BoundaryConditionTest = ref T function(ref Slice!(N, T*) slice, Indices indices);
}

unittest {
	import std.range : iota;
	import std.array : array;

	static assert(isBoundaryCondition!nobc);
	static assert(isBoundaryCondition!neumann);
	static assert(isBoundaryCondition!periodic);
	static assert(isBoundaryCondition!symmetric);

	/*
	 * [0, 1, 2,
	 *  3, 4, 5,
	 *  6, 7, 8]
	 */
	auto s = iota(9).array.sliced(3, 3);

	assert(s.nobc(0, 0) == s[0, 0]);
	assert(s.nobc(2, 2) == s[2, 2]);

	assert(s.neumann(-1, -1) == s[0, 0]);
	assert(s.neumann(0, -1) == s[0, 0]);
	assert(s.neumann(-1, 0) == s[0, 0]);
	assert(s.neumann(0, 0) == s[0, 0]);
	assert(s.neumann(2, 2) == s[2, 2]);
	assert(s.neumann(3, 3) == s[2, 2]);
	assert(s.neumann(1, 3) == s[1, 2]);
	assert(s.neumann(3, 1) == s[2, 1]);

	assert(s.symmetric(-1, -1) == s[1, 1]);
	assert(s.symmetric(-2, -2) == s[2, 2]);
	assert(s.symmetric(0, 0) == s[0, 0]);
	assert(s.symmetric(2, 2) == s[2, 2]);
	assert(s.symmetric(3, 3) == s[1, 1]);
}

private:

ref auto bcImpl(alias bcfunc, size_t N, T, Indices...)(ref Slice!(N, T*) slice, Indices indices) {
	static if (N == 1) {
		return slice[bcfunc(cast(int)indices[0], cast(int)slice.length)];
	} else static if (N == 2) {
		return slice[
			bcfunc(cast(int)indices[0], cast(int)slice.length!0),
			bcfunc(cast(int)indices[1], cast(int)slice.length!1)
		];
	} else static if (N == 3) {
		return slice[
			bcfunc(cast(int)indices[0], cast(int)slice.length!0),
			bcfunc(cast(int)indices[1], cast(int)slice.length!1),
			bcfunc(cast(int)indices[2], cast(int)slice.length!2)
		];
	} else {
		foreach(i, ref id; indices) {
			id = bcfunc(cast(int)id, cast(int)slice.shape[i]);
		}
		return slice[indices];
	}
}

int _neumann(int x, int nx) {
	if (x < 0) {
		x = 0;
	} else if (x >= nx) {
		x = nx - 1;
	}

	return x;
}

int _periodic(int x, int nx) {
	if (x < 0) {
		const int n = 1 - cast(int) (x / (nx + 1));
		const int ixx = x + n * nx;

		x = ixx % nx;
	} else if (x >= nx) {
		x = x % nx;
	}

	return x;
}

int _symmetric(int x, int nx) {
	if (x < 0) {
		const int borde = nx - 1;
		const int xx = -x;
		const int n = cast(int) (xx / borde) % 2;

		if (n)
			x = borde - (xx % borde);
		else
			x = xx % borde;
	} else if (x >= nx) {
		const int borde = nx - 1;
		const int n = cast(int) (x / borde) % 2;

		if (n)
			x = borde - (x % borde);
		else
			x = x % borde;
	}
	return x;
}

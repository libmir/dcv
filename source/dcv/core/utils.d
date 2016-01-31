module dcv.core.utils;

/*
 * Module for various utilities used throughout the library.
 */

private import mir.ndslice;
private import std.traits;
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
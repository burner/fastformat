module fastformat;

import std.stdio;

@safe:

alias StringOutput = void delegate(string str) @safe;
alias CharOutput = void delegate(char str) @safe;

struct FFormatSpec {
	static ulong Width = 0b0011_1111UL;
	static ulong Base = 0b0011_1100_0000UL;

	private ulong store;

	@property void width(uint w) {
		enforce(w < 64, "width value must be less than 64");
		this.store = this.store | (Width & w);
	}

	@property uint width() {
		return cast(uint)this.store & Width;
	}

	@property void base(uint w) {
		enforce(w < 64, "base value must be less than 64");
		this.store = this.store | (Base & (w << 6));
	}

	@property uint base() {
		return cast(uint)((this.store & Base) >> 6);
	}
}

void fformattedWrite(Args...)(StringOutput sOut, CharOutput cOut, string format
		, Args args)
{
}

void fformattedWrite(Args...)(StringOutput sOut, string format, Args args) {
}

class FFormatException : Exception {
	this(string s, string f = __FILE__, int line = __LINE__) {
		super(s, file, line);
	}
}

private:

static const char[71] numChars = 
	"zyxwvutsrqponmlkjihgfedcba9876543210123456789abcdefghijklmnopqrstuvwxyz";

void fformattedWriteImpl(ref Array array, FFormatSpec spec, long value) {
	int base = spec.base == 0
		? 10
		: spec.base;

	long tmp_value;

    do {
        tmp_value = value;
        value /= base;
		array.put(numChars[35 + (tmp_value - value * base)]);
    } while(value);

	if(tmp_value < 0) {
		array.put('-');
	}

	foreach(idx; 0 .. array.pos / 2) {
		char tmp = array.buf[array.pos - idx - 1];
		array.buf[array.pos - idx - 1] = array.buf[idx];
		array.buf[idx] = tmp;
	}
}

unittest {
	Array arr;

	fformattedWriteImpl(arr, FFormatSpec.init, -1337L);
	assert(arr.pos == 5);
	assert(arr.buf[0 .. 5] == "-1337");

	arr.reset();

	fformattedWriteImpl(arr, FFormatSpec.init, -13370L);
	assert(arr.pos == 6);
	assert(arr.buf[0 .. 6] == "-13370");

	arr.reset();

	fformattedWriteImpl(arr, FFormatSpec.init, 13370L);
	assert(arr.pos == 5);
	assert(arr.buf[0 .. 5] == "13370");

	arr.reset();

	FFormatSpec spec;
	spec.base = 2;
	fformattedWriteImpl(arr, spec, -1L);
	assert(arr.pos == 2);
	assert(arr.buf[0 .. 2] == "-1");

	arr.reset();

	fformattedWriteImpl(arr, spec, -8L);
	assert(arr.pos == 5);
	assert(arr.buf[0 .. 5] == "-1000");
}

void fformattedWriteImpl(ref Array array, FFormatSpec spec, ulong value) {
	int base = spec.base == 0
		? 10
		: spec.base;

	ulong tmp_value;

    do {
        tmp_value = value;
        value /= base;
		array.put(numChars[35 + (tmp_value - value * base)]);
    } while(value);

	foreach(idx; 0 .. array.pos / 2) {
		char tmp = array.buf[array.pos - idx - 1];
		array.buf[array.pos - idx - 1] = array.buf[idx];
		array.buf[idx] = tmp;
	}
}

unittest {
	Array arr;

	fformattedWriteImpl(arr, FFormatSpec.init, 1337UL);
	assert(arr.pos == 4);
	assert(arr.buf[0 .. 4] == "1337");

	arr.reset();

	fformattedWriteImpl(arr, FFormatSpec.init, 13370UL);
	assert(arr.pos == 5);
	assert(arr.buf[0 .. 5] == "13370");

	arr.reset();

	FFormatSpec spec;
	spec.base = 2;
	fformattedWriteImpl(arr, spec, 1UL);
	assert(arr.pos == 1);
	assert(arr.buf[0 .. 1] == "1");

	arr.reset();

	fformattedWriteImpl(arr, spec, 8UL);
	assert(arr.pos == 4);
	assert(arr.buf[0 .. 4] == "1000");
}

void enforce(bool cond, string str) {
	if(!cond) {
		throw new FFormatException(str);
	}
}

struct Array {
	char[127] buf;
	ubyte pos;

	void put(char c) {
		enforce(pos < 127, "Can't store additional character buffer already"
				~ " has 127 elements");
		this.buf[pos] = c;
		this.pos++;
	}

	void reset() {
		this.buf[] = '\0';
		this.pos = 0;
	}
}

unittest {
	static assert(Array.sizeof == 128);
}

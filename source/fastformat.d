module fastformat;

@safe:

alias StringOutput = void delegate(string str) @safe;
alias CharOutput = void delegate(char str) @safe;

struct FFormatSpec {
	private ulong store;

	@property void width(uint w) {
		enforce(w < 64, "width value must be less than 64");
		this.store = this.store | (0b0011_1111U & w);
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
	int base = 10;
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
}

void fformattedWriteImpl(ref Array array, FFormatSpec spec, ulong value) {
	int base = 10;
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


module fastformat.impl;

import std.math : abs, pow, lround;

@safe:

alias FFOutputter = void delegate(ref Array array, string str) @safe;

struct FFormatSpec {
@safe pure:
	static const ulong Width =                               0b_0011_1111UL;
	static const ulong Base =                            0b1111_1100_0000UL;
	static const ulong SeperatorWidth =        0b0000_0111_0000_0000_0000UL;
	static const ulong Seperator =        0b0111_1111_1000_0000_0000_0000UL;
	static const ulong Precision =   0b0111_1000_0000_0000_0000_0000_0000UL;

	private ulong store;

	@property void width(uint w) {
		enforce(w <= 64, "width value must be less than 64");
		this.store = this.store | (Width & w);
	}

	@property uint width() const {
		return cast(uint)this.store & Width;
	}

	@property void base(uint w) {
		enforce(w <= 64, "base value must be less than 64");
		this.store = this.store | (Base & (w << 6));
	}

	@property uint base() const {
		return cast(uint)((this.store & Base) >> 6);
	}

	@property void seperatorWidth(char w) {
		enforce(w <= 8, "base value must be less than 8");
		this.store = this.store | (SeperatorWidth & (w << 13));
	}

	@property ubyte seperatorWidth() const {
		return cast(ubyte)((this.store & SeperatorWidth) >> 13);
	}

	@property void seperator(char w) {
		this.store = this.store | (Seperator & (w << 15));
	}

	@property char seperator() const {
		return cast(char)((this.store & Seperator) >> 15);
	}

	@property void precision(ubyte w) {
		this.store = this.store | (Precision & (w << 23));
	}

	@property ubyte precision() const {
		return cast(ubyte)((this.store & Precision) >> 23);
	}

	ulong getStore() const {
		return this.store;
	}
}

void fformattedWrite(Args...)(FFOutputter sOut, string format, Args args) {
	Array arr;
	size_t last = 0;
	size_t cur = 0;
    size_t cur2 = 0;
	size_t argsIdx = 0;
	bool prevIsAmp;
    FFormatSpec spec;
	outer: for(; cur < format.length; ) {
		if(prevIsAmp && format[cur] == '%') { // %%
			arr.reset();
			sOut(arr, format[last .. cur]);
			++cur;
			last = cur;
        } else if(prevIsAmp && format[cur] == '.') {
            cur2 = 1;
            int preci = 4;
            if(cur + cur2 < format.length 
                    && format[cur + cur2] >= '0' 
                    && format[cur + cur2] <= '9') 
            {
                preci = format[cur + cur2] - '0';
                ++cur2;
            }
            if(cur + cur2 < format.length 
                    && format[cur + cur2] >= '0' 
                    && format[cur + cur2] <= '9') 
            {
                preci = preci * 10 + format[cur + cur2] - '0';
                ++cur2;
            }
            cur += cur2;
            spec.precision = cast(ubyte)preci;
		} else if(prevIsAmp 
				&&   ( format[cur] == 's'
					|| format[cur] == 'x'
					|| format[cur] == 'X'
					|| format[cur] == 'f'
					|| format[cur] == 'd'
					|| format[cur] == 'o'
				     )
				)
		{
			long argIdx;
			arr.reset();
			if(format[cur] == 'x' || format[cur] == 'X') {
				spec.base = 16;
			} else if(format[cur] == 'o') {
				spec.base = 8;
			} else if(format[cur] == 'b') {
				spec.base = 2;
			}
			sOut(arr, format[last .. cur - 1 - cur2]);
			static foreach(arg; args) {{
				if(argIdx == argsIdx) {
					fformatWriteForward(sOut, spec, arg);
                    spec = FFormatSpec.init;
					++cur;
					last = cur;
					continue outer;
				}
				++argIdx;
			}}
		} else if(!prevIsAmp && format[cur] == '%') { // %
			prevIsAmp = true;
			++cur;
		} else {
			++cur;
		}
	}
	if(last < cur) {
		arr.reset();
		sOut(arr, format[last .. cur]);
	}
}

struct FormatSpecParseResult {
	FFormatSpec spec;
	long charParse;
}

FormatSpecParseResult parseFormatSpec(string toParse) {
	FormatSpecParseResult ret;
	return ret;
}

void fformat(Args...)(ref Array output, string format, Args args) {
	void inputter(ref Array array, string str) {
		if(array.pos > 0) {
            output.put(array);
		}
		if(str.length > 0) {
            output.put(str);
		}
	}

	fformattedWrite(&inputter, format, args);
}

string fformat(Args...)(string format, Args args) {
	string ret;

	void inputter(ref Array array, string str) {
		if(array.pos > 0) {
			ret ~= array.buf[0 .. array.pos];
		}
		if(str.length > 0) {
			ret ~= str;
		}
	}

	fformattedWrite(&inputter, format, args);
	return ret;
}

class FFormatException : Exception {
@safe:
	this(string s, string f = __FILE__, int line = __LINE__) pure {
		super(s, file, line);
	}
}

private:

void fformatWriteForward(T)(FFOutputter sOut, FFormatSpec spec, T t) {
	Array arr;
    static if(__traits(isUnsigned, T)) {{
		fformattedWriteImpl(arr, spec, cast(ulong)t);
		sOut(arr, "");
	}} else static if(__traits(isIntegral, T)) {{
		fformattedWriteImpl(arr, spec, cast(long)t);
		sOut(arr, "");
	}} else static if(__traits(isFloating, T)) {{
		fformattedWriteImplNatural(arr, spec, cast(double)t);
		sOut(arr, "");
	}} else static if(is(T == string)) {{
		sOut(arr, t);
	}}
}

static const char[71] numChars = 
	"zyxwvutsrqponmlkjihgfedcba9876543210123456789abcdefghijklmnopqrstuvwxyz";

package void fformattedWriteImpl(ref Array array, FFormatSpec spec, long value) {
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
	reverse(array);

	insertSeparator(array, spec);
}

package void fformattedWriteImplNatural(ref Array array, FFormatSpec spec, double value) {
	long integral = cast(long)value;
	fformattedWriteImpl(array, spec, integral);

	array.put('.');

	double f = (value - cast(double)integral) * cast(double)(pow(10, (spec.precision == 0
					? 6
					: spec.precision)));
	long frac = abs(lround(f));
	Array fracArr;
	fformattedWriteImpl(fracArr, spec, frac);
	array.put(fracArr);
}

    /*
void stringCmp(string a, string b) {
    import std.format : format;
    assert(a.length == b.length, format("%s %s", a.length, b.length));
    foreach(idx; 0 .. a.length) {
        assert(a[idx] == b[idx], format("%s %s %s", idx, a[idx], b[idx]));
    }
}
    */
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

	insertSeparator(array, spec);
}

package void insertSeparator(ref Array arr, FFormatSpec spec) {
	Array tmp;

	if(spec.seperator == '\0' && spec.seperatorWidth == 0) {
		return;
	}

	char sep = spec.seperator;
	ubyte step = spec.seperatorWidth == 0
		? 4
		: spec.seperatorWidth;

	foreach(idx; 0 .. arr.pos) {
		if(idx != 0 && idx % step == 0) {
			tmp.put(sep);
		}
		tmp.put(arr.buf[idx]);
	}

	arr.buf = tmp.buf;
	arr.pos = tmp.pos;
}

void enforce(bool cond, string str) pure {
	if(!cond) {
		throw new FFormatException(str);
	}
}

void reverse(ref Array array) {
    int left = 0;
    int right = array.pos - 1;
    while(left < right) {
        char t = array.buf[left];
        array.buf[left] = array.buf[right];
        array.buf[right] = t;
        left++;
        right--;
    }
}

public struct Array {
	char[127] buf;
	ubyte pos;

	bool put(char c) {
		if(this.pos >= 127) {
            return false;
        }
		this.buf[this.pos] = c;
		this.pos++;
        return true;
	}

	bool put(ref Array a) {
		if(this.pos + a.pos >= 127) {
            return false;
        }
		this.buf[this.pos .. this.pos + a.pos] = a.buf[0 .. a.pos];
		this.pos += a.pos;
        return true;
	}

    bool put(string s) {
		if(this.pos + s.length >= 127) {
            return false;
        }
        this.buf[this.pos .. this.pos + s.length] = s;
        this.pos += s.length;
        return true;
    }

	void reset() {
		this.buf[] = '\0';
		this.pos = 0;
	}

    string toString() const {
        return this.buf[0 .. this.pos].idup;
    }
}

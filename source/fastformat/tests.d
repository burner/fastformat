module fastformat.tests;

version(unittest) {
import std.stdio;
import std.conv : to;

import fastformat.impl;

unittest {
	string s = fformat("Hello %s", "World");
	assert(s == "Hello World", s);
}

unittest {
	string s = fformat("Hello %s", 1337);
	assert(s == "Hello 1337", s);
}

unittest {
	string s = fformat("%o", 8);
	assert(s == "10", s);
}

unittest {
	string s = fformat("%x", 15);
	assert(s == "f", s);
}

unittest {
	FFormatSpec s;
	s.precision = 4;
	Array arr;
	fformattedWriteImplNatural(arr, s, 1337.3737);
    string str = arr.toString();
    assert(str.length == 9, to!(string)(str.length));
    assert(str == "1337.3737", "'" ~ str ~ "'");
}

unittest {
	FFormatSpec s;
	s.precision = 15;
	assert(s.precision == 15, to!string(s.precision));
}

unittest {
	FFormatSpec s;
	s.precision = 4;
	Array arr;
	fformattedWriteImplNatural(arr, s, -1337.3737);
    string str = arr.toString();
    assert(str == "-1337.3737", str);
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

unittest {
	Array arr;

	fformattedWriteImpl(arr, FFormatSpec.init, 1337UL);
	assert(arr.pos == 4);
	assert(arr.buf[0 .. 4] == "1337");

	FFormatSpec spec;
	spec.seperatorWidth = 2;
	spec.seperator = 'j';

	insertSeparator(arr, spec);
	assert(arr.pos == 5);
	assert(arr.buf[0 .. 5] == "13j37");
}

unittest {
	static assert(Array.sizeof == 128);
}

unittest {
    Array arr;
    fformat(arr, "HEllo");
    string s = arr.toString();
    assert(s == "HEllo", "'" ~ s ~ "'");
}

unittest {
    Array arr;
    fformat(arr, "HEllo %.2s", 13.37);
    string s = arr.toString();
    assert(s == "HEllo 13.37", s);
}

unittest {
	string s = fformat("%2d", 8);
	assert(s == " 8", "\"" ~ s ~ "\"");
}

}

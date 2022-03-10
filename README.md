# filesizes
A library for parsing, formatting, and generally working with file sizes.

## Formatting
First, a simple example:
```d
import filesizes;
import std.file : getSize;
import std.stdio;

void main() {
    ulong size = getSize("my-large-file.dat");
    writefln!"My file is %s"(formatFilesize(size));
}
```
Assuming `my-large-file.dat` is 92874 bytes, we will get the following output:
```
My file is 92.9 KB
```

You can provide additional settings to change how things are formatted:
```d
string s = formatFilesize("%.3f", size, false, false);
writefln!"My file is %s"(s);
```

This will write the following:
```
My file is 90.687 Kibibytes
```

## Parsing
This library also provides methods to parse filesize expressions.
```d
import filesizes;
import std.stdio;

void main() {
    string sizeStr = "45 gigabytes";
    writefln!"%s is equal to %d bytes"(sizeStr, parseFilesize(sizeStr));
}
```

This will write the following:
```
45 gigabytes is equal to 45000000000 bytes"
```

Please see the documentation for more details.

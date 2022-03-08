module filesizes.filesize;

import std.math : pow;

/** 
 * Represents the properties of a particular filesize denomination.
 */
public struct SizeDenomination {
    /** 
     * The size factor for this denomination, in bytes. This tells how many
     * bytes are in one "unit" of this denomination.
     */
    const ulong sizeFactor;

    /** 
     * The shortname for the denomination.
     */
    const string abbreviation;

    /** 
     * The full name for the denomination.
     */
    const string name;
}

/** 
 * Enumeration of various valid filesize denominations.
 */
static enum Size : SizeDenomination {
    BYTES = SizeDenomination(1, "B", "Byte"),
    KILOBYTES = SizeDenomination(1000, "KB", "Kilobyte"),
    MEGABYTES = SizeDenomination(pow(1000, 2), "MB", "Megabyte"),
    GIGABYTES = SizeDenomination(pow(1000, 3), "GB", "Gigabyte"),
    TERABYTES = SizeDenomination(pow(1000, 4), "TB", "Terabyte"),

    KIBIBYTES = SizeDenomination(1024, "KiB", "Kibibyte"),
    MEBIBYTES = SizeDenomination(pow(1024, 2), "MiB", "Mebibyte"),
    GIBIBYTES = SizeDenomination(pow(1024, 3), "GiB", "Gibibyte"),
    TEBIBYTES = SizeDenomination(pow(1024, 4), "TiB", "Tebibyte")
}

/** 
 * Exception that's thrown when a filesize component cannot be parsed from a
 * string.
 */
public class FilesizeParseException : Exception {
    public this(string msg) {
        super(msg);
    }
}

/** 
 * Parses a filesize from a string that's formatted like so:
 * "<number> <unit>", where the unit is any one of the defined Size types.
 * Accepts floating-point and integer numbers.
 * Params:
 *   s = The string to parse.
 * Returns: The parsed filesize, in bytes.
 */
public ulong parseFilesize(string s) {
    import std.regex;
    import std.conv : to;
    import std.uni : toLower;
    auto r = ctRegex!(`(\d*\.\d+|\d+)\s*(kilobyte|kibibyte|megabyte|mebibyte|gigabyte|gibibyte|terabyte|tebibyte|byte|kb|kib|mb|mib|gb|gib|tb|tib|b)`);
    auto c = matchFirst(s.toLower, r);
    if (c.empty) throw new FilesizeParseException("Could not parse file size.");
    double num = c[1].to!double;
    Size size = parseDenomination(c[2]);
    return (num *= size.sizeFactor).to!ulong;
}

unittest {
    assert("1 b".parseFilesize == 1);
    assert("2 kb".parseFilesize == 2000);
    assert("1 kib".parseFilesize == 1024);
    assert("0.5 mb".parseFilesize == Size.MEGABYTES.sizeFactor / 2);
    assert("0.25 bytes".parseFilesize == 0);
    assert("25gb".parseFilesize == Size.GIGABYTES.sizeFactor * 25);
    assert("0.125 tib".parseFilesize == Size.TEBIBYTES.sizeFactor / 8);
    assert("3 gibibytes".parseFilesize == Size.GIBIBYTES.sizeFactor * 3);
    assert("1024 bytes".parseFilesize == 1024);
    assert("2MB".parseFilesize == Size.MEGABYTES.sizeFactor * 2);
    try {
        "not a filesize".parseFilesize;
        assert(false);
    } catch (FilesizeParseException e) {}
    try {
        "".parseFilesize;
        assert(false);
    } catch (FilesizeParseException e) {}
}

/** 
 * Parses a filesize unit denomination from a string, such as "bytes",
 * "kilobyte", or "tibibytes".
 * Params:
 *   s = The string to parse.
 * Returns: 
 */
public Size parseDenomination(string s) {
    import std.uni : toLower;
    import std.string : strip;
    import std.traits : EnumMembers;
    import std.algorithm.searching : startsWith;
    s = s.toLower.strip;
    foreach (denom; EnumMembers!Size) {
        if (s.startsWith(denom.abbreviation.toLower) || s.startsWith(denom.name.toLower)) return denom;
    }
    throw new FilesizeParseException("Could not parse file size denomination.");
}

unittest {
    import std.traits : EnumMembers;
    foreach (denom; EnumMembers!Size) {
        assert(denom.abbreviation.parseDenomination == denom);
        assert(denom.name.parseDenomination == denom);
        assert((denom.name ~ "s").parseDenomination == denom);
    }
    try {
        "not a denomination".parseDenomination;
        assert(false);
    } catch (FilesizeParseException e) {}
    try {
        "".parseDenomination;
        assert(false);
    } catch (FilesizeParseException e) {}
}

/** 
 * 
 * Params:
 *   formatString = The format string for formatting the size number.
 *   byteSize = The total number of bytes.
 *   size = The denomination to use when representing the size.
 *   useAbbreviation = Whether to use the abbreviated unit name, or the full.
 * Returns: A string representation of the file size.
 */
public string formatFilesize(string formatString, ulong byteSize, SizeDenomination size, bool useAbbreviation = true) {
    double bytes = cast(double) byteSize / size.sizeFactor;
    import std.string : format;
    string unit = useAbbreviation ? size.abbreviation : size.name;
    if (!useAbbreviation && bytes != 1.0) {
        unit ~= 's';
    }
    return format(formatString ~ " %s", bytes, unit);
}

unittest {
    assert(formatFilesize("%.0f", 42, Size.BYTES) == "42 B");
    assert(formatFilesize("%.0f", 42, Size.BYTES, false) == "42 Bytes");
    assert(formatFilesize("%.0f", 1, Size.BYTES, false) == "1 Byte");
    assert(formatFilesize("%.1f", 512, Size.KIBIBYTES) == "0.5 KiB");
    assert(formatFilesize("%.0f", 2000, Size.KILOBYTES) == "2 KB");
    assert(formatFilesize("%.2f", 256, Size.KIBIBYTES) == "0.25 KiB");
}

public string formatFilesize(string formatString, ulong byteSize, bool useAbbreviation = true, bool useMetric = true) {
    return formatFilesize(formatString, byteSize, getAppropriateSize(byteSize, useMetric), useAbbreviation);
}

public string formatFilesize(ulong byteSize, bool useAbbreviation = true, bool useMetric = true) {
    return formatFilesize("%.1f", byteSize, useAbbreviation, useMetric);
}

/** 
 * Determines the best size denomination to use to describe the given byte
 * size.
 * Params:
 *   byteSize = The number of bytes.
 *   useMetric = Whether to use metric or IEC style units.
 * Returns: The best size to describe the given byte size.
 */
public Size getAppropriateSize(ulong byteSize, bool useMetric = true) {
    import std.traits : EnumMembers;
    Size[] availableSizes;
    if (useMetric) {
        availableSizes = [Size.BYTES, Size.KILOBYTES, Size.MEGABYTES, Size.GIGABYTES, Size.TERABYTES];
    } else {
        availableSizes = [Size.BYTES, Size.KIBIBYTES, Size.MEBIBYTES, Size.GIBIBYTES, Size.TEBIBYTES];
    }
    foreach (denom; availableSizes) {
        double num = cast(double) byteSize / denom.sizeFactor;
        if (useMetric) {
            if (num < 1000) return denom;
        } else {
            if (num < 1024) return denom;
        }
    }
    return useMetric ? Size.TERABYTES : Size.TEBIBYTES;
}

unittest {
    assert(getAppropriateSize(42) == Size.BYTES);
    assert(getAppropriateSize(2048) == Size.KILOBYTES);
    assert(getAppropriateSize(2048, false) == Size.KIBIBYTES);
    assert(getAppropriateSize(1_000_000) == Size.MEGABYTES);
    assert(getAppropriateSize(3_000_000_000) == Size.GIGABYTES);
    assert(getAppropriateSize(4_000_000_000_000) == Size.TERABYTES);
    assert(getAppropriateSize(0) == Size.BYTES);
}

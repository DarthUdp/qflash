module lib.list_parser;
import std.string;
import std.algorithm;
import std.array;

/// Parse a list from a file in the format:
/// # comment
/// One item per line
class ConfigList
{
	string[] items;
	this(string in_buffer)
	{
		// Split with lineSplitter as a lazy range, and alloc only once
		items = in_buffer.lineSplitter()
			.filter!(x => !x.startsWith("#"))
			.array();
	}

	bool itemsContains(string x)
	{
		return items.canFind(x);
	}
}

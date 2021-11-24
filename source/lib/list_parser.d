module lib.list_parser;
import std.string;
import std.algorithm;
import std.array;

/// Parse a list from a file in the format:
/// ---
/// # comment
/// One item per line
/// ---
/// Comment character can be customized as the second argument to constructor
class ConfigList
{
	string[] items;
	this(string in_buffer, string commentChar = "#")
	{
		// Split with lineSplitter as a lazy range, and alloc only once
		items = in_buffer.lineSplitter()
			.filter!(line => !line.startsWith(commentChar))
			.array();
	}

	bool canFind(string x)
	{
		return items.canFind(x);
	}

	ulong lenght()
	{
		return items.length;
	}
}

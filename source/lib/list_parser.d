module lib.list_parser;
import std.string;

/// Parse a list from a file in the format:
/// # comment
/// One item per line
class ConfigList
{
	string[] items;
	this(string in_buffer, uint expected_entries = 20)
	{
		items = new string[expected_entries];
		foreach (line; splitLines(in_buffer))
		{
			if (line[0] == '#')
				continue;

			items ~= line;
		}
	}

	bool itemsContains(string x)
	{
		auto ret = false;
		foreach (current; this.items)
		{
			if (x == current)
			{
				ret = true;
				return ret;
			}
		}
		return ret;
	}
}

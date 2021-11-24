import std.stdio;
import std.getopt;
import std.file;

import lib.dev_geometry;
import lib.list_parser;

int main(string[] args)
{
	auto quiet = false;
	auto zfill = false;
	auto rfill = false;
	ConfigList denyList;
	size_t maxTransf = 0;
	string inFile;
	string outFile;
	auto optHelp = getopt(
		args,
		"in-file|i", "Input file, if zfill or rfill are set this is ignored", &inFile,
		"out-file|o", "Output file", &outFile,
		"lenght|l", "Copy up to n B(default), MiB, GiB", &maxTransf,
		"zfill", "fill the output with 0", &zfill,
		"rfill", "fill the output with random data", &rfill,
		"quiet", "do not report anything", &quiet
	);

	if (optHelp.helpWanted)
	{
		defaultGetoptPrinter("qFlash: Quick flashing utility\nCopyright (c) 2021 Matheus Xavier",
			optHelp.options);
		return 0;
	}

	if (exists("deny.cfg"))
		denyList = new ConfigList(readText("deny.cfg"));

	// if one of these options is present we ignore the input file
	if (!zfill && !rfill)
	{
		// check if the input file exists
		try
		{
			if (denyList.itemsContains(inFile))
			{
				writefln("File %s is in deny.cfg", inFile);
				return 1;
			}
			isFile(inFile);
		}
		catch (FileException e)
		{
			writeln(e);
			return 1;
		}
	}

	return 0;
}

import std.stdio;
import std.getopt;
import std.file;

import lib.dev_geometry;
import lib.list_parser;
import lib.copy_op;

int main(string[] args)
{
	auto quiet = false;
	auto zfill = false;
	auto rfill = false;
	auto unsafe = false;
	ConfigList denyList = ConfigList.init;
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
		"quiet", "do not report anything", &quiet,
		"unsafe", "Don't even try to load deny.cfg (you can break your system by doing so)", &unsafe
	);

	if (optHelp.helpWanted)
	{
		defaultGetoptPrinter("qFlash: Quick flashing utility\nCopyright (c) 2021 Matheus Xavier",
			optHelp.options);
		return 0;
	}

	if (!unsafe && exists("deny.cfg"))
		denyList = new ConfigList(readText("deny.cfg"));
	else if (!unsafe)
	{
		writeln(
			"Could not find the deny.cfg file please create it (even if empty) or invoke with --unsafe"
		);
		return 1;
	}

	// if one of these options is present we ignore the input file
	if (!zfill && !rfill)
	{
		// Sanity check for the outputFile
		if (!unsafe && denyList.canFind(outFile))
		{
			writefln("File %s is in deny.cfg", outFile);
			return 1;
		}
		// Check if our input file exists
		if (!exists(inFile))
		{
			writefln("File %s does not exist", inFile);
			return 1;
		}
		auto copyOp = new CopyOp(inFile, outFile, maxTransf);
	}

	return 0;
}

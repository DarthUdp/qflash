module lib.copy_op;

import std.stdio;
import std.file;
import std.typecons;
import lib.dev_geometry;
import core.thread.fiber;

enum FileType
{
	reg,
	dir,
	dev,
}

/// Struct describing target details (dev or file)
struct TargetInfo
{
	FileType type;
	File file_data;
	DevGeometry dev_geom;
	@property ulong length()
	{
		final switch (type)
		{
		case FileType.reg:
			return file_data.size();
		case FileType.dev:
			return dev_geom.devSize;
		case FileType.dir:
			// No-op as this should never be reached always fail in debug
			assert(0);
		}
	}

	void[] opSlice(ulong start, ulong end)
	{
		final switch (type)
		{
		case FileType.reg:
			return file_data.rawRead(new ubyte[end - start]);
		case FileType.dev:
			return dev_geom.fp.rawRead(new ubyte[end - start]);
		case FileType.dir:
			// No-op as this should never be reached always fail in debug
			assert(0);
		}
	}

	auto opSliceAssign(T)(T value, ulong start, ulong end)
	{
		final switch (type)
		{
		case FileType.reg:
			file_data.rawWrite(value);
			break;
		case FileType.dev:
			dev_geom.fp.rawWrite(value);
			break;
		case FileType.dir:
			// No-op as this should never be reached always fail in debug
			assert(0);
		}
	}

	auto opIndex(ulong i)
	{
		return 0UL;
	}

	void sync()
	{
		if (type == FileType.dev)
			return dev_geom.devSync();
		else
			return;
	}

	alias targetSize = length;
	alias opDollar = targetSize;
}

FileType figureFileType(string path)
{
	if (isDir(path))
	{
		return FileType.dir;
	}
	else if (isFile(path) || isSymlink(path))
	{
		return FileType.reg;
	}
	else
	{
		return FileType.dev;
	}
}

/// Copy n bytes from in to out bytewise
class CopyOp
{
	TargetInfo inFile;
	TargetInfo outFile;
	ulong length;
	ulong blkCt;
	ulong currentBlock;
	auto inProgress = false;

	this(string inPath, string outPath, ulong maxLength = 0, uint bs = 4096, bool createOut = true)
	{
		// We need to figure out what we are dealing with and act accordingly here
		final switch (figureFileType(inPath))
		{
		case FileType.reg:
			inFile = TargetInfo(FileType.reg, File(inPath, "rb"), DevGeometry.init);
			break;
		case FileType.dev:
			inFile = TargetInfo(FileType.dev, File.init,
				new DevGeometry(inPath, DevGeometryMode.read));
			break;
		case FileType.dir:
			// We can't handle directories
			throw new Exception("");
		}

		if (!exists(outPath) && createOut)
		{
			std.file.write(outPath, []);
		}
		// Same as above but for the output
		final switch (figureFileType(outPath))
		{
		case FileType.reg:
			outFile = TargetInfo(FileType.reg, File(outPath, "wb"), DevGeometry.init);
			break;
		case FileType.dev:
			outFile = TargetInfo(FileType.dev, File.init,
				new DevGeometry(outPath, DevGeometryMode.write));
			break;
		case FileType.dir:
			throw new Exception("");
		}
		// Refuse to do anything if the input is longer than the output and the output is a dev
		if (outFile.type == FileType.dev && inFile.targetSize > outFile.targetSize)
			throw new Exception("The input is larger than the output");
		// if the file is a device use outFile if outfile is the exact size or smaller than the input
		if (outFile.type == FileType.dev && outFile.length <= inFile.length)
			length = maxLength > 0 ? maxLength : outFile.targetSize;
		// otherwise we write the input length
		else
			length = maxLength > 0 ? maxLength : inFile.length;
	}

	/// Execute the copy operation proper, the behaviour of this procedure
	/// can be fine-tuned by the flags passed as parameters, this function
	/// should be ran as a fiber.
	/// Params:
	/// blockSize = The size of the memory mapped blocks
	/// sync = if true sync will be called after each block being written
	/// Returns: The ammount of bytes copied to the destination
	ulong copyAsync(uint blockSize = 4096, immutable bool sync = true)
	{
		auto inSize = inFile.length;
		auto blkStart = 0UL;
		auto blkEnd = 0UL;
		blkCt = length / blockSize;

		inProgress = true;
		for (; currentBlock <= blkCt; currentBlock++)
		{
			if (currentBlock * blockSize > inSize)
			{
				writeln("Warning: unnaligned last block");
				// Go back a block
				blkStart = (currentBlock - 1) * blockSize;
				// last block should span to the end of the file
				blkEnd = inFile.length;
			}
			else
			{
				blkStart = currentBlock * blockSize;
				blkEnd = (currentBlock + 1) * blockSize;
			}

			outFile[blkStart .. blkEnd] = inFile[blkStart .. blkEnd];

			if (sync)
			{
				outFile.sync();
			}
			
			if (currentBlock % 10 == 0)
				Fiber.yield();
		}
		Fiber.yield();
		inProgress = false;
		return currentBlock * blockSize;
	}

	/// Execute the copy operation proper, the behaviour of this procedure
	/// can be fine-tuned by the flags passed as parameters, this function.
	/// Params:
	/// blockSize = The size of the memory mapped blocks
	/// sync = if true sync will be called after each block being written
	/// Returns: The ammount of bytes copied to the destination
	ulong copy(uint blockSize = 4096, immutable bool sync = true)
	{
		auto inSize = inFile.length;
		auto blkStart = 0UL;
		auto blkEnd = 0UL;
		blkCt = length / blockSize;

		inProgress = true;
		for (; currentBlock <= blkCt; currentBlock++)
		{
			if (currentBlock * blockSize > inSize)
			{
				writeln("Warning: unnaligned last block");
				// Go back a block
				blkStart = (currentBlock - 1) * blockSize;
				// last block should span to the end of the file
				blkEnd = inFile.length;
			}
			else
			{
				blkStart = currentBlock * blockSize;
				blkEnd = (currentBlock + 1) * blockSize;
			}

			outFile[blkStart .. blkEnd] = inFile[blkStart .. blkEnd];

			if (sync)
			{
				outFile.sync();
			}
		}
		inProgress = false;
		return currentBlock * blockSize;
	}
}

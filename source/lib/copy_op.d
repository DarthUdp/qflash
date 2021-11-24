module lib.copy_op;
import std.stdio;
import std.file;
import std.typecons;
import lib.dev_geometry;

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
	ulong targetSize()
	{
		final switch(type)
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
	size_t length;
	this(string inPath, string outPath, size_t maxLength = 0, bool createOut = true)
	{
		// We need to figure out what we are dealing with and act accordingly here
		final switch (figureFileType(inPath))
		{
		case FileType.reg:
			inFile = TargetInfo(FileType.reg, File(inPath, "rb"), DevGeometry.init);
			break;
		case FileType.dev:
			inFile = TargetInfo(FileType.dev, File.init, new DevGeometry(inPath, DevGeometryMode.read));
			break;
		case FileType.dir:
			throw new Exception("");
		}

		if (!exists(outPath) && createOut)
		{
			std.file.write(outPath, []);
		}
		final switch (figureFileType(outPath))
		{
		case FileType.reg:
			outFile	 = TargetInfo(FileType.reg, File(outPath, "wb"), DevGeometry.init);
			break;
		case FileType.dev:
			outFile = TargetInfo(FileType.dev, File.init, new DevGeometry(outPath, DevGeometryMode.write));
			break;
		case FileType.dir:
			throw new Exception("");
		}
		length = maxLength > 0 ? maxLength : outFile.targetSize;
	}
}

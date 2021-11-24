module lib.dev_geometry;

import std.format;
import std.file;
import std.stdio;

enum DevGeometryMode
{
	read,
	write,
}

enum DevType
{
	blk_dev,
	char_dev,
	udef_dev,
}

class DevOpException : Exception
{
	this(string dev, string op, string file = __FILE__, size_t line = __LINE__)
	{
		super(format("Dev Operation %s failed on dev %s", op, dev), file, line);
	}
}

/// Disk geometry represented in a os agnostic way
class DevGeometry
{
	// Both windows and linux have paths to the raw devices
	string devPath;
	size_t devSize = 0;
	uint preferredIoSize = 0;
	DevType type = DevType.udef_dev;
	// Linux specific implementation
	version (linux)
	{
		import core.sys.posix.sys.ioctl;
		import core.sys.linux.fs;
		import core.sys.posix.sys.stat;

		int fd;
		File fp;

		this(string devPath, DevGeometryMode mode)
		{
			/* Before we try to do anything ensure the file exists
			and is readable or writeable (based on mode) 
			and let any exception bubble */
			isFile(devPath);
			fp = File(devPath, mode == DevGeometryMode.write ? "wb" : "rb");
			fd = fp.fileno();
			// Normal init after it
			devPath = devPath;
			getDevSize();
		}

		private void getDevSize()
		{
			/* figuring out dev type, we need to get the results of `stat`
			and then figure if it's a char dev (i.e /dev/zero) or
			a block dev (i.e /dev/sda) */
			auto entry = DirEntry(devPath);
			auto statResult = entry.statBuf();
			ulong devSz = 0;
			if (S_ISBLK(statResult.st_mode))
			{
				type = DevType.blk_dev;
				// c style error check with -1
				if (ioctl(fd, BLKGETSIZE64, &devSz) == -1)
					throw new DevOpException("ioctl(BLKGETSIZE64) failed", this
							.devPath);

				// the ioctl is assumed to have succeeded
				devSize = devSz;
			}
		}
	}

	// Windows is not implemented yet
	version (Windows) static assert(0, "Windows is not yet implemented");
}

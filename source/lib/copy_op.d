module lib.copy_op;
import std.stdio;

/// Copy n bytes from in to out bytewise
class CopyOp
{
	File in_;
	File out_;
	size_t n;
	this(File in_, File out_, size_t n)
	{
		this.in_ = in_;
		this.out_ = out_;
		this.n = n;
	}


}

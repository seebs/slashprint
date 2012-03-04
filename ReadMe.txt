This is a trivial /print command useful for debugging.  It can display
tables (though it isn't much good at tables where a key is another table,
so don't do that), it can't display functions or userdata or whatever,
but at least it knows it.  Handy also as a pocket calculator.

Takes options:
	-d #	to specify a maximum depth of table dumping.
	-v	print nil-valued table members

You can build a table of up to about 10k lines with this.  However, printed
output is capped at around 1k lines due to a crash.

You can obtain the .data.dump() method from Inspect.Addon.Detail('SlashPrint')
and use it to populate arrays:
	dump(target, value)
will insert lines into target which represent value.


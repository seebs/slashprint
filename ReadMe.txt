This is a trivial /print command useful for debugging.  It can display
tables (though it isn't much good at tables where a key is another table,
so don't do that), it can't display functions or userdata or whatever,
but at least it knows it.  Handy also as a pocket calculator.

Takes one option, "-d #", to specify a maximum depth of table dumping.

Output will be terminated at ~700 lines of output to avoid a wonderful
crash case I developed.

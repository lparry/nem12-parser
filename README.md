# AEMO NEM12 parser

A quick and dirty parser to consume an OVO "detailed report" NEM12 file with a
controlled load circuit, and recalculate what it would cost with the two plans
OVO are currently offering me.

It may get more flexibility over time if I switch to other power companies and
need to process their versions of an NEM12 file, but it also might not.

Currently I'm only offered TOU plans, one with free time and the other without.
There's minimal flexibility there, but if TOU periods were to not end on hours,
or were to be different on weekends, you're out of luck.

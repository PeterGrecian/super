The TODO consolidator is finding FIXMEs and so on in the .claude files which are not directly interesting to humans


It is crucial to run git pull on everything before running cld unless you have bad connectivity and are really sure it's all up to date and maybe you just want one repo.

The cld command should be a script in super/bin.  The commands in there should be short and easy to remember.  Probably 3 letters or so.  It should prompt for global pull?  before it launches claude.  It should suggest global commit/push at the end which will be the "gcp" command
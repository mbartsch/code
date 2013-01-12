#!/bin/bash
for d in `arkc -backup -done -Fcanreplicate  -moreinfo` 
do 
	
	echo $d
	OUTPUT=$(arkc -journal -jbackup -D  $d | grep -e "Start of .* backup")
	echo $OUTPUT
	echo "$OUTPUT" | grep -q ORACL-NFS
	if [ $? -eq 0 ] ; then
		arkc -d2t -start -D ${d} dkname=TapeDrivepack plname=DATABASE retention=62 retunit=DAY wait=YES email=NO policy=COMPLETE
		echo "Err Code $?"
	fi
done


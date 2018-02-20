#!/bin/bash
# the sam file are 2003 lines long and will always differ on the last line
head -2000 $1 > tail1
head -2000 $2 > tail2
diff tail1 tail2

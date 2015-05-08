#!/bin/bash
gawk -F': ' '{
   if ($0 ~ /VM Name.Avamar. /) {
     printf("%s ", $2)
   } else if ($0 ~ /CBT Enabled/) {
     printf("%s\n", $2)
   }
}'

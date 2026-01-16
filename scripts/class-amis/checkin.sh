#!/bin/bash

echo "Enter checkin message"
read msg

# go to each 2sl directory and checkin any code
maindir=$HOME/build/2sl
cd $maindir

#loop through all the directories in 2sldir
for dir in */; do
    echo "check in $dir"
    cd $dir
    #git pull
    git add .
    c="git commit -m '$msg'"
    eval $c
    git push
    cd ..
done

#!/bin/bash

echo "Running jobs:"
ps aux | grep jekyll 

echo "Killing jobs if any:"
kill -9 $(ps aux | grep jekyll | head -1 | awk '{print $2}')


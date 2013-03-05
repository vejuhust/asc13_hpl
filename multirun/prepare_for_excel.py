#!/usr/bin/env python
# -*- coding: utf-8 -*-

from operator import itemgetter
from sys import argv

# Open the file
if (len(argv) == 2):
    input_file = argv[1]
else:
    print "Input file name missing.\n"
    exit(1)

source = open(input_file, "r")
lines = source.readlines()
list = []
source.close()

# Input the (x,y,z)
for line in lines:
    if (line[0] != '#'):
        numbers = line.split()
        item = (int(numbers[0]), int(numbers[1]), float(numbers[2]))
        list.append(item)

sorted(list, key=itemgetter(1, 0))

# Print first line 
print "NBs\\Ns\t",
xs = []
for item in list:
    if ((item[0] in xs) == False):
        print "%d\t" % item[0], 
        xs.append(item[0])
print "\n",

# Get Ys
ys = []
for item in list:
    if ((item[1] in ys) == False):
        ys.append(item[1])

for y in ys:
    print "%d\t" % y,
    for x in xs:
        for item in list:
            if ((item[0] == x) & (item[1] == y)):
                print "%.10f\t" % item[2],
    print "\n",

exit(0)

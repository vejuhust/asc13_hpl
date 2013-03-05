#!/usr/bin/env python
# -*- coding: utf-8 -*-

from operator import itemgetter
from sys import argv

# Open the file
if (len(argv) != 3):
    print "Input file names missing.\n"
    exit(1)

file_source_one = open(argv[1], "r")
lines_source_one = file_source_one.readlines()
list_source_one = []
file_source_one.close()

file_source_two = open(argv[2], "r")
lines_source_two = file_source_two.readlines()
list_source_two = []
file_source_two.close()

# Input the data
for line in lines_source_one:
    if (line[0] != '#'):
        numbers = line.split()
        item = (int(numbers[0]), int(numbers[1]), float(numbers[2]))
        list_source_one.append(item)
sorted(list_source_one, key=itemgetter(1, 0))

for line in lines_source_two:
    if (line[0] != '#'):
        numbers = line.split()
        item = (int(numbers[0]), int(numbers[1]), float(numbers[2]))
        list_source_two.append(item)
sorted(list_source_two, key=itemgetter(1, 0))

# Print first line 
print "NBs\\Ns\t",
xs = []
for item in list_source_one:
    if ((item[0] in xs) == False):
        print "%d\t" % item[0], 
        xs.append(item[0])
print "\n",

# Get Ys
ys = []
for item in list_source_one:
    if ((item[1] in ys) == False):
        ys.append(item[1])

for y in ys:
    print "%d\t" % y,
    for x in xs:
        # Find value_source_one
        for item in list_source_one:
            if ((item[0] == x) & (item[1] == y)):
                value_source_one = item[2]
                break
        # Find value_source_two
        for item in list_source_two:
            if ((item[0] == x) & (item[1] == y)):
                value_source_two = item[2]
                break
        if ((value_source_one == 0) or (value_source_two == 0)):
            pass
            #print "0\t",
            #continue
        #result = (value_source_one / (value_source_one + value_source_two))
        result = value_source_one - value_source_two
        print "%.10f\t" % result,    
    print "\n",

exit(0)

#!/usr/bin/env python
from __future__ import print_function
import argparse
import subprocess
import os
import sys
import re
import pdb
import itertools

def options():
    parser = argparse.ArgumentParser(description="Takes two files and takes the first line from the first one and the next five from the second",
                                    formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-f1",
                        help="First file to take lines from",
                        required = True)
    parser.add_argument("-f2",
                        help="Second file to take lines from",
                        required = True)
    parser.add_argument("-n1",
                        help="Number of lines to take at a time from first file",
                        required = True)
    parser.add_argument("-n2",
                        help="Number of lines to take a time from second file",
                        required = True)
    args = parser.parse_args()
    return args

def main():
    args = options()
    f1 = args.f1
    f2 = args.f2
    n1 = int(args.n1)
    n2 = int(args.n2)

    with open(f1, 'r') as file1, open(f2, 'r') as file2:
        print("Library,Input (reads),Quality Trimmed,Percent Total,Kmer Trimmed,Percent Total,Low entropy discards,Percent Total,Total Removed,Percent Total,Result,Percent Total")
        while True:
            f1_lines = list(itertools.islice(file1, n1))
            f2_lines = list(itertools.islice(file2, n2))
            pdb.set_trace()
            if(len(f1_lines) == 0 and len(f2_lines) == 0):
                break
            for line in f1_lines:
                library = line.strip()
                print(library, end=",")
            for line in f2_lines:
                if "Input:" in line:
                    line = line.split()
                    line = ' '.join(line[1:3]).strip()
                    line = line.split('reads')[0].strip()
                    line = line + ","
                elif "Result:" in line:
                    line = line.split()
                    line = ' '.join(line[1:4])
                    line = ','.join([x.strip().replace('(','',).replace(')','') for x in line.split('reads')])
                else:
                    line = line.split()
                    if len(line) > 7:
                        line = ' '.join(line[-6:-3])
                        line = ','.join([x.strip().replace('(','',).replace(')','') for x in line.split('reads')])
                    else:
                        line = ' '.join(line[1:4])
                        line = ','.join([x.strip().replace('(','',).replace(')','') for x in line.split('reads')])
                    line = line + ","
                print(line, end = "")
            print()

if __name__ == "__main__":
    main()
            
    

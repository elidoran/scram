
fs = require 'fs'
LineByLineReader = require 'line-by-line'

# What can this central 'module' provide to the scripts?

# shorthand for specifying input files to read, in series or parallel

# shorthand for specifying output: stdout or file, per input or combined

# accept functions to process sections, or to even discover sections?

# specify simple things like:
#  1. how many lines the header is, if known, and to skip it, or provide it,
#     possibly to a provided function.
#  2. how many lines of data to process at a time, and the handler function
#  3. how many lines the footer is, if known, and to skip it or provide it


# make headers available to data processor?

# allow regex to define a header, data, or footer?

# allow extracting extra info from header or footer?

# allow enhanced data processing aid by providing a function to apply to
# specific data cell, provide prebuilt functions for counting, sum, average...

# a pretty printed console status screen!
# thru inter-process communication the scripts can emit events as they process
# and we can receive them and update the status on the command console.
# for example, showing the current file being processed and the current line
# count processed. we can't do a progress bar because we don't know the total
# number of lines in the file.




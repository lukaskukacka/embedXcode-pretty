#!/usr/bin/env ruby

# The MIT License (MIT)
#
# Copyright (c) 2017 Lukas Kukacka
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'open3'

# Regex matching error and warnings in embedXcode's output
REGEX_ERROR = /^([a-zA-Z\-\.\/]+)\:(\d+)\:(\d)\: (error|warning)\: (.*)$/

if ARGV.empty?
    puts 'Missing input. Usage: ' + File.basename(__FILE__) + '"command to execute"'
    exit 1
end

command = ARGV[0]
base_dir = __dir__

puts '' + File.basename(__FILE__) + ' Executing command: ' + command

# Count matched errors so the script can return success or failure status code
errors_count = 0

# Execute the command watching. Using Open3 so the script can process both
# STDOUT and STDERR separatelly
# Reading using while so the output is process while being output from command
# and not only at the end
Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
    # Just print STDOUT
    while outline = stdout.gets
        puts outline
    end

    # Process STDERR
    while errline = stderr.gets
        error_matches = REGEX_ERROR.match(errline)

        if error_matches.nil?
            # If the line does not match error pattern, print out the original output line
            STDERR.puts errline
        else
            # Error pattern matches
            errors_count += 1

            # Parse error pattern and output it in Xcode compatible format
            relative_path = error_matches[1]
            if relative_path.start_with?('./')
                relative_path = relative_path[2..-1]
            end
            line = error_matches[2]
            character = error_matches[3]
            issue_type = error_matches[4]
            message = error_matches[5]

            STDERR.puts base_dir + '/' + relative_path + ':' + line + ':' + character + ': ' + issue_type + ': ' + message
        end
    end
end

if errors_count > 0
    exit 1
end

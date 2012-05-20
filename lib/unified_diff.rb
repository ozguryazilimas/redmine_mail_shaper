require 'diff/lcs'


module Diff
  module LCS
    def self.unified_diff(str_from, str_to)
      newline_seperator = "\r\n"
      difference = newline_seperator

      array_from = str_from.split(newline_seperator)
      array_to = str_to.split(newline_seperator)

      diffs = diff(array_from, array_to)
      diffs.each_with_index{ |diff, i|
        diff.each{ |d|
          difference += newline_seperator + d.action + d.element
        }
      }

      difference + newline_seperator
    end
  end
end



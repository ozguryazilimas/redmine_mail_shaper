require 'diff/lcs'
require 'diff/lcs/string'
require 'diff/lcs/hunk'


module Diff
  module LCS
    def self.unified_diff(str_from, str_to)
      newline_seperator = "\r\n"
      difference = ''
      oldhunk = hunk = nil
      len = 0

      array_from = str_from.split(newline_seperator)
      array_to = str_to.split(newline_seperator)

      diffs = Diff::LCS.diff array_from, array_to
      diffs.each do |diff|
        begin
          hunk = Diff::LCS::Hunk.new(array_from, array_to, diff, RedmineMailShaper.settings[:diff_hunk_line_size], len)
          len = hunk.file_length_difference
          next unless oldhunk

          if hunk.overlaps?(oldhunk) then
            hunk.unshift(oldhunk)
          else
            difference << oldhunk.diff(:unified)
          end
        ensure
          oldhunk = hunk
          difference << newline_seperator
        end
      end

      difference << oldhunk.diff(:unified)
      difference << newline_seperator

      difference
    end
  end
end


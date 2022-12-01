# this class wraps a reusable pipeline of Procs, similar to chaining method
# calls from the Enumerable module, except you can chain long and complicated
# things all in one object and then reuse that pipeline anywhere. sure you could
# do basically the same thing by defining a method - not disagreeing there.
#
# Usage:
#   let's look at a text processing example where you want to process lines from
#   a log file and convert it into a more helpful data structure. let's start
#   with this line from a log file:
#   2022-11-19T17:34:05.299295Z  25888 INFO loading configuration from ./config.yml\n
#
#   ... and let's say that we want to extract the parts of this line into a
#   Hash, then we might build a pipeline like this:
#
#   line = "2022-11-19T17:34:05.299295Z  25888 INFO loading configuration from ./config.yml\n"
#   p = TinyPipe.new(
#         [
#           TinyPipe::MAP_STRIP,                    # the list of procs
#           ->(line){ line.split(' ', 4),
#           ->(list){
#             {
#               timestamp: DateTime.parse(list[0]),
#               process_id: list[1].to_i,
#               log_level: list[2].downcase.to_sym,
#               log_line: list[3]
#             }
#           },
#         ]
#       )
#   
#   parts = p.pipe(line)
#
# If you had a whole log file of lines then you just warp the above with
# something like this:
#
#   results = log_file.each_line.map{|l| p.pipe(l) }
#   [ ... an array of Hashes ... ]
#
# TinyPipe comes with a few common pipeline steps for common text processing
# cases that you can pass in as elements of the procs parameter to the
# initialize method.
class TinyPipe
  SUPPORTED_INPUT_CLASSES = [String, Array, IO].freeze

  # some pre-build procs for common text processing steps
  MAP_STRIP = ->(l){ l.strip }
  MAP_UPCASE = ->(l){ l.upcase }
  MAP_DOWNCASE = ->(l){ l.downcase }

  JOIN = ->(l){ l.join }
  JOIN_SPACE = ->(l){ l.join(' ') }
  JOIN_COMMA = ->(l){ l.join(',') }
  JOIN_TAB = ->(l){ l.join("\t") }
  JOIN_PIPE = ->(l){ l.join('|') }

  SPLIT_SPACE = ->(l){ l.split }
  SPLIT_COMMA = ->(l){ l.split(',') }
  SPLIT_TAB = ->(l){ l.split("\t") }
  SPLIT_PIPE = ->(l){ l.split('|') }

  FIELD_FIRST = ->(l){ l.first }
  FIELD_LAST = ->(l){ l.last }

  SELECT_EMPTY = ->(l){ l.empty? ? l : nil }
  REJECT_EMPTY = ->(l){ l.empty? ? nil : l }

  # procs: the list of procs to be run over the input lines, in the order in
  #   which they should be run
  def initialize(procs)
    @procs = procs
  end

  # process a single input item, returning the processed item
  #
  # NOTE: the pipeline will exit early if any step within the pipeline returns
  # nil
  def pipe(item)
    dup = item.dup

    @procs.each do |p|
      break if dup.nil?
      dup = p.call(dup)
    end

    dup
  end
end

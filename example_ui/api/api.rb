require_relative '../../api_client'

# # TODO:
# require_relative 'env'

# require 'bundler'
# Bundler.require :default

require "oj"
require "roda"

module FormatStream

  SSE_IDS = {}

  Format = -> (stream, hash) {
    out = ""
    id = SSE_IDS[:stream] || 0 # we need an auto-increment id for the sse to work
    # this is the (simple) output format - id: ID \n data: [JSON] \n\n
    out << "id: #{id}\n"
    out << "data: #{JSONDump.(hash)} \n\n" # json data
    SSE_IDS[:stream] = id
    out
  }

  # private

  JSONDump = -> (hash) {
    Oj.dump(hash, mode: :compat)
  }

end

Log = -> (msg) {
  puts msg
}

FetchLocation = -> {
  deviceLoc = CommaAPI.deviceDefaultLocation()
  Log.("new device location: #{deviceLoc}\n\n")
  deviceLoc
}


CONFIG = {
  host: "http://localhost:3001"
}

class Api < Roda

  plugin :streaming

  route do |r|

    r.root do
      "OK"
    end

    r.on "data" do
      response['Access-Control-Allow-Origin'] = CONFIG[:host]
      response['Content-Type'] = 'text/event-stream'
      stream do |out|
        while true do
          data = FetchLocation.()
          puts "loc: #{data}"
          out << FormatStream::Format.(:update_location, data)
          sleep 3
        end
      end
    end

  end

end

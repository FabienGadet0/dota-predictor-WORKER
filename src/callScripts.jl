module callScripts
using PyCall

ENV["DEBUG"] = false

pushfirst!(PyVector(pyimport("sys")."path"), "./files_generator")
csv_generator = pyimport("csv_generator")
live_watcher = pyimport("live_watcher")

end

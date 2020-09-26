using PyCall

pushfirst!(PyVector(pyimport("sys")."path"), "./files_generator")
csv_generator = pyimport("csv_generator")
csv_generator.generate_games(days_ago=2)
csv_generator.generate_meta()

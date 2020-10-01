include("./src/DBInterface.jl") # ? Maybe not mandatory to add src cause already in path ?
include("./src/CallScripts.jl")
include("./src/Generator.jl")

import CSV , Query
using DotEnv,  .DBInterface, ArgParse, .CallScripts, Match, DataFrames, .Generator, Dates
DotEnv.config()

# todo [x]  every week call generate_games for days_ago=10
# todo [x]  insert games in db
# todo [x]  every hours get incoming games
# todo [x]  insert it
# todo [x]  update_meta every week (depending on the amount of query (set in next todo))
# todo [ ]  predict these games
# todo [ ]  set to env number of queries done

# todo setup julia dans docker

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--generate-games"
            help = "Call python script and generate last games"
            arg_type = Int
            default = 0
        "--generate-meta"
            help = "Call python script and generate meta stats used for generating dataset indices"
            action = :store_true
        "--generate-live"
            help = "Call python script and generate live games"
            action = :store_true        
    end
return parse_args(s)
end

function handle_commandline(arg, value)
    @match (arg, value) begin
    ("generate-games", n::Int)   => n > 0 ? Generator.call_generate_games(n) : nothing
    ("generate-meta", b::Bool)   => (b && Dates.dayofweek(now()) === 1) ? Generator.call_generate_meta() : nothing
    ("generate-live", b::Bool)   => b ? Generator.call_generate_live() : nothing
    bad                          => println("Unknown argument: $bad")
    end
end

    
function main()
    # HTTP.serve(handler, "0.0.0.0", parse(Int, ARGS[1]))
    parsed_args = parse_commandline()
    @debug parsed_args
    for (arg, val) in parsed_args
        @debug "$arg  =>  $val"
        handle_commandline(arg, val)
    end
end


main()

# Generator.call_generate_live()
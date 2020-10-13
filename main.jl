include("src/postgresWrapper.jl") # ? Maybe not mandatory to add src cause already in path ?
include("src/callScripts.jl")
include("src/generator.jl")
include("src/Model.jl")
include("src/misc.jl")


import CSV , Query
using DotEnv,  .postgresWrapper, ArgParse, .callScripts, Match, DataFrames, .generator, Dates, .model
DotEnv.config()

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
        "--predict-all"
            help = "Get all non predicted games and predict"
            action = :store_true
    end
return parse_args(s)
end

function handle_commandline(arg, value)
    @match (arg, value) begin
    ("generate-games", n::Int)   => n > 0 ? generator.call_generate_games(n) : nothing
    ("generate-meta", b::Bool)   => (b && Dates.dayofweek(now()) === 1) ? generator.call_generate_meta() : nothing
    ("generate-live", b::Bool)   => b ? generator.call_generate_live() : nothing
    ("predict-all", b::Bool)   => b ? model.predictForEach() : nothing
    ("generate-and-predict", b::Bool)   => b ? generateAndPredict()  : nothing
    bad                          => println("Unknown argument: $bad")
    end
end

function generateAndPredict()
    generator.call_generate_games(1)
    generator.call_generate_live()
    model.predictForEach() 
end


function main()
    parsed_args = parse_commandline()
    @debug parsed_args
    for (arg, val) in parsed_args
        @debug "$arg  =>  $val"
        handle_commandline(arg, val)
    end
end

main()
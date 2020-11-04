module server

include("generator.jl")
include("model.jl")

using Genie
using .generator, .model
import Genie.Router: route
import Genie.Renderer.Json: json

Genie.config.run_as_server = true




function runServer()
    @info "Server start"
    route("/") do
    (:code => 0, :data => "Dota-predictor Worker") |> json
    end

    route("/generate-live") do
        rows = generator.call_generate_live()    
        model.predictForEach() 
        (:code => 0,  :data => (:rows_inserted => rows)) |> json
    end

    route("/generate-recent-games/:nb_days") do
        generator.call_generate_games(payload(nb_days))
        rows = model.predictForEach() 
        (:code => 0,  :data => (:rows_inserted => rows)) |> json
    end

    route("/predict-all") do
        rows = model.predictForEach() 
        (:code => 0, :data => (:rows_inserted => rows)) |> json
    end

    route("/train-all") do
        results = model.trainAll!()
        (:code => 0, :data => results) |> json
    end

    # Genie.config.server_port = parse(Int64, get(ENV, "PORT", "8000"))
    Genie.config.server_port = Int(ARGS[2]) #* Heroku compatibility
    @info "Running on port $(Genie.config.server_port)"
    Genie.startup()
end

end

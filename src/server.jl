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
    
    Genie.startup()
end

end
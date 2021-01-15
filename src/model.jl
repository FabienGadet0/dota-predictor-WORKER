module model

include("postgresWrapper.jl")



using .postgresWrapper, Match, DataFrames, Dates, DataFramesMeta
using JSON
using MLJ , MLJScikitLearnInterface


_countmissings(df) = DataFrame(zip(names(df), colwise(x -> sum(ismissing.(x)), df)))


# * Preprocess ####################################################################

function getPredictions(db)
    select(postgresWrapper.execQueryFromFile(db, "queries/get_new_predictions.sql"), Not([:fill_na, :winner_name]))
end

function getLastWeekDataForTrain(db)
    select(postgresWrapper.execQueryFromFile(db, "queries/get_last_week_games.sql"), Not(:fill_na))
end


function checkMissings(df)
    d = @where(_countmissings(df),:2 .> nrow(df) / 3)
    if nrow(d) > 0 
        @warn "Lots of missings (total rows : $(nrow(df))) : $d"
    end
    df
end



function cleanData(df)
    dropmissing(df)
    # ? Alternative is fillna(mean)
end

function defineTypes!(df)
    coerce!(df, autotype(df))
    coerce!(df,
                :radiant_team_winrate_with               => Continuous,
                :dire_team_winrate_with                  => Continuous,
                :radiant_team_winrate_against            => Continuous,
                :dire_team_winrate_against               => Continuous)
    df
end

# * Model   ##############################################################################



function prepareUnpack(df)
    defineTypes!(df)
    y, X = unpack(df, ==(:winner), name -> true; rng=123)
    train, test = partition(eachindex(y), 0.7, shuffle=true)
    X, y, train, test
end

function train!(modelName, df)
    X, y, train, test = prepareUnpack(df)
    mach = machine("models/files/$modelName.jlso", X, y)
    fit!(mach, rows=train, verbosity=2)
    @info "Training Model $modelName with $(nrow(df)) lines"
    evaluation = evaluate!(mach,resampling=CV(nfolds=6),
                 measures=[cross_entropy, brier_score])
    MLJ.save("models/files/$(modelName).jlso", mach)

    @info "(cross_entropy , brier_score)"
    @info evaluation
    evaluation
end

function loadSettings(modelName::String)
    try
        f = open(f -> read(f, String), "models/config/$modelName.json")
        return JSON.parse(f)
    catch _
        return nothing
    end
end

function getDfReadyForModel(modelName, df, addFeatures=[])
    features = loadSettings(modelName)["features"]
    if !isnothing(features)
        t = df[!, vcat(features, addFeatures)]
        return cleanData(t)
    end
    return nothing
end

function trainAll!()
    db = postgresWrapper.DbConstructor()
    df = getLastWeekDataForTrain(db)
    results = []
    models = getModels()
    if nrow(df) > 0 && length(models) > 0
        for modelName in models
            toTrain = getDfReadyForModel(modelName, df, ["winner"])
            if nrow(toTrain) > 0
                e = train!(modelName, toTrain)
                evals = zip(string.(e.measure), e.measurement) |> collect
                push!(results, (:model_name => modelName, :evaluations => evals))
            end
        end
    end
    results
end


function get_proba(predictions)
    map(x -> x < 0.5 ? 1 - x : x, pdf.(predictions, "radiant_team"))
end

function pred(modelName, X)
    mach = machine("models/files/$(modelName).jlso")
    predictions = predict(mach, X)
    predictions_name = mode.(predictions)
    predictions_proba = get_proba(predictions)
    [predictions_name, predictions_proba]
end

function getModels()
    files = split.(readdir("models/files"), '.')
    map(x -> x[2] == "jlso" ? string(x[1]) : nothing, files)
end

function predictForEach(df=DataFrame(), returnValues=false)
    # ? For each jlso in models , predict with it
    db = postgresWrapper.DbConstructor()

    results = DataFrame()
    models = getModels()
    if nrow(df) == 0
        df = getPredictions(db)
    end
    if nrow(df) > 0 && length(models) > 0
        X = select(df, Not(:match_id))
        for modelName in models
            tmp = DataFrame()
            toPredict = getDfReadyForModel(modelName, df, ["match_id"])
            X = select(toPredict, Not(:match_id))
            if nrow(toPredict) > 0
                p = pred(modelName, X)
                tmp["predict_name"] = p[1]
                tmp["predict_proba"] = p[2]
                tmp["model_name"] = modelName
                tmp["match_id"] = toPredict[!,"match_id"]
                results = vcat(tmp, results)
            end
        end

        postgresWrapper.write(db, results, "prediction", "inserted_date")
        postgresWrapper.close(db)
    end
    returnValues ? results : nrow(results)
end

# ? Load fresh model
# model = load(pkg="ScikitLearn", "RandomForestClassifier")

# ? Get all datas 
# df = @linq postgresWrapper.execQuery(db, "select t.*, g.winner from technical_data t inner join games g on g.match_id = t.match_id") |> DataFrame |> select(vcat(TEST_MODEL_FEATURES, "winner")) |> cleanData

# # ? Save
# MLJ.save("models/first_classifier.jlso", mach)


# # ? Load
# mach2 = machine("neural_net.jlso")
# # ? if you want to refit it 
# mach3 = machine("neural_net.jlso", X, y)

# # ? Predict
# mode.(yhat[1:4])
# # ? or 
# predict_mode(mach, X[test, :])[1]

# # ? Predict proba 
# broadcast(pdf, yhat[1], "dire_team")    

end
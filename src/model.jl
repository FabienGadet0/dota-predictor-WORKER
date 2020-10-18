module model

include("postgresWrapper.jl")



using .postgresWrapper, Match, DataFrames, Dates, DataFramesMeta
using MLJ, MLJScikitLearnInterface


_countmissings(df) = DataFrame(zip(names(df), colwise(x -> sum(ismissing.(x)), df)))


# * Preprocess ####################################################################

function getPredictions(db)
    postgresWrapper.execQueryFromFile(db, "queries/get_new_predictions.sql")[Not([:fill_na, :winner_name])]
end

function getLastWeekDataForTrain(db)
    postgresWrapper.execQueryFromFile(db, "queries/get_last_week_games.sql")[Not(:fill_na)]
end


function checkMissings(df)
    d = @where(_countmissings(df),:2 .> nrow(df) / 3)
    if nrow(d) > 0 
        @warn "Lots of missings (total rows : $(nrow(df))) : $d"
    end
    df
end



function cleanData(df)
    dropmissing!(df)
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
    # df = @linq df |> select(vcat(postgresWrapper.MODEL_FEATURES, "winner")) |> cleanData
    X, y, train, test = prepareUnpack(df)
    mach = machine("models/$modelName.jlso", X, y)
    fit!(mach, rows=train, verbosity=2)
    @info "Training Model $modelName with $(nrow(df)) lines"
    @info "(cross_entropy , brier_score)"
    @info (evaluate!(mach,resampling=CV(nfolds=6),
                 measures=[cross_entropy, brier_score]))
    MLJ.save("models/$(modelName).jlso", mach)
end

function trainAll!()
    db = postgresWrapper.DbConstructor()
    df = @linq getLastWeekDataForTrain(db) |> select(postgresWrapper.MODEL_FEATURES) |> cleanData
    files = split.(readdir("models/"), ".")
    files = map(x -> x[2] == "jlso" ? x[1] : nothing, files)
    if nrow(df) > 0 && length(files) > 0
        for modelName in files
            if modelName == "test_classifier"
                df = @linq getLastWeekDataForTrain(db) |> select(postgresWrapper.TEST_MODEL_FEATURES) |> cleanData
            end
            train!(modelName, df)
        end
    end
end


function get_proba(predictions)
    map(x -> x < 0.5 ? 1 - x : x, pdf.(predictions, "radiant_team"))
end

function pred(modelName, X)
    mach = machine("models/$(modelName).jlso")
    predictions = predict(mach, X)
    predictions_name = mode.(predictions)
    predictions_proba = get_proba(predictions)
    [predictions_name, predictions_proba]
end

function predictForEach(df=DataFrame(), returnValues=false)
    # ? For each jlso in models , predict with it
    db = postgresWrapper.DbConstructor()

    results = DataFrame()
    files = split.(readdir("models/"), ".")
    files = map(x -> x[2] == "jlso" ? x[1] : nothing, files)

    if nrow(df) == 0
        df = @linq getPredictions(db) |> select(vcat(postgresWrapper.MODEL_FEATURES, "match_id"))  |> cleanData
    end

    if nrow(df) > 0 && length(files) > 0
        X = df[Not(:match_id)]
        for modelName in files
            tmp = DataFrame()
            if modelName == "test_classifier"
                df = @linq getPredictions(db) |> select(vcat(postgresWrapper.TEST_MODEL_FEATURES, "match_id"))  |> cleanData
                X = df[Not(:match_id)]
            end
            p = pred(modelName, X)
            tmp["predict_proba"] = p[2]
            tmp["predict_name"] = p[1]
            tmp["model_name"] = modelName
            tmp["match_id"] = df["match_id"]
            results = vcat(tmp, results)
        end
        results["inserted_date"] = now()
        postgresWrapper.write(db, results, "prediction")
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
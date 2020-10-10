module Model

include("DBInterface.jl")



using .DBInterface, Match, DataFrames, Dates, DataFramesMeta
using MLJ, MLJScikitLearnInterface


_countmissings(df) = DataFrame(zip(names(df), colwise(x -> sum(ismissing.(x)), df)))


# * Preprocess ####################################################################

function getPredictions(db)
    DBInterface.execQueryFromFile(db, "queries/get_new_predictions.sql")[Not([:fill_na, :winner_name])]
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
    df = @linq df |> select(vcat(DBInterface.MODEL_FEATURES, "winner"))
    X, y, train, test = prepareUnpack(df)
    mach = machine("models/$modelName.jlso", X, y)
    fit!(mach, rows=train, verbosity=2)
    evaluate!(machine("models/test.jlso", X, y),resampling=CV(nfolds=6),
                 measures=[cross_entropy, brier_score])
    MLJ.save("models/$(modelName).jlso", mach)
end


function get_proba(predictions)
    pdf.(predictions, "radiant_team")
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
    db = DBInterface.DbConstructor()
    tmp = DataFrame()
    results = DataFrame()
    files = split.(readdir("models/"), ".")
    files = map(x -> x[2] == "jlso" ? x[1] : nothing, files)

    if nrow(df) == 0
        df = getPredictions(db) |> cleanData
    end

    if nrow(df) > 0 && length(files) > 0
        X =  @linq df |> select(DBInterface.MODEL_FEATURES)
        for modelName in files
            p = pred(modelName, X)
            tmp["predict_proba"] = p[2]
            tmp["predict_name"] = p[1]
            tmp["model_name"] = modelName
            tmp["match_id"] = df["match_id"]
            results = vcat(tmp, results)
        end
        DBInterface.write(db, results, "prediction")
        DBInterface.close(db)
    end
    returnValues ? results : nrow(results)
end


# model = load(pkg="ScikitLearn", "RandomForestClassifier")

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
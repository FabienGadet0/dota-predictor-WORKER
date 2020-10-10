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
    y, X = unpack(df, ==(:winner), name -> true; rng=123)
    train, test = partition(eachindex(y), 0.7, shuffle=true)
    X, y, train, test
end

function train(modelName, df)
    X, y, train, test = prepareUnpack(df)
    mach = machine(modelName, X, y)
    fit!(mach, rows=train, verbosity=2)
    MLJ.save(modelName, mach)
end

function predictForEach(modelName, df)
    # ? For each jlso in models , predict with it
    mach = machine("models/$modelName.jlso")
    predict(mach, df)
end


    # model = load(pkg="ScikitLearn", "RandomForestClassifier")

# ? Save
MLJ.save("models/first_classifier.jlso", mach)


# ? Load
mach2 = machine("neural_net.jlso")
# ? if you want to refit it 
mach3 = machine("neural_net.jlso", X, y)

# ? Predict
mode.(yhat[1:4])
# ? or 
predict_mode(mach, X[test, :])[1]

# ? Predict proba 
broadcast(pdf, yhat[1], "dire_team")    
using DataFrames, DotEnv, DataFramesMeta

module generator

    include("postgresWrapper.jl")
    include("callScripts.jl")


    import CSV , Query
    using .postgresWrapper, .callScripts, DataFrames

function call_generate_meta()
    callScripts.csv_generator.generate_meta()
end

function call_generate_games(days_ago::Int)
    callScripts.csv_generator.generate_games(days_ago=days_ago)
    db = postgresWrapper.DbConstructor()
    rows_inserted = postgresWrapper.file_to_db(db, "./data/dataset.csv")
    postgresWrapper.close(db)
    rows_inserted
end

function call_generate_live()
    callScripts.live_watcher.get_live()
    db = postgresWrapper.DbConstructor()
    rows_inserted = postgresWrapper.file_to_db(db, "./data/live_games.csv")
    postgresWrapper.close(db)
    rows_inserted
end


end

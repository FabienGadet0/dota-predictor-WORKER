using DataFrames, DotEnv, DataFramesMeta

module Generator

    include("DBInterface.jl")
    include("CallScripts.jl")

    import CSV , Query
    using .DBInterface, .CallScripts, DataFrames

function call_generate_meta()
    CallScripts.csv_generator.generate_meta()
end

function call_generate_games(days_ago::Int)
    CallScripts.csv_generator.generate_games(days_ago=days_ago)
    db = DBInterface.DbConstructor()
    rows_inserted = DBInterface.file_to_db(db, "./data/dataset.csv")
    DBInterface.close(db)
    rows_inserted
end

function call_generate_live()
    CallScripts.live_watcher.get_live()
    db = DBInterface.DbConstructor()
    rows_inserted = DBInterface.file_to_db(db, "./data/live_games.csv")
    DBInterface.close(db)
    rows_inserted
        # DBInterface.write(db, df, "games")
end


end

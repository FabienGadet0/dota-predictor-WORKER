module postgresWrapper

import Query
using IterTools, Tables, DataFramesMeta, DataFrames , Dates
using LibPQ

const COLUMNS_TO_CHANGE = Dict{String,String}("last_update_time" => "start_date", "start_time" => "start_date") 
const COLUMNS_TO_CONVERT_TO_INT = ["dire_score", "radiant_score", "first_blood_time", "duration", "radiant_score" , "duration", "match_id"]
const GAMES_MAIN_COLUMNS = ["match_id", "start_date", "dire_team", "radiant_team", "winner", "patch", "dire_score", "radiant_score" , "duration", "source"]
const TECHNICAL_DATA_COLUMNS = ["dire_team_heroes_meta_points"
,"radiant_team_heroes_meta_points"
,"dire_team_matchup_score"
,"radiant_team_matchup_score"
,"dire_team_synergy_with"
,"radiant_team_synergy_with"
,"dire_team_synergy_against"
,"radiant_team_synergy_against"
,"dire_team_synergy_score"
,"radiant_team_synergy_score"
,"dire_team_winrate"
,"radiant_team_winrate"
,"dire_team_winrate_with"
,"radiant_team_winrate_with"
,"dire_team_winrate_againpst"
,"radiant_team_winrate_against"
,"dire_team_rating"
,"first_blood_time"
,"radiant_team_rating"
,"radiant_team_peers_score"
,"dire_team_peers_score"
,"match_id"]


struct dbClass
    conn::LibPQ.Connection
end


function DbConstructor()
    return dbClass(LibPQ.Connection(ENV["CONNECTION_STRING"]))
end

function execQuery(db::dbClass, query::String)
    @debug "Exec Query $query" 
    return LibPQ.execute(db.conn, query) 
end


function execQueryFromFile(db::dbClass, file_path::String)
    @debug "Exec Query from file : $file" 
    @debug file_path
    open(file_path) do f
        query = Base.read(f, String)
        return DataFrame(LibPQ.execute(db.conn, query))
    end
end


function read(db::dbClass, tableName, limit=500000000)
    @debug "Read query : $tableName with limit $limit"
    LibPQ.execute(db.conn, "select * from  $tableName limit $limit;")
end

# function write(db::dbClass, df, tableName, timestamp_col="")
#     _prepare_field(x::Any) = x
#     _prepare_field(x::Missing) = ""
#     _prepare_field(x::AbstractString) = string("\"", replace(x, "\"" => "\"\""), "\"")

#     if timestamp_col != ""
#         df["inserted_date"] = now()
#     end

#     alreadyInDb = @linq read(db, tableName) |> DataFrame |> sort(:inserted_date, rev=true)

#     missingsColumns = filter(x -> !(x in names(df)), names(alreadyInDb))
#     for col in filter(x -> !(x in names(df)), names(alreadyInDb))
#         df[col] = missing
#     end
#     if tableName == "prediction"
#         toInsert = @linq vcat(df, alreadyInDb) |> unique([:match_id, :model_name])
#     else
#         toInsert = @linq vcat(df, alreadyInDb) |> unique([:match_id])
#     end

#     toInsert = dropmissing(df, [:match_id])

#     if nrow(toInsert) > 0
#         LibPQ.execute(db.conn, "truncate $tableName;")
#         row_names = join(string.(Tables.columnnames(toInsert)), ",")
#         row_strings = imap(Tables.eachrow(toInsert)) do row
#             join((_prepare_field(x) for x in row), ",") * "\n"
#         end
#         @debug "Inserting $(nrow(toInsert)) in $tableName)"
#         copyin = LibPQ.CopyIn("COPY $tableName ($row_names) FROM STDIN (FORMAT CSV) ;", row_strings)
#         LibPQ.execute(db.conn, copyin, throw_error=false)
#     end
#     nrow(toInsert)
# end


function write(db::dbClass, df, tableName, timestamp_col="", onConflict="")
    _prepare_field(x::Any) = x
    _prepare_field(x::Missing) = ""
    _prepare_field(x::AbstractString) = string(replace(x, "\'" => " \""))

    params = join(names(df), ',')
    toInsert = dropmissing(_prepare_field(df), [:match_id])
    valuesPlaceholder = chop(join(["\$" * string(x) * ',' for x in 1:length(names(df))]))
    if nrow(toInsert) > 0
        execute(db.conn, "BEGIN;")
        LibPQ.load!(
        toInsert,
        db.conn,
        "INSERT INTO $tableName ($params) VALUES ($valuesPlaceholder) $onConflict ;")
        execute(db.conn, "COMMIT;")
        nrow(toInsert)
    end
end


function close(db::dbClass)
    LibPQ.close(db.conn)
end

function get_all_new_prediction(db)
    df = execQuery(db, query)
end

function file_to_db(db::dbClass, path_to_csv::String)
    df = @linq CSV.read(path_to_csv) |> DataFrame
    if nrow(df) == 0
        @warn "$path_to_csv is empty, nothing to insert"
        return nothing
    end
    df = @linq df |> unique(:match_id)
    # ? Rename columns using the const dict upper (COLUMNS_TO_CHANGE)
    map(column -> column in keys(COLUMNS_TO_CHANGE) ? rename!(df, column => COLUMNS_TO_CHANGE[column]) : nothing, names(df))
    map(column -> column in COLUMNS_TO_CONVERT_TO_INT && sum(ismissing.(df[column])) == 0 ? df[!,column] = convert.(Int64, df[!,column]) : df[!,column], names(df))

    df = @linq df  |> dropmissing(["match_id", "dire_team", "radiant_team"])
    # ? Get the available columns
    games_columns = intersect(names(df), GAMES_MAIN_COLUMNS)
    technical_data_columns = intersect(names(df), TECHNICAL_DATA_COLUMNS)


    games = @linq df |> select(games_columns) 

    if "winner" in names(games)
        games["winner_name"] = ("winner" in names(games) && games["winner"] === "dire_team") ? games["dire_team"] : games["radiant_team"]
    end

    technical_data = @linq df |> 
        select(technical_data_columns)

    # games["inserted_date"] = now()
    postgresWrapper.write(db, technical_data, "technical_data", "inserted_date", "ON CONFLICT DO NOTHING")
    postgresWrapper.write(db, games, "games", "inserted_date", "ON CONFLICT DO NOTHING")

    nrow(games) 
end

end

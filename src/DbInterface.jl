module DbInterface
import CSV , Query, DataFrames,LibPQ
using IterTools, Tables

    struct dbClass
        conn::LibPQ.Connection
    end




    export DbConstructor
    function DbConstructor()
        return dbClass(LibPQ.Connection(ENV["CONNECTION_STRING"]))
    end

    export execQuery
    function execQuery(db::dbClass, query::String)
        return LibPQ.execute(db.conn, query) |> DataFrame
    end



    export read
    function read(db::dbClass, tableName, limit=500000)
        LibPQ.execute(db.conn, "select * from  $tableName limit $limit;")
    end

    export write
    function write(db::dbClass, df, tableName)
        _prepare_field(x:: Any) = x
        _prepare_field(x:: Missing) = ""
        _prepare_field(x:: AbstractString) = string("\"", replace(x, "\""=>"\"\""), "\"")
    
        row_names = join(string.(Tables.columnnames(df)), ",")
        row_strings = imap(Tables.eachrow(df)) do row
            join((_prepare_field(x) for x in row), ",")*"\n"
        end
        copyin = LibPQ.CopyIn("COPY $tableName ($row_names) FROM STDIN (FORMAT CSV);", row_strings)
        LibPQ.execute(db.conn, copyin)
    end

    export close
    function close(db::dbClass)
        LibPQ.close(db.conn)
    end

end

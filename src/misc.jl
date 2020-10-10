# module Misc
# include("./postgresWrapper.jl")
# include("./CallScripts.jl")

# import .postgresWrapper, CSV

# using DataFrames, DotEnv, DataFramesMeta, .CallScripts

# DotEnv.config()

# ENV["DEBUG"] = "False"


# end


_countmissings(df) = DataFrame(zip(names(df), colwise(x -> sum(ismissing.(x)), df)))
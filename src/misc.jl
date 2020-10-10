# module Misc
# include("./postgresWrapper.jl")
# include("./callScripts.jl")

# import .postgresWrapper, CSV

# using DataFrames, DotEnv, DataFramesMeta, .callScripts

# DotEnv.config()

# ENV["DEBUG"] = "False"


# end


_countmissings(df) = DataFrame(zip(names(df), colwise(x -> sum(ismissing.(x)), df)))
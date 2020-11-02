FROM julia:1.5.2-buster

COPY . /app
WORKDIR /app

ENV PYTHON=

# RUN julia -e "using Pkg; ; pkg\"activate . \"; Pkg.add(\"PyCall\") ; Pkg.build(\"PyCall\")"
RUN julia -e 'using Pkg; Pkg.add("ArgParse") ; Pkg.add("CSV") ; Pkg.add("Conda") ; Pkg.add("DataFrames") ; Pkg.add("DataFramesMeta"Dates") ; Pkg.add("DotEnv") ; Pkg.add("Genie") ; Pkg.add("IterTools") ; Pkg.add("JLSO") ; Pkg.add("JSON") ; Pkg.add("LibPQ") ; Pkg.add("MLJ") ; Pkg.add("MLJModels") ; Pkg.add("MLJScikitLearnInterface") ; Pkg.add("Match") ; Pkg.add("PrettyPrinting"PyCall") ; Pkg.add("Query") ; Pkg.add(Tables")'
# RUN julia -e "using Pkg;  pkg\"instantiate\"; pkg\"precompile\";"
RUN julia -e "using Conda; Conda.add(\"pandas\", Conda.ROOTENV); Conda.add(\"numpy\", Conda.ROOTENV); Conda.add(\"requests\", Conda.ROOTENV); Conda.add(\"termcolor\", Conda.ROOTENV);"
RUN julia -e "using Pkg;  pkg\"build\" ; pkg\"precompile\";"

# EXPOSE 8000

ENTRYPOINT ["julia", "src/app.jl", "--serve"]
FROM julia:1.5.2-buster

COPY . /app
WORKDIR /app

ENV PYTHON=

# RUN julia -e "using Pkg; ; pkg\"activate . \"; Pkg.add(\"PyCall\") ; Pkg.build(\"PyCall\")"
RUN julia -e 'using Pkg; Pkg.add("ArgParse") ;' 
RUN julia -e 'using Pkg; Pkg.add("CSV") ;' 
RUN julia -e 'using Pkg; Pkg.add("Conda") ;' 
RUN julia -e 'using Pkg; Pkg.add("DataFrames") ;' 
RUN julia -e 'using Pkg; Pkg.add("DataFramesMeta"Dates") ;' 
RUN julia -e 'using Pkg; Pkg.add("DotEnv") ;' 
RUN julia -e 'using Pkg; Pkg.add("Genie") ;' 
RUN julia -e 'using Pkg; Pkg.add("IterTools") ;' 
RUN julia -e 'using Pkg; Pkg.add("JLSO") ;' 
RUN julia -e 'using Pkg; Pkg.add("JSON") ;' 
RUN julia -e 'using Pkg; Pkg.add("LibPQ") ;' 
RUN julia -e 'using Pkg; Pkg.add("MLJ") ;' 
RUN julia -e 'using Pkg; Pkg.add("MLJModels") ;' 
RUN julia -e 'using Pkg; Pkg.add("MLJScikitLearnInterface") ;' 
RUN julia -e 'using Pkg; Pkg.add("Match") ;' 
RUN julia -e 'using Pkg; Pkg.add("PrettyPrinting"PyCall") ;' 
RUN julia -e 'using Pkg; Pkg.add("Query") ;' 
RUN julia -e 'using Pkg; Pkg.add(Tables");'

# RUN julia -e "using Pkg;  pkg\"instantiate\"; pkg\"precompile\";"
RUN julia -e "using Conda; Conda.add(\"pandas\", Conda.ROOTENV); Conda.add(\"numpy\", Conda.ROOTENV); Conda.add(\"requests\", Conda.ROOTENV); Conda.add(\"termcolor\", Conda.ROOTENV);"
RUN julia -e "using Pkg;  pkg\"build\" ; pkg\"precompile\";"

# EXPOSE 8000

ENTRYPOINT ["julia", "src/app.jl", "--serve"]
FROM julia:1.5.2-buster

COPY . /app
WORKDIR /app

ENV PYTHON=

# RUN julia -e "using Pkg; ; pkg\"activate . \"; Pkg.add(\"PyCall\") ; Pkg.build(\"PyCall\")"
RUN julia -e 'using Pkg; Pkg.add(["ArgParse","CSV","Conda","DataFrames","DataFramesMeta"Dates","DotEnv","Genie","IterTools","JLSO","JSON","LibPQ","MLJ","MLJModels","MLJScikitLearnInterface","Match","PrettyPrinting"PyCall","Query",Tables"])'
# RUN julia -e "using Pkg;  pkg\"instantiate\"; pkg\"precompile\";"
RUN julia -e "using Conda; Conda.add(\"pandas\", Conda.ROOTENV); Conda.add(\"numpy\", Conda.ROOTENV); Conda.add(\"requests\", Conda.ROOTENV); Conda.add(\"termcolor\", Conda.ROOTENV);"
RUN julia -e "using Pkg;  pkg\"build\" ; pkg\"precompile\";"

# EXPOSE 8000

ENTRYPOINT ["julia", "src/app.jl", "--serve"]
FROM julia:1.5.2-buster

# ADD packageInstall.jl /tmp/packageInstall.jl
# COPY Project.toml ~/.julia/environments/v1.5/
# COPY Manifest.toml ~/.julia/environments/v1.5/

COPY . /app/app
WORKDIR /app/app

# RUN julia --project=. /tmp/packageInstall.jl
ENV PYTHON=
# RUN julia --project=/app -e "using Pkg;Pkg.add(\"PyCall\");Pkg.build(\"PyCall\")"
RUN julia --project -e "using Pkg; Pkg.add(\"PyCall\") ; Pkg.build(\"PyCall\")"

RUN julia --project -e "using Conda ; Conda.add("pandas", Conda.ROOTENV)" && \
    julia --project -e "Conda.add("numpy", Conda.ROOTENV)" && \
    julia --project -e "Conda.add("requests", Conda.ROOTENV)" && \
    julia --project -e "Conda.add("termcolor", Conda.ROOTENV)"

# julia -e "Pkg.using("")"
#     julia -e "Pkg.update()" && \
#     julia -e "Pkg.add("CSV")" && \
#     julia -e "Pkg.add("DataFrames")" && \
#     julia -e "Pkg.add("DotEnv")" && \
#     julia -e "Pkg.add("IterTools")" && \
#     julia -e "Pkg.add("LibPQ")" && \
#     julia -e "Pkg.add("Missings")" && \
#     julia -e "Pkg.add("DataFramesMeta")" && \
#     julia -e "Pkg.add("ArgParse")" && \
#     julia -e "Pkg.add("Match")" && \
#     julia -e "Pkg.add("Conda")" && \
#     julia -e "Pkg.add("Query")" && \
#     julia -e "Pkg.add("Tables")" && \
#     julia -e "Pkg.add("PyCall")" && \
#     julia -e "import Conda" && \

# ENTRYPOINT [ "/bin/bash" ]
# CMD ["/bin/bash"]

CMD ["julia", "--project", "src/app.jl" , "--generate-and-predict"]
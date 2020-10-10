FROM julia:1.5.2-buster

ADD packageInstall.jl /tmp/packageInstall.jl

COPY . /app
WORKDIR /app

RUN julia  /tmp/packageInstall.jl

# RUN julia -e "using Pkg; Pkg.instantiate()" && \
#     # julia -e "Pkg.init()" && \
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
#     julia -e "Conda.add("pandas", Conda.ROOTENV)" && \
#     julia -e "Conda.add("numpy", Conda.ROOTENV)" && \
#     julia -e "Conda.add("requests", Conda.ROOTENV)" && \
#     julia -e "Conda.add("termcolor", Conda.ROOTENV)"

# ENTRYPOINT [ "/bin/bash" ]
# CMD ["/bin/bash"]

CMD ["julia"]
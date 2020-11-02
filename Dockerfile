FROM julia:1.5.2-buster

COPY . /app/app
WORKDIR /app/app

ENV PYTHON=

# RUN julia -e "using Pkg; ; pkg\"activate . \"; Pkg.add(\"PyCall\") ; Pkg.build(\"PyCall\")"
RUN julia --project=/app -e "using Pkg;  pkg\"instantiate\"; pkg\"precompile\";"
RUN julia --project=/app -e "using Conda; Conda.add(\"pandas\", Conda.ROOTENV); Conda.add(\"numpy\", Conda.ROOTENV); Conda.add(\"requests\", Conda.ROOTENV); Conda.add(\"termcolor\", Conda.ROOTENV);"

# EXPOSE 8000

ENTRYPOINT ["julia", "--project=/app", "src/app.jl", "--serve"]
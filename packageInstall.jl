using Pkg

metadata_packages = [
    "CSV",
    "DataFrames",
    "DotEnv",
    "IterTools",
    "LibPQ",
    "Missings",
    "PyCall",
    "Query",
    "Tables"
]

Pkg.update()

for package=metadata_packages
    Pkg.add(package)
end

# need to build XGBoost version for it to work
# Pkg.clone("https://github.com/antinucleon/XGBoost.jl.git")
# Pkg.build("XGBoost")

# Pkg.clone("https://github.com/benhamner/MachineLearning.jl")
# Pkg.pin("MachineLearning")

# Pkg.clone("https://github.com/Allardvm/LightGBM.jl.git")
# ENV["LIGHTGBM_PATH"] = "../LightGBM"

Pkg.resolve()
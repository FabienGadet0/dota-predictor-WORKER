### A Pluto.jl notebook ###
# v0.12.1

using Markdown
using InteractiveUtils

# ╔═╡ ef564012-0953-11eb-32ca-f1139f0f92fe
using MLJ

# ╔═╡ c0f28d10-0954-11eb-18e4-c7e4c92a45ea
begin
	include("src/model.jl")
	include("src/postgresWrapper.jl")
end

# ╔═╡ bafdc3a2-0954-11eb-220f-43d79e77e99c
begin
	const PATH = "/Users/fabien.gadet/Projects/dota-predictor-worker/";
    ENV["CONNECTION_STRING"] = "postgres://wemhcarsvfoxfm:461d5d8017ffe9c1b3f59832c87984860f4232654bea3c92822271c5efe5067f@ec2-176-34-114-78.eu-west-1.compute.amazonaws.com:5432/d61kmh9prjnrua"
end

# ╔═╡ 24fe4410-0956-11eb-1a60-472d2cd3389b
cd(PATH)

# ╔═╡ 08569d2a-0957-11eb-26fe-7775ffdb8c3f
db = postgresWrapper.dbConstructor()

# ╔═╡ Cell order:
# ╠═ef564012-0953-11eb-32ca-f1139f0f92fe
# ╠═bafdc3a2-0954-11eb-220f-43d79e77e99c
# ╠═24fe4410-0956-11eb-1a60-472d2cd3389b
# ╠═c0f28d10-0954-11eb-18e4-c7e4c92a45ea
# ╠═08569d2a-0957-11eb-26fe-7775ffdb8c3f

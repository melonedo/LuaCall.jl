using Clang.Generators
using Lua_jll

cd(@__DIR__)

const INCLUDE_DIR = normpath(Lua_jll.artifact_dir, "include")

options = load_options(joinpath(@__DIR__, "generator.toml"))

args = get_default_args()
push!(args, "-I$INCLUDE_DIR")

headers = joinpath.(INCLUDE_DIR, ["lua.h", "lauxlib.h", "lualib.h"])

ctx = create_context(headers, args, options)

build!(ctx)


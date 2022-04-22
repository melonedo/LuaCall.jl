struct LuaError <: Exception
    msg::String
end

function LuaError(LS::LuaState)
    msg = LS[]
    pop!(LS, 1)
    LuaError(msg)
end

Base.showerror(io::IO, ex::LuaError) = print(io, "LuaError: ", ex.msg)
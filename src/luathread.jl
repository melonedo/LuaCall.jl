
function new_thread!(LS::LuaState, main::Union{LuaCallable,Nothing}=nothing)
    t = LuaThread(lua_newthread(LS))
    isnothing(main) || start(t, main)
    t
end

function status(t::LuaThread)
    lua_status(t)
end

function start(t::LuaThread, main::LuaCallable)
    push!(t, main)
end



"""
    resume(host::LuaState, guest::LuaThread, args...; multiret=false, stacktrace=nothing)

Resume a thread `guest` with arguments `args`. The results will be moved to `host`. Keyword arguments
are similar to `(::LuaFunction)(...)`.
"""
function resume(host::LuaState, guest::LuaThread, args...; multiret=false, stacktrace=nothing)
    host = get_julia_wrapper(host)
    push!(guest, args...)
    nresults = Ref{Cint}()
    isnothing(stacktrace) || (old_debug = set_debug!(host, stacktrace))
    status = lua_resume(guest, host, length(args), nresults)
    isnothing(stacktrace) || set_debug!(host, old_debug)
    if status == LUA_OK || status == LUA_YIELD
        checkstack(host, nresults[])
        lua_xmove(guest, host, nresults[])
        return_on_lua_stack(host, multiret ? (-nresults[]:-1) : -1)
    else
        throw(LuaError(guest))
    end
end

function getstack(LS::LuaState, idx, ::Type{LuaThread})
    LuaThread(lua_tothread(LS, idx))
end



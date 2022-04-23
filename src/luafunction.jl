


const LuaCallable = Union{LuaFunction,LuaTable,LuaUserData}

iscfunction(f::LuaFunction) = lua_iscfunction(LS(f), idx(f)) |> !iszero

"""
    (f::LuaCallable)(args...; multiret=false)

Call the Lua function. By default only the first return value is used,
pass `multiret=true` to collect all return values.
"""
function (F::LuaCallable)(args...; multiret=false)
    call(F, args...; multiret)
end

function call(F::LuaCallable, args...; multiret=false)
    push!(LS(F), F)
    pcall(LS(F), args...; multiret)
end

"Pop and call the function at the top of the stack with `args`."
function pcall(LS::LuaState, args...; multiret=false)
    @assert lua_isfunction(LS, -1)
    old_top = top(LS) - 1
    push!(LS, args...)
    rc = lua_pcall(LS, length(args), multiret ? -1 : 1, 0)
    rc == LUA_OK || throw(LuaError(LS))
    nret = top(LS) - old_top
    PopStack(multiret ? [LS[i] for i in -nret:-1] : LS[], LS, nret)
end


"""
    push_cfunction!(LS::LuaState, f::Ptr{Cvoid}, upvalues...)

Push a C function to the Lua stack and return it. 
You may optionally associate upvalues with it, which can be accessed 
in the function with pseudo-index `lua_upvalueindex`.
"""
function push_cfunction!(LS::LuaState, f::Ptr{Cvoid}, upvalues...)
    checkstack(LS, length(upvalues) + 1)
    @inbounds push!(LS, upvalues...)
    lua_pushcclosure(LS, f, length(upvalues))
    PopStack(getstack(LS, -1, LuaFunction), LS, 1)
end

struct MultipleReturn{T}
    ret::T
end

"""
    LuaFunctionWrapper{func,narg}

Wrap a Julia `@cfunction` into a Lua function which handles error and yield.
Return a single value unless the return values is wrapped in `MultipleReturn`.

To avoid jumping out of `@cfunction`, this function returns a status code
(0 for normal return, 1 for error, 2 for yield), and the real return is handled
by Lua code. See `get_julia_function_wrapper`.

TODO: Multiple return need an C wrapper.
"""
struct LuaFunctionWrapper{func,narg} end
LuaFunctionWrapper(f, narg) = LuaFunctionWrapper{f,narg}()

function (::LuaFunctionWrapper{func,narg})(LS::Ptr{lua_State})::Cint where {func,narg}
    cur_top = top(LS)
    if narg > 0 && cur_top < narg
        push!(LS, 1, "Not enough arguments for $func: expect $narg, got $cur_top")
        return 2
    end

    try
        args = (get_julia(LS[i]) for i in 1:cur_top)
        ret = func(args...)
        if ret isa MultipleReturn
            ret = ret.ret
            push!(LS, 0, ret...)
            return 1 + length(ret)
        else
            push!(LS, 0, ret)
            return 2
        end
    catch e
        @debug "Error occurred when Lua calls Julia function `$func`" exception = (e, catch_backtrace())
        # `lua_error` is implemented as longjmp that jump out of this @cfunction
        # which is not allowed. So we simply return nothing and store the error
        msg = sprint(showerror, e)
        push!(LS, 1, msg)
        return 2
    end
end

"""
    @lua_CFunction

Shorthand for `@cfunction \$func Cint (Ptr{lua_State},)`.

The Lua API requires that this function has single argument `LS::Ptr{lua_State}`.
Arguments are everything on the stack, upvalues can be accessed with `lua_upvalueindex`
pseudo index on the stack. Return values are simply pushed to the stack, and this function
return the number of return values.
"""
macro lua_CFunction(func)
    quote
        @cfunction $func Cint (Ptr{lua_State},)
    end
end

function get_julia_function_wrapper(nret=1)
    rets = join(("ret$i" for i in 1:nret), ", ")
    """
    -- lua wrapper for $nret-return julia function
    local f = ...
    return function (...)
        status, $rets, k = f(...)
        if status == 0 then
            return $rets
        elseif status == 1 then
            error(ret1)
        elseif status == 2 then
            arg = coroutine.yield($rets)
            -- Lua implements proper tail calls
            return julia_call_handler(k, arg)
        end
    end
    """
end

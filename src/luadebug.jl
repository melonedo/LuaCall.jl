

function LuaError(msg::AbstractString)
    LuaError(msg, [])
end

function LuaError(LS::LuaState)
    msg = LS[] |> get_julia
    pop!(LS, 1)
    stack = get_stacktrace(LS)
    set_stacktrace!(LS, [])
    LuaError(msg, stack)
end

function Base.showerror(io::IO, ex::LuaError)
    println(io, "LuaError: ", ex.msg)
    if ex.stacktrace |> !isempty
        for frame in ex.stacktrace
            println(io, frame)
        end
    end
end

@noinline function get_julia_stacktrace(offset)
    anchor_frame = stacktrace()[offset]
    full_julia_stack = catch_backtrace()
    anchor = findfirst(full_julia_stack) do x
        for f in StackTraces.lookup(x)
            f == anchor_frame && return true
        end
        false
    end
    if isnothing(anchor)
        StackTraces.StackTrace()
    else
        julia_stack = full_julia_stack[1:anchor-1]
        stacktrace(julia_stack)
    end
end

Base.@kwdef struct LuaStackFrame
    name::String
    namewhat::String
    what::String
    source::String # short source
    currentline::Int
    istailcall::Bool
    # parameter names or "..." for vararg
    params::Vector{String}
end

function Base.show(io::IO, f::LuaStackFrame)
    print(io, '[', f.what, "] ")
    if f.namewhat != ""
        print(io, f.namewhat, ' ')
    end
    print(io, f.name, '(', join(f.params, ", "), ')')
    print(io, " at ", f.source, ':', f.currentline)
    if f.istailcall
        print(io, " [tailcall]")
    end
end

function get_param_names(LS::LuaState, ar::Ref{lua_Debug})
    nparams = ar[].nparams
    [unsafe_string(lua_getlocal(LS, ar, i)) for i in 1:nparams]
end

function get_lua_stacktrace(LS::LuaState)
    level = 0
    info = Ref{lua_Debug}()
    lua_stack = LuaStackFrame[]
    while lua_getstack(LS, level, info) |> !iszero
        level += 1
        lua_getinfo(LS, "nSlut", info)
        name_ptr = info[].name
        name = name_ptr == C_NULL ? "(anonymous)" : unsafe_string(name_ptr)
        namewhat = unsafe_string(info[].namewhat)
        what = unsafe_string(info[].what)
        buf = collect(mod.(info[].short_src, UInt8))
        GC.@preserve buf source = unsafe_string(pointer(buf))
        params = get_param_names(LS, info)
        if info[].isvararg |> !iszero
            push!(params, "...")
        end
        frame = LuaStackFrame(;
            name,
            namewhat,
            what,
            source,
            info[].currentline,
            istailcall = !iszero(info[].istailcall),
            params)
        push!(lua_stack, frame)
    end
    lua_stack
end

@noinline function store_stacktrace(LS::LuaState)
    # We may be unwinding a stack from a coroutine
    wrapper = get_julia_wrapper(LS)
    get_debug(wrapper) || return
    julia_stack = get_julia_stacktrace(5)
    lua_stack = get_lua_stacktrace(LS)
    set_stacktrace!(wrapper, [julia_stack; lua_stack])
end

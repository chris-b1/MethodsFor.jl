module MethodsFor

export methodsfor

using DataStructures: DefaultDict
using InteractiveUtils: methodswith
using Crayons: Crayon

struct MethodInfo
    name::Symbol
    def_mod::Module
    fx_mod::Module
end

struct GroupedMethods
    method_dct
end

const method_color = Crayon(foreground=:light_yellow)
const module_color = Crayon(foreground=:light_cyan)
const title_color = Crayon(foreground=:light_green)

function _groupmethods(methods::Array{Method}, q)
    exported = Dict{MethodInfo, Int}()
    method_dct = DefaultDict(() -> DefaultDict(() -> 0))

    for method in methods
        if !isnothing(q) && !occursin(q, string(method.name))
            continue
        end

        sig = Base.unwrap_unionall(method.sig)
        generic_fx_mod = sig.types[1].name.module

        mi = MethodInfo(method.name, method.module, generic_fx_mod)

        is_exported = mi.name in names(mi.def_mod) || mi.fx_mod == Base

        if is_exported
            method_dct[mi.fx_mod][mi.name] += 1
        end
    end

    return GroupedMethods(method_dct)
end

function Base.show(io::IO, ::MIME"text/plain", g::GroupedMethods)
    method_dct = g.method_dct
    colwidth = 45

    group_lengths = Dict((k, length(method_dct[k])) for k in keys(method_dct))
    ordered_keys = sort(collect(keys(group_lengths)), by=x->group_lengths[x]; rev=true)

    cols = [[], []]
    col_len(i) = isempty(cols[i]) ? 0 : sum(group_lengths[x] for x in cols[i])

    for k in ordered_keys
        next_length = group_lengths[k]
        if col_len(1) > col_len(2) + next_length + 2
            push!(cols[2], k)
        else
            push!(cols[1], k)
        end
    end
    coltexts = [[], []]
    for i in 1:2
        for k in cols[i]
            push!(coltexts[i], string(module_color(string(k))) * ":")

            for f in sort(collect(keys(method_dct[k])))
                count = method_dct[k][f]
                push!(coltexts[i], "  " * string(method_color(string(f))) * " with $count methods")
            end
        end
    end

    col_text(i, row) = row > length(coltexts[i]) ? "" : coltexts[i][row]

    for row in 1:max(length(coltexts[1]), length(coltexts[2]))
        one = rpad(col_text(1, row), colwidth)
        two = col_text(2, row)
        println(io, one, two)
    end
end

function _printmodule(types, modules)
    colwidth = 30

    coltexts = [
        [string(module_color("Types:"))],
        [string(module_color("Modules:"))],
    ]
    for typ in types
        push!(coltexts[1], "  " * string(typ))
    end
    for mod in modules
        push!(coltexts[2], "  " * string(mod))
    end

    col_text(i, row) = row > length(coltexts[i]) ? "" : coltexts[i][row]

    for row in 1:max(length(coltexts[1]), length(coltexts[2]))
        extra_pad = row == 1 ? 10 : 0
        one = rpad(col_text(1, row), colwidth + extra_pad)
        two = col_text(2, row)
        println(one, two)
    end
end


"""
    methodsfor(obj; q=nothing, supertypes=true, ret=false)

Pretty print list of exported methods related to `obj`
 - `obj` is a value -> functions that take a  typeof(obj)
 - `obj` is a type -> function that take a `obj`
 - `obj` is a Module -> all public types, modules and functions of `obj`
"""
function methodsfor(::Type{T}; q=nothing, supertypes=true) where {T}
    methods = methodswith(T; supertypes=supertypes)
    grouped = _groupmethods(methods, q)
    return grouped
end
methodsfor(val; kwargs...) = methodsfor(typeof(val); kwargs...)


function methodsfor(m::Module; functions=false, q=nothing)
    types = []
    fs = Method[]
    modules = []

    for name in names(m)
        obj = nothing
        try
            obj = getfield(m, name)
        catch
            continue
        end

        typ = typeof(obj)

        if typ == UnionAll || typ == DataType
            push!(types, name)
        elseif typ == Module
            push!(modules, name)
        else
            append!(fs, methods(obj))
        end
    end

    method_dct = _groupmethods(fs, q)

    _printmodule(types, modules)

    if functions
        println("\nExported Functions:\n")
        _printmethods(method_dct)
    end
end

end

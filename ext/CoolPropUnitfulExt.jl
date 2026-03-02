module CoolPropUnitfulExt
using CoolProp
using Unitful

# units for humid air
const _ha_units = Dict(
    "Tdb" => Unitful.u"K",
    "Twb" => Unitful.u"K",
    "Tdp" => Unitful.u"K",
    "D" => Unitful.u"K",
    "H" => Unitful.u"J/kg",
    "Hha" => Unitful.u"J/kg",
    "U" => Unitful.u"J/kg",
    "S" => Unitful.u"J/kg/K",
    "V" => Unitful.u"m^3/kg",
    "Vda" => Unitful.u"m^3/kg",
    "Vha" => Unitful.u"m^3/kg",
    "cp" => Unitful.u"J/kg/K",
    "CV" => Unitful.u"J/kg/K",
    "Cha" => Unitful.u"J/kg/K",
    "CVha" => Unitful.u"J/kg/K",
    "P_w" => Unitful.u"Pa",
    )



function CoolProp._get_unit(param::AbstractString, is_ha::Bool,val::Unitful.Quantity)
    # First check if it's a humid air parameter
    if is_ha && haskey(_ha_units, param)
        return _ha_units[param]
    end
    # Otherwise use the normal parameter info
    unit_str = "-"
    try
        unit_str = CoolProp.get_parameter_information_string(param, "units")
    catch
    end
    if unit_str == "-"
        return Unitful.NoUnits
    end
    try
        # The unit uses e.g. Pa-s to mean Pa*s
        unit_str = replace(unit_str, "-" => "*")
        parsed_unit =  Unitful.uparse(unit_str)
        if parsed_unit isa Unitful.Quantity
            return Unitful.unit(parsed_unit)
        end
        return parsed_unit
    catch err
        @warn "Failed to parse unit $(unit_str): " err
    end
    return Unitful.NoUnits
end

CoolProp._si_value(unit::Unitful.Units, value) = Unitful.ustrip(Unitful.uconvert(unit, value))

end #module
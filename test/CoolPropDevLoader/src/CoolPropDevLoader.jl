module CoolPropDevLoader

using Preferences
using Downloads

const SOURCEFORGE_URL = "https://sourceforge.net/projects/coolprop/files/CoolProp/nightly/source/CoolProp_sources.zip/download"
const COOLPROP_UUID = "e084ae63-2819-5025-826e-f8e611a84251"

#only available in linux
function compile_from_sourceforge()
    # 1. Configuration
    download_url = SOURCEFORGE_URL
    build_dir = joinpath(@__DIR__, "coolprop_build")  # Change as needed
    source_zip = joinpath(build_dir, "CoolProp_sources.zip")
    extract_dir = joinpath(build_dir, "CoolProp")
    lib_name = "libCoolProp.so"
    
    # 2. Create build directory
    mkpath(build_dir)
    mkpath(extract_dir)

    # 3. Download the source zip
    @info "Downloading CoolProp source from $download_url..."
    # SourceForge redirects: we need to find the actual download link
    # The nightly source is typically at:
    # https://sourceforge.net/projects/coolprop/files/CoolProp/nightly/source/CoolProp_sources.zip/download
    
    Downloads.download(download_url, source_zip)
    
    # 4. Extract the zip
    @info "Extracting source..."
    run(`unzip -q $source_zip -d $build_dir`)
    
    # 5. Prepare for CMake build
    cd(extract_dir) do
        # Create build directory inside extracted source
        build_subdir = joinpath(extract_dir, "build")
        mkpath(build_subdir)
        cd(build_subdir) do
            # 6. Configure with CMake - build shared library
            @info "Configuring with CMake..."
            run(`cmake .. -DCOOLPROP_SHARED_LIBRARY=ON -DCMAKE_BUILD_TYPE=Release`)
            
            # 7. Build
            @info "Compiling CoolProp (this may take a few minutes)..."
            run(`cmake --build . --config Release --parallel $(Sys.CPU_THREADS)`)
        end
    end
    
    # 8. Locate the generated shared library
    # The library is typically in build/ or build/Release/
    possible_paths = [
        joinpath(extract_dir, "build", lib_name),
        joinpath(extract_dir, "build", "Release", lib_name),
        joinpath(extract_dir, "build", "lib", lib_name),
    ]
    
    lib_path = nothing
    for p in possible_paths
        if isfile(p)
            lib_path = p
            break
        end
    end
    
    if lib_path === nothing
        error("Could not find compiled library. Looked in: $(join(possible_paths, ", "))")
    end
    
    @info "CoolProp library built successfully at: $lib_path"
    return lib_path
end

struct CompileCoolPropFromSourceforge end

function use_dev_library(::CompileCoolPropFromSourceforge)
    lib_src = compile_from_sourceforge()
    set_preferences!(COOLPROP_UUID,"coolprop_library" => lib_src, force = true)
    @info "Preference set to $lib_src"
end

function use_dev_library(lib_src::String)
    set_preferences!(COOLPROP_UUID,"coolprop_library" => lib_src, force = true)
    @info "Preference set to $lib_src"
end

function use_default_library()
    delete_preferences!(COOLPROP_UUID,"coolprop_library",force = true)
end

end #module
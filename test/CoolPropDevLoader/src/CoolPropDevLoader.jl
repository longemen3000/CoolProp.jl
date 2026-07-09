module CoolPropDevLoader

using Preferences
using Downloads

const SOURCEFORGE_URL = "https://sourceforge.net/projects/coolprop/files/CoolProp/nightly/source/CoolProp_sources.zip/download"
const COOLPROP_UUID = "e084ae63-2819-5025-826e-f8e611a84251"

#only available in linux
function compile_from_sourceforge()
    # 1. Configuration
    url = SOURCEFORGE_URL
    build_dir = joinpath(@__DIR__, "coolprop_build")  # Change as needed
    source_zip = joinpath(build_dir, "CoolProp_sources.zip")
    extract_dir = build_dir  # We'll extract directly into build_dir, then locate source root
    lib_name = "libCoolProp.so"
    
    # 2. Create build directory
    mkpath(build_dir)
    mkpath(extract_dir)

    # 3. Download the source zip
    @info "Downloading CoolProp source from $url..."
    download_url = "https://sourceforge.net/projects/coolprop/files/CoolProp/nightly/source/CoolProp_sources.zip/download"
    Downloads.download(download_url, source_zip)
    
    # 4. Extract the zip into build_dir
    @info "Extracting source..."
    run(`unzip -q $source_zip -d $build_dir`)
    
    # 5. Find the actual source root: a directory that contains CMakeLists.txt
    @info "Locating source root..."
    function find_cmakelists_root(dir)
        # Check if dir itself contains CMakeLists.txt
        if isfile(joinpath(dir, "CMakeLists.txt"))
            return dir
        end
        # Otherwise, look for a subdirectory that contains it
        for entry in readdir(dir)
            path = joinpath(dir, entry)
            if isdir(path) && isfile(joinpath(path, "CMakeLists.txt"))
                return path
            end
        end
        # If not found, search recursively (but be careful with deep structures)
        for (root, dirs, files) in walkdir(dir)
            if "CMakeLists.txt" in files
                return root
            end
        end
        error("Could not find CMakeLists.txt anywhere in $dir")
    end
    
    source_root = find_cmakelists_root(extract_dir)
    @info "Source root found at: $source_root"
    
    # 6. Prepare for CMake build: create a build subdirectory inside source_root
    build_subdir = joinpath(source_root, "build")
    mkpath(build_subdir)
    cd(build_subdir) do
        # 7. Configure with CMake - build shared library
        @info "Configuring with CMake..."
        run(`cmake .. -DCOOLPROP_SHARED_LIBRARY=ON -DCMAKE_BUILD_TYPE=Release`)
        
        # 8. Build
        @info "Compiling CoolProp (this may take a few minutes)..."
        run(`cmake --build . --config Release --parallel $(Sys.CPU_THREADS)`)
    end
    
    # 9. Locate the generated shared library
    # The library is typically in build/ or build/Release/ or build/lib/
    possible_paths = [
        joinpath(source_root, "build", lib_name),
        joinpath(source_root, "build", "Release", lib_name),
        joinpath(source_root, "build", "lib", lib_name),
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
    set_preferences!((COOLPROP_UUID,"CoolProp"),"coolprop_library" => lib_src, force = true,active_project_only = false)
    @info "Preference set to $lib_src"
end

function use_default_library()
    delete_preferences!((COOLPROP_UUID,"CoolProp"),"coolprop_library",force = true,active_project_only = false)
end

end #module
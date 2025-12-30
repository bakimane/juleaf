# Cross-platform PATH setup
if Sys.iswindows()
    # Windows: Add TinyTeX and Pandoc paths
    tinytex_path = joinpath(ENV["APPDATA"], "TinyTeX", "bin", "windows")
    pandoc_paths = [
        joinpath(get(ENV, "LOCALAPPDATA", ""), "Pandoc"),
        "C:\\Program Files\\Pandoc",
    ]
    
    if isdir(tinytex_path)
        ENV["PATH"] = ENV["PATH"] * ";" * tinytex_path
    end
    for p in pandoc_paths
        if isdir(p)
            ENV["PATH"] = ENV["PATH"] * ";" * p
        end
    end
else
    # macOS/Linux
    tinytex_path = joinpath(homedir(), "Library", "TinyTeX", "bin", "universal-darwin")
    if isdir(tinytex_path)
        ENV["PATH"] = ENV["PATH"] * ":" * tinytex_path
    end
    
    # Linux TinyTeX location
    linux_tinytex = joinpath(homedir(), ".TinyTeX", "bin", "x86_64-linux")
    if isdir(linux_tinytex)
        ENV["PATH"] = ENV["PATH"] * ":" * linux_tinytex
    end
end

using HTTP
using Weave
using Base64

const PORT = 8080
const TEMPLATES_DIR = joinpath(@__DIR__, "templates")
const OUTPUT_DIR = joinpath(@__DIR__, "output")

mkpath(TEMPLATES_DIR)
mkpath(OUTPUT_DIR)


function compile_document(content::String, packages::String, filetype::String="jmd")
    temp_dir = mktempdir()
    
    try
        cd(temp_dir) do
            filename = "document.jmd"
            write(filename, content)
            
            # Copy support files
            for file in ["IEEEtran.cls", "juleaf_logo.png", "ref.bib"]
                src = joinpath(TEMPLATES_DIR, file)
                if isfile(src)
                    cp(src, file)
                    println("✓ $file copied")
                end
            end
            
            # Check if Beamer
            is_beamer = occursin(r"documentclass:\s*beamer"i, content)
            
            # Check if Letter (raw LaTeX with \begin{document})
            is_letter = occursin(r"documentclass:\s*letter"i, content)
            
            if is_letter
                println("=== Compiling Letter (raw LaTeX) ===")
                
                # Extract content after YAML header and compile directly
                yaml_match = match(r"^---\s*\n.*?\n---\s*\n"s, content)
                if !isnothing(yaml_match)
                    latex_content = content[length(yaml_match.match)+1:end]
                else
                    latex_content = content
                end
                
                write("document.tex", latex_content)
                println("✓ Extracted LaTeX content")
                
                run(`xelatex -interaction=nonstopmode document.tex`)
                run(`xelatex -interaction=nonstopmode document.tex`)
                
                if isfile("document.pdf")
                    output_path = joinpath(OUTPUT_DIR, "output.pdf")
                    cp("document.pdf", output_path, force=true)
                    println("✓ Letter PDF created")
                    return output_path
                else
                    error("Letter compilation failed")
                end
            end
            
            if is_beamer
                println("=== Compiling Beamer presentation ===")
                
                # Step 1: Weave to markdown (execute Julia code)
                weave(filename, doctype="pandoc", out_path="document.md")
                
                if !isfile("document.md")
                    error("Weave failed to produce document.md")
                end
                println("✓ Weaved to markdown")
                
                # Read the markdown to check for images
                md_content = read("document.md", String)
                
                # Step 2: Use pandoc to convert markdown -> beamer PDF
                # Use pipeline to capture stderr for debugging
                pandoc_cmd = `pandoc document.md -t beamer -o document.pdf --pdf-engine=xelatex -V navigation=empty`
                
                println("Running: $pandoc_cmd")
                try
                    run(pandoc_cmd)
                catch e
                    # Try to get more info
                    println("Pandoc failed, trying with --verbose...")
                    run(pipeline(`pandoc document.md -t beamer -o document.tex`, stderr=devnull))
                    if isfile("document.tex")
                        println("Generated .tex content (first 2000 chars):")
                        tex = read("document.tex", String)
                        println(first(tex, 2000))
                    end
                    rethrow(e)
                end
                
                if isfile("document.pdf")
                    output_path = joinpath(OUTPUT_DIR, "output.pdf")
                    cp("document.pdf", output_path, force=true)
                    println("✓ Beamer PDF created")
                    return output_path
                else
                    error("Pandoc failed to produce PDF")
                end
            end
            
            # Regular .jmd compilation (non-beamer)
            if !isempty(strip(packages))
                content_lines = split(content, '\n')
                
                if startswith(strip(content), "---")
                    yaml_end = findfirst(i -> i > 1 && strip(content_lines[i]) == "---", 1:length(content_lines))
                    
                    if !isnothing(yaml_end)
                        has_header = false
                        header_line = 0
                        
                        for i in 1:yaml_end
                            if occursin("header-includes:", content_lines[i])
                                has_header = true
                                header_line = i
                                break
                            end
                        end
                        
                        if !has_header
                            insert!(content_lines, yaml_end, "header-includes:")
                            yaml_end += 1
                            header_line = yaml_end - 1
                        end
                        
                        pkg_lines = split(packages, '\n')
                        insert_pos = header_line + 1
                        for pkg in pkg_lines
                            pkg_stripped = strip(pkg)
                            if !isempty(pkg_stripped)
                                insert!(content_lines, insert_pos, "  - " * pkg_stripped)
                                insert_pos += 1
                            end
                        end
                        
                        write(filename, join(content_lines, '\n'))
                    end
                end
            end
            
            compilation_successful = false
            pdf_file = nothing
            
            println("Trying: pandoc2pdf with xelatex...")
            try
                weave(filename, doctype="pandoc2pdf", pandoc_options=["--pdf-engine=xelatex"])
                
                if isfile("document.pdf")
                    pdf_file = "document.pdf"
                    compilation_successful = true
                    println("✓ Success with pandoc2pdf + xelatex")
                end
            catch e
                println("✗ Failed: pandoc2pdf + xelatex: $(e)")
            end
            
            if !compilation_successful
                println("\nTrying: md2pdf...")
                try
                    weave(filename, doctype="md2pdf")
                    
                    if isfile("document.pdf")
                        pdf_file = "document.pdf"
                        compilation_successful = true
                        println("✓ Success with md2pdf")
                    end
                catch e
                    println("✗ Failed: md2pdf: $(e)")
                end
            end
            
            if !compilation_successful
                println("\nTrying: pandoc -> LaTeX -> xelatex...")
                try
                    weave(filename, doctype="pandoc", out_path="document.md")
                    
                    if isfile("document.md")
                        # Convert markdown to PDF via pandoc
                        run(`pandoc document.md -o document.pdf --pdf-engine=xelatex`)
                        
                        if isfile("document.pdf")
                            pdf_file = "document.pdf"
                            compilation_successful = true
                            println("✓ Success with pandoc markdown->pdf")
                        end
                    end
                catch e
                    println("✗ Failed: pandoc pipeline: $(e)")
                end
            end
            
            if compilation_successful && !isnothing(pdf_file) && isfile(pdf_file)
                output_path = joinpath(OUTPUT_DIR, "output.pdf")
                cp(pdf_file, output_path, force=true)
                println("✓ PDF created: $output_path")
                return output_path
            else
                error("All compilation strategies failed")
            end
        end
    catch e
        println("Compilation error:")
        println(sprint(showerror, e, catch_backtrace()))
        rethrow(e)
    end
end

router = HTTP.Router()

HTTP.register!(router, "GET", "/", req -> begin
    html_path = joinpath(@__DIR__, "juleaf.html")
    if isfile(html_path)
        HTTP.Response(200, ["Content-Type" => "text/html"], body=read(html_path))
    else
        HTTP.Response(404, "juleaf.html not found")
    end
end)

HTTP.register!(router, "POST", "/compile", req -> begin
    try
        content = String(req.body)
        
        packages = ""
        filetype = "jmd"
        
        header_pair = findfirst(p -> p.first == "X-LaTeX-Packages", req.headers)
        if !isnothing(header_pair)
            packages = String(base64decode(req.headers[header_pair].second))
        end
        
        type_pair = findfirst(p -> p.first == "X-File-Type", req.headers)
        if !isnothing(type_pair)
            filetype = String(req.headers[type_pair].second)
        end
        
        compile_document(content, packages, filetype)
        
        logs = "✓ Compilation successful"
        HTTP.Response(200, ["X-Compilation-Logs" => base64encode(logs)], "OK")
    catch e
        error_msg = sprint(showerror, e, catch_backtrace())
        HTTP.Response(500, ["X-Compilation-Logs" => base64encode(error_msg)], error_msg)
    end
end)

HTTP.register!(router, "GET", "/logo", req -> begin
    logo_path = joinpath(TEMPLATES_DIR, "juleaf_logo.png")
    if isfile(logo_path)
        HTTP.Response(200, ["Content-Type" => "image/png"], body=read(logo_path))
    else
        HTTP.Response(404, "Logo not found")
    end
end)

HTTP.register!(router, "GET", "/output.pdf", req -> begin
    pdf_path = joinpath(OUTPUT_DIR, "output.pdf")
    if isfile(pdf_path)
        HTTP.Response(200, ["Content-Type" => "application/pdf"], body=read(pdf_path))
    else
        HTTP.Response(404, "PDF not found")
    end
end)

# Workspace routes
HTTP.register!(router, "GET", "/workspace", req -> begin
    files = []
    
    # List output directory
    if isdir(OUTPUT_DIR)
        for f in readdir(OUTPUT_DIR)
            path = joinpath(OUTPUT_DIR, f)
            if isfile(path)
                push!(files, Dict(
                    "name" => f,
                    "size" => filesize(path),
                    "modified" => string(mtime(path))
                ))
            end
        end
    end
    
    # List templates directory
    if isdir(TEMPLATES_DIR)
        for f in readdir(TEMPLATES_DIR)
            path = joinpath(TEMPLATES_DIR, f)
            if isfile(path) && (endswith(f, ".jmd") || endswith(f, ".tex") || endswith(f, ".md"))
                push!(files, Dict(
                    "name" => f,
                    "size" => filesize(path),
                    "modified" => string(mtime(path))
                ))
            end
        end
    end
    
    json = "{\"files\":[" * join(["{\"name\":\"$(f["name"])\",\"size\":$(f["size"])}" for f in files], ",") * "]}"
    HTTP.Response(200, ["Content-Type" => "application/json"], body=json)
end)

HTTP.register!(router, "GET", "/workspace/{filename}", req -> begin
    filename = HTTP.getparams(req)["filename"]
    
    # Security: prevent path traversal
    if occursin("..", filename) || occursin("/", filename)
        return HTTP.Response(400, "Invalid filename")
    end
    
    # Check output directory first
    path = joinpath(OUTPUT_DIR, filename)
    if !isfile(path)
        path = joinpath(TEMPLATES_DIR, filename)
    end
    
    if isfile(path)
        content_type = if endswith(filename, ".pdf")
            "application/pdf"
        elseif endswith(filename, ".png")
            "image/png"
        elseif endswith(filename, ".jpg") || endswith(filename, ".jpeg")
            "image/jpeg"
        elseif endswith(filename, ".svg")
            "image/svg+xml"
        else
            "text/plain"
        end
        HTTP.Response(200, ["Content-Type" => content_type], body=read(path))
    else
        HTTP.Response(404, "File not found")
    end
end)

println("🚀 Juleaf server starting on http://localhost:$PORT")
println("📁 Templates: $TEMPLATES_DIR")

HTTP.serve(router, "0.0.0.0", PORT)

ENV["PATH"] = ENV["PATH"] * ":" * homedir() * "/Library/TinyTeX/bin/universal-darwin"
using HTTP, Sockets, Weave, Base64

const PORT = 8080
const EDITOR_HTML = read("editor.html", String)

# Default preamble
const DEFAULT_PREAMBLE = """
\\usepackage{amsthm}
\\usepackage{amsmath}
\\usepackage{amssymb}
\\newtheorem{theorem}{Theorem}
\\newtheorem{lemma}{Lemma}
\\newtheorem{definition}{Definition}
\\newtheorem{corollary}{Corollary}
"""

# Auto-create preamble.tex if missing
if !isfile("preamble.tex")
    write("preamble.tex", DEFAULT_PREAMBLE)
    println("✓ Created preamble.tex with default packages")
end

function compile_handler(req::HTTP.Request)
    try
        # Clean up old temp files
        for f in readdir()
            if startswith(f, "temp_doc") || startswith(f, "jl_")
                rm(f, force=true, recursive=true)
            end
        end
        if isdir("figures")
            rm("figures", recursive=true)
        end
        
        # Get custom packages from header
        packages_header = get(Dict(req.headers), "X-LaTeX-Packages", "")
        custom_packages = !isempty(packages_header) ? String(base64decode(packages_header)) : DEFAULT_PREAMBLE
        
        # Write custom preamble
        write("preamble.tex", custom_packages)
        
        content = String(req.body)
        temp_file = "temp_doc.jmd"
        write(temp_file, content)
        cp("./templates/IEEEtran.cls", "IEEEtran.cls", force=true)
        # Compile with preamble
        weave(temp_file, doctype="pandoc2pdf", 
        pandoc_options=["--include-in-header=preamble.tex", 
                      "--from=markdown+raw_tex"])
        
        log_file = "temp_doc.log"
        logs = isfile(log_file) ? read(log_file, String) : "Compilation completed"
        
        pdf_path = "temp_doc.pdf"
        if isfile(pdf_path)
            cp(pdf_path, "output.pdf", force=true)
            
            # Clean up
            for f in readdir()
                if startswith(f, "temp_doc") || startswith(f, "jl_")
                    rm(f, force=true, recursive=true)
                end
            end
            if isdir("figures")
                rm("figures", recursive=true)
            end
            
            return HTTP.Response(200, 
                ["Content-Type" => "application/json",
                 "X-Compilation-Logs" => base64encode(logs)], 
                body="{\"status\":\"success\"}")
        else
            return HTTP.Response(500, "PDF not generated")
        end
    catch e
        error_msg = sprint(showerror, e)
        println("Error: $error_msg")
        return HTTP.Response(500, error_msg)
    end
end

function editor_handler(req::HTTP.Request)
    return HTTP.Response(200, ["Content-Type" => "text/html"], body=EDITOR_HTML)
end

function pdf_handler(req::HTTP.Request)
    pdf_path = "output.pdf"
    if isfile(pdf_path)
        pdf_data = read(pdf_path)
        return HTTP.Response(200, ["Content-Type" => "application/pdf"], body=pdf_data)
    else
        return HTTP.Response(404, "PDF not found")
    end
end

function handle_request(req::HTTP.Request)
    if req.target == "/"
        return editor_handler(req)
    elseif req.target == "/compile" && req.method == "POST"
        return compile_handler(req)
    elseif req.target == "/output.pdf"
        return pdf_handler(req)
    else
        return HTTP.Response(404, "Not Found")
    end
end

println("Starting Julia Weave Editor on http://localhost:$PORT")
println("Press Ctrl+C to stop")
HTTP.serve(handle_request, Sockets.localhost, PORT)

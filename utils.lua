function ls (directory, all) --Function that returns a table with the contents of a directory
    if all then
        all = "-a"
    else
        all = ""
    end

    local i, t, popen = 0, {}, io.popen
    for filename in popen('ls '..all..' "'..directory..'"'):lines() do
        i = i + 1
        t[i] = filename
    end
    return t
end

function isDir (path) --Returns true if path is a directory
    local result = io.popen('[ -d "'..path..'" ] && echo "true"')
    if result then result = result:read() end
    return result == "true"
end

function getParentDir (path) --Returns the parent directory of the path (to avoid '/..' clutter)
    local dir = io.popen('cd "'..path..'/.." && pwd'):read()
    return dir
end

function getExtension (name)
    return name:match("^.+(%..+)$")
end

textExtensions = {'.lua', '.txt', '.py', '.cpp', '.rs', '.c', '.rb', '.ini', '.sh', '.xml', '.toml', '.md', '.html', '.js'}
for k,v in pairs(textExtensions) do
    textExtensions[v] = true
end

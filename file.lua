local file = {}

function file:clicked(mousex, mousey)
    return mousex < self.x+100 and
         self.x < mousex+1 and
         mousey < self.y+100 and
         self.y < mousey+1     
end

function file:new(path, name)
    local f = {}          
    setmetatable(f,file)
    f.path = path
    f.name = name
    f.x = 90
    f.y = 90
    f.clicked = file.clicked
    if isDir(f.path) then
        f.type = "dir"
        f.color = {255,140,0}
    else
        if textExtensions[getExtension(f.name)] then
            f.type = "text"
        end
        f.color = {255,255,255}
    end
    return f
end

return file

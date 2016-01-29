local file = require "file"
local camera = require "camera"
require "utils"

local HOME = os.getenv("HOME")
local currentdir
local time = 60
local options = {}
local typing
local typingText
local doneTyping
local typingOption
local help
local helpText = [[
'.' to show hidden files
'esc' to go to the parent directory
'r' to reset options
]]

items = {} --This table holds the files and directories paths, names, position etc

local function optionparse (string)
    local t = {}
    for i=0,#string,1 do
        if string:sub(i,i) == ":" then
            t[1] = string:sub(1,i-1)
            t[2] = string:sub(i+2,#string)
            break
        end
    end
    return t[1], t[2]
end

local function update()
    print("Updating")
    local files = ls(currentdir, options.showhiddenfiles) --get table with contents of directory
    items = {}

    for k,name in pairs(files) do --pass those names to more complex items
        if name ~= "." and name ~= ".." then
            items[#items+1] = file:new(currentdir.."/"..name, name)
        end
    end
        
    local row = 90 --thing to hold the vertical axis
    for k,f in pairs(items) do
        if items[k-1] then
            f.x = items[k-1].x+130
            if f.x+110 > width then --hits the border of the screen, go to next row
                f.x = 90
                row = row+130
            end
            f.y = row
        end
    end
end

function love.load()
    width = love.graphics.getWidth()
    height = love.graphics.getHeight()
    
    if love.filesystem.exists("options.txt") then --If the file options.txt exists, then
        for line in love.filesystem.lines("options.txt") do --Iterate each line
            local var, value  = optionparse(line) --Parse each line
            print("Reading option:", var, value)
            options[var] = value --Save the value to a table
        end
    else
        love.filesystem.write("options.txt", "") --If it doesn't exist, create it
    end

    currentdir = HOME
    if options.showhiddenfiles == "true" then
        options.showhiddenfiles = true
    else
        options.showhiddenfiles = false
    end
end

function love.update(dt)
    time = time+dt
    
    if doneTyping then
        doneTyping = false
        options[typingOption] = typingText
        typingText = ""
    end

    if time > 60 then --Update every minute
        time = 0
        update()
    end
end

function love.draw()
    camera:set()
    
    for k,f in pairs(items) do --Print rectangles which represent the files/directories
        love.graphics.setColor(f.color)
        love.graphics.rectangle("fill", f.x,f.y, 100,100)
        
        love.graphics.setColor(255,255,255)
        if #f.name > 16 and not f:clicked(love.mouse.getX()+camera:getX(), love.mouse.getY()+camera:getY()) then
            love.graphics.print(f.name:sub(1,13).."...", f.x, f.y+110)
        else
            love.graphics.print(f.name, f.x, f.y+110)
        end
    end

    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill", camera:getX(), camera:getY(), width, 50)
    love.graphics.setColor(255,255,255)
    love.graphics.print(currentdir, 20+camera:getX(), 30+camera:getY()) --Print on top of the window the current directory path
    love.graphics.print("H to toggle help", camera:getX(), camera:getY())
    
    if help then
        love.graphics.print(helpText, camera:getX()+width/3, camera:getY())
    end

    if typing then
        love.graphics.setColor(0,0,0)
        love.graphics.rectangle("fill", camera:getX(), camera:getY()+height/2-230, width, 50)
        love.graphics.setColor(255,255,255)
        if typingOption == "editor" then
            love.graphics.print("Type the name of the text editing program",camera:getX()+width/2-200, camera:getY()+height/2-220)
        end
        love.graphics.print(typingText, camera:getX()+width/2-200, camera:getY()+height/2-200)
    end

    camera:unset()
end

function love.keypressed(k)
    if k == "escape" and not typing then --When escape is pressed,
        if currentdir ~= "/" then --go to parent dir
            currentdir = getParentDir(currentdir)
            update()
        end
        camera:setY(0) --Reset camera
    
    elseif k == "h" and not typing then
        help = not help --toggle help

    elseif k == "r" and not typing then
        print("Resetting")
        options = {showhiddenfiles = false}
        update()
        love.filesystem.write("options.txt", "")

    elseif k == "." and not typing then --Toggle hidden files ('.*')
        print("Toggling hidden files")
        options.showhiddenfiles = not options.showhiddenfiles
        options.showhiddenfiles = options.showhiddenfiles
        update()
    
    elseif typing then
        if k == "backspace" then
            typingText = typingText:sub(1, #typingText-1)
        elseif k == "return" then
            typing = false
            doneTyping = true
        elseif k == "escape" then
            typing = false
            typingText = ""
        end
    end
end

function love.mousepressed(x,y, button, istouch)
    if button == 1 then --If left mouse button is pressed
        for k,f in pairs(items) do
            if f:clicked(x+camera:getX(),y+camera:getY()) then --If a item is pressed
                print("Clicked item", k)
                if f.type == "dir" then --If that item is a directory cd to it
                    currentdir = f.path
                    camera:setY(0)
                    update()

                elseif f.type == "text" then
                    if not options.editor then
                        print("Typing")
                        typing = true
                        typingOption = 'editor'
                        typingText = ""
                    else
                        os.execute(string.format("%s %s &", options.editor, f.path))
                    end
                end
            end
        end
    end
end

function love.wheelmoved(x, y) --Scrolling
    if y > 0 and camera:getY() > 0 then --Up
        camera:setY(camera:getY()-10)
    elseif y < 0 then --Down
        camera:setY(camera:getY()+10)
    end
end

function love.resize(w,h) --Update when resized
    update()
    width = love.graphics.getWidth()
    height = love.graphics.getHeight()
end

function love.quit()
    print("Saving options")
    love.filesystem.write("options.txt", "")
    for k,v in pairs(options) do
        local v = tostring(v)
        print("Appending", string.format("%s: %s\n", k, v))
        love.filesystem.append("options.txt", string.format("%s: %s\n", k, v))
    end
    print("Saved options, quitting")
end

function love.textinput(ch)
    if typing then
        typingText = typingText..ch
    end
end

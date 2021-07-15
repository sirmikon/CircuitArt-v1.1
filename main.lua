
-- set directory
love.filesystem.setIdentity("screenshots")
love.keyboard.setKeyRepeat(true)

-- load font
local font40b = love.graphics.newFont("fonts/Hack-Bold.ttf", 40)
local font40_height = font40b:getHeight()
local font40 = love.graphics.newFont("fonts/Hack-Regular.ttf", 40)

-- set dimensions
local cell = 25
local border = cell * 4
local rows
local cols

function upScreenSize(c, b)
  rows = math.floor((love.graphics.getHeight() - b * 2) / c)
  cols = math.floor((love.graphics.getWidth()  - b * 2) / c)
end

upScreenSize(cell, border)

-- make tables
local nodes = {}    -- nodes
local paths = {}    -- basic paths relative to nodes
local pathsC = {}   -- paths with actual coordinates and colors

-- path length
local maxAttempts = 4   -- influences length of path
local jitter = cell * .05

-- create test directions
local direction = {}
  direction[1] = {x = 0, y = -1}
  direction[2] = {x = 1, y = 0}
  direction[3] = {x = 0, y = 1}
  direction[4] = {x = -1, y = 0}

function buildPaths()
  -- assign node coordinates and set to isOccupied = false
  for i = 1, rows do
    nodes[i] = {}
    for j = 1, cols do
      nodes[i][j] = {
        isOccupied = false,
        isEndpoint = false,
        x = border + j * cell - cell/2,
        y = border + i * cell - cell/2
      }
    end
  end
  --cycle through nodes
  paths = {}
  pathsC = {}
  for i = 1, rows do
    for j = 1, cols do
      -- check if node isOccupied first
      -- ******************************
      if nodes[i][j].isOccupied == false then
        -- set last node
        local current_x = j
        local current_y = i
        --
        local pathNumber= #paths+1
        local pathLength = 0
        -- keep trying until max attempts hit
        local attempts = 0  --reset attempt counter
        repeat
          -- randomly select direction to test
          local testDirection = love.math.random(1,4)
          -- get node coorindates of proposed direction
          proposed_x = current_x + direction[testDirection].x
          proposed_y = current_y + direction[testDirection].y

          -- determine if proposed direction is viable
          if proposed_x > 0 and proposed_x <= cols and proposed_y > 0 and proposed_y <= rows and nodes[proposed_y][proposed_x].isOccupied == false then
            nodes[current_y][current_x].isOccupied = true -- set current node to occupied
            if pathLength == 0 then  -- if it is the first point in the path
              nodes[current_y][current_x].isEndpoint = true   -- estblish current path as an endpoint
              paths[pathNumber] = {}
              paths[pathNumber][#paths[pathNumber]+1] = current_x    -- write initial node map to path
              paths[pathNumber][#paths[pathNumber]+1] = current_y
            end
            pathLength = pathLength + 1 -- update path length
            paths[pathNumber][#paths[pathNumber]+1] = proposed_x    -- add x coordinate to path
            paths[pathNumber][#paths[pathNumber]+1] = proposed_y    -- add y coordinate to path
            nodes[proposed_y][proposed_x].isOccupied = true
            -- update currrent_x and current_y
            current_x = proposed_x
            current_y = proposed_y
            attempts = 0
          else
            attempts = attempts + 1
          end
          -- search surrounding nodes
          if attempts == maxAttempts then
            nodes[current_y][current_x].isEndpoint = true
          end
        until attempts == maxAttempts
      end
    end
  end
end

buildPaths()

local colors = {}
function loadColors()

  -- Polar Ice, Dark Variant
  -- https://themer.dev/
  -- https://meyerweb.com/eric/tools/color-blend/#::1:hex

  colors.shade = {}
    colors.shade[1] = {.27, .28, .31}    -- background (dark grey)
    colors.shade[2] = {.34, .38, .41}    -- 1 shade lighter
    colors.shade[3] = {.41, .47, .51}    -- 1 shade lighter
    colors.shade[4] = {.49, .57, .61}    -- 1 shade lighter
    colors.shade[5] = {.56, .67, .70}    -- 1 shade lighter
    colors.shade[6] = {.63, .76, .80}    -- 1 shade lighter
    colors.shade[7] = {.71, .86, .90}    -- 1 shade lighter
    colors.shade[8] = {.78, .95, 1  }    -- brightest shade

  colors.accent = {}
    colors.accent[1] = {.96, .58, .59}  --  red
    colors.accent[2] = {.95, .71, .58}  --  orange
    colors.accent[3] = {.95, .86, .58}  --  yellow
    colors.accent[4] = {.78, .95, .62}  --  green
    colors.accent[5] = {.58, .95, .87}  --  blue/green
    colors.accent[6] = {.58, .81, .95}  --  blue
    colors.accent[7] = {.86, .61, .97}  --  purple
    colors.accent[8] = {.97, .61, .88}  --  pink
end

loadColors()
-- colors & weights
local color_chooser = {}
local color_prob = {}
local color_cumProb = {}

function loadColorChooser()
  for i = 1, #colors.accent do
    color_chooser[#color_chooser+1] = {c = colors.accent[i], w = 1}
  end
  color_chooser[#color_chooser+1] = {c = colors.shade[3], w = 30}
-- build color probability table
  -- get total weight
  local color_totalWeight = 0
  for i = 1, #color_chooser do
    color_totalWeight = color_totalWeight + color_chooser[i].w
  end
  -- get probability
  local color_cumP = 0
  for i = 1, #color_chooser do
    color_prob[i] = color_chooser[i].w / color_totalWeight
    color_cumP = color_cumP + color_prob[i]
    color_cumProb[i] = color_prob[i] + color_cumP
  end
end

loadColorChooser()

-- turn paths into coordinates by checking against nodes table!
function constructPath()
  for i = 1, #paths do
    pathsC[i] = {}

    -- pick a color
    local roll = love.math.random()
    local color_choice
    for i = 1, #color_chooser do
      if roll <= color_cumProb[i] then
        color_choice = i
        break
      end
    end
    pathsC[i].c = color_chooser[color_choice].c

    -- assign coordinates
    pathsC[i].p = {}
    for j = 1, #paths[i], 2 do
      pathsC[i].p[j]   = nodes[paths[i][j+1]][paths[i][j]].x
      pathsC[i].p[j+1] = nodes[paths[i][j+1]][paths[i][j]].y
    end
  end
end

function nodeJitter()
  for i = 1, rows do
    for j = 1, cols do
      roll = love.math.random() * (jitter - jitter*-1) + jitter*-1
      nodes[i][j].x = nodes[i][j].x + roll
      roll = love.math.random() * (jitter - jitter*-1) + jitter*-1
      nodes[i][j].y = nodes[i][j].y + roll
    end
  end
end

nodeJitter()
constructPath()

-- create a text-box
local msgBox = {on = false}
local text = ""
function msgBox_dimensions()
  msgBox = {
    x = love.graphics.getWidth() / 3,
    y = love.graphics.getHeight() / 2 - (love.graphics.getHeight() / 4)/2,
    w = love.graphics.getWidth() / 3,
    h = font40_height * 4
  }
end

msgBox_dimensions()

-- set background color
love.graphics.setBackgroundColor(colors.shade[1])

function love.draw()

  --draw unoccupied nodes as circles
  love.graphics.setLineWidth(3)
  love.graphics.setColor(colors.shade[2])
  for i = 1, rows do
    for j = 1, cols do
      if nodes[i][j].isOccupied == false then
        love.graphics.circle("line", nodes[i][j].x, nodes[i][j].y, 5)
      end
    end
  end

  for i = 1, #pathsC do
    -- draw paths
    love.graphics.setColor(pathsC[i].c)
    love.graphics.line(pathsC[i].p)
    -- draw inner circles at endpoints
    love.graphics.setColor(colors.shade[1])
    love.graphics.circle("fill", pathsC[i].p[1], pathsC[i].p[2], 5)
    love.graphics.circle("fill", pathsC[i].p[#pathsC[i].p-1], pathsC[i].p[#pathsC[i].p], 5)
    -- draw circles at endpoints
    love.graphics.setColor(pathsC[i].c)
    love.graphics.circle("line", pathsC[i].p[1], pathsC[i].p[2], 5)
    love.graphics.circle("line", pathsC[i].p[#pathsC[i].p-1], pathsC[i].p[#pathsC[i].p], 5)
  end

  -- draw message msgBox
  if msgBox.on == true then
    love.graphics.setColor(colors.shade[1])
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("fill", msgBox.x, msgBox.y, msgBox.w, msgBox.h)
    love.graphics.setColor(colors.shade[8])
    love.graphics.rectangle("line", msgBox.x, msgBox.y, msgBox.w, msgBox.h)

    love.graphics.setFont(font40b)
    love.graphics.printf(text, msgBox.x, msgBox.y + font40_height, msgBox.w, "center")
  end
end

function love.resize(w, h)
  upScreenSize(cell, border)
  buildPaths()
  constructPath()
  msgBox_dimensions()
end

function love.keypressed(key)
  if key == "f2" then
    buildPaths()
    constructPath()
  elseif key == "f3" then
    love.graphics.captureScreenshot("circuits_"..os.time().."_"..love.graphics.getWidth().."x"..love.graphics.getHeight()..".png")
  elseif key == "f4" then
    nodeJitter()
    constructPath()
  elseif key == "escape" then
    love.event.quit()
  elseif key == "f1" then  -- toggle message box
    msgBox.on = not msgBox.on
  elseif key == "backspace" and msgBox.on == true then
    text = text:sub(1, #text-1)
  elseif key == "f9" then
    love.window.setMode(1440, 960, {resizable = true})
    love.resize(w, h)
  elseif key == "f10" then
    love.window.setMode(750, 1334, {resizable = true})
    love.resize(w, h)
  elseif key == "f11" then
    love.window.setMode(240, 336, {resizable = true})
    love.resize(w, h)

  end
end

function love.textinput(t)
  if msgBox.on == true then
    text = text..t
  end
end

-- TODO
-- falling tiles
-- generate somewhere other than the transition.onComplete handler
-- put scanning for 3 or more tiles in a row/col in a utility function somewhere (fuck lua's module system)

local composer = require('composer')
local widget = require('widget')

local utils = require('utils')
local icons_sheet = require('icons_sheet')

local scene = composer.newScene()


local TC = {

    __tostring = function(self)
        return string.format('TC: name = %s', self.name)
    end,

    createTile = function(self, tileType, column, row)
            local tileX,tileY = self:tilePositionByColRow(column, row)
            local tileType = math.random(1, #icons_sheet.frames)
            local rect = display.newImageRect(self.container, self.imageSheet, tileType, self.tileWidth, self.tileHeight)
            rect.x = tileX
            rect.y = tileY
            rect.rotation = math.random(1,360)
            local tile = SimplifiedTile:new(tileType, rect, column, row)
            return tile
    end,


    new = function(self, numHorizontalTiles, numVerticalTiles, containerWidth, containerHeight,
                    tileMarginX, tileMarginY, scoreBoard, effectsLayer)

        local tileWidth = math.floor(containerWidth / numHorizontalTiles) - tileMarginX
        local tileHeight = math.floor(containerHeight / numVerticalTiles) - tileMarginY

        local o = {
            numHorizontalTiles = numHorizontalTiles, numVerticalTiles = numVerticalTiles,
            containerWidth = containerWidth, containerHeight = containerHeight,
            tileMarginX = tileMarginX, tileMarginY = tileMarginY,
            tileWidth = tileWidth, tileHeight = tileHeight,
            tiles = {},
            name = os.date(),
            activeTile = nil,
            scoreBoard = scoreBoard,
            effectsLayer = effectsLayer,
        }

        print(string.format('tileWidth %d, tileHeight %d', tileWidth, tileHeight))



        local container = display.newGroup()
        container.x = display.contentCenterX
        container.y = display.contentCenterY
        local containerBackground = display.newRect( container, 0, 0,
            containerWidth, containerHeight)
        containerBackground:setFillColor(0, 0.5, 0)
        local numTiles = numHorizontalTiles*numVerticalTiles

        local tiles = Tiles:new(numHorizontalTiles, numVerticalTiles)

        -- load imagesheet
        local imageSheet = graphics.newImageSheet('icons_sheet.png', icons_sheet)

        o.imageSheet = imageSheet
        o.container = container
        o.containerBackground = containerBackground
        o.tiles = tiles

        setmetatable(o, self)
        self.__index = self



        for tileNum = 0, (numTiles -1) do
            local tileColumn = tileNum % numHorizontalTiles
            local tileRow = math.floor(tileNum / numVerticalTiles)
            -- NOTE using #icons_sheet.frames here is a bit iffy, but let it go for now
            -- should probably do lOgIc here to make sure the boar doesn't start with pre-completed rows/cols
            local tileType = math.random(1, #icons_sheet.frames)
            local tile = o:createTile(tileType, tileColumn, tileRow)
            tiles:setTileAtColRow(tileColumn, tileRow, tile)
        end

        local drawGrid = false
        if drawGrid then
            local grid = display.newGroup()
            local line
            for y = -containerHeight/2, containerHeight/2, tileHeight+tileMarginX do
                line = display.newLine(grid,
                    -containerWidth/2,y,
                    containerWidth/2,y)
                line:setStrokeColor(1,1,0,1)

                line = display.newLine(grid,
                    y,-containerHeight/2,
                    y,containerHeight/2)
                line:setStrokeColor(1,1,0,1)
            end
            container:insert(grid)
        end

        print(utils.dumpContentBounds(container.contentBounds))
        print(string.format('calculated: tileWidth = %f, tileHeight = %f',
            tileWidth, tileHeight))



        return o
    end,

    tileColRowFromLocalPoint = function (self, lp)
        local col = math.floor(lp.x / (self.tileWidth + self.tileMarginX))
        local row = math.floor(lp.y / (self.tileHeight + self.tileMarginY))
        return col, row
    end,

    tileByLocalPoint = function (self, lp)
        local col,row = self:tileColRowFromLocalPoint(lp)
        return self.tiles:getTileAtColRow(col, row)
    end,

    touch = function(self, event)
        local lp = {}
        local leftBound = self.container.x - self.containerWidth/2
        local topBound = self.container.y - self.containerHeight/2
        lp.x = event.x - leftBound
        lp.y = event.y - topBound

        local clampX = ((self.tileWidth+self.tileMarginX)*self.numHorizontalTiles)-1
        local clampY = ((self.tileHeight+self.tileMarginY)*self.numVerticalTiles)-1
        lp.x = utils.clamp(lp.x, 0, clampX)
        lp.y = utils.clamp(lp.y, 0, clampY)

        local xd = event.x - event.xStart
        local yd = event.y - event.yStart
        local MAX_DRAG_X_DISTANCE = self.tileWidth
        local MAX_DRAG_Y_DISTANCE = self.tileHeight

        if ( event.phase == 'began' ) then
            display.getCurrentStage():setFocus(self.container)
            self.activeTile = self:tileByLocalPoint(lp)
            -- need to keep these so that we can snap the tile back into place (since we move the rect)
            self.activeTile:saveRectPos()
            print(string.format('begin drag of tile %s at %d,%d',
                tostring(self.activeTile), self.activeTile.column, self.activeTile.row))

        -- end drag began
        elseif ( event.phase == 'moved' and self.activeTile ~= nil ) then
            local baseX, baseY = self:tilePositionByColRow(self.activeTile.column, self.activeTile.row)

            if(math.abs(xd) > math.abs(yd)) then
                self.activeTile.rect.x = baseX + utils.clamp(xd,-MAX_DRAG_X_DISTANCE, MAX_DRAG_X_DISTANCE)
                self.activeTile.rect.x = utils.clamp(self.activeTile.rect.x, 
                    -self.containerWidth/2+self.tileWidth/2, self.containerWidth/2-self.tileWidth/2)
                self.activeTile.rect.y = baseY
            else
                self.activeTile.rect.x = baseX
                self.activeTile.rect.y = baseY +  utils.clamp(yd, -MAX_DRAG_Y_DISTANCE, MAX_DRAG_Y_DISTANCE)
                self.activeTile.rect.y = utils.clamp(self.activeTile.rect.y,
                -self.containerHeight/2+self.tileWidth/2, self.containerHeight/2-self.tileHeight/2)
            end
            -- set activeTile on top of whatever else
            -- reinserting something that already exists in a container
            -- puts it on top in z-order
            self.container:insert(self.activeTile.rect)
        -- end drag moved
        elseif ( event.phase == 'ended' ) then
            display.getCurrentStage():setFocus(nil)
            local baseX, baseY = self:tilePositionByColRow(self.activeTile.column, self.activeTile.row)
            print(string.format('end drag of tile %s', tostring(self.activeTile)))
            print(string.format('xd = %d, yd = %d', xd, yd))

            local targetTile
            local distanceMoved = math.max(math.abs(xd), math.abs(yd))
            local activeTileIdx = self:getTileIndexByColRow(self.activeTile.column, self.activeTile.row)

            -- need to move at least half a tile.
            -- NOTE FIXME assuming tiles are square shaped here, so can use just width to determine 'half'
            if (distanceMoved > self.tileWidth / 2) then
                self.scoreBoard:setMoves(self.scoreBoard:getMoves() + 1)
                self.scoreBoard:update()

                if (math.abs(xd) > math.abs(yd)) then
                    -- horizontal direction
                    if (xd > 0) then
                        targetTile = self.tiles:rightOf(self.activeTile)
                    else
                        targetTile = self.tiles:leftOf(self.activeTile)
                    end
                else
                    -- vertical direction
                    if (yd > 0) then
                        targetTile = self.tiles:below(self.activeTile)
                    else
                        targetTile = self.tiles:above(self.activeTile)
                    end
                end
            end

            if targetTile == nil then 
                -- restore dragged tile to it's 'base' location
                self.activeTile:restoreRectPos()
                self.activeTile = nil
                return
            end

            print(string.format('activeTile before restoreRectPos  %s', tostring(self.activeTile)))
            -- restore dragged tile to it's 'base' location
            self.activeTile:restoreRectPos()
            print(string.format('activeTile after restoreRectPos %s', tostring(self.activeTile)))

            -- exchange active tile and target tile
            self.tiles:swapTiles(self.activeTile, targetTile)
            print(string.format('activeTile after swap %s', tostring(self.activeTile)))
            self.activeTile = nil


            local tilesToProcess = {}
            local col
            local row
            local pcl -- potential chain length
            local MINIMUM_TILE_CHAIN_LENGTH = 3

            row = 0
            repeat
                col = 1
                pcl = 1
                repeat
                    local t = self.tiles:getTileAtColRow(col, row)
                    local pt = self.tiles:getTileAtColRow(col-1, row)
                    if (t.tileType == pt.tileType) then
                        pcl = pcl + 1
                    else
                        if (pcl >= MINIMUM_TILE_CHAIN_LENGTH) then 
                            tilesToProcess = utils.conj(tilesToProcess,self.tiles:getColSlice(row, col-pcl, col))
                        end
                        pcl = 1
                    end
                col = col + 1
                until col == self.numHorizontalTiles
                if (pcl >= MINIMUM_TILE_CHAIN_LENGTH) then
                    tilesToProcess = utils.conj(tilesToProcess,self.tiles:getColSlice(row, col-pcl, col))
                end
            row = row + 1
            until row == self.numVerticalTiles

            col = 0
            repeat
                row = 1
                pcl = 1
                repeat
                    --print(string.format('SCAN %d %d %d', col, row, pcl))
                    local t = self.tiles:getTileAtColRow(col, row)
                    local pt = self.tiles:getTileAtColRow(col, row-1)
                    if (t.tileType == pt.tileType) then
                        pcl = pcl + 1
                    else
                        if (pcl >= MINIMUM_TILE_CHAIN_LENGTH) then 
                            tilesToProcess = utils.conj(tilesToProcess,self.tiles:getRowSlice(col, row-pcl, row))
                        end
                        pcl = 1
                    end
                row = row + 1
                until row == self.numVerticalTiles
                if (pcl >= MINIMUM_TILE_CHAIN_LENGTH) then
                    tilesToProcess = utils.conj(tilesToProcess,self.tiles:getRowSlice(col, row-pcl, row))
                end

            col = col + 1
            until col == self.numHorizontalTiles




            --local tilesToProcess = utils.scanTilesForMatches(self.tiles, self.numHorizontalTiles, self.numVerticalTiles)

            local scoreMultiplier = 1
            local streak = 0
            for tile,_ in pairs(tilesToProcess) do
                --print(string.format('blowing up tile %s', tostring(tile)))
                streak = streak + 1
                if streak < 4 then
                    scoreMultiplier = 1
                else
                    scoreMultiplier = scoreMultiplier + 1
                end
                local scoreForThisTile = 10 * streak
                self.scoreBoard:setScore(self.scoreBoard:getScore() + scoreForThisTile * scoreMultiplier)
                self.scoreBoard:update()
                local outerSelf = self
                transition.to(tile.rect, {xScale=3, yScale=5, time=200, transition=easing.continuousLoop, iterations=1, 
                onComplete = function(_)
                    print(string.format('now removing %s', tostring(tile)))
                    local tileRow = tile.row
                    local tileColumn = tile.column
                    self.tiles:removeTile(tile)
                    self.tiles:setTileAtColRow(tileColumn, tileRow, self:createTile(math.random(1,10), tileColumn, tileRow))
                end})

            end
        end -- end drag ended
    end,

    getTileIndexByColRow = function(self, col, row)
        return row * self.numHorizontalTiles + col
    end,

    tilePositionByColRow = function(self, col, row)
            -- the container coordinates are such that 0,0 is in the middle
            -- so the first part, -(self.containerWidth/2) is needed to
            -- offset the position in such a way that x = 0 ends up on the
            -- left edge of the container. the same goes for the -(self.containerHeight/2)
            local tileX = math.floor(-(self.containerWidth/2) +
                (self.tileWidth/2+self.tileMarginX/2) + (col * (self.tileWidth+self.tileMarginX)))
            local tileY = math.floor(-(self.containerHeight/2) +
                (self.tileHeight/2+self.tileMarginY/2) + (row * (self.tileHeight+self.tileMarginY)))
            return tileX, tileY
    end,
}

ScoreBoard = {
    new = function(self, initialScore, initialMoves)
        local container = display.newGroup()
        local containerBackground = display.newRect( container, 0, 0,
            100, 50)
        containerBackground:setFillColor(0, 0.5, 0)

        container.x = 20
        container.y = 50

        local scoreText = display.newText({
            parent=container,
            text=string.format('score: %d\nmoves: %d', initialScore, initialMoves)
        })

        local o = {
            score = initialScore,
            moves = initialMoves,
            container = container,
            containerBackground = containerBackground,
            scoreText = scoreText,
        }
        setmetatable(o, self)
        self.__index = self
        return o
    end,


    setMoves = function(self)
        self.moves = self.moves + 1
    end,

    getMoves = function(self)
        return self.moves
    end,

    setScore = function(self, newScore)
        self.score = newScore
    end,

    getScore = function(self)
        return self.score
    end,

    update = function(self)
        self.scoreText.text = string.format('score: %d\nmoves: %d', self.score, self.moves)
    end,
}

EffectLayer = {
    new = function(self, width, height)
        local container = display.newGroup()

        --local containerBackground = display.newRect( container, 0,0,width, height)
        --containerBackground:setFillColor(1,1,0,0.1)
        container.x = display.contentCenterX
        container.y = display.contentCenterY

        local o = {
            height = height,
            width = width,
            container = container,
            --containerBackground = containerBackground,
        }

        setmetatable(o, self)
        self.__index = self
        return o
    end,

    spawnInfoText = function(self, text, x, y) 

        print('spawnInfoText', text, x, y)
        local fit = display.newText({
            parent=self.container,
            text = text,font='MarkerFelt-Wide'
        })
        fit:setFillColor(0,1,0,1)
        fit.x = x
        fit.y = y
        transition.to(fit, {
            alpha=-1, y=-2000, time=500,  delta=true,
            xScale=50,
            transition=easing.inExpo,
            onComplete=self._removeFloatingInfoTextAfterTransition
        })
    end,
    _removeFloatingInfoTextAfterTransition = function(fit)
        display.remove(fit)
    end,
}

SimplifiedTile = {
    removeSelf = function(self)
        print(string.format('Tile(%s):removeSelf()',
            tostring(self)))
        display.remove(self.rect)
    end,
    __tostring = function(self)
        --return string.format('simplified tile type %d col %d row %d rect.x = %d, rect.y = %d',
        --self.tileType, self.column, self.row, self.rect.x, self.rect.y)
        return string.format('tile: type %d col %d row %d rect %s %s rx = %d ry = %d',
            self.tileType, self.column, self.row,
            tostring(self.rect),
            tostring(self.rect.fill),
            self.rect.x, self.rect.y
        )

    end,

    saveRectPos = function(self)
        self._saved_rect_pos_x = self.rect.x
        self._saved_rect_pos_y = self.rect.y
    end,

    restoreRectPos = function(self)
        self.rect.x = self._saved_rect_pos_x
        self.rect.y = self._saved_rect_pos_y
    end,

    new = function(self, tileType, rect, column, row)
        local tile = {
            tileType = tileType, rect = rect,
            column = column, row = row,
        }
        setmetatable(tile, self)
        self.__index = self
        return tile
    end,
}

Tiles = {
    swapTiles= function(self, tileA, tileB)
        local tempTile = self:getTileAtColRow(tileA.column, tileA.row)
        self:setTileAtColRow(tileA.column, tileA.row, tileB)
        self:setTileAtColRow(tileB.column, tileB.row, tempTile)
        local rx = tileA.rect.x
        local ry = tileA.rect.y
        tileA.rect.x = tileB.rect.x
        tileA.rect.y = tileB.rect.y
        tileB.rect.x = rx
        tileB.rect.y = ry
        local tc = tileA.column
        local tr = tileA.row
        tileA.column = tileB.column
        tileA.row = tileB.row
        tileB.column = tc
        tileB.row = tr
    end,

    tileCanMoveDown = function(self, tile)
        if tile.row < (self.numVerticalTiles -1) and self:below(tile) == nil then return true else return false end
    end,
    removeTile = function(self, tile)
        print(string.format('Tiles:removeTile(%s)',
            tostring(tile)))
        self:setTileAtColRow(tile.column, tile.row, nil)
        tile:removeSelf()
    end,


    getIndexForColRow = function(self, col, row) return row * self.numHorizontalTiles + col end,
    
    setTileAtIndex = function(self, index, tile)
        if (index < 0 or index > self.numVerticalTiles * self.numHorizontalTiles) then return end
        self._storage[index] = tile
        --self[index] = tile
    end,

    getTileAtIndex = function(self, index)
        if (index < 0 or index > self.numVerticalTiles * self.numHorizontalTiles) then return end
        return self._storage[index]
        --return self[index]
    end,


    setTileAtColRow = function(self, col, row, tile)
        if (col < 0 or col >= self.numHorizontalTiles or row < 0 or row >= self.numVerticalTiles) then return nil end
        self:setTileAtIndex(self:getIndexForColRow(col,row), tile)
    end,


    getTileAtColRow = function(self, col, row)
        if (col < 0 or col >= self.numHorizontalTiles or row < 0 or row >= self.numVerticalTiles) then return nil end
        return self:getTileAtIndex(self:getIndexForColRow(col, row))
    end,

    getColSlice = function(self, row, start, length)
        local colSlice = {}
        for col = start,length-1 do
            --colSlice[#colSlice+1] = self:getTileAtColRow(col, row)
            --colSlice[#colSlice+1] = string.format('%d%d',col,row)
            local t = self:getTileAtColRow(col, row)
            colSlice[t] = 1
        end
        return colSlice
    end,

    getRowSlice = function(self, col, start, length)
        local rowSlice = {}
        for row = start,length-1 do
            --rowSlice[#rowSlice+1] = self:getTileAtColRow(col, row)
            --rowSlice[#rowSlice+1] = string.format('%d%d',col,row)
            local t = self:getTileAtColRow(col, row)
            rowSlice[t] = 1
        end
        return rowSlice
    end,

    getColumn = function(self, col)
        local column = {}
        for i=0,self.numVerticalTiles-1 do
            column[i] = self:getTileAtColRow(col, i)
        end
        return column
    end,

    leftOf = function(self, tile) return self:getTileAtColRow(tile.column-1, tile.row) end,
    rightOf = function(self, tile) return self:getTileAtColRow(tile.column+1, tile.row) end,
    above = function(self, tile) return self:getTileAtColRow(tile.column, tile.row-1) end,
    below = function(self, tile) return self:getTileAtColRow(tile.column, tile.row+1) end,

    new = function(self, numHorizontalTiles, numVerticalTiles)
        local o = {
            numHorizontalTiles = numHorizontalTiles,
            numVerticalTiles = numVerticalTiles,
            _storage = {},
        }

        setmetatable(o, self)
        self.__index = self
        return o
    end,
}


local function mainMenuButtonEvent(event)
    if (event.phase == 'ended' ) then
        print('going back to main menu')
        composer.gotoScene('mainMenu')
    end
end

local function durpButtonEvent(event)
    if (event.phase == 'ended' ) then
        print('the goat enterth')
    end
end
function scene:create(event)
    local scoreBoard = ScoreBoard:new(0,0)
    local effectsLayer = EffectLayer:new(100,100)
    local params = event.params

    local tileContainer = TC:new(
        params.numHorizontalTiles, params.numVerticalTiles,
        params.containerWidth, params.containerHeight,
        params.tileMarginX, params.tileMarginY, 
        scoreBoard, effectsLayer
    )
    tileContainer.container:addEventListener('tap', tileContainer)
    tileContainer.container:addEventListener('touch', tileContainer)


    --Runtime:addEventListener('tap', tileContainer)

    local mainMenuButton = widget.newButton({
        x = 10, y = 200,
        id = 'btnMainMenuButton',
        label = 'Return to\nmain menu',
        labelAlign = 'left', 
        onEvent = mainMenuButtonEvent,
        shape = 'roundedRect', width=100
    })

    self.view:insert(scoreBoard.container)
    self.view:insert(mainMenuButton)
    self.view:insert(tileContainer.container)
    self.view:insert(effectsLayer.container)
    print('scene:create')
end

function scene:hide(event)
    if (event.phase == 'did') then
        composer.removeScene('tileGame')
    end
end

scene:addEventListener('create', scene)
scene:addEventListener('hide', scene)
return scene

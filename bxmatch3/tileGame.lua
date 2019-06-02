local composer = require('composer')
local widget = require('widget')

local utils = require('utils')
local icons_sheet = require('icons_sheet')

local scene = composer.newScene()


local TC = {

    __tostring = function(self)
        return string.format('TC: name = %s', self.name)
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
        local containerBackground = display.newRect( container, 0, 0,
            containerWidth, containerHeight)
        containerBackground:setFillColor(0, 0.5, 0)
        local numTiles = numHorizontalTiles*numVerticalTiles

        local tiles = Tiles:new(numHorizontalTiles, numVerticalTiles)

        local tileMetaTable = {
            __tostring = function(self)
                return string.format('tile #%d column %d row %d type %d',
                self.tileNum, self.column, self.row, self.tileType)
            end,
        }

        -- load imagesheet
        local imageSheet = graphics.newImageSheet('icons_sheet.png', icons_sheet)
        o.imageSheet = imageSheet



        for tileNum = 0, (numTiles -1) do
            local tileColumn = tileNum % numHorizontalTiles
            local tileRow = math.floor(tileNum / numVerticalTiles)

            local tileX = math.floor(-(containerWidth/2) + (tileWidth/2+tileMarginX/2) + (tileColumn * (tileWidth+tileMarginX)))
            local tileY = math.floor(-(containerHeight/2) + (tileHeight/2+tileMarginY/2) + (tileRow * (tileHeight+tileMarginY)))

            --local rect = display.newRoundedRect( container, tileX,tileY, tileWidth, tileHeight, tileRounding)
            local tileType = math.random(1, #icons_sheet.frames)
            local rect = display.newImageRect(container, imageSheet, tileType, tileWidth, tileHeight)
            rect.x = tileX
            rect.y = tileY

            rect.rotation = math.random(1,360)
            local tile = {
                tileNum = tileNum,
                baseX = tileX, baseY = tileY,
                currentX = tileX, currentY = tileY,
                rect = rect, color = color,
                row = tileRow, column = tileColumn,
                tileType = tileType,
            }
            setmetatable(tile, tileMetaTable)
            tiles[tileNum] = tile
        end
        o.container = container
        o.containerBackground = containerBackground
        o.tiles = tiles

        setmetatable(o, self)
        self.__index = self
        return o
    end,

    tileRowColumnFromLocalPoint = function (self, lp)
        return {
            tileColumn = math.floor(lp.x / (self.tileWidth + self.tileMarginX)),
            tileRow = math.floor(lp.y / (self.tileHeight + self.tileMarginY))
        }
    end,

    tileByLocalPoint = function (self, lp)
        local trc = self:tileRowColumnFromLocalPoint(lp)
        local tileIndex = trc.tileRow * self.numHorizontalTiles + trc.tileColumn
        return self.tiles[tileIndex]
    end,

    touch = function(self, event)
        local lp = utils.absPointToContentBounds(event.x, event.y, 
            self.container.contentBounds)

        local xd = event.x - event.xStart
        local yd = event.y - event.yStart
        local MAX_DRAG_X_DISTANCE = self.tileWidth
        local MAX_DRAG_Y_DISTANCE = self.tileHeight

        if ( event.phase == 'began' ) then
            local tile = self:tileByLocalPoint(lp)
            display.getCurrentStage():setFocus(self.container)
            print(string.format('begin drag of tile %s', tostring(tile)))
            self.activeTile = tile
        elseif ( event.phase == 'moved' and self.activeTile ~= nil ) then
            if(math.abs(xd) > math.abs(yd)) then
                self.activeTile.rect.x = self.activeTile.baseX + utils.clamp(xd,-MAX_DRAG_X_DISTANCE, MAX_DRAG_X_DISTANCE)
                self.activeTile.rect.x = utils.clamp(self.activeTile.rect.x, 
                    -self.containerWidth/2+self.tileWidth/2, self.containerWidth/2-self.tileWidth/2)
                self.activeTile.rect.y = self.activeTile.baseY
            else
                self.activeTile.rect.x = self.activeTile.baseX
                self.activeTile.rect.y = self.activeTile.baseY +  utils.clamp(yd, -MAX_DRAG_Y_DISTANCE, MAX_DRAG_Y_DISTANCE)
                self.activeTile.rect.y = utils.clamp(self.activeTile.rect.y,
                -self.containerHeight/2+self.tileWidth/2, self.containerHeight/2-self.tileHeight/2)
            end
            -- set activeTile on top of whatever else
            self.container:insert(self.activeTile.rect)

        elseif ( event.phase == 'ended' ) then
            display.getCurrentStage():setFocus(nil)
            print(string.format('end drag of tile %s', tostring(self.activeTile)))
            print(string.format('xd = %d, yd = %d', xd, yd))

            local targetTile
            local distanceMoved = math.max(math.abs(xd), math.abs(yd))
            
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
                -- reset active tile
                self.activeTile.rect.x = self.activeTile.baseX
                self.activeTile.rect.y = self.activeTile.baseY
                self.activeTile = nil
                return
            end

            -- switcharoo!
            -- TODO implement swapTiles(a,b)
            local temp = targetTile.tileType

            targetTile.tileType = self.activeTile.tileType
            self.activeTile.tileType = temp

            self.activeTile.rect.fill = { type = 'image', sheet = self.imageSheet, frame = self.activeTile.tileType }
            targetTile.rect.fill = { type = 'image', sheet = self.imageSheet, frame = targetTile.tileType }

            --targetTile.rect.rotation = self.activeTile.rect.rotation
            --self.activeTile.rect.rotation = temp.rect.rotation


            -- reset active tile
            self.activeTile.rect.x = self.activeTile.baseX
            self.activeTile.rect.y = self.activeTile.baseY
            self.activeTile = nil

            local tilesToProcess = utils.scanTilesForMatches(self.tiles, self.numHorizontalTiles, self.numVerticalTiles)

            local scoreMultiplier = 1
            local streak = 0
            for k,tile in pairs(tilesToProcess) do
                streak = streak + 1
                if streak < 4 then
                    scoreMultiplier = 1
                else
                    scoreMultiplier = scoreMultiplier + 1
                end
                local scoreForThisTile = 10 * streak
                --print(string.format('processing tile %s', tostring(tile)))
                -- TODO increase score depending on tileType
                -- and length of chain? or set bonus multiplier?
                self.scoreBoard:setScore(self.scoreBoard:getScore() + scoreForThisTile * scoreMultiplier)
                self.scoreBoard:update()
                tile.tileType = math.random(1, #icons_sheet.frames)
                tile.rect.fill = { type = 'image', sheet = self.imageSheet, frame = tile.tileType}
                transition.to(tile.rect, {xScale=2, yScale=2.5, time=200, transition=easing.continuousLoop, iterations=1})
                self.effectsLayer:spawnInfoText(string.format('%d!', scoreForThisTile), tile.baseX, tile.baseY)
            end
        end

    end,
    tap = function(self, event)
        local lp = utils.absPointToContentBounds(event.x, event.y, 
            self.container.contentBounds)
        local tile = self:tileByLocalPoint(lp)
        local trc = self:tileRowColumnFromLocalPoint(lp)
        --print('trc',  trc.tileColumn,trc.tileRow)

    --tileRowColumnFromLocalPoint = function (self, lp)
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

Tiles = {
    new = function(self, numHorizontalTiles, numVerticalTiles)
        local o = {
            numHorizontalTiles = numHorizontalTiles,
            numVerticalTiles = numVerticalTiles,

            tileAtColRow = function(self, col, row)
                if (col < 0 or col >= self.numHorizontalTiles or row < 0 or row >= self.numVerticalTiles) then return nil end
                return self[row*self.numHorizontalTiles+col]
            end,

            leftOf = function(self, tile) return self:tileAtColRow(tile.column-1, tile.row) end,
            rightOf = function(self, tile) return self:tileAtColRow(tile.column+1, tile.row) end,
            above = function(self, tile) return self:tileAtColRow(tile.column, tile.row-1) end,
            below = function(self, tile) return self:tileAtColRow(tile.column, tile.row+1) end,

            swapTiles = function(self, tileA, tileB)
                local tempTile = self[tileA.tileNum]
                self[tileA.tileNum] = self[tileB.tileNum]
                self[tileB.tileNum] = tempTile
            end,
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

    tileContainer.container.x = display.contentCenterX
    tileContainer.container.y = display.contentCenterY

    --Runtime:addEventListener('tap', tileContainer)

    local mainMenuButton = widget.newButton({
        x = 50, y = 200,
        id = 'btnMainMenuButton',
        label = 'Return to\nmain menu',
        labelAlign = 'left', 
        onEvent = mainMenuButtonEvent,
    })

    self.view:insert(tileContainer.container)
    self.view:insert(scoreBoard.container)
    self.view:insert(effectsLayer.container)
    self.view:insert(mainMenuButton)
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

t = {
dumpTile = function(tile)
    local s = 'tile:\n'
    for k, v in pairs(tile) do
        s = s .. string.format('%s = %s\n', k, tostring(v))
    end
    return s
end,

dumpContentBounds = function(cb)
    return string.format('xMin: %d yMin: %d xMax: %d yMax: %d', 
        cb.xMin, cb.yMin, cb.xMax, cb.yMax)
end,

tileDistance = function(tile1, tile2)
    local xd = math.abs(tile1.column - tile2.column)
    local yd = math.abs(tile1.row - tile2.row)
    return math.floor(1)
end,

absPointToContentBounds = function(px, py, cb)
    local lp = {
        x = math.floor(px - cb.xMin),
        y = math.floor(py - cb.yMin),
    }
    return lp
end,
clamp = function(v, min, max)
    return (v <= min) and min or ((v > min and v < max ) and v) or max
end,

scanTilesForMatches = function(tiles, numHorizontalTiles, numVerticalTiles)
    local tileAt = function(col, row)
        if (col < 0 or col >= numHorizontalTiles or row < 0 or row >= numVerticalTiles) then return nil end
        return tiles[row*numHorizontalTiles+col]
    end

    local leftOf = function(tile) return tileAt(tile.column-1, tile.row) end
    local rightOf = function(tile) return tileAt(tile.column+1, tile.row)  end
    local above = function(tile)  return tileAt(tile.column, tile.row - 1) end 
    local below = function(tile) return tileAt(tile.column, tile.row + 1) end

    local tilesToProcess = {}
    local currentTile = nil



    local row
    local col
    local potentialTileChainLength
    local potentialTileChain

    row = 0
    repeat
        col = 1
        potentialTileChainLength = 0
        potentialTileChain = {}
        repeat
            local tile = tileAt(col, row)
            prevTile = tileAt(col-1, row)
            if(prevTile.tileType == tile.tileType) then
                if potentialTileChainLength == 0 then
                    potentialTileChainLength = 2
                else
                    potentialTileChainLength = potentialTileChainLength + 1
                end
                potentialTileChain[tile.tileNum] = tile
                potentialTileChain[prevTile.tileNum] = prevTile
            else
                potentialTileChainLength = 0
                potentialTileChain = {}
            end

            if (potentialTileChainLength >= 3) then
                for _, tile in pairs(potentialTileChain) do
                    print('inserting', tile, ' into tilesToProcess')
                    tilesToProcess[tile.tileNum] = tile
                end
            end
            col = col + 1
        until col == numHorizontalTiles
        row = row + 1
    until row == numVerticalTiles


    col = 0
    repeat
        row = 1
        potentialTileChainLength = 0
        potentialTileChain = {}
        repeat
            local tile = tileAt(col, row)
            prevTile = tileAt(col, row-1)
            if(prevTile.tileType == tile.tileType) then
                if potentialTileChainLength == 0 then
                    potentialTileChainLength = 2
                else
                    potentialTileChainLength = potentialTileChainLength + 1
                end
                potentialTileChain[tile.tileNum] = tile
                potentialTileChain[prevTile.tileNum] = prevTile
            else
                potentialTileChainLength = 0
                potentialTileChain = {}
            end

            if (potentialTileChainLength >= 3) then
                for _, tile in pairs(potentialTileChain) do
                    print('inserting', tile, ' into tilesToProcess')
                    tilesToProcess[tile.tileNum] = tile
                end
            end
            row = row + 1
        until row == numVerticalTiles
        col = col + 1
    until col == numHorizontalTiles
    return tilesToProcess
end,
foo = function()
    local row = 0
    local block = {}
    local blockLen = 0

    for col = 1,numHorizontalTiles -1 do
        local currentTile = tileAt(col, row)
        local prevTile = leftOf(currentTile)

        if currentTile.tileType == prevTile.tileType then
            print(string.format('adding\n %s\n %s\nto block', 
                tostring(currentTile), tostring(prevTile)))
            block[currentTile.tileNum] = currentTile
            block[prevTile.tileNum] = prevTile
            if blockLen == 0 then blockLen = 2 else blockLen = blockLen + 1 end
        else
            if blockLen > 2 then
                tilesToProcess[#tilesToProcess + 1] = block
                blockLen = 0
            end
            block = {}
        end
        if blockLen > 2 then
            tilesToProcess[#tilesToProcess + 1] = block
            blockLen = 0
        end

        print(string.format('currentTile = %s', tostring(currentTile)))
    end
    return tilesToProcess

end,
}

return t

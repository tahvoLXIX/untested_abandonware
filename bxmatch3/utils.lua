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

clamp = function(v, min, max)
    return (v <= min) and min or ((v > min and v < max ) and v) or max
end,

scanTilesForMatches = function(tiles, numHorizontalTiles, numVerticalTiles)
    local tileAt = function(col, row)
        if (col < 0 or col >= numHorizontalTiles or row < 0 or row >= numVerticalTiles) then return nil end
        return tiles[row*numHorizontalTiles+col]
    end

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
}

return t

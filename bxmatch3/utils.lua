t = {
conj = function(tableA, tableB)
    local tableC = {}

    if (tableA ~= nil) then
        for k,v in pairs(tableA) do
            tableC[k] = v
        end
    end
    if (tableB ~= nil) then
        for k,v in pairs(tableB) do
            tableC[k] = v
        end
    end
    return tableC
end,

countNils = function(t, len) 
    local nilCount=0
    for n =0,len do
        if t[n] == nil then nilCount = nilCount + 1 end
    end
    return nilCount
end,

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
}

return t

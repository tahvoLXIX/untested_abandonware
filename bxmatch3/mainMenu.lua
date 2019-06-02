local composer = require('composer')
local widget = require('widget')

local defaultGameSettings = {
    numHorizontalTiles = 8,
    numVerticalTiles = 8,
    containerWidth = 280,
    containerHeight = 280,
    tileMarginX = 2,
    tileMarginY = 2,
}



local function conj(a,b)
    local c = {}
    for k,v in pairs(a) do
        c[k] = v
    end
    for k,v in pairs(b) do
        c[k] = v
    end
    return c
end

local mapSizeStepperValue = 6
local function mapSizeStepperPress(event)
    if (event.phase == 'increment') then
        mapSizeStepperValue = mapSizeStepperValue + 1
    elseif (event.phase == 'decrement' ) then
        mapSizeStepperValue = mapSizeStepperValue - 1
    end
    event.target.setLabel(mapSizeStepperValue)
end
local function startCustomGameButtonEvent(event)
    if ( event.phase == 'ended' ) then
        composer.gotoScene('tileGame', {
            params = conj(defaultGameSettings, {numHorizontalTiles = mapSizeStepperValue, numVerticalTiles = mapSizeStepperValue})
        })
    end
end




local scene = composer.newScene()

function scene:create(event)
    print('creating scene')
    local menuItems = display.newGroup()
    menuItems.x = display.contentCenterX
    menuItems.y = display.contentCenterY


    local mapSizeLabel = display.newText({
        parent = menuItems,
        text = '',
        x = 0,
        y = -40,
    })

    local updateLabel = function(newValue)
        mapSizeLabel.text = string.format('Map size: %d', newValue)
    end

    local mapSizeStepper = widget.newStepper({
        x = 0, y =0,
        id = 'mapSizeStepper', initialValue = mapSizeStepperValue,
        minimumValue = 3, maximumValue = 12,
        onPress = mapSizeStepperPress,
    })
    mapSizeStepper.setLabel = updateLabel
    mapSizeStepper.label = mapSizeLabel
    mapSizeStepper.setLabel(mapSizeStepperValue)

    menuItems:insert(mapSizeStepper)
    local startCustomGameButton = widget.newButton({
        x = 0, y = 40,
        id = 'btnStartCustomGameButton',
        label = 'Start game',
        onEvent = startCustomGameButtonEvent,

    })
    menuItems:insert(startCustomGameButton)


    self.view:insert(menuItems)

end

scene:addEventListener('create', scene)
return scene

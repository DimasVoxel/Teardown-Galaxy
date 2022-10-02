function init()
end

function draw()

    UiPush()
        UiColor(0, 0, 0)
        UiAlign("center bottom")
        UiRect(1920,1080)
    UiPop()

    UiPop()
	UiTranslate(UiCenter(), 80)
	UiAlign("center middle")

	--Title
	UiFont("bold.ttf", 48)
	UiText("Performance options")

	--Draw buttons
	UiTranslate(150, 200)
	UiFont("regular.ttf", 26)
	UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
    UiButtonHoverColor(1, 1, 0)
    
    
    UiTranslate(0, 200)
    UiMakeInteractive()
    UiPush()
        
		UiTranslate(-450, 0)
            if UiTextButton("Play in Beauty mode", 280, 0) then
                UiSound("sound/click.ogg")
                StartLevel("", "MOD/main.xml")
		    end
        
        UiTranslate(0, -200)

        
        UiTranslate(300, 200)
		if UiTextButton("Play in Performance mode", 280, 40) then
            UiSound("sound/click.ogg")
			StartLevel("", "MOD/lowspec.xml")
		end

        UiTranslate(0, -200)
        
            
        UiTranslate(0, 300)
        if UiTextButton("Main menu", 0, 0) then
            UiSound("sound/click.ogg")
            Menu()
        end
    UiPop()
end
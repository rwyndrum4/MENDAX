extends RichTextLabel


func _process(delta):
	set_text("Balance: "+str(Global.money))

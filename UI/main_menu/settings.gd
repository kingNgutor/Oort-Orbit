extends CanvasLayer

@onready var settingsPanel: PanelContainer = $CenterContainer/"OverlayLayer (_Settings_Screen_)"/SettingsPanel
@onready var settingsButton: Button = $PanelContainer/VBoxContainer/Button3_settings
@onready var closeSettings: Button = $"OverlayLayer (_Settings_Screen_)"/SettingsPanel/VBoxContainer/"Button (_Close_Settings_)"
@onready var main_menu_ui: CenterContainer = $CenterContainer


func _ready():
	#hide the settings panel initially
	settingsPanel.visible = false
	# Connect the settings button
	settingsButton.pressed.connect(_show_settings)
	
func _show_settings():
	# diable main menu input
	main_menu_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# show the panel (but it's invisible because its scale is 0, etc.)
	
	settingsPanel.visible = true
	settingsPanel.modulate.a = 0.0
	settingsPanel.scale = Vector2(0.8,0.8)
	
	# create a tween and animate
	var tween = create_tween()
	tween.set_parallel(true) # run animations together
	tween.tween_property(settingsPanel, "modulate:a", 1.0,0.3)
	tween.tween_property(settingsPanel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)
	
	pass

func _hide_settings():
	# Animate out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(settingsPanel, "modulate:a", 0.0,0.2)
	tween.tween_property(settingsPanel, "scale", Vector2(0.9,0.9), 0.2).set_ease(Tween.EASE_IN)
	
	#after animation finishes, hide panel and restore input
	tween.finished.connect(_on_settings_hidden)
	pass

func _on_settings_hidden():
	settingsPanel.visible = false
	main_menu_ui.mouse_filter = Control.MOUSE_FILTER_STOP

extends SceneTree
## Hoja con las 78 cartas ampliadas para revisar el arte: godot --headless --path . -s res://tools/cards_sheet.gd -- <carpeta> [desde] [hasta]


func _initialize() -> void:
	var argv := OS.get_cmdline_user_args()
	var out := argv[0] if not argv.is_empty() else "user://cartas"
	var a := int(argv[1]) if argv.size() > 1 else 0
	var b := int(argv[2]) if argv.size() > 2 else Deck.N
	DirAccess.make_dir_recursive_absolute(out)
	var s := 3
	var cols := 8
	var n := b - a
	var rows := ceili(n / float(cols))
	var sheet := Image.create_empty(cols * (Arcana.W + 4) * s, rows * (Arcana.H + 4) * s, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("2a2140"))
	for k in n:
		var im: Image = Deck.image(a + k)
		im.resize(Arcana.W * s, Arcana.H * s, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i((k % cols) * (Arcana.W + 4) * s + 2 * s, (k / cols) * (Arcana.H + 4) * s + 2 * s))
	sheet.save_png(out.path_join("hoja_%d_%d.png" % [a, b]))
	print("hoja guardada")
	quit()

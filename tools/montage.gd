extends SceneTree
## Junta capturas en una hoja: godot --headless --path . -s res://tools/montage.gd -- <carpeta> <prefijo> <salida> [columnas]


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var dir: String = a[0]
	var files: Array = Array(DirAccess.get_files_at(dir)).filter(func(f): return f.begins_with(a[1]) and f.ends_with(".png"))
	files.sort()
	var cols := int(a[3]) if a.size() > 3 else 4
	var w := 320
	var h := 180
	var rows := ceili(files.size() / float(cols))
	var sheet := Image.create_empty(cols * w, rows * h, false, Image.FORMAT_RGBA8)
	for i in files.size():
		var im := Image.load_from_file(dir.path_join(files[i]))
		im.convert(Image.FORMAT_RGBA8)
		im.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	sheet.save_png(a[2])
	print("hoja ", files.size())
	quit()

extends SceneTree
## Genera el banco de sonidos, mide el tiempo y guarda cada uno en WAV para escucharlos:
## godot --headless --path . -s res://tools/sfx_test.gd -- <carpeta>


func _initialize() -> void:
	var argv := OS.get_cmdline_user_args()
	var t0 := Time.get_ticks_msec()
	var s: Node = load("res://scripts/sfx.gd").new()
	s._ready()
	print("sonidos: %d en %d ms" % [s.bank.size(), Time.get_ticks_msec() - t0])
	if not argv.is_empty():
		DirAccess.make_dir_recursive_absolute(argv[0])
		for k in s.bank:
			(s.bank[k] as AudioStreamWAV).save_to_wav(argv[0].path_join(k + ".wav"))
	s.free()
	quit()

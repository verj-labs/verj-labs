extends SceneTree
## A tiny test runner (no add-ons): every res://tests/test_*.gd extends TestCase, and every
## method named test_* is a test. Run through ../test.sh.
##   godot --headless --path godot -s ../tools/run_tests.gd -- [name filter]

func _initialize() -> void:
	var filter := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		filter = args[0]
	var passed := 0
	var failed := 0
	var dir := DirAccess.open("res://tests")
	var files := Array(dir.get_files()).filter(func(f: String) -> bool: return f.begins_with("test_") and f.ends_with(".gd"))
	files.sort()
	for file in files:
		var script: GDScript = load("res://tests/" + file)
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_") or (filter != "" and not (file + "::" + name).contains(filter)):
				continue
			var case: TestCase = script.new()
			case.call(name)
			if case.failures.is_empty():
				passed += 1
			else:
				failed += 1
				print("FAIL %s::%s" % [file, name])
				for line in case.failures:
					print("    " + line)
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

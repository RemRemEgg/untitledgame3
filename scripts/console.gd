extends CanvasLayer

@onready var lines: RichTextLabel
@onready var input: LineEdit

var active: bool = true
var history: Array[String]
var h_index := -1
var load_status: int = 0
var load_call: Callable

func _ready() -> void:
	lines = $margin/vbox/lines as RichTextLabel
	input = $margin/vbox/input as LineEdit
	history = []
	input.text_submitted.connect(submit)

func _process(_delta: float) -> void:
	if load_status % 3 == 1:
		load_call.call_deferred()
		load_status += 1
	if load_status % 3 == 2: return
	match load_status:
		0: attempt_load(Global.load_resources, "Loading Global Resources")
		3: attempt_load(Server.load_resources, "Loading Server Resources")
		6: attempt_load(ProcItem.register_all, "Loading Static Items")
		9: attempt_load(self.cleanup, "Loading R.E.M. Core")
		12: attempt_load(func(): get_tree().change_scene_to_file.call_deferred("res://scenes/ui/main_menu.tscn"), "Starting Main Menu...")

func attempt_load(load_step: Callable, load_id: String) -> void:
	Console.print(load_id)
	load_call = load_step
	load_status += 1

func cleanup() -> void:
	Console.print("Finalizing")
	load_status += 1

func _input(event: InputEvent) -> void:
	if event is InputEventKey && event.is_pressed():
		if event.is_action("dbg_console") || (event.is_action("esc") && active): call_deferred("toggle")
		if event.keycode == KEY_UP:
			h_index = clamp(h_index +1, -1, history.size() -1)
			input.clear()
			if h_index != -1: input.insert_text_at_caret(history[h_index])
		if event.keycode == KEY_DOWN:
			h_index = clamp(h_index -1, -1, history.size() -1)
			input.clear()
			if h_index != -1: input.insert_text_at_caret(history[h_index])

func toggle() -> void:
	if load_status != -1 && active == true: return
	active = !active
	visible = active
	set_process(active)
	if active:
		input.grab_focus()
		input.text = ""

func submit(text: String) -> void:
	input.text = ""
	parse_command(text)
	h_index = -1
	if (history.size() > 0 && history[0] != text) || history.size() == 0: history.push_front(text)

func print(text: String) -> void:
	print_rich("[Console] " + text.replace("\n", "\n          "))
	lines.text += ("\n" if lines.text != "" else "") + text

func print_err(text: String) -> void:
	print_rich("[color=red][Error] " + text.replace("\n", "\n[Error] ") + "[/color]")
	push_error("[Error] " + text.replace("\n", "\n[Error] "))
	lines.text += ("\n" if lines.text != "" else "") + "[color=red]" + text + "[/color]"

func parse_command(text: String) -> void:
	var commands := split_in_same_level(text, ";")
	self.print("< " + text)
	for command in commands:
		var args := split_in_same_level(command, " ")
		while args.size() > 0 && args[0] == "": args.pop_front()
		run_command(args)

func run_command(args: Array[String]) -> void:
	match args[0]:
		"clear": lines.clear()
		"say": self.print(" ".join(args.slice(1)))
		"fps":
			if args.size() < 2: return self.print(" > Current FPS target is %s (%s mspt), running at %s" % ["uncapped" if Engine.max_fps == 0 else str(Engine.max_fps),round(1000.0/Engine.max_fps),Engine.get_frames_per_second()])
			Engine.max_fps = int(args[1])
			self.print(" > FPS target set to %s (%s mspt), was running at %s" % [Engine.max_fps,round(1000.0/Engine.max_fps),Engine.get_frames_per_second()])
		"ai":
			if args.size() < 2: return print_err(" > Not enough arguments for command")
			match args[1]:
				"tree": self.print(" > %s" % ProcEnt.TEMP_CONST_PROCAI.to_string())
				"rand":
					if args.size() < 3: return self.print(" > ProcEnt randomization is %s" % ProcEnt.RAND)
					ProcEnt.RAND = args[2].to_lower() == "true"
					self.print(" > ProcEnt randomization set to %s" % ProcEnt.RAND)
				"seed":
					if args.size() < 3: return print_err(" > Not enough arguments for command")
					seed(args[2].hash())
					ProcEnt.TEMP_CONST_PROCAI = ProcEnt.generate_new()
					self.print(" > %s" % ProcEnt.TEMP_CONST_PROCAI.to_string())
				"root":
					if args.size() < 3: return print_err(" > Not enough arguments for command")
					match args[2]:
						"type":
							if args.size() < 4: return print_err(" > Not enough arguments for command")
							ProcEnt.TEMP_CONST_PROCAI.move_type = int(args[3])
				"type":
					if args.size() < 3: return print_err(" > Not enough arguments for command")
					Global.TEMP.FORCE_AI_TYPE = int(args[2])
					self.print(" > Force AI type set to %s" % ProcEnt.move_names[Global.TEMP.FORCE_AI_TYPE])
				_: print_err(" > Unknown Command '%s'" % args[1])
		"eval":
			var expr: Expression = Expression.new()
			expr.parse(" ".join(args.slice(1)), ["Global", "Server", "root", "Projectile", "Entity", "Item", "ProcProj", "ProcEnt", "ProcItem", "GMP"])
			var output = expr.execute([Global, Server, get_tree().root, Projectile, Entity, Item, ProcProj, ProcEnt, ProcItem, Global.MAIN_PLAYER], self)
			self.print(" > " + (str(output) if output != null else "<No output>"))
		"timescale":
			if args.size() < 2: return print_err(" > Not enough arguments for command")
			Engine.time_scale = float(args[1])
			self.print(" > Timescale set to %s" % Engine.time_scale)
		"terrain":
			if args.size() < 2: return self.print(" > Terrain ID: %s" % Server.terrain_id)
			if !Server.is_host: return print_err(" > Cannot change terrain as client") 
			self.print(" > Changing Terrain %s -> %s " % [Server.terrain_id, int(args[1])])
			Global.WORLD.change_terrain(int(args[1]), true)
		"respawn":
			if !Global.MAIN_PLAYER: return print_err(" > No player to respawn")
			Global.MAIN_PLAYER.respawn.rpc()
			self.print("> Respawned")
		_: print_err(" > Unknown Command '%s'" % args[0])

func split_in_same_level(text: String, blade: String) -> Array[String]:
	if !text.contains(blade) || text.is_empty(): return [text]
	var ret: Array[String] = []
	var pos: int = 0
	var dist: int = 0
	var stack: Array[String] = []
	while true:
		if pos + dist >= text.length():
			ret.append(text.substr(pos))
			return ret
		var chari: String = text[pos + dist]
		if chari == "\\":
			dist += 2
			continue
		if !stack.is_empty(): if stack[-1] == chari: 
			stack.pop_back()
			dist += 1
			continue
		if stack.is_empty() && text.substr(pos + dist).begins_with(blade):
			ret.append(text.substr(pos, dist))
			pos += dist + 1
			dist = 0
		else:
			match chari:
				"[": stack.append("]")
				"{": stack.append("}")
				"(": stack.append(")")
				"\"": stack.append("\"")
			dist += 1
	# hopefully this code never runs
	print_err("[SISL-NACPRAV]\tinput: '%s'" % text)
	return ["NACPRAV"]

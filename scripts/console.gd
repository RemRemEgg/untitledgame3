extends CanvasLayer

@onready var lines: RichTextLabel = $margin/vbox/lines as RichTextLabel
@onready var input: LineEdit = $margin/vbox/input as LineEdit

var active: bool = true
var history: Array[String] = []
var h_index = -1

func _input(event: InputEvent) -> void:
	if event is InputEventKey && event.is_pressed():
		if event.is_action("dbg_console") || (event.is_action("esc") && active): call_deferred("toggle")
		if event.keycode == KEY_UP:
			h_index = clamp(h_index +1, -1, history.size() -1)
			input.text = ""
			if h_index != -1: input.insert_text_at_caret(history[h_index])
		if event.keycode == KEY_DOWN:
			h_index = clamp(h_index -1, -1, history.size() -1)
			input.text = ""
			if h_index != -1: input.insert_text_at_caret(history[h_index])

func toggle() -> void:
	active = !active
	visible = active
	set_process(active)
	if active:
		input.grab_focus()
		input.text = ""

func clear() -> void: lines.text = ""

func _ready() -> void:
	toggle()
	input.text_submitted.connect(submit)

func submit(text: String) -> void:
	input.text = ""
	parse_command(text)
	h_index = -1
	if (history.size() > 0 && history[0] != text) || history.size() == 0: history.push_front(text)

func print(text: String) -> void:
	print_rich("[Console] " + text.replace("\n", "\n[Console] "))
	lines.text += ("\n" if lines.text != "" else "") + text

func print_err(text: String) -> void:
	print_rich("[Error] " + text.replace("\n", "\n[Error] "))
	lines.text += ("\n" if lines.text != "" else "") + "[color=red]" + text + "[/color]"

func parse_command(text: String) -> void:
	var args: Array[String] = split_in_same_level(text, " ")
	
	match args[0]:
		"clear": clear()
		"say": self.print(" ".join(args.slice(1)))
		"fps":
			if args.size() < 2: return self.print("Current FPS target is %s (%s mspt), running at %s" % [Engine.max_fps,round(1000/Engine.max_fps),Engine.get_frames_per_second()])
			Engine.max_fps = int(args[1])
			self.print("FPS target set to %s (%s mspt), running at %s" % [Engine.max_fps,round(1000/Engine.max_fps),Engine.get_frames_per_second()])
		"ai":
			if args.size() < 2: return print_err("Not enough arguments for command")
			match args[1]:
				"tree": self.print(Entity.TEMP_CONST_PROCAI.to_string())
				"rand":
					if args.size() < 3: return self.print("Entity AI randomization is %s" % Entity.RAND)
					Entity.RAND = args[2].to_lower() == "true"
					self.print("Entity AI randomization set to %s" % Entity.RAND)
				"seed":
					if args.size() < 3: return print_err("Not enough arguments for command")
					seed(args[2].hash())
					Entity.TEMP_CONST_PROCAI = ProcAI.generate_new()
					self.print(Entity.TEMP_CONST_PROCAI.to_string())
				"root":
					if args.size() < 3: return print_err("Not enough arguments for command")
					match args[2]:
						"type":
							if args.size() < 4: return print_err("Not enough arguments for command")
							Entity.TEMP_CONST_PROCAI.move_type = int(args[3])
				"type":
					if args.size() < 3: return print_err("Not enough arguments for command")
					Global.TEMP.FORCE_AI_TYPE = int(args[2])
					self.print("Force AI type set to %s" % ProcAI.move_names[Global.TEMP.FORCE_AI_TYPE])
				_: print_err("Unknown Command '%s'" % args[1])
		"eval":
			var exp: Expression = Expression.new()
			exp.parse(" ".join(args.slice(1)))
			self.print(str(exp.execute()))
		"test":
			self.print("%s" % ItemData.ids.ROCK)
			self.print("%s" % ItemData.lookup(ItemData.ids.ROCK))
			self.print("%s" % ItemData.lookup(2))
		"timescale":
			if args.size() < 2: return print_err("Not enough arguments for command")
			Engine.time_scale = float(args[1])
			self.print("Timescale set to %s" % Engine.time_scale)
		_: print_err("Unknown Command '%s'" % args[0])

func split_in_same_level(text: String, blade: String) -> Array[String]:
	if !text.contains(blade) || text.is_empty(): return [text]
	var ret: Array[String] = []
	var pos: int = 0
	var dist: int = 0
	var stack: Array[String]
	while true:
		if pos + dist >= text.length():
			ret.append(text.substr(pos))
			return ret
		var char: String = text[pos + dist]
		if char == "\\":
			dist += 2
			continue
		if !stack.is_empty(): if stack[-1] == char: 
			stack.pop_back()
			dist += 1
			continue
		if stack.is_empty() && text.substr(pos + dist).begins_with(blade):
			ret.append(text.substr(pos, dist))
			pos += dist + 1
			dist = 0
		else:
			match char:
				"[": stack.append("]")
				"{": stack.append("}")
				"(": stack.append(")")
				"\"": stack.append("\"")
			dist += 1
	print_err("[SISL-NACPRAV]\tinput: '%s'" % text)
	return ["NACPRAV"]

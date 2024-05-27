extends CanvasLayer

@onready var lines: RichTextLabel = $margin/vbox/lines
@onready var input: LineEdit = $margin/vbox/input

var active: bool = false
var history: Array[String] = []
var h_index = -1

func _input(event: InputEvent) -> void:
	if event is InputEventKey && event.is_pressed():
		if event.is_action("dbg_console"): call_deferred("toggle")
		if event.keycode == KEY_UP:
			h_index = clamp(h_index +1, -1, history.size() -1)
			if h_index != -1: input.text = history[h_index]
			else: input.text = ""
		if event.keycode == KEY_DOWN:
			h_index = clamp(h_index -1, -1, history.size() -1)
			if h_index != -1: input.text = history[h_index]
			else: input.text = ""

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
	
	if !args[0].begins_with("/"):
		self.print(text)
		return
	args[0] = args[0].substr(1)
	
	match args[0]:
		"clear": clear()
		"tree":
			Entity.TEMP_CONST_PROCAI = ProcAI.generate_new()
			self.print(Entity.TEMP_CONST_PROCAI.to_string())
		"error": self.print_err("error")
		"sisl": self.print(":".join(args))
		"ai":
			if args.size() < 2: return print_err("Not enough arguments for command")
			match args[1]:
				"tree": self.print(Entity.TEMP_CONST_PROCAI.to_string())
				"rand":
					Entity.TEMP_CONST_PROCAI = ProcAI.generate_new()
					self.print(Entity.TEMP_CONST_PROCAI.to_string())
				"build":
					if args.size() < 3: return print_err("Not enough arguments for command")
					Entity.TEMP_CONST_PROCAI = ProcAI.from_string(args[3])
				_: print_err("Unknown Command '/%s'" % args[0])
		_: print_err("Unknown Command '/%s'" % args[0])

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

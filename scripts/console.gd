extends CanvasLayer

@onready var lines: RichTextLabel = $margin/vbox/lines
@onready var input: LineEdit = $margin/vbox/input

var active: bool = true

func _input(event: InputEvent) -> void: if event is InputEventKey && event.is_action("dbg_console") && event.is_pressed(): call_deferred("toggle")

func toggle() -> void:
	active = !active
	visible = active
	set_process(active)
	if active:
		input.grab_focus()
		input.text = ""

func _ready() -> void:
	toggle()
	input.text_submitted.connect(submit)

func submit(text: String) -> void:
	input.text = ""
	parse_command(text)

func print(text: String) -> void:
	print("[Console] " + text)
	lines.text += ("\n" if lines.text != "" else "") + text

func print_err(text: String) -> void:
	print("[Error] " + text)
	lines.text += ("\n" if lines.text != "" else "") + "[color=red]" + text + "[/color]"

func parse_command(text: String) -> void:
	self.print("|".join(split_in_same_level(text, " ")))
	#var args: Array[String] = split_in_same_level(text, " ")
	#
	#if args[0].begins_with("/"):
		#args[0] = args[0].substr(1)

func split_in_same_level(text: String, blade: String) -> Array[String]:
	#if !text.contains(blade) || text.is_empty(): return [text]
	if text.is_empty(): return ["empty"]
	if !text.contains(blade): return ["no blade"]
	var ret: Array[String] = []
	var pos: int = 0
	var dist: int = 0
	var stack: Array[String]
	while true:
		print("\n",pos,"|",dist)
		if pos + dist >= text.length():
			ret.append(text.substr(pos))
			return ret
		var char: String = text[pos + dist]
		print("char: '%s'" % char)
		if char == "\\":
			dist += 2
			continue
		if !stack.is_empty(): print("stack[%s] == '%s': %s" % [stack[-1], char, stack[-1] == char])
		if !stack.is_empty(): if stack[-1] == char: print("popped '%s'" % stack.pop_back())
		print("'%s' | '%s' | %s" % [text.substr(pos + dist), blade, text.substr(pos).begins_with(blade)])
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
	return ["NACPRAV"]

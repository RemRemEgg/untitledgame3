class_name Item
extends RefCounted

var proc_item: ProcItem

static func from(lookup: int) -> Item:
	var plit: Item = Item.new()
	plit.proc_item = ProcItem.lookup(lookup)
	return plit

shader_type canvas_item;

void fragment() {
	vec2 pos = UV;
	float vez = float(int(TIME * 24.0) % 38) / 28.0;
	if (pos.y >= vez && pos.y < vez + TEXTURE_PIXEL_SIZE.y * 0.5)
		pos.x += TEXTURE_PIXEL_SIZE.x * 0.25 * sign(pos.y - vez - TEXTURE_PIXEL_SIZE.y * 0.25);
	COLOR = texture(TEXTURE, pos);
}
shader_type canvas_item;

varying vec2 pos;

void vertex() {
	pos = UV;
	pos.x *= length(vec3(MODEL_MATRIX[0][0], MODEL_MATRIX[0][1], MODEL_MATRIX[0][2]));
	pos.y *= length(vec3(MODEL_MATRIX[1][0], MODEL_MATRIX[1][1], MODEL_MATRIX[1][2]));
	//pos *= 0.5;
}

void fragment() {
	vec2 npos;
	npos.x = float(int(pos.x * 16.0) % 16) / 16.0;
	npos.y = float(int(pos.y * 16.0) % 8) / 16.0 + .28 + sign(pos.y - .5) * .225;
	COLOR = texture(TEXTURE, npos);
}
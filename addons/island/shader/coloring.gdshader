shader_type canvas_item;

uniform sampler2D noise_texture;
uniform sampler2D coloring;
uniform sampler2D falloff_map;

void fragment() {
    // получаем значение шума
    float noise = texture(noise_texture, UV).r;
    
    // применяем falloff-карту (ожидается градиент от 0 до 1)
    float falloff = texture(falloff_map, UV).r;
    noise *= falloff; // корректируем шум falloff-картой

    // используем скорректированное значение для выборки цвета
    COLOR = texture(coloring, vec2(noise, 0.0));
}

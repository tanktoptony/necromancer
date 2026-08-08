class_name FrameLibrary
extends RefCounted

static func build_frames(folder: String, prefix: String, animations: Dictionary) -> SpriteFrames:
	var sprite_frames: SpriteFrames = SpriteFrames.new()
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")

	for key: Variant in animations.keys():
		var animation_name: String = str(key)
		var specification: Dictionary = animations[key]
		var frame_indices: Array = specification.get("frames", [])
		sprite_frames.add_animation(animation_name)
		sprite_frames.set_animation_speed(animation_name, float(specification.get("fps", 6.0)))
		sprite_frames.set_animation_loop(animation_name, bool(specification.get("loop", true)))
		for frame_value: Variant in frame_indices:
			var frame_index: int = int(frame_value)
			var path: String = "%s/%s_%d.png" % [folder, prefix, frame_index]
			var texture: Texture2D = load(path) as Texture2D
			if texture != null:
				sprite_frames.add_frame(animation_name, texture)

	return sprite_frames

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
		sprite_frames.set_animation_loop(animation_name, bool(specification.get("loop", true)))
		var requested_fps: float = float(specification.get("fps", 6.0))
		var added_count: int = 0
		for frame_value: Variant in frame_indices:
			var frame_index: int = int(frame_value)
			var path: String = "%s/%s_%d.png" % [folder, prefix, frame_index]
			var texture: Texture2D = load(path) as Texture2D
			if texture != null:
				sprite_frames.add_frame(animation_name, texture)
				added_count += 1
		# If art for some requested frames doesn't exist yet (e.g. a walk cycle
		# expanded from 2 to 4 poses ahead of the art landing), the remaining
		# frames still play at the fps tuned for the FULL set unless corrected
		# here -- which doubles their effective speed instead of smoothing
		# anything out, and reads as a stutter rather than a better walk.
		var effective_fps: float = requested_fps
		if frame_indices.size() > 0 and added_count > 0 and added_count < frame_indices.size():
			effective_fps = requested_fps * (float(added_count) / float(frame_indices.size()))
		sprite_frames.set_animation_speed(animation_name, effective_fps)

	return sprite_frames

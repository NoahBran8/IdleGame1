class_name GardenAudio
extends RefCounted

static func tone(frequency: float = 660.0) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples: int = 3307
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	for i: int in range(samples):
		var t: float = float(i) / 22050.0
		var envelope: float = minf(1.0, t * 100) * pow(1.0 - float(i) / samples, 2)
		var value: int = int(sin(TAU * frequency * t) * envelope * 5000)
		bytes.encode_s16(i * 2, value)
	stream.data = bytes
	return stream

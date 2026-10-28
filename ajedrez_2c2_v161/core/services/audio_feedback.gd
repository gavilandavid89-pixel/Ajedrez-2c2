extends Node
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")

const SAMPLE_RATE := 22050
var player: AudioStreamPlayer
var stream: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback

func _ready() -> void:
    player = AudioStreamPlayer.new()
    add_child(player)
    stream = AudioStreamGenerator.new()
    stream.mix_rate = SAMPLE_RATE
    stream.buffer_length = 0.25
    player.stream = stream

func _exit_tree() -> void:
    if player != null and is_instance_valid(player):
        player.stop()
        player.stream = null
    playback = null
    player = null
    stream = null

func play_feedback(kind: String) -> void:
    # El auditor recorre partidas y botones masivamente; no debe crear
    # AudioStreamGeneratorPlayback porque ese backend puede retenerlo al salir.
    var app = RuntimeServicesScript.get_autoload("App")
    if app != null and bool(app.navigation_audit_mode):
        return
    if OS.has_feature("headless"):
        return
    var data := RuntimeServicesScript.get_autoload("PlayerData")
    if data != null and not data.get_setting("sound", true):
        return
    var spec := _spec(kind)
    if spec.is_empty():
        return
    player.stop()
    playback = null
    player.play()
    playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
    if playback == null:
        return
    var frames := PackedVector2Array()
    var duration: float = float(spec.get("duration", 0.10))
    var frequency: float = float(spec.get("frequency", 440.0))
    var frequency2: float = float(spec.get("frequency2", frequency))
    var amplitude: float = float(spec.get("amplitude", 0.08))
    var total := int(SAMPLE_RATE * duration)
    frames.resize(total)
    for i in range(total):
        var t := float(i) / float(SAMPLE_RATE)
        var blend: float = min(1.0, t * 22.0) * min(1.0, (duration - t) * 18.0)
        var f := lerpf(frequency, frequency2, min(1.0, t / max(0.001, duration)))
        var sample: float = sin(TAU * f * t) * amplitude * blend
        var noise_amount: float = float(spec.get("noise", 0.0))
        if bool(spec.get("wood", false)):
            # Golpe de madera: ataque ruidoso muy corto + resonancias graves
            # no armónicas y caída rápida. Evita el tono electrónico puro.
            var attack := exp(-t * 115.0)
            var body := exp(-t * 34.0)
            var click := (randf() * 2.0 - 1.0) * amplitude * 0.58 * attack
            var resonance := (
                sin(TAU * 148.0 * t) * 0.48
                + sin(TAU * 226.0 * t + 0.7) * 0.27
                + sin(TAU * 392.0 * t + 1.2) * 0.12
            ) * amplitude * body
            sample = click + resonance
        elif noise_amount > 0.0:
            sample += (randf() * 2.0 - 1.0) * amplitude * noise_amount * blend
        frames[i] = Vector2(sample, sample)
    playback.push_buffer(frames)

func _spec(kind: String) -> Dictionary:
    match kind:
        "move": return {"frequency": 420.0, "frequency2": 520.0, "duration": 0.07, "amplitude": 0.055}
        "move_impact": return {"frequency": 235.0, "frequency2": 105.0, "duration": 0.085, "amplitude": 0.115, "wood": true}
        "capture": return {"frequency": 300.0, "frequency2": 190.0, "duration": 0.10, "amplitude": 0.075}
        "capture_impact": return {"frequency": 175.0, "frequency2": 72.0, "duration": 0.11, "amplitude": 0.13, "wood": true}
        "castle": return {"frequency": 360.0, "frequency2": 620.0, "duration": 0.13, "amplitude": 0.065}
        "promotion": return {"frequency": 520.0, "frequency2": 820.0, "duration": 0.18, "amplitude": 0.07}
        "result": return {"frequency": 500.0, "frequency2": 760.0, "duration": 0.22, "amplitude": 0.065}
    return {}

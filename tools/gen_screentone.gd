extends Node

func run():
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var gs := 24
	var r := 5
	var rr := r * r
	
	var y := 0
	while y <= 256 + gs:
		var x := 0
		while x <= 256 + gs:
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var px := x + dx
					var py := y + dy
					if px < 0 or px >= 256 or py < 0 or py >= 256:
						continue
					if dx * dx + dy * dy <= rr:
						img.set_pixel(px, py, Color(0, 0, 0, 1))
			x += gs
		y += gs
	
	var d := DirAccess.open("res://")
	if d:
		d.make_dir_recursive("assets/textures/ui")
		img.save_png("res://assets/textures/ui/screentone.png")
		print("Screentone generated: 256x256, grid=24px, dot=10px")

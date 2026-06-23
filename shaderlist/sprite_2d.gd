extends Sprite2D

# 截图保存路径
var screenshot_path = "res://"

func _ready():
	# 确保截图目录存在
	DirAccess.make_dir_recursive_absolute(screenshot_path)

# 截图按钮按下时的处理（假设按钮连接到这个函数）
func _on_CaptureButton_pressed():
	# 获取整个屏幕截图
	var viewport = get_viewport()
	var image = viewport.get_texture().get_image()
	
	# 使用当前Sprite2D的大小和位置作为截图区域
	var global_pos = global_position
	var size = scale * Vector2(texture.get_width() if texture else 32, texture.get_height() if texture else 32)
	
	# 创建要裁剪的区域
	var capture_rect = Rect2i(
		int(global_pos.x - size.x / 2),  # Sprite2D原点在中心，需要调整
		int(global_pos.y - size.y / 2),
		int(size.x),
		int(size.y)
	)
	
	# 确保区域在图像范围内
	capture_rect = capture_rect.intersection(Rect2i(0, 0, image.get_width(), image.get_height()))
	
	if capture_rect.has_area():
		# 裁剪图像
		var cropped_image = image.get_region(capture_rect)
		
		# 创建纹理并设置给当前Sprite2D
		var the_texture = ImageTexture.create_from_image(cropped_image)
		self.texture = the_texture
		
		# 保存截图
		save_screenshot(cropped_image)
		
		print("截图已设置到Sprite2D")

# 或者：截取整个屏幕并设置为Sprite2D纹理
func capture_entire_screen():
	var viewport = get_viewport()
	var image = viewport.get_texture().get_image()
	
	# 创建纹理并设置给Sprite2D
	var the_texture = ImageTexture.create_from_image(image)
	self.texture = the_texture
	
	# 保存截图
	save_screenshot(image)
	print("全屏截图已设置到Sprite2D")

# 保存截图到文件
func save_screenshot(image: Image):
	# 生成唯一文件名
	var filename = "screenshot_" + str(Time.get_ticks_msec()) + ".png"
	var file_path = screenshot_path + filename
	
	# 保存PNG文件
	image.save_png(file_path)
	print("截图已保存: ", file_path)
	
	return file_path

# 从文件加载纹理到Sprite2D
func load_texture_from_file(file_path: String):
	if FileAccess.file_exists(file_path):
		var image = Image.new()
		image.load(file_path)
		
		var the_texture = ImageTexture.create_from_image(image)
		self.texture = the_texture
		print("已从文件加载纹理: ", file_path)
	else:
		push_error("文件不存在: ", file_path)

# 重新调整Sprite2D大小以匹配纹理
func resize_to_texture():
	if texture:
		# 根据纹理大小调整Sprite2D的大小
		var texture_size = texture.get_size()
		
		# 创建一个新的矩形形状（如果需要碰撞检测）
		# 这里只是调整视觉大小
		print("纹理大小: ", texture_size)
	else:
		push_error("Sprite2D没有纹理")

# 键盘快捷键截图（例如按F2）
#func _input(event):
	#if event.is_action_pressed("ui_screenshot"):  # 需要在项目设置中定义这个动作
		#capture_entire_screen()

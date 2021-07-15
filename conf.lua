function love.conf(t)
  -- 1440X960 for a 4x6 photo
  -- 750x1334
  t.window.width = 1440
  t.window.height = 960
  t.window.resizable = true

  -- For Windows debugging
	t.console = true
	io.stdout:setvbuf("no")
end

function onCreate()
  qtTrace("hola desde luaslice engine: " .. qtEngineName)
  return "test.lua OK, 2 + 3 = patata " .. (2 + 3)
end

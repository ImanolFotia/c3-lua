import lua;

fn void main() {

  lua::Lua_State *l = lua::luaL_newstate();
  lua::luaL_openlibs(l);
  lua::luaL_dofile(l, "script.lua");

  lua::luaL_dofile(l, "mymodule.lua");
  lua::lua_setglobal(l, "mymodule");
  lua::lua_settop(l, 0);

  lua::lua_getglobal(l, "mymodule");
  lua::lua_getfield(l, -1, "sayhi");  // -1 means stack top.
  lua::lua_call(l, 0, 0);   

}
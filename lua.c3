module lua;

const String LUA_VERSION_MAJOR =	"5";
const String LUA_VERSION_MINOR	 = "4";
const String LUA_VERSION_RELEASE	= "7";

const int LUA_VERSION_NUM = 504;
const int LUA_VERSION_RELEASE_NUM =	(LUA_VERSION_NUM * 100 + 7);

const String LUA_VERSION =	"Lua $LUA_VERSION_MAJOR.$LUA_VERSION_MINOR";
const String LUA_RELEASE =	"$LUA_VERSION.$LUA_VERSION_RELEASE";
const String LUA_COPYRIGHT = "$LUA_RELEASE Copyright (C) 1994-2024 Lua.org, PUC-Rio";
const String LUA_AUTHORS =	"R. Ierusalimschy, L. H. de Figueiredo, W. Celes";

const int LUAI_MAXSTACK	= 1000000;
const int LUA_IDSIZE	= 60;

/* mark for precompiled code ('<esc>Lua') */
const char* LUA_SIGNATURE =	"\x1bLua";

/* option for multiple returns in 'lua_pcall' and 'lua_call' */
const int LUA_MULTRET = -1;

/*
** Pseudo-indices
** (-LUAI_MAXSTACK is the minimum valid index; we keep some free empty
** space after that to help overflow detection)
*/
const int LUA_REGISTRYINDEX =	(-LUAI_MAXSTACK - 1000);

macro lua_upvalueindex(i) {
  LUA_REGISTRYINDEX - (i);
}

def Instruction = uint;

enum Tm : int
{
  TM_INDEX,
  TM_NEWINDEX,
  TM_GC,
  TM_MODE,
  TM_LEN,
  TM_EQ,  /* last tag method with fast access */
  TM_ADD,
  TM_SUB,
  TM_MUL,
  TM_MOD,
  TM_POW,
  TM_DIV,
  TM_IDIV,
  TM_BAND,
  TM_BOR,
  TM_BXOR,
  TM_SHL,
  TM_SHR,
  TM_UNM,
  TM_BNOT,
  TM_LT,
  TM_LE,
  TM_CONCAT,
  TM_CALL,
  TM_CLOSE,
  TM_N		/* number of elements in the enum */
}


/* thread status */
const int LUA_OK = 	0;
const int LUA_YIELD = 1;
const int LUA_ERRRUN = 2;
const int LUA_ERRSYNTAX = 3;
const int LUA_ERRMEM = 4;
const int LUA_ERRERR = 5;



/*
** basic types
*/
const int LUA_TNONE =	-1;

const int LUA_TNIL = 0;
const int LUA_TBOOLEAN = 1;
const int LUA_TLIGHTUSERDATA =2;
const int LUA_TNUMBER = 3;
const int LUA_TSTRING = 4;
const int LUA_TTABLE = 5;
const int LUA_TFUNCTION = 6;
const int LUA_TUSERDATA = 7;
const int LUA_TTHREAD = 8;

const int LUA_NUMTYPES = 9;

/* minimum Lua stack available to a C function */
const int LUA_MINSTACK = 20;
const int STRCACHE_N = 53;
const int STRCACHE_M = 2;

/* predefined values in the registry */
const int LUA_RIDX_MAINTHREAD = 1;
const int LUA_RIDX_GLOBALS = 2;
const int LUA_RIDX_LAST = LUA_RIDX_GLOBALS;

def Lua_Number = float;
def Lua_Integer = Lua_Number;
def Lua_Unsigned = uint;

def Lu_byte = char;
def Ls_byte = ichar;
//if x86_64
const int _JBLEN = ((9 * 2) + 3 + 16);
def Jmp_buf = int [_JBLEN];
def Sigjmp_buf = int[_JBLEN + 1];

def Luai_jmpbuf =	Jmp_buf;

struct Lua_longjmp {
  Lua_longjmp *previous;
  Luai_jmpbuf b;
  int status;  /* error code */
}

struct GCObject {
    GCObject *next;
    Lu_byte tt;
    Lu_byte marked;
}

def CommonHeader = GCObject;


struct TValuefields {
    Value value_;
    Lu_byte tt_;
}

struct TValue {
  inline TValuefields values;
}

struct Tbclist{
  TValuefields values;
  ushort delta;
}

union StackValue {
  TValue val;
  Tbclist tbclist;
}


/* index to stack elements */
def StkId = StackValue*;

/*
** When reallocating the stack, change all pointers to the stack into
** proper offsets.
*/
union StkIdRel{
  StkId p;  /* actual pointer */
  isz offset;  /* used while the stack is being reallocated */
} 


def Lua_CFunction = fn int(Lua_State *l);

/*
** Union of all Lua values
*/
union Value {
  GCObject *gc;    /* collectable objects */
  void *p;         /* light userdata */
  Lua_CFunction f; /* light C functions */
  Lua_Integer i;   /* integer numbers */
  Lua_Number n;    /* float numbers */
  /* not used, but may avoid warnings for uninitialized value */
  Lu_byte ub;
}

/*
** Header for a string value.
*/
struct TString {
  CommonHeader header;
  Lu_byte extra;  /* reserved words for short strings; "has hash" for longs */
  Lu_byte shrlen;  /* length for short strings, 0xFF for long strings */
  uint hash;
  union {
    usz lnglen;  /* length for long strings */
    TString *hnext;  /* linked list for hash table */
  }
  char[1] contents;
} 

struct Stringtable {
  TString **hash;
  int nuse;  /* number of elements */
  int size;
}


/*
** Upvalues for Lua closures
*/


union Vv{
  TValue *p;  /* points to stack or to its own value */
  isz offset;  /* used while the stack is being reallocated */
}

struct Open {  /* (when open) */
  UpVal *next;  /* linked list */
  UpVal **previous;
} 

union Uu{
  Open open;
  TValue value;  /* the value (when closed) */
}

struct UpVal {
  CommonHeader header;
  Vv v;
  Uu u;
}

struct NodeKey {
  TValuefields fields;  /* fields for value */
  Lu_byte key_tt;  /* key type */
  int next;  /* for chaining */
  Value key_val;  /* key value */
}

union Node {
  NodeKey u;
  TValue i_val;
}

struct Table {
  CommonHeader header;
  Lu_byte flags;  /* 1<<p means tagmethod(p) is not present */
  Lu_byte lsizenode;  /* log2 of size of 'node' array */
  uint alimit;  /* "limit" of 'array' array */
  TValue *array;  /* array part */
  Node *node;
  Node *lastfree;  /* any free position is before this position */
  Table *metatable;
  GCObject *gclist;
}



def Lua_Alloc = fn void *(void *ud, void *ptr, usz osize, usz nsize);
def Lua_WarnFunction = fn void(void *ud, char *msg, int tocont);
def Lua_Hook = fn void(Lua_State *l, Lua_Debug *ar);
def Lua_KFunction = fn int(Lua_State *l, int status, Lua_KContext *ctx);

def L_signalT = isz;
def Lua_KContext = isz;


struct Ustr {  /* only for Lua functions */
  Instruction *savedpc;
  L_signalT trap;  /* function is tracing lines/counts */
  int nextraargs;  /* # of extra arguments in vararg functions */
}

struct Cstr1{  /* only for C functions */
      Lua_KFunction k;  /* continuation in case of yields */
      isz old_errfunc;
      Lua_KContext ctx;  /* context info. in case of yields */
    }

union Un1{
    Ustr ustr;
    Cstr1 c;
  }

struct Transferinfo{  /* info about transferred values (for call/return hooks) */
      ushort ftransfer;  /* offset of first value transferred */
      ushort ntransfer;  /* number of values transferred */
    } 

  union Un2{
    int funcidx;  /* called-function index */
    int nyield;  /* number of values yielded */
    int nres;  /* number of values returned */
    Transferinfo transferinfo;
  }

struct CallInfo {
  StkIdRel func;  /* function index in the stack */
  StkIdRel	top;  /* top for this function */
  CallInfo *previous;
  CallInfo *next;  /* dynamic call link */
  Un1 u1;
  Un2 u2;
  short nresults;  /* expected number of results from this function */
  ushort callstatus;
}

struct Global_State {
  Lua_Alloc frealloc;  /* function to reallocate memory */
  void *ud;         /* auxiliary data to 'frealloc' */
  isz totalbytes;  /* number of bytes currently allocated - GCdebt */
  isz gcdebt;  /* bytes allocated not yet compensated by the collector */
  usz gcestimate;  /* an estimate of the non-garbage memory in use */
  usz lastatomic;  /* see function 'genstep' in file 'lgc.c' */
  Stringtable strt;  /* hash table for strings */
  TValue l_registry;
  TValue nilvalue;  /* a nil value */
  uint seed;  /* randomized seed for hashes */
  Lu_byte currentwhite;
  Lu_byte gcstate;  /* state of garbage collector */
  Lu_byte gckind;  /* kind of GC running */
  Lu_byte gcstopem;  /* stops emergency collections */
  Lu_byte genminormul;  /* control for minor generational collections */
  Lu_byte genmajormul;  /* control for major generational collections */
  Lu_byte gcstp;  /* control whether GC is running */
  Lu_byte gcemergency;  /* true if this is an emergency collection */
  Lu_byte gcpause;  /* size of pause between successive GCs */
  Lu_byte gcstepmul;  /* GC "speed" */
  Lu_byte gcstepsize;  /* (log2 of) GC granularity */
  GCObject *allgc;  /* list of all collectable objects */
  GCObject **sweepgc;  /* current position of sweep in list */
  GCObject *finobj;  /* list of collectable objects with finalizers */
  GCObject *gray;  /* list of gray objects */
  GCObject *grayagain;  /* list of objects to be traversed atomically */
  GCObject *weak;  /* list of tables with weak values */
  GCObject *ephemeron;  /* list of ephemeron tables (weak keys) */
  GCObject *allweak;  /* list of all-weak tables */
  GCObject *tobefnz;  /* list of userdata to be GC */
  GCObject *fixedgc;  /* list of objects not to be collected */
  /* fields for generational collector */
  GCObject *survival;  /* start of objects that survived one GC cycle */
  GCObject *old1;  /* start of old1 objects */
  GCObject *reallyold;  /* objects more than one cycle old ("really old") */
  GCObject *firstold1;  /* first OLD1 object in the list (if any) */
  GCObject *finobjsur;  /* list of survival objects with finalizers */
  GCObject *finobjold1;  /* list of old1 objects with finalizers */
  GCObject *finobjrold;  /* list of really old objects with finalizers */
  Lua_State *twups;  /* list of threads with open upvalues */
  Lua_CFunction panic;  /* to be called in unprotected errors */
  Lua_State *mainthread;
  TString *memerrmsg;  /* message for memory-allocation errors */
  TString[(int)Tm.TM_N] *tmname;  /* array with tag-method names */
  Table[LUA_NUMTYPES] *mt;  /* metatables for basic types */
  TString[STRCACHE_N][STRCACHE_M] *strcache;  /* cache for strings in API */
  Lua_WarnFunction warnf;  /* warning function */
  void *ud_warn;         /* auxiliary data to 'warnf' */
} 


struct Lua_State {
  CommonHeader header;
  Lu_byte status;
  Lu_byte allowhook;
  ushort nci;  /* number of items in 'ci' list */
  StkIdRel top;  /* first free slot in the stack */
  Global_State *l_G;
  CallInfo *ci;  /* call info for current function */
  StkIdRel stack_last;  /* end of stack (last element + 1) */
  StkIdRel stack;  /* stack base */
  UpVal *openupval;  /* list of open upvalues in this stack */
  StkIdRel tbclist;  /* list of to-be-closed variables */
  GCObject *gclist;
  Lua_State *twups;  /* list of threads with open upvalues */
  Lua_longjmp *errorJmp;  /* current error recover point */
  CallInfo base_ci;  /* CallInfo for first level (C calling Lua) */
  Lua_Hook hook;
  isz errfunc;  /* current error handling function (stack index) */
  uint nCcalls;  /* number of nested (non-yieldable | C)  calls */
  int oldpc;  /* last pc traced */
  int basehookcount;
  int hookcount;
  L_signalT hookmask;
}

struct Lua_Debug {
  int event;
  char *name;	/* (n) */
  char *namewhat;	/* (n) 'global', 'local', 'field', 'method' */
  char *what;	/* (S) 'Lua', 'C', 'main', 'tail' */
  char *source;	/* (S) */
  usz srclen;	/* (S) */
  int currentline;	/* (l) */
  int linedefined;	/* (S) */
  int lastlinedefined;	/* (S) */
  char nups;	/* (u) number of upvalues */
  char nparams;/* (u) number of parameters */
  char isvararg;        /* (u) */
  char istailcall;	/* (t) */
  ushort ftransfer;   /* (r) index of first value transferred */
  ushort ntransfer;   /* (r) number of transferred values */
  char[LUA_IDSIZE] short_src; /* (S) */
  /* private part */
  CallInfo *i_ci;  /* active function */
}

def Lua_Reader = fn char *(Lua_State *l, void *ud, usz *sz);
def Lua_Writer = fn int(Lua_State *l, void *p, usz sz, void *ud);

/*
** state manipulation
*/

extern fn Lua_State *lua_newstate(Lua_Alloc f, void *ud);
extern fn void lua_close(Lua_State *l);
extern fn Lua_State *lua_newthread(Lua_State *l);
extern fn int lua_closethread(Lua_State *l, Lua_State *from);
extern fn int lua_resetthread(Lua_State *l); /* Deprecated*/
extern fn Lua_CFunction lua_atpanic(Lua_State *l, Lua_CFunction panicf);
extern fn Lua_Number lua_version(Lua_State *l);


/*
** basic stack manipulation
*/

extern fn int lua_absindex(Lua_State *l, int idx);
extern fn int lua_gettop(Lua_State *l);
extern fn void lua_settop(Lua_State *l, int idx);
extern fn void lua_pushvalue(Lua_State *l, int idx);
extern fn void lua_rotate(Lua_State *l, int idx, int n);
extern fn void lua_copy(Lua_State *l, int fromidx, int toidx);
extern fn int lua_checkstack(Lua_State *l, int n);

extern fn void lua_xmove(Lua_State *from, Lua_State *to, int n);

/*
** access functions (stack -> C)
*/

extern fn int             lua_isnumber (Lua_State *l, int idx);
extern fn int             lua_isstring (Lua_State *l, int idx);
extern fn int             lua_iscfunction (Lua_State *l, int idx);
extern fn int             lua_isinteger (Lua_State *l, int idx);
extern fn int             lua_isuserdata (Lua_State *l, int idx);
extern fn int             lua_type (Lua_State *l, int idx);
extern fn char     *lua_typename (Lua_State *l, int tp);

extern fn Lua_Number      lua_tonumberx (Lua_State *l, int idx, int *isnum);
extern fn Lua_Integer     lua_tointegerx (Lua_State *l, int idx, int *isnum);
extern fn int             lua_toboolean (Lua_State *l, int idx);
extern fn char     *lua_tolstring (Lua_State *l, int idx, usz *len);
extern fn Lua_Unsigned    lua_rawlen (Lua_State *l, int idx);
extern fn Lua_CFunction   lua_tocfunction (Lua_State *l, int idx);
extern fn void	       *lua_touserdata (Lua_State *l, int idx);
extern fn Lua_State      *lua_tothread (Lua_State *l, int idx);
extern fn void     *lua_topointer (Lua_State *l, int idx);


const int LUA_OPADD = 	0;	/* ORDER TM, ORDER OP */
const int LUA_OPSUB = 	1;
const int LUA_OPMUL = 	2;
const int LUA_OPMOD = 	3;
const int LUA_OPPOW = 	4;
const int LUA_OPDIV = 	5;
const int LUA_OPIDIV = 	6;
const int LUA_OPBAND = 	7;
const int LUA_OPBOR = 	8;
const int LUA_OPBXOR = 	9;
const int LUA_OPSHL = 	10;
const int LUA_OPSHR = 	11;
const int LUA_OPUNM = 	12;
const int LUA_OPBNOT = 	13;

extern fn void lua_arith(Lua_State *l, int op);

const int LUA_OPEQ = 	0;
const int LUA_OPLT = 	1;
const int LUA_OPLE = 	2;


extern fn int  lua_rawequal(Lua_State *l, int idx1, int idx2);
extern fn int  lua_compare(Lua_State *l, int idx1, int idx2, int op);

/*
** push functions (C -> stack)
*/

extern fn void        lua_pushnil(Lua_State *l);
extern fn void        lua_pushnumber(Lua_State *l, Lua_Number n);
extern fn void        lua_pushinteger (Lua_State *l, Lua_Integer n);
extern fn char *lua_pushlstring (Lua_State *l, char *s, usz len);
extern fn char *lua_pushstring (Lua_State *l, char *s);
extern fn char *lua_pushvfstring (Lua_State *l, char *fmt, ...);
extern fn char *lua_pushfstring (Lua_State *l, char *fmt, ...);
extern fn void  lua_pushcclosure (Lua_State *l, Lua_CFunction fun, int n);
extern fn void  lua_pushboolean (Lua_State *l, int b);
extern fn void  lua_pushlightuserdata (Lua_State *l, void *p);
extern fn int   lua_pushthread (Lua_State *l);

/*
** get functions (Lua -> stack)
*/
extern fn int lua_getglobal (Lua_State *l, char *name);
extern fn int lua_gettable (Lua_State *l, int idx);
extern fn int lua_getfield (Lua_State *l, int idx, char *k);
extern fn int lua_geti (Lua_State *l, int idx, Lua_Integer n);
extern fn int lua_rawget (Lua_State *l, int idx);
extern fn int lua_rawgeti (Lua_State *l, int idx, Lua_Integer n);
extern fn int lua_rawgetp (Lua_State *l, int idx, void *p);

extern fn void  lua_createtable (Lua_State *l, int narr, int nrec);
extern fn void *lua_newuserdatauv (Lua_State *l, usz sz, int nuvalue);
extern fn int   lua_getmetatable (Lua_State *l, int objindex);
extern fn int  lua_getiuservalue (Lua_State *l, int idx, int n);

/*
** set functions (stack -> Lua)
*/

extern fn void  lua_setglobal (Lua_State *l, char *name);
extern fn void  lua_settable (Lua_State *l, int idx);
extern fn void  lua_setfield (Lua_State *l, int idx, char *k);
extern fn void  lua_seti (Lua_State *l, int idx, Lua_Integer n);
extern fn void  lua_rawset (Lua_State *l, int idx);
extern fn void  lua_rawseti (Lua_State *l, int idx, Lua_Integer n);
extern fn void  lua_rawsetp (Lua_State *l, int idx, void *p);
extern fn int   lua_setmetatable (Lua_State *l, int objindex);
extern fn int   lua_setiuservalue (Lua_State *l, int idx, int n);

/*
** 'load' and 'call' functions (load and run Lua code)
*/

extern fn void  lua_callk (Lua_State *l, int nargs, int nresults,
                           Lua_KContext ctx, Lua_KFunction k);
// #define lua_call(L,n,r)		lua_callk(L, (n), (r), 0, NULL)

macro lua_call(l,n,r) {
  lua_callk(l,n, r, 0, (Lua_KFunction)0);
}

extern fn int   lua_pcallk (Lua_State *l, int nargs, int nresults, int errfunc,
                            Lua_KContext ctx, Lua_KFunction k);
// #define lua_pcall(L,n,r,f)	lua_pcallk(L, (n), (r), (f), 0, NULL)

macro lua_pcall(l,n,r,f) {
  return lua_pcallk(l,n, r, f, 0, (Lua_KFunction)0);
}

extern fn int   lua_load (Lua_State *l, Lua_Reader reader, void *dt,
                          char *chunkname, char *mode);

extern fn int lua_dump (Lua_State *l, Lua_Writer writer, void *data, int strip);

/*
** coroutine functions
*/
extern fn int  lua_yieldk     (Lua_State *l, int nresults, Lua_KContext ctx,
                               Lua_KFunction k);
extern fn int  lua_resume     (Lua_State *l, Lua_State *from, int narg,
                               int *nres);
extern fn int  lua_status     (Lua_State *l);
extern fn int lua_isyieldable (Lua_State *l);

//#define lua_yield(L,n)		lua_yieldk(L, (n), 0, NULL)

macro lua_yield(l,n) {
  lua_yieldk(l,n, 0, 0);
}

/*
** Warning-related functions
*/
extern fn void lua_setwarnf (Lua_State *l, Lua_WarnFunction f, void *ud);
extern fn void lua_warning  (Lua_State *l, char *msg, int tocont);

/*
** garbage-collection function and options
*/

const int LUA_GCSTOP = 		0;
const int LUA_GCRESTART = 		1;
const int LUA_GCCOLLECT = 		2;
const int LUA_GCCOUNT = 		3;
const int LUA_GCCOUNTB = 		4;
const int LUA_GCSTEP = 		5;
const int LUA_GCSETPAUSE = 		6;
const int LUA_GCSETSTEPMUL = 	7;
const int LUA_GCISRUNNING = 		9;
const int LUA_GCGEN = 		10;
const int LUA_GCINC = 		11;


extern fn int lua_gc (Lua_State *l, int what, ...);


/*
** miscellaneous functions
*/

extern fn int   lua_error (Lua_State *l);

extern fn int   lua_next (Lua_State *l, int idx);

extern fn void  lua_concat (Lua_State *l, int n);
extern fn void  lua_len    (Lua_State *l, int idx);

extern fn usz   lua_stringtonumber (Lua_State *l, char *s);

extern fn Lua_Alloc lua_getallocf (Lua_State *l, void **ud);
extern fn void      lua_setallocf (Lua_State *l, Lua_Alloc f, void *ud);

extern fn void lua_toclose (Lua_State *l, int idx);
extern fn void lua_closeslot (Lua_State *l, int idx);

/*
** {==============================================================
** some useful macros
** ===============================================================
*/

// #define lua_getextraspace(L)	((void *)((char *)(L) - LUA_EXTRASPACE))


macro lua_getextraspace(l) {
  return ((void *)((char *)(l) - LUA_EXTRASPACE));
}

// #define lua_tonumber(L,i)	lua_tonumberx(L,(i),NULL)

macro lua_tonumber(l,i) {
  return lua_tonumberx(l,(i),0);
}

// #define lua_tointeger(L,i)	lua_tointegerx(L,(i),NULL)

macro lua_tointeger(l,i) {
  return lua_tointegerx(l,(i),0);
}

// #define lua_pop(L,n)		lua_settop(L, -(n)-1)

macro lua_pop(l,n) {
  return lua_settop(l,-n-1);
}

// #define lua_newtable(L)		lua_createtable(L, 0, 0)

macro lua_newtable(l) {
  return lua_createtable(l,0,0);
}

// #define lua_register(L,n,f) (lua_pushcfunction(L, (f)), lua_setglobal(L, (n)))

macro lua_register(l,n,f) {
  lua_pushcfunction(l, (f)); 
  lua_setglobal(l, (n));
}

// #define lua_pushcfunction(L,f)	lua_pushcclosure(L, (f), 0)

macro lua_pushcfunction(l,f) {
  return lua_pushcclosure(l, (f), 0);
}

// #define lua_isfunction(L,n)	(lua_type(L, (n)) == LUA_TFUNCTION)

macro lua_isfunction(l,n) {
  return (lua_type(L, (n)) == LUA_TFUNCTION);
}
// #define lua_istable(L,n)	(lua_type(L, (n)) == LUA_TTABLE)

macro lua_istable(l,n) {
  return (lua_type(L, (n)) == LUA_TTABLE);
}
// #define lua_islightuserdata(L,n)	(lua_type(L, (n)) == LUA_TLIGHTUSERDATA)
macro lua_islightuserdata(l,n) {
  return (lua_type(L, (n)) == LUA_TLIGHTUSERDATA);
}
// #define lua_isnil(L,n)		(lua_type(L, (n)) == LUA_TNIL)
macro lua_isnil(l,n) {
 return  (lua_type(L, (n)) == LUA_TNIL);
}
// #define lua_isboolean(L,n)	(lua_type(L, (n)) == LUA_TBOOLEAN)
macro lua_isboolean(l,n) {
  return (lua_type(L, (n)) == LUA_TBOOLEAN);
}
// #define lua_isthread(L,n)	(lua_type(L, (n)) == LUA_TTHREAD)
macro lua_isthread(l,n) {
  return (lua_type(L, (n)) == LUA_TTHREAD);
}
// #define lua_isnone(L,n)		(lua_type(L, (n)) == LUA_TNONE)
macro lua_isnone(l,n) {
  return (lua_type(L, (n)) == LUA_TNONE);
}
// #define lua_isnoneornil(L, n)	(lua_type(L, (n)) <= 0)
macro lua_isnoneornil(l,n) {
  return (lua_type(L, (n)) <= 0);
}

// #define lua_pushliteral(L, s)	lua_pushstring(L, "" s)
macro lua_pushliteral(l,n) {
 return lua_pushstring(L, ""+ s);
}

//#define lua_pushglobaltable(L)  \
//	((void)lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS))

macro lua_pushglobaltable(l) {
  return lua_rawgeti(l, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
}


//#define lua_tostring(L,i)	lua_tolstring(L, (i), NULL)

macro lua_tostring(l,i) {
  return lua_tolstring(l, (i), NULL);
}


//#define lua_insert(L,idx)	lua_rotate(L, (idx), 1)

macro lua_insert(l,idx) {
  return lua_rotate(l, (idx), 1);
}

//#define lua_remove(L,idx)	(lua_rotate(L, (idx), -1), lua_pop(L, 1))

macro lua_remove(l,idx) {
  lua_rotate(l, (idx), -1);
  lua_pop(l, 1);
}

//#define lua_replace(L,idx)	(lua_copy(L, -1, (idx)), lua_pop(L, 1))

macro lua_replace(l,idx) {
  lua_copy(l, -1, (idx)); 
  lua_pop(l, 1);
}

/* }============================================================== */


/*
** {==============================================================
** compatibility macros
** ===============================================================
*/

//#if defined(LUA_COMPAT_APIINTCASTS)

//#define lua_pushunsigned(L,n)	lua_pushinteger(L, (Lua_Integer)(n))
macro lua_pushunsigned(l,n) {
  return lua_pushinteger(l, (Lua_Integer)(n));
}
//#define lua_tounsignedx(L,i,is)	((Lua_Unsigned)lua_tointegerx(L,i,is))
macro lua_tounsignedx(l,i,is) {
  return ((Lua_Unsigned)lua_tointegerx(l,i,is));
}
//#define lua_tounsigned(L,i)	lua_tounsignedx(L,(i),NULL)
macro lua_tounsigned(l,i) {
 return lua_tounsignedx(l,(i),0);
}

//#endif

//#define lua_newuserdata(L,s)	lua_newuserdatauv(L,s,1)
macro lua_newuserdata(l,s) {
  return lua_newuserdatauv(l,s,1);
}
//#define lua_getuservalue(L,idx)	lua_getiuservalue(L,idx,1)
macro lua_getuservalue(l,idx) {
  return lua_getiuservalue(l,idx,1);
}
//#define lua_setuservalue(L,idx)	lua_setiuservalue(L,idx,1)
macro lua_setuservalue(l,idx) {
  return lua_setiuservalue(l,idx,1);
}
const int LUA_NUMTAGS		 = LUA_NUMTYPES;

/* }============================================================== */

/*
** {======================================================================
** Debug API
** =======================================================================
*/


/*
** Event codes
*/
const int LUA_HOOKCALL = 	0;
const int LUA_HOOKRET = 	1;
const int LUA_HOOKLINE = 	2;
const int LUA_HOOKCOUNT = 	3;
const int LUA_HOOKTAILCALL =  4;


/*
** Event masks
*/
const int LUA_MASKCALL =	(1 << LUA_HOOKCALL);
const int LUA_MASKRET =	(1 << LUA_HOOKRET);
const int LUA_MASKLINE =	(1 << LUA_HOOKLINE);
const int LUA_MASKCOUNT =	(1 << LUA_HOOKCOUNT);


extern fn int lua_getstack (Lua_State *l, int level, Lua_Debug *ar);
extern fn int lua_getinfo (Lua_State *l, char *what, Lua_Debug *ar);
extern fn char *lua_getlocal (Lua_State *l, Lua_Debug *ar, int n);
extern fn char *lua_setlocal (Lua_State *l, Lua_Debug *ar, int n);
extern fn char *lua_getupvalue (Lua_State *l, int funcindex, int n);
extern fn char *lua_setupvalue (Lua_State *l, int funcindex, int n);

extern fn void *lua_upvalueid (Lua_State *l, int fidx, int n);
extern fn void  lua_upvaluejoin (Lua_State *l, int fidx1, int n1,
                                               int fidx2, int n2);

extern fn void lua_sethook (Lua_State *l, Lua_Hook func, int mask, int count);
extern fn Lua_Hook lua_gethook (Lua_State *l);
extern fn int lua_gethookmask (Lua_State *l);
extern fn int lua_gethookcount (Lua_State *l);

extern fn int lua_setcstacklimit (Lua_State *l, uint limit);

/*
* luabib.h
*/

/* version suffix for environment variable names */
const String LUA_VERSUFFIX = "_$LUA_VERSION_MAJOR_$LUA_VERSION_MINOR";

extern fn int luaopen_base(Lua_State *l);
const String LUA_COLIBNAME = "coroutine";
extern fn int luaopen_coroutine(Lua_State *l);

const String LUA_TABLIBNAME = "table";
extern fn int luaopen_table(Lua_State *l);

const String LUA_IOLIBNAME = "io";
extern fn int luaopen_io(Lua_State *l);

const String LUA_OSLIBNAME = "os";
extern fn int luaopen_os(Lua_State *l);

const String LUA_STRLIBNAME = "string";
extern fn int luaopen_string(Lua_State *l);

const String LUA_UTF8LIBNAME = "utf8";
extern fn int luaopen_utf8(Lua_State *l);

const String LUA_MATHLIBNAME = "math";
extern fn int luaopen_math(Lua_State *l);

const String LUA_DBLIBNAME = "debug";
extern fn int luaopen_debug(Lua_State *l);

const String LUA_LOADLIBNAME = "package";
extern fn int luaopen_package(Lua_State *l);

extern fn void luaL_openlibs(Lua_State *l);


//luaauxlib.h


extern fn int luaL_loadfilex (Lua_State *l, char *filename, char *mode);

extern fn Lua_State *luaL_newstate();

macro luaL_loadfile(l,f) {
  return luaL_loadfilex(l,f,(char*)0);
}

macro luaL_dofile(l,fun) {
	return (luaL_loadfile(l, fun) || lua_pcall(l, 0, LUA_MULTRET, 0));
}
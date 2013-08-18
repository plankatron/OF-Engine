// script binding functionality

enum { VAL_NULL = 0, VAL_INT, VAL_FLOAT, VAL_STR, VAL_ANY, VAL_CODE, VAL_MACRO, VAL_IDENT, VAL_CSTR, VAL_CANY, VAL_WORD, VAL_POP, VAL_COND };

enum
{
    CODE_START = 0,
    CODE_OFFSET,
    CODE_NULL, CODE_TRUE, CODE_FALSE, CODE_NOT,
    CODE_POP,
    CODE_ENTER, CODE_ENTER_RESULT,
    CODE_EXIT, CODE_RESULT_ARG,
    CODE_VAL, CODE_VALI,
    CODE_DUP,
    CODE_MACRO,
    CODE_BOOL,
    CODE_BLOCK, CODE_EMPTY,
    CODE_COMPILE, CODE_COND,
    CODE_FORCE,
    CODE_RESULT,
    CODE_IDENT, CODE_IDENTU, CODE_IDENTARG,
    CODE_COM, CODE_COMD, CODE_COMC, CODE_COMV,
    CODE_CONC, CODE_CONCW, CODE_CONCM, CODE_DOWN,
    CODE_SVAR, CODE_SVARM, CODE_SVAR1,
    CODE_IVAR, CODE_IVAR1, CODE_IVAR2, CODE_IVAR3,
    CODE_FVAR, CODE_FVAR1,
    CODE_LOOKUP, CODE_LOOKUPU, CODE_LOOKUPARG,
    CODE_LOOKUPM, CODE_LOOKUPMU, CODE_LOOKUPMARG,
    CODE_ALIAS, CODE_ALIASU, CODE_ALIASARG, CODE_CALL, CODE_CALLU, CODE_CALLARG,
    CODE_PRINT,
    CODE_LOCAL,
    CODE_DO,
    CODE_JUMP, CODE_JUMP_TRUE, CODE_JUMP_FALSE, CODE_JUMP_RESULT_TRUE, CODE_JUMP_RESULT_FALSE,

    CODE_OP_MASK = 0x3F,
    CODE_RET = 6,
    CODE_RET_MASK = 0xC0,

    /* return type flags */
    RET_NULL   = VAL_NULL<<CODE_RET,
    RET_STR    = VAL_STR<<CODE_RET,
    RET_INT    = VAL_INT<<CODE_RET,
    RET_FLOAT  = VAL_FLOAT<<CODE_RET,
};

enum { ID_VAR, ID_FVAR, ID_SVAR, ID_COMMAND, ID_ALIAS, ID_LOCAL, ID_DO, ID_IF, ID_RESULT, ID_NOT, ID_AND, ID_OR };

/* OF: IDF_ALLOC, IDF_SIGNAL, IDF_SAFE, IDF_TRUSTED */
enum { IDF_PERSIST  = 1<<0, IDF_OVERRIDE   = 1<<1, IDF_HEX     = 1<<2,
       IDF_READONLY = 1<<3, IDF_OVERRIDDEN = 1<<4, IDF_UNKNOWN = 1<<5,
       IDF_ARG      = 1<<6, IDF_ALLOC      = 1<<7, IDF_SIGNAL  = 1<<8,
       IDF_SAFE     = 1<<9, IDF_TRUSTED    = 1<<10 };

struct ident;

struct identval
{
    union
    {
        int i;      // ID_VAR, VAL_INT
        float f;    // ID_FVAR, VAL_FLOAT
        char *s;    // ID_SVAR, VAL_STR
        const uint *code; // VAL_CODE
        ident *id;  // VAL_IDENT
        const char *cstr; // VAL_CSTR
    };
};

struct tagval : identval
{
    int type;

    void setint(int val) { type = VAL_INT; i = val; }
    void setfloat(float val) { type = VAL_FLOAT; f = val; }
    void setstr(char *val) { type = VAL_STR; s = val; }
    void setnull() { type = VAL_NULL; i = 0; }
    void setcode(const uint *val) { type = VAL_CODE; code = val; }
    void setmacro(const uint *val) { type = VAL_MACRO; code = val; }
    void setcstr(const char *val) { type = VAL_CSTR; cstr = val; }
    void setident(ident *val) { type = VAL_IDENT; id = val; }

    const char *getstr() const;
    int getint() const;
    float getfloat() const;
    bool getbool() const;
    void getval(tagval &r) const;

    void cleanup();
};

struct identstack
{
    identval val;
    int valtype;
    identstack *next;
};

union identvalptr
{
    void *p;  // ID_*VAR
    int *i;   // ID_VAR
    float *f; // ID_FVAR
    char **s; // ID_SVAR
};

typedef void (__cdecl *identfun)(ident *id);

extern int identflags;

struct ident
{
    int type;           // one of ID_* above
    const char *name;
    union
    {
        int minval;    // ID_VAR
        float minvalf; // ID_FVAR
        int valtype;   // ID_ALIAS
        int numargs;   // ID_COMMAND
    };
    union
    {
        int maxval;    // ID_VAR
        float maxvalf; // ID_FVAR
        uint *code;    // ID_ALIAS
    };
    union
    {
        const char *args;    // ID_COMMAND
        identval val;        // ID_ALIAS
        identvalptr storage; // ID_VAR, ID_FVAR, ID_SVAR
    };
    union
    {
        identval overrideval; // ID_VAR, ID_FVAR, ID_SVAR
        identstack *stack;    // ID_ALIAS
        uint argmask;         // ID_COMMAND
    };
    identfun fun; // ID_VAR, ID_FVAR, ID_SVAR, ID_COMMAND
    int flags, index;

    ident() {}
    // ID_VAR
    ident(int t, const char *n, int m, int x, int *s, void *f = NULL, int flags = 0)
        : type(t), name(n), minval(m), maxval(x), fun((identfun)f), flags(flags | (m > x ? IDF_READONLY : 0))
    { storage.i = s; }
    // ID_FVAR
    ident(int t, const char *n, float m, float x, float *s, void *f = NULL, int flags = 0)
        : type(t), name(n), minvalf(m), maxvalf(x), fun((identfun)f), flags(flags | (m > x ? IDF_READONLY : 0))
    { storage.f = s; }
    // ID_SVAR
    ident(int t, const char *n, char **s, void *f = NULL, int flags = 0)
        : type(t), name(n), fun((identfun)f), flags(flags)
    { storage.s = s; }
    // ID_ALIAS
    // OF: safe, trusted
    ident(int t, const char *n, char *a, int flags)
        : type(t), name(n), valtype(VAL_STR), code(NULL), stack(NULL), flags(flags)
    { val.s = a; flags |= identflags&(IDF_SAFE|IDF_TRUSTED); }
    ident(int t, const char *n, int a, int flags)
        : type(t), name(n), valtype(VAL_INT), code(NULL), stack(NULL), flags(flags)
    { val.i = a; flags |= identflags&(IDF_SAFE|IDF_TRUSTED); }
    ident(int t, const char *n, float a, int flags)
        : type(t), name(n), valtype(VAL_FLOAT), code(NULL), stack(NULL), flags(flags)
    { val.f = a; flags |= identflags&(IDF_SAFE|IDF_TRUSTED); }
    ident(int t, const char *n, int flags)
        : type(t), name(n), valtype(VAL_NULL), code(NULL), stack(NULL), flags(flags)
    { flags |= identflags&(IDF_SAFE|IDF_TRUSTED); }
    ident(int t, const char *n, const tagval &v, int flags)
        : type(t), name(n), valtype(v.type), code(NULL), stack(NULL), flags(flags)
    { val = v; flags |= identflags&(IDF_SAFE|IDF_TRUSTED); }
    // ID_COMMAND
    ident(int t, const char *n, const char *args, uint argmask, int numargs, void *f = NULL, int flags = 0)
        : type(t), name(n), numargs(numargs), args(args), argmask(argmask), fun((identfun)f), flags(flags)
    {}

    /* OF: command.cpp */
    void changed();

    void setval(const tagval &v)
    {
        valtype = v.type;
        val = v;
    }

    void setval(const identstack &v)
    {
        valtype = v.valtype;
        val = v.val;
    }

    void forcenull()
    {
        if(valtype==VAL_STR) delete[] val.s;
        valtype = VAL_NULL;
    }

    float getfloat() const;
    int getint() const;
    const char *getstr() const;
    void getval(tagval &r) const;
    void getcstr(tagval &v) const;
    void getcval(tagval &v) const;
};

extern void addident(ident *id);

extern tagval *commandret;
extern const char *intstr(int v);
extern void intret(int v);
extern const char *floatstr(float v);
extern void floatret(float v);
extern void stringret(char *s);
extern void result(tagval &v);
extern void result(const char *s);

static inline int parseint(const char *s)
{
    return int(strtoul(s, NULL, 0));
}

static inline float parsefloat(const char *s)
{
    // not all platforms (windows) can parse hexadecimal integers via strtod
    char *end;
    double val = strtod(s, &end);
    return val || end==s || (*end!='x' && *end!='X') ? float(val) : float(parseint(s));
}

static inline void intformat(char *buf, int v, int len = 20) { nformatstring(buf, len, "%d", v); }
static inline void floatformat(char *buf, float v, int len = 20) { nformatstring(buf, len, v==int(v) ? "%.1f" : "%.7g", v); }

static inline const char *getstr(const identval &v, int type)
{
    switch(type)
    {
        case VAL_STR: case VAL_MACRO: case VAL_CSTR: return v.s;
        case VAL_INT: return intstr(v.i);
        case VAL_FLOAT: return floatstr(v.f);
        default: return "";
    }
}
inline const char *tagval::getstr() const { return ::getstr(*this, type); }
inline const char *ident::getstr() const { return ::getstr(val, valtype); }

static inline int getint(const identval &v, int type)
{
    switch(type)
    {
        case VAL_INT: return v.i;
        case VAL_FLOAT: return int(v.f);
        case VAL_STR: case VAL_MACRO: case VAL_CSTR: return parseint(v.s);
        default: return 0;
    }
}
inline int tagval::getint() const { return ::getint(*this, type); }
inline int ident::getint() const { return ::getint(val, valtype); }

static inline float getfloat(const identval &v, int type)
{
    switch(type)
    {
        case VAL_FLOAT: return v.f;
        case VAL_INT: return float(v.i);
        case VAL_STR: case VAL_MACRO: case VAL_CSTR: return parsefloat(v.s);
        default: return 0.0f;
    }
}
inline float tagval::getfloat() const { return ::getfloat(*this, type); }
inline float ident::getfloat() const { return ::getfloat(val, valtype); }

static inline void getval(const identval &v, int type, tagval &r)
{
    switch(type)
    {
        case VAL_STR: case VAL_MACRO: case VAL_CSTR: r.setstr(newstring(v.s)); break;
        case VAL_INT: r.setint(v.i); break;
        case VAL_FLOAT: r.setfloat(v.f); break;
        default: r.setnull(); break;
    }
}

inline void tagval::getval(tagval &r) const { ::getval(*this, type, r); }
inline void ident::getval(tagval &r) const { ::getval(val, valtype, r); }

inline void ident::getcstr(tagval &v) const
{
    switch(valtype)
    {
        case VAL_MACRO: v.setmacro(val.code); break;
        case VAL_STR: case VAL_CSTR: v.setcstr(val.s); break;
        case VAL_INT: v.setstr(newstring(intstr(val.i))); break;
        case VAL_FLOAT: v.setstr(newstring(floatstr(val.f))); break;
        default: v.setcstr(""); break;
    }
}

inline void ident::getcval(tagval &v) const
{
    switch(valtype)
    {
        case VAL_MACRO: v.setmacro(val.code); break;
        case VAL_STR: case VAL_CSTR: v.setcstr(val.s); break;
        case VAL_INT: v.setint(val.i); break;
        case VAL_FLOAT: v.setfloat(val.f); break;
        default: v.setnull(); break;
    }
}

// nasty macros for registering script functions, abuses globals to avoid excessive infrastructure
// OF: unsafe variants
#define KEYWORD(name, type) static bool __dummy_##type = addcommand(#name, (identfun)NULL, NULL, type)
#define _COMMANDKN(name, type, fun, nargs, flags) static bool __dummy_##fun = addcommand(#name, (identfun)fun, nargs, type, flags)
#define COMMANDKN(name, type, fun, nargs) _COMMANDKN(name, type, fun, nargs, IDF_SAFE)
#define COMMANDKNU(name, type, fun, nargs) _COMMANDKN(name, type, fun, nargs, 0)
#define COMMANDK(name, type, nargs) COMMANDKN(name, type, name, nargs)
#define COMMANDKU(name, type, nargs) COMMANDKNU(name, type, name, nargs)
#define COMMANDN(name, fun, nargs) COMMANDKN(name, ID_COMMAND, fun, nargs)
#define COMMANDNU(name, fun, nargs) COMMANDKNU(name, ID_COMMAND, fun, nargs)
#define COMMAND(name, nargs) COMMANDN(name, name, nargs)
#define COMMANDU(name, nargs) COMMANDNU(name, name, nargs)

#define _VAR(name, global, min, cur, max, persist)  int global = variable(#name, min, cur, max, &global, NULL, persist)
#define VARN(name, global, min, cur, max) _VAR(name, global, min, cur, max, 0)
#define VARNP(name, global, min, cur, max) _VAR(name, global, min, cur, max, IDF_PERSIST)
#define VARNR(name, global, min, cur, max) _VAR(name, global, min, cur, max, IDF_OVERRIDE)
#define VAR(name, min, cur, max) _VAR(name, name, min, cur, max, 0)
#define VARP(name, min, cur, max) _VAR(name, name, min, cur, max, IDF_PERSIST)
#define VARR(name, min, cur, max) _VAR(name, name, min, cur, max, IDF_OVERRIDE)
#define _VARF(name, global, min, cur, max, body, persist)  void var_##name(ident *id); int global = variable(#name, min, cur, max, &global, var_##name, persist); void var_##name(ident *id) { body; }
#define VARFN(name, global, min, cur, max, body) _VARF(name, global, min, cur, max, body, 0)
#define VARF(name, min, cur, max, body) _VARF(name, name, min, cur, max, body, 0)
#define VARFP(name, min, cur, max, body) _VARF(name, name, min, cur, max, body, IDF_PERSIST)
#define VARFR(name, min, cur, max, body) _VARF(name, name, min, cur, max, body, IDF_OVERRIDE)
#define VARFNP(name, global, min, cur, max, body) _VARF(name, global, min, cur, max, body, IDF_PERSIST)
#define VARFNR(name, global, min, cur, max, body) _VARF(name, global, name, min, cur, max, body, IDF_OVERRIDE)

#define _HVAR(name, global, min, cur, max, persist)  int global = variable(#name, min, cur, max, &global, NULL, persist | IDF_HEX)
#define HVARN(name, global, min, cur, max) _HVAR(name, global, min, cur, max, 0)
#define HVARNP(name, global, min, cur, max) _HVAR(name, global, min, cur, max, IDF_PERSIST)
#define HVARNR(name, global, min, cur, max) _HVAR(name, global, min, cur, max, IDF_OVERRIDE)
#define HVAR(name, min, cur, max) _HVAR(name, name, min, cur, max, 0)
#define HVARP(name, min, cur, max) _HVAR(name, name, min, cur, max, IDF_PERSIST)
#define HVARR(name, min, cur, max) _HVAR(name, name, min, cur, max, IDF_OVERRIDE)
#define _HVARF(name, global, min, cur, max, body, persist)  void var_##name(ident *id); int global = variable(#name, min, cur, max, &global, var_##name, persist | IDF_HEX); void var_##name(ident *id) { body; }
#define HVARFN(name, global, min, cur, max, body) _HVARF(name, global, min, cur, max, body, 0)
#define HVARF(name, min, cur, max, body) _HVARF(name, name, min, cur, max, body, 0)
#define HVARFP(name, min, cur, max, body) _HVARF(name, name, min, cur, max, body, IDF_PERSIST)
#define HVARFR(name, min, cur, max, body) _HVARF(name, name, min, cur, max, body, IDF_OVERRIDE)
#define HVARFNP(name, global, min, cur, max, body) _HVARF(name, global, min, cur, max, body, IDF_PERSIST)
#define HVARFNR(name, global, min, cur, max, body) _HVARF(name, global, name, min, cur, max, body, IDF_OVERRIDE)

#define _FVAR(name, global, min, cur, max, persist) float global = fvariable(#name, min, cur, max, &global, NULL, persist)
#define FVARN(name, global, min, cur, max) _FVAR(name, global, min, cur, max, 0)
#define FVARNP(name, global, min, cur, max) _FVAR(name, global, min, cur, max, IDF_PERSIST)
#define FVARNR(name, global, min, cur, max) _FVAR(name, global, min, cur, max, IDF_OVERRIDE)
#define FVAR(name, min, cur, max) _FVAR(name, name, min, cur, max, 0)
#define FVARP(name, min, cur, max) _FVAR(name, name, min, cur, max, IDF_PERSIST)
#define FVARR(name, min, cur, max) _FVAR(name, name, min, cur, max, IDF_OVERRIDE)
#define _FVARF(name, global, min, cur, max, body, persist) void var_##name(ident *id); float global = fvariable(#name, min, cur, max, &global, var_##name, persist); void var_##name(ident *id) { body; }
#define FVARFN(name, global, min, cur, max, body) _FVARF(name, global, min, cur, max, body, 0)
#define FVARF(name, min, cur, max, body) _FVARF(name, name, min, cur, max, body, 0)
#define FVARFP(name, min, cur, max, body) _FVARF(name, name, min, cur, max, body, IDF_PERSIST)
#define FVARFR(name, min, cur, max, body) _FVARF(name, name, min, cur, max, body, IDF_OVERRIDE)
#define FVARFNP(name, global, min, cur, max, body) _FVARF(name, global, min, cur, max, body, IDF_PERSIST)
#define FVARFNR(name, global, min, cur, max, body) _FVARF(name, global, name, min, cur, max, body, IDF_OVERRIDE)

#define _SVAR(name, global, cur, persist) char *global = svariable(#name, cur, &global, NULL, persist)
#define SVARN(name, global, cur) _SVAR(name, global, cur, 0)
#define SVARNP(name, global, cur) _SVAR(name, global, cur, IDF_PERSIST)
#define SVARNR(name, global, cur) _SVAR(name, global, cur, IDF_OVERRIDE)
#define SVAR(name, cur) _SVAR(name, name, cur, 0)
#define SVARP(name, cur) _SVAR(name, name, cur, IDF_PERSIST)
#define SVARR(name, cur) _SVAR(name, name, cur, IDF_OVERRIDE)
#define _SVARF(name, global, cur, body, persist) void var_##name(ident *id); char *global = svariable(#name, cur, &global, var_##name, persist); void var_##name(ident *id) { body; }
#define SVARFN(name, global, cur, body) _SVARF(name, global, cur, body, 0)
#define SVARF(name, cur, body) _SVARF(name, name, cur, body, 0)
#define SVARFP(name, cur, body) _SVARF(name, name, cur, body, IDF_PERSIST)
#define SVARFR(name, cur, body) _SVARF(name, name, cur, body, IDF_OVERRIDE)
#define SVARFNP(name, global, cur, body) _SVARF(name, global, cur, body, IDF_PERSIST)
#define SVARFNR(name, global, cur, body) _SVARF(name, global, cur, body, IDF_OVERRIDE)

// anonymous inline commands, uses nasty template trick with line numbers to keep names unique
// OF: unsafe variants
#define ICOMMANDNAME(name) _icmd_##name
#define ICOMMANDSNAME _icmds_
#define _ICOMMANDKNS(name, type, cmdname, nargs, proto, flags, b) template<int N> struct cmdname; template<> struct cmdname<__LINE__> { static bool init; static void run proto; }; bool cmdname<__LINE__>::init = addcommand(name, (identfun)cmdname<__LINE__>::run, nargs, type, flags); void cmdname<__LINE__>::run proto \
    { b; }
#define ICOMMANDKNS(name, type, cmdname, nargs, proto, b) _ICOMMANDKNS(name, type, cmdname, nargs, proto, IDF_SAFE, b)
#define ICOMMANDKNSU(name, type, cmdname, nargs, proto, b) _ICOMMANDKNS(name, type, cmdname, nargs, proto, 0, b)
#define ICOMMANDKN(name, type, cmdname, nargs, proto, b) ICOMMANDKNS(#name, type, cmdname, nargs, proto, b)
#define ICOMMANDKNU(name, type, cmdname, nargs, proto, b) ICOMMANDKNSU(#name, type, cmdname, nargs, proto, b)
#define ICOMMANDK(name, type, nargs, proto, b) ICOMMANDKN(name, type, ICOMMANDNAME(name), nargs, proto, b)
#define ICOMMANDKU(name, type, nargs, proto, b) ICOMMANDKNU(name, type, ICOMMANDNAME(name), nargs, proto, b)
#define ICOMMANDKS(name, type, nargs, proto, b) ICOMMANDKNS(name, type, ICOMMANDSNAME, nargs, proto, b)
#define ICOMMANDKSU(name, type, nargs, proto, b) ICOMMANDKNSU(name, type, ICOMMANDSNAME, nargs, proto, b)
#define ICOMMANDNS(name, cmdname, nargs, proto, b) ICOMMANDKNS(name, ID_COMMAND, cmdname, nargs, proto, b)
#define ICOMMANDNSU(name, cmdname, nargs, proto, b) ICOMMANDKNSU(name, ID_COMMAND, cmdname, nargs, proto, b)
#define ICOMMANDN(name, cmdname, nargs, proto, b) ICOMMANDNS(#name, cmdname, nargs, proto, b)
#define ICOMMANDNU(name, cmdname, nargs, proto, b) ICOMMANDNSU(#name, cmdname, nargs, proto, b)
#define ICOMMAND(name, nargs, proto, b) ICOMMANDN(name, ICOMMANDNAME(name), nargs, proto, b)
#define ICOMMANDU(name, nargs, proto, b) ICOMMANDNU(name, ICOMMANDNAME(name), nargs, proto, b)
#define ICOMMANDS(name, nargs, proto, b) ICOMMANDNS(name, ICOMMANDSNAME, nargs, proto, b)
#define ICOMMANDSU(name, nargs, proto, b) ICOMMANDNSU(name, ICOMMANDSNAME, nargs, proto, b)

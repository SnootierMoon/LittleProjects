enum EndCondition {
    END_EOF,
    END_PAREN,
};

struct DynamicString;
void DynamicString_init(struct DynamicString *str);
void DynamicString_append(struct DynamicString *str, char *to_add);
void DynamicString_free(struct DynamicString* str);
struct DynamicString {
    char* ptr;
    int len;
    int capacity;
};

struct HashEntry;
int HashEntry_cmpByAtom(struct HashEntry *h1, struct HashEntry *h2);
struct HashEntry {
    char *atom;
    int count;
    UT_hash_handle hh;
};

struct Context;
void Context_init(struct Context *ctx, char *formula);
void Context_free(struct Context *ctx);
void Context_addAtom(struct Context *ctx, char *atom, int count);
int Context_parseMolecule(struct Context *ctx, int multiplier);
int Context_parseExpr(struct Context *ctx, int multiplier, enum EndCondition end);
int Context_parse(struct Context *ctx);
char *Context_getCounts(struct Context *ctx);
struct Context {
    struct HashEntry *count_map;
    char *buffer;
    int pos;
};

void DynamicString_init(struct DynamicString *str) {
    str->ptr = malloc(16);
    str->ptr[0] = 0;
    str->len = 0;
    str->capacity = 16;
}

void DynamicString_append(struct DynamicString *str, char *to_add) {
    int to_add_len = strlen(to_add);

    if (str->capacity < str->len + to_add_len + 1) {
        do {
            str->capacity = 2 * str->capacity;
        } while (str->capacity < str->len + to_add_len + 1);

        str->ptr = realloc(str->ptr, str->capacity);
    }

    memcpy(str->ptr + str->len, to_add, to_add_len + 1);
    str->len += to_add_len;
}

void DynamicString_free(struct DynamicString* str) {
    free(str->ptr);
}

int HashEntry_cmpByAtom(struct HashEntry *h1, struct HashEntry *h2) {
    return strcmp(h1->atom, h2->atom);
}

void Context_init(struct Context *ctx, char *formula) {
    ctx->count_map = NULL;
    ctx->buffer = formula;
    ctx->pos = strlen(formula) - 1;
}

void Context_free(struct Context *ctx) {
    struct HashEntry *ent, *tmp;

    HASH_ITER(hh, ctx->count_map, ent, tmp) {
        HASH_DEL(ctx->count_map, ent);
        free(ent->atom);
        free(ent);
    }
}

void Context_addAtom(struct Context *ctx, char *atom, int count) {
    struct HashEntry *ent;

    HASH_FIND_STR(ctx->count_map, atom, ent);

    if (ent == NULL) {
        ent = malloc(sizeof(struct HashEntry));
        ent->atom = atom;
        ent->count = count;
        HASH_ADD_KEYPTR(hh, ctx->count_map, atom, strlen(atom), ent);
    } else {
        ent->count += count;
        free(atom);
    }
}

int Context_parseMole(struct Context *ctx, int multiplier) {
    if (ctx->buffer[ctx->pos] < 0) {
        return -1;
    } else if (isdigit(ctx->buffer[ctx->pos])) {
        do {
            ctx->pos--;
        } while (ctx->pos >= 0 && isdigit(ctx->buffer[ctx->pos]));
        int mult = (int)strtol(&ctx->buffer[ctx->pos] + 1, NULL, 10);
        return Context_parseMole(ctx, mult * multiplier);
    } else if (isalpha(ctx->buffer[ctx->pos])) {
        int end_pos = ctx->pos;
        while (ctx->pos > 0 && islower(ctx->buffer[ctx->pos])) {
            ctx->pos--;
        }
        if (!isupper(ctx->buffer[ctx->pos])) {
            return -1;
        } else {
            char *atom = strndup(&ctx->buffer[ctx->pos], end_pos - ctx->pos + 1);
            Context_addAtom(ctx, atom, multiplier);
            ctx->pos--;
            return 1;
        }
    } else if (ctx->buffer[ctx->pos] == ')') {
        ctx->pos--;
        if (Context_parseExpr(ctx, multiplier, END_PAREN) < 0) {
            return -1;
        } else {
            ctx->pos--;
            return 1;
        }
    } else {
        return -1;
    }
}

int Context_parseExpr(struct Context *ctx, int multiplier, enum EndCondition end) {
    while (ctx->pos >= 0 && ctx->buffer[ctx->pos] != '(') {
        if (Context_parseMole(ctx, multiplier) < 0) {
            return -1;
        }
    }

    return (ctx->pos < 0 && end == END_EOF || ctx->buffer[ctx->pos] == '(' && end == END_PAREN) ? 1 : -1;
}

int Context_parse(struct Context *ctx) {
    return Context_parseExpr(ctx, 1, END_EOF);
}

char *Context_getCounts(struct Context *ctx) {
    struct HashEntry *ent, *tmp;
    struct DynamicString result;
    char buf[11];
    DynamicString_init(&result);

    HASH_SORT(ctx->count_map, HashEntry_cmpByAtom);

    HASH_ITER(hh, ctx->count_map, ent, tmp) {
        DynamicString_append(&result, ent->atom);
        if (ent->count > 1) {
            sprintf(buf, "%d", ent->count);
            DynamicString_append(&result, buf);
        }
    }

    return result.ptr;
}

char *countOfAtoms(char *formula) {
    struct Context ctx;
    Context_init(&ctx, formula);

    if (Context_parse(&ctx) < 0) {
        Context_free(&ctx);
        printf("PARSE FAILURE");
        return NULL;
    }

    char *result = Context_getCounts(&ctx);
    Context_free(&ctx);

    return result;
}

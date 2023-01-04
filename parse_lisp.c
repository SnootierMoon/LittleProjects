#include <stdbool.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct StringSlice {
    char* ptr;
    int len;
};

bool string_slice_cmp(struct StringSlice s1, struct StringSlice s2) {
    return s1.len == s2.len && !memcmp(s1.ptr, s2.ptr, s1.len);
}

struct Item {
    enum ItemKind { ITEM_ADD, ITEM_MULT, ITEM_LET, ITEM_NUM } kind;
    union {
        struct { int val; bool first; } add;
        struct { int val; bool first; } mult;
        struct { int val; } num;
        struct { int var_count; struct StringSlice var_name; } let;
    };
};

struct ItemStack {
    struct Item* ptr;
    int capacity;
    int len;
};

struct ItemStack item_stack_new() {
    struct ItemStack stack;
    stack.ptr = malloc(sizeof(struct Item));
    stack.capacity = 1;
    stack.len = 0;
    return stack;
}

void item_stack_delete(struct ItemStack* stack) {
    free(stack->ptr);
}

void item_stack_push(struct ItemStack* stack, struct Item i) {
    if (stack->len == stack->capacity) {
        stack->capacity = 2 * stack->capacity;
        stack->ptr = realloc(stack->ptr, stack->capacity * sizeof(struct Item));
    }
    stack->ptr[stack->len] = i;
    stack->len++;
}

struct Item item_stack_pop(struct ItemStack* stack) {
    stack->len--;
    return stack->ptr[stack->len];
}

struct Item* item_stack_top(struct ItemStack* stack) {
    return &stack->ptr[stack->len - 1];
}

struct Var {
    struct StringSlice name;
    int val;
};

struct VarStack {
    struct Var* ptr;
    int capacity;
    int len;
};

struct VarStack var_stack_new() {
    struct VarStack stack;
    stack.ptr = malloc(sizeof(struct Var));
    stack.capacity = 1;
    stack.len = 0;
    return stack;
}

void var_stack_delete(struct VarStack* stack) {
    free(stack->ptr);
}

void var_stack_push(struct VarStack* stack, struct StringSlice var_name, int val) {
    if (stack->len == stack->capacity) {
        stack->capacity = 2 * stack->capacity;
        stack->ptr = realloc(stack->ptr, stack->capacity * sizeof(struct Item));
    }
    struct Var v;
    v.name = var_name;
    v.val = val;
    stack->ptr[stack->len] = v;
    stack->len++;
}

void var_stack_pop(struct VarStack* stack, int count) {
    stack->len -= count;
}

int var_stack_find(struct VarStack* stack, struct StringSlice name) {
    for (int i = stack->len - 1; i >= 1; i--) {
        if (string_slice_cmp(name, stack->ptr[i].name)) {
            return stack->ptr[i].val;
        }
    }
    return stack->ptr[0].val;
}

int evaluate(const char* input) {
    int pos = 0;

    struct ItemStack items = item_stack_new();
    struct VarStack vars = var_stack_new();
    
    while (true) {
        int val = 0;
        bool sign = input[pos] == '-';
        if (sign) pos++;
        if (isdigit(input[pos])) {
            do {
                val = 10 * val + (sign ? -(int)(input[pos] - '0') : (int)(input[pos] - '0'));
                pos++;
            } while (isdigit(input[pos]));
        } else if (input[pos] == ')') {
            pos++;
            val = item_stack_pop(&items).num.val;
        } else if (isalpha(input[pos])) {
            int start_pos = pos;
            do {
                pos++;
            } while (isalnum(input[pos]));
            struct StringSlice slice;
            slice.ptr = &input[start_pos];
            slice.len = pos - start_pos;

            struct Item* top = item_stack_top(&items);
            if (input[pos] == ')' || top->kind != ITEM_LET || top->let.var_name.ptr != NULL) {
                val = var_stack_find(&vars, slice);
            } else {
                top->let.var_name = slice;
                pos++;
                continue;
            }
        } else if (input[pos + 1] == 'a') {
            pos += 5;
            struct Item i;
            i.kind = ITEM_ADD;
            i.add.val = 0;
            i.add.first = true;
            item_stack_push(&items, i);
            continue;
        } else if (input[pos + 1] == 'm') {
            pos += 6;
            struct Item i;
            i.kind = ITEM_MULT;
            i.mult.val = 0;
            i.mult.first = true;
            item_stack_push(&items, i);
            continue;
        } else if (input[pos + 1] == 'l') {
            pos += 5;
            struct Item i;
            i.kind = ITEM_LET;
            i.let.var_name.ptr = NULL;
            i.let.var_count = 0;
            item_stack_push(&items, i);
            continue;
        }

        if (items.len == 0) {
            item_stack_delete(&items);
            var_stack_delete(&vars);
            return val;
        } else {
            struct Item* i = item_stack_top(&items);
            switch (i->kind) {
                case ITEM_ADD:
                    if (i->add.first) {
                        i->add.val = val;
                        pos++;
                        i->add.first = false;
                    } else {
                        int sum = i->add.val + val;
                        i->kind = ITEM_NUM;
                        i->num.val = sum;
                    }
                    break;
                case ITEM_MULT:
                    if (i->mult.first) {
                        i->mult.val = val;
                        pos++;
                        i->mult.first = false;
                    } else {
                        int sum = i->mult.val * val;
                        i->kind = ITEM_MULT;
                        i->mult.val = sum;
                    }
                    break;
                case ITEM_LET:
                    if (i->let.var_name.ptr != NULL) {
                        var_stack_push(&vars, i->let.var_name, val);
                        i->let.var_name.ptr = NULL;
                        i->let.var_count++;
                        pos++;
                    } else {
                        var_stack_pop(&vars, i->let.var_count);
                        i->kind = ITEM_NUM;
                        i->num.val = val;
                    }
                    break;
            }
        }
    }
}

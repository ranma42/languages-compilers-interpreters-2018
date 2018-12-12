struct vector;
void vector_init(struct vector *v);
void vector_grow(struct vector *v, size_t n);
void vector_fini(struct vector *v);
void *vector_get(struct vector *v, size_t idx);
void vector_set(struct vector *v, size_t idx, void *x);

struct string_int;
void string_int_init(struct string_int *v);
void string_int_fini(struct string_int *v);
void string_int_resize(struct string_int *v, size_t n);
size_t string_int_get(struct string_int *v, const char *key);
const char *string_int_rev(struct string_int *v, size_t id);

extern struct string_int global_ids;
extern struct vector global_types;

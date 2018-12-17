#include <stdlib.h>
#include <string.h>

static size_t hash(const char *s) {
  size_t r = 0xcbf29ce484222325;
  while (*s) {
    r *= 0x100000001b3;
    r ^= *s;
    s++;
  }

  return r;
}

/* vector */

struct vector {
  size_t capacity;
  void **data;
};

void vector_init(struct vector *v) {
  v->capacity = 16;
  v->data = calloc(v->capacity, sizeof(v->data[0]));
}

void vector_grow(struct vector *v, size_t n) {
  if (n < v->capacity) {
    return;
  }
  v->data = realloc(v->data, n * sizeof(v->data[0]));
  for (size_t i = v->capacity; i < n; i++) {
    v->data[0] = NULL;
  }
  v->capacity = n;
}

void vector_fini(struct vector *v) {
  free(v->data);
}

void *vector_get(struct vector *v, size_t idx) {
  vector_grow(v, idx + 1);
  return v->data[idx];
}

void vector_set(struct vector *v, size_t idx, void *x) {
  vector_grow(v, idx + 1);
  v->data[idx] = x;
}

/* string_int */

struct string_int {
  struct vector rev;
  size_t count;
  size_t capacity;
  struct kv {
    char *key;
    int id;
  } *data;
};

void string_int_init(struct string_int *v) {
  vector_init(&v->rev);
  v->count = 0;
  v->capacity = 16;
  v->data = calloc(v->capacity, sizeof(v->data[0]));
}

void string_int_fini(struct string_int *v) {
  vector_fini(&v->rev);
  for (size_t i = 0; i < v->capacity; i++) {
    free(v->data[i].key);
  }

  free(v->data);
}

void string_int_resize(struct string_int *v, size_t n) {
  struct kv *newdata = calloc(n, sizeof(v->data[0]));

  for (size_t i = 0; i < v->capacity; i++) {
    char *key = v->data[i].key;
    if (key) {
      size_t idx = hash(key);
      while (newdata[idx % n].key) {
        idx++;
      }
      newdata[idx % n].key = v->data[i].key;
      newdata[idx % n].id = v->data[i].id;
    }
  }
  free(v->data);
  v->data = newdata;
  v->capacity = n;
}

size_t string_int_get(struct string_int *v, const char *key) {
  size_t idx;

  if (2 * v->count >= v->capacity) {
    string_int_resize(v, 2 * v->count);
  }

  for (idx = hash(key) % v->capacity; v->data[idx].key; idx = (idx + 1) % v->capacity) {
    if (!strcmp(v->data[idx].key, key)) {
      return v->data[idx].id;
    }
  }

  size_t id = v->count++;
  char *k = strdup(key);

  v->data[idx].id = id;
  v->data[idx].key = k;
  vector_set(&v->rev, id, k);

  return id;
}

const char *string_int_rev(struct string_int *v, size_t id) {
  return vector_get(&v->rev, id);
}

struct string_int global_ids;
struct vector global_types;

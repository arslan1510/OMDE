#pragma once

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct OmdeIndex OmdeIndex;

OmdeIndex *omde_index_new(void);
void omde_index_free(OmdeIndex *index);
void omde_index_clear(OmdeIndex *index);
void omde_index_add(OmdeIndex *index, const char *name, const char *words, const char *key);
size_t omde_index_rank(OmdeIndex *index, const char *query, size_t limit,
                       const char *const *boost_keys, const int *boost_values,
                       size_t boost_count, size_t *out_indices);

#ifdef __cplusplus
}
#endif

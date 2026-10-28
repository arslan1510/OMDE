use nucleo_matcher::pattern::{Atom, AtomKind, CaseMatching, Normalization};
use nucleo_matcher::{Config, Matcher, Utf32Str};

use std::collections::HashMap;
use std::ffi::{c_char, CStr};

struct Entry {
    name: String,
    lower: String,
    lower_len: usize,
    words: String,
    key: String,
}

impl Entry {
    fn new(name: &str, words: &str, key: &str) -> Self {
        let lower = name.to_lowercase();
        Self {
            name: name.to_owned(),
            lower_len: lower.chars().count(),
            lower,
            words: words.to_owned(),
            key: key.to_owned(),
        }
    }
}

pub struct Index {
    entries: Vec<Entry>,
    matcher: Matcher,
}

impl Default for Index {
    fn default() -> Self {
        Self::new()
    }
}

impl Index {
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            matcher: Matcher::new(Config::DEFAULT),
        }
    }

    pub fn clear(&mut self) {
        self.entries.clear();
    }

    pub fn add(&mut self, name: &str, words: &str, key: &str) {
        self.entries.push(Entry::new(name, words, key));
    }

    pub fn count(&self) -> usize {
        self.entries.len()
    }

    pub fn rank(&mut self, query: &str, limit: usize, boosts: &HashMap<String, i32>) -> Vec<usize> {
        if limit == 0 {
            return Vec::new();
        }

        // With no query, history boosts set the order; ties keep insertion order.
        if query.trim().is_empty() {
            let mut ranked: Vec<(usize, i32)> = (0..self.entries.len())
                .map(|i| (i, boosts.get(&self.entries[i].key).copied().unwrap_or(0)))
                .collect();
            if !boosts.is_empty() {
                ranked.sort_unstable_by(|a, b| b.1.cmp(&a.1).then_with(|| a.0.cmp(&b.0)));
            }
            ranked.truncate(limit);
            return ranked.into_iter().map(|(index, _)| index).collect();
        }

        // Smart case first; if that misses, retry case-insensitively at 3/4 score.
        let strict = parse_query(query, CaseMatching::Smart);
        let loose = parse_query(query, CaseMatching::Ignore);
        if strict.is_empty() {
            return Vec::new();
        }

        let mut ranked = Vec::new();
        let mut buf = Vec::new();
        let entries = &self.entries;
        let matcher = &mut self.matcher;
        for (index, entry) in entries.iter().enumerate() {
            if let Some(score) = score_entry(matcher, &strict, &loose, entry, &mut buf) {
                let boost = boosts.get(&entry.key).copied().unwrap_or(0);
                ranked.push((index, score + boost));
            }
        }
        // Sort by score, breaking ties by name length, alphabetically, then insertion order.
        ranked.sort_unstable_by(|a, b| {
            b.1.cmp(&a.1)
                .then_with(|| entries[a.0].lower_len.cmp(&entries[b.0].lower_len))
                .then_with(|| entries[a.0].lower.cmp(&entries[b.0].lower))
                .then_with(|| a.0.cmp(&b.0))
        });
        ranked.truncate(limit);
        ranked.into_iter().map(|(index, _)| index).collect()
    }
}

fn parse_query(query: &str, case: CaseMatching) -> Vec<Atom> {
    query
        .split_whitespace()
        .filter_map(|raw| {
            // A leading ' matches substrings and ^ matches prefixes; anything else is fuzzy.
            let (kind, text) = if raw.len() > 1 {
                match raw.as_bytes()[0] {
                    b'\'' => (AtomKind::Substring, &raw[1..]),
                    b'^' => (AtomKind::Prefix, &raw[1..]),
                    _ => (AtomKind::Fuzzy, raw),
                }
            } else {
                (AtomKind::Fuzzy, raw)
            };
            if text.is_empty() {
                return None;
            }
            let case = if kind == AtomKind::Fuzzy {
                case
            } else {
                CaseMatching::Ignore
            };
            Some(Atom::new(text, case, Normalization::Smart, kind, true))
        })
        .collect()
}

fn score_entry(
    matcher: &mut Matcher,
    strict: &[Atom],
    loose: &[Atom],
    entry: &Entry,
    buf: &mut Vec<char>,
) -> Option<i32> {
    // Try the name first, then fall back to the extra words.
    let mut total = 0;
    for (i, atom) in strict.iter().enumerate() {
        let score = atom
            .score(Utf32Str::new(&entry.name, buf), matcher)
            .or_else(|| {
                let atom = loose.get(i)?;
                atom.score(Utf32Str::new(&entry.name, buf), matcher)
                    .map(|score| score * 3 / 4)
            })
            .or_else(|| atom.score(Utf32Str::new(&entry.words, buf), matcher))
            .or_else(|| {
                let atom = loose.get(i)?;
                atom.score(Utf32Str::new(&entry.words, buf), matcher)
                    .map(|score| score * 3 / 4)
            })?;
        total += i32::from(score);
    }
    Some(total)
}

unsafe fn text(value: *const c_char) -> String {
    if value.is_null() {
        String::new()
    } else {
        CStr::from_ptr(value).to_string_lossy().into_owned()
    }
}

#[no_mangle]
pub extern "C" fn omde_index_new() -> *mut Index {
    Box::into_raw(Box::new(Index::new()))
}

#[no_mangle]
pub unsafe extern "C" fn omde_index_free(index: *mut Index) {
    if !index.is_null() {
        drop(Box::from_raw(index));
    }
}

#[no_mangle]
pub unsafe extern "C" fn omde_index_clear(index: *mut Index) {
    if let Some(index) = index.as_mut() {
        index.clear();
    }
}

#[no_mangle]
pub unsafe extern "C" fn omde_index_add(
    index: *mut Index,
    name: *const c_char,
    words: *const c_char,
    key: *const c_char,
) {
    if let Some(index) = index.as_mut() {
        let (name, words, key) = (text(name), text(words), text(key));
        index.add(&name, &words, &key);
    }
}

#[no_mangle]
pub unsafe extern "C" fn omde_index_rank(
    index: *mut Index,
    query: *const c_char,
    limit: usize,
    boost_keys: *const *const c_char,
    boost_values: *const i32,
    boost_count: usize,
    out_indices: *mut usize,
) -> usize {
    let Some(index) = index.as_mut() else {
        return 0;
    };
    if out_indices.is_null() {
        return 0;
    }

    let mut boosts = HashMap::new();
    if !boost_keys.is_null() && !boost_values.is_null() {
        for i in 0..boost_count {
            boosts.insert(text(*boost_keys.add(i)), *boost_values.add(i));
        }
    }

    let ranked = index.rank(&text(query), limit, &boosts);
    for (i, entry) in ranked.iter().enumerate() {
        *out_indices.add(i) = *entry;
    }
    ranked.len()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn index(names: &[&str]) -> Index {
        let mut index = Index::new();
        for name in names {
            index.add(name, "", name);
        }
        index
    }

    fn names(index: &mut Index, query: &str, limit: usize) -> Vec<String> {
        let boosts = HashMap::new();
        index
            .rank(query, limit, &boosts)
            .into_iter()
            .map(|i| index.entries[i].name.clone())
            .collect()
    }

    fn first(index: &mut Index, query: &str) -> Option<String> {
        names(index, query, index.count()).into_iter().next()
    }

    #[test]
    fn all_words_must_match() {
        let mut index = index(&["Firefox", "Firefox Browser", "Files", "Fish"]);
        assert_eq!(
            first(&mut index, "fi br").as_deref(),
            Some("Firefox Browser")
        );
    }

    #[test]
    fn subsequence_and_initials() {
        let mut index = index(&["Firefox", "Visual Studio Code"]);
        assert_eq!(first(&mut index, "ffx").as_deref(), Some("Firefox"));
        assert_eq!(
            first(&mut index, "vsc").as_deref(),
            Some("Visual Studio Code")
        );
    }

    #[test]
    fn smart_case_and_fallback() {
        let mut index = index(&["Fish", "Firefox", "FastFetch"]);
        assert_eq!(first(&mut index, "Fi").as_deref(), Some("Fish"));
        assert_eq!(first(&mut index, "FF").as_deref(), Some("FastFetch"));
    }

    #[test]
    fn operators() {
        let mut index = index(&["Fish", "Firefox", "Firefox Browser"]);
        assert_eq!(first(&mut index, "^fi").as_deref(), Some("Fish"));
        assert_eq!(first(&mut index, "'fox").as_deref(), Some("Firefox"));
    }

    #[test]
    fn words_match_after_name() {
        let mut index = Index::new();
        index.add("Firefox", "Browser", "firefox");
        assert_eq!(first(&mut index, "browser").as_deref(), Some("Firefox"));
    }

    #[test]
    fn empty_query_keeps_insertion_order_and_uses_boosts() {
        let mut index = index(&["C", "A", "B"]);
        assert_eq!(names(&mut index, "", 3), ["C", "A", "B"]);

        let mut boosts = HashMap::new();
        boosts.insert("B".to_owned(), 10);
        let ranked: Vec<_> = index
            .rank("", 3, &boosts)
            .into_iter()
            .map(|i| index.entries[i].name.clone())
            .collect();
        assert_eq!(ranked, ["B", "C", "A"]);
    }

    #[test]
    fn clear_and_limit() {
        let mut index = index(&["A", "B", "C"]);
        assert_eq!(names(&mut index, "", 2).len(), 2);
        index.clear();
        assert_eq!(index.count(), 0);
        assert!(names(&mut index, "a", 10).is_empty());
    }

    #[test]
    fn whitespace_query_is_empty_query() {
        let mut index = index(&["C", "A", "B"]);
        assert_eq!(names(&mut index, "   ", 3), ["C", "A", "B"]);
    }

    #[test]
    fn name_match_beats_words_match() {
        let mut index = Index::new();
        index.add("Browser", "", "browser");
        index.add("Firefox", "Browser", "firefox");
        assert_eq!(first(&mut index, "browser").as_deref(), Some("Browser"));
    }

    #[test]
    fn name_and_words_can_match_different_terms() {
        let mut index = Index::new();
        index.add("Firefox", "Browser", "firefox");
        assert_eq!(first(&mut index, "fire brow").as_deref(), Some("Firefox"));
    }

    #[test]
    fn operators_ignore_case() {
        let mut index = index(&["Fish", "GIMP"]);
        assert_eq!(first(&mut index, "^FI").as_deref(), Some("Fish"));
        assert_eq!(first(&mut index, "'IM").as_deref(), Some("GIMP"));
    }

    #[test]
    fn boost_ties_keep_insertion_order() {
        let mut index = index(&["A", "B"]);
        let boosts = HashMap::from([("A".to_owned(), 5), ("B".to_owned(), 5)]);
        let ranked: Vec<_> = index
            .rank("", 2, &boosts)
            .into_iter()
            .map(|i| index.entries[i].name.clone())
            .collect();
        assert_eq!(ranked, ["A", "B"]);
    }

    #[test]
    fn unknown_boost_key_is_ignored() {
        let mut index = index(&["A", "B"]);
        let boosts = HashMap::from([("missing".to_owned(), 100)]);
        assert_eq!(names(&mut index, "", 2), ["A", "B"]);
        assert_eq!(index.rank("", 2, &boosts).len(), 2);
    }

    #[test]
    fn ffi_handles_null_pointers() {
        unsafe {
            let mut out = [0usize; 2];
            assert_eq!(
                omde_index_rank(
                    std::ptr::null_mut(),
                    std::ptr::null(),
                    2,
                    std::ptr::null(),
                    std::ptr::null(),
                    0,
                    out.as_mut_ptr()
                ),
                0
            );

            let index = omde_index_new();
            assert_eq!(
                omde_index_rank(
                    index,
                    std::ptr::null(),
                    2,
                    std::ptr::null(),
                    std::ptr::null(),
                    0,
                    std::ptr::null_mut()
                ),
                0
            );

            omde_index_add(
                index,
                b"Firefox\0".as_ptr() as *const c_char,
                std::ptr::null(),
                std::ptr::null(),
            );
            let found = omde_index_rank(
                index,
                std::ptr::null(),
                2,
                std::ptr::null(),
                std::ptr::null(),
                0,
                out.as_mut_ptr(),
            );
            assert_eq!(found, 1);
            assert_eq!(out[0], 0);

            omde_index_clear(index);
            assert_eq!((*index).count(), 0);
            omde_index_free(index);
            omde_index_free(std::ptr::null_mut());
        }
    }

    #[test]
    fn unicode_normalization() {
        let mut index = index(&["Äpfel"]);
        assert_eq!(first(&mut index, "äpfel").as_deref(), Some("Äpfel"));
    }
}

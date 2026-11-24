# Multilingual learning content

Tomo keeps canonical learning content at `schemaVersion: 1`. Multilingual
support is additive: all new properties are optional, so existing canonical
and legacy N2 JSON continues to decode without migration.

Vocabulary and kanji may add an `explanation` object with `ja`, `en`, and `my`
keys. Examples keep the legacy English `translation` string and may add a
`translations` object using the same language keys. When both exist, an
explicit English value in `translations.en` takes precedence over the legacy
string.

Grammar keeps its existing string `explanation` property. New content uses the
optional `explanations` object to avoid changing the published field type. The
legacy string participates as the English fallback in the app.

Content resolution follows the selected language, then English, then Japanese.
The resolved value retains its actual language so fallback text is labeled
correctly. Japanese explanations are shown independently whenever authored,
and original Japanese example sentences are always shown.

The app preference `explanation_language` stores `ja`, `en`, or `my`. Missing
or unknown stored values default to English. Navigation labels are outside this
content-language preference.

The pilot fixture under `test/fixtures` is not production content. It includes
intentional translation gaps and requires human language review before reuse.

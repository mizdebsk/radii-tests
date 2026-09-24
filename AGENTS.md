Code style
----------

Keep code simple and readable. Prefer self-documenting code; add comments
only to explain non-obvious behavior or decisions.

Shell scripts
-------------

Keep shell code close to Bourne shell style. Light Bash features, such as
`[[ ... ]]`, `set -o pipefail`, and `shopt`, are welcome when they improve
readability. Avoid arrays and other complex Bash-specific constructs.

Test conventions
----------------

Use BeakerLib for tests and shared test libraries.
Follow Beaker naming conventions, including `runtest.sh`, `lib.sh`, and
`Library/`, `Sanity/`, and `Regression/` directories as appropriate.

Commit messages
---------------

Use ASCII only. Require an imperative subject starting with a capital
letter, without markup or a trailing period. Aim for at most 50 characters.

Add body paragraphs only as needed, separated from the subject by a blank
line and wrapped at 72 characters. Be concise; inline code and emphasis
markup are allowed in the body.

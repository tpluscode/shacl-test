# SHACL-test

Runs SHACL shapes against a set of positive and negative test cases (data graphs).

Positive test cases are a simple fail/pass.
Negative test cases are expected to fail and the validation report is compared against the
expectation using [approvals](https://npm.im/approvals).

In case of failures, a [SHACL Playground](https://shacl-playground.zazuko.com) 
link is provided for further investigation.

## Usage

```sh
npx shacl-test \
  --shapes=${SHAPES} \
  --valid-cases="${VALID_CASES_GLOB}" \
  --invalid-cases="${INVALID_CASES_GLOB}" \
  --filter="${FILTER}" \
  --approve \
  --debug \
  --prefixes=${PREFIXES} \
  --command="${COMMAND}"
```

The `--shapes` option is required. 
Also, you must provide at least `--valid-cases` or `--invalid-cases`, lest no tests are run. 
The rest are optional.

`--shapes` can be a filesystem path or URL and include [`code:imports`](https://github.com/zazuko/rdf-transform-graph-imports).

`--valid-cases` and `--invalid-cases` are globs that match the test cases. 
Make sure to put them in quotes to avoid shell expansion.

`--filter` is a regular expression to filter the test cases.

`--approve` will approve the validation reports for the negative test cases instead of failing.

`--debug` will print the validation report for each test case.

`--prefixes` is a comma-separated list of prefix declarations to be used in the SHACL shapes.
For example, `--prefixes=schema,qudt,cube=https://cube.link/`, will declare the prefixes
`schema`, `qudt` and `cube` with the respective URIs. In the case of `schema` and `qudt`, their
URIs are taken from the list provided by the [`@zazuko/prefixes`](https://github.com/zazuko/rdf-vocabularies/blob/master/packages/prefixes/prefixes.ts) package (and, by extension, the [Zazuko prefix server](https://prefix.zazuko.com)).

`--command` is a command to run for each test case. It will be passed the shapes path as argument and the test case on standard input. The default is `npx barnard59 shacl validate --shapes`, which translates to `npx barnard59 shacl validate --shapes ${shapes} < $testCase`. The script must return a non-zero exit code if the test case is invalid.


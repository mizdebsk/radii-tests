Mock RPMs and repositories
=========================

Import with `rlImport radii/mock-rpms`. Declare a local library requirement
with `name: /Library/mock-rpms` and `nick: radii` in the test metadata.

Call helpers directly inside BeakerLib phases. They record assertions and
return nonzero on failure:

```sh
radiiMockInit
radiiMakeRepo drivers
radiiMakeRepo extras --disabled
radiiBuildRpm drivers empty --define 'mock_name example' --define 'mock_version 1.0'
radiiExposeRepos
# Run scenario assertions here.
radiiMockCleanup
```

Specs live in `specs/`; the build helper takes their basename without
`.spec`. All binary RPMs from a build go to the selected repository.
Each test gets a temporary workspace in `radiiMockRoot`. Exposing creates
metadata for every repository and a temporary file in `/etc/yum.repos.d`,
whose path is `radiiMockRepoFile`. It preserves each repository's enabled
setting. Call cleanup in the test's cleanup phase to remove both the repo
file and workspace. Other repositories are left unchanged.

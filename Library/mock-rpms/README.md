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

NVIDIA fixtures
---------------

```sh
radiiBuildNvidiaDriver drivers 580.178.04
# For installation tests, use this instead of the driver-only fixture:
radiiBuildNvidiaStack drivers 580.178.04
radiiBuildNvidiaKmod drivers 580.178.04 6.12.0-211.51.1.el10_2 default
radiiBuildNvidiaKmod drivers 580.178.04 6.12.0-211.51.1.el10_2 64k --target aarch64
```

The driver is an empty package for version discovery, not a complete NVIDIA
stack. Kmod packages preserve the supplied template's dependency metadata,
including conditional kernel requirements. The 64k package also provides
`kmod-64k-nvidia-open`, modeling the intended packaging fix. Neither fixture
contains functional drivers or runs module-management scriptlets.

`radiiBuildNvidiaStack` adds empty companion packages requested by radii and
basic version dependencies. Its driver requires the matching `nvidia-kmod`
provide, so build a kmod fixture separately. These packages do not reproduce
the complete dependency graph or functionality of the real NVIDIA stack.

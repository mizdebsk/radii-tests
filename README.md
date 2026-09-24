radii-tests
===========

Integration tests for [radii](https://github.com/mizdebsk/radii), the
hardware driver manager for Linux, and related RPM packages. Tests
exercise installed packages and their interaction with the system.

This repository contains tests implemented in shell using the
[BeakerLib](https://beakerlib.readthedocs.io/en/latest/) framework and
annotated with [tmt](https://tmt.readthedocs.io/en/stable/) metadata for
integration with [Testing Farm](https://testing-farm.io/).

This repository contains tmt tests only, not tmt test plans. Test plans
are maintained by Linux distributions.

Licensed under GPL v3 or later.

Examples
--------

For details on running tests with tmt, refer to the
[tmt documentation](https://tmt.readthedocs.io/en/stable/).

Run all tests on a remote guest accessible over SSH:

```sh
tmt run -a provision --how connect --guest 192.168.122.10 report -vv
```

Run a specific test:

```sh
tmt run -a tests --name '^/Sanity/list$' provision --how connect --guest 192.168.122.10 report -vv
```

List the available tests:

```sh
tmt tests ls
```

load("@bazel_features//:features.bzl", "bazel_features")
load("@hermetic_cc_toolchain//toolchain:defs.bzl", zig_toolchains = "toolchains")

_exec_platform = tag_class(
    attrs = {
        "os": attr.string(
            values = ["linux", "windows", "macos"],
            mandatory = True,
        ),
        "arch": attr.string(
            values = ["amd64", "arm64"],
            mandatory = True,
        ),
    },
    doc = "Zig execution platform tuple",
)

def _toolchains_impl(mctx):
    exec_platforms = {}
    root_direct_deps = []
    root_direct_dev_deps = []
    is_non_dev_dependency = mctx.root_module_has_non_dev_dependency

    for mod in mctx.modules:
        if mod.is_root:
            for ep in mod.tags.exec_platform:
                _archs = exec_platforms.get(ep.os, list())
                if ep.arch not in _archs:
                    _archs.append(ep.arch)
                exec_platforms[ep.os] = _archs

            repos = zig_toolchains(exec_platforms = exec_platforms)

            root_direct_deps = list(repos.public) if is_non_dev_dependency else []
            root_direct_dev_deps = list(repos.public) if not is_non_dev_dependency else []

    metadata_kwargs = {}
    if bazel_features.external_deps.extension_metadata_has_reproducible:
        metadata_kwargs["reproducible"] = True

    return mctx.extension_metadata(
        root_module_direct_deps = root_direct_deps,
        root_module_direct_dev_deps = root_direct_dev_deps,
        **metadata_kwargs
    )

toolchains = module_extension(
    implementation = _toolchains_impl,
    tag_classes = {"exec_platform": _exec_platform},
)

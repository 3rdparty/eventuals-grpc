"""Adds repostories/archives."""

########################################################################
# DO NOT EDIT THIS FILE unless you are inside the
# https://github.com/3rdparty/stout-eventuals repository. If you
# encounter it anywhere else it is because it has been copied there in
# order to simplify adding transitive dependencies. If you want a
# different version of stout-eventuals follow the Bazel build
# instructions at https://github.com/3rdparty/stout-eventuals.
########################################################################

load("//3rdparty/bazel-rules-libuv:repos.bzl", libuv_repos = "repos")
load("//3rdparty/bazel-rules-curl:repos.bzl", curl_repos = "repos")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

def repos(external = True, repo_mapping = {}):
    libuv_repos(
        repo_mapping = repo_mapping,
    )

    curl_repos(
        repo_mapping = repo_mapping,
    )

    if external:
        maybe(
            git_repository,
            name = "com_github_3rdparty_stout_eventuals",
            remote = "https://github.com/3rdparty/stout-eventuals",
            commit = "6b9865a9bade8deb81258249766270c213e6df99",
            shallow_since = "1633608622 +0300",
            repo_mapping = repo_mapping,
        )

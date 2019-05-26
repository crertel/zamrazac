# zamrazac
Opinionated elixir state site generator for single-file HTML posts

## Usage

Clone this using git.

I mostly reccommend you talking to it via shell scripts like:

```bash
#! /bin/bash

# Script to create a post given a string title.

set -eou pipefail

BLOG_AUTHOR="Your Name"
BLOG_DIRECTORY="$HOME/.blog"
BLOG_BUILD_PATH="$HOME/.blog_output"
ZAMRAZAC_PATH="$HOME/projects/zamrazac" # or wherever you cloned it to

mkdir -p "$BLOG_DIRECTORY"
mkdir -p "$BLOG_BUILD_PATH"

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "" > /dev/null
}

pushd "$ZAMRAZAC_PATH"
BLOG_DIRECTORY="$BLOG_DIRECTORY" BLOG_AUTHOR="$BLOG_AUTHOR" mix zamrazac.create "$1"
popd
```

```bash
#! /bin/bash

# Script to run the blog creation pipeline.

set -eou pipefail

BLOG_TITLE="Swizzled Bits"
BLOG_DIRECTORY="$HOME/.blog"
BLOG_BUILD_PATH="$HOME/.blog_output"
ZAMRAZAC_PATH="$HOME/projects/zamrazac" # or wherever you cloned it to

mkdir -p "$BLOG_DIRECTORY"
mkdir -p "$BLOG_BUILD_PATH"

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "" > /dev/null
}

pushd "$ZAMRAZAC_PATH"
BLOG_TITLE="$BLOG_TITLE" BLOG_DIRECTORY="$BLOG_DIRECTORY" OUTPUT_DIRECTORY="$BLOG_BUILD_PATH" mix zamrazac.generate
popd
```
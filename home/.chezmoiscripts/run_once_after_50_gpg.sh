#!/bin/env bash

# .gnupg/pub.scottames.asc hash: {{ include ".gnupg/pub.scottames.asc" | sha256sum }}
gpg --import "${HOME}/.gnupg/pub.scottames.asc"

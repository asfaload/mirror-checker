# About

Asfaload maintains a mirror of checksums so they can be used to increase security of downloading files as both the mirror and published would have to be hacked to make you download a malicious file unknowingly. But why should you trust our mirror? The answer is easy: don't trust, verify!
With this script, you can verify that the mirror does not modify files once they've been committed.

# How

This script will simply maintain a git clone of the mirror, and will regularly pull from it, accepting only fast forward pulls. This means that if a commit you had downloaded if amended, the pull will fail.

# Deployment

Set the environment `BASE_DIR`, under which the script will store all its data, including the git clone of the checksums mirror.
You can run the script manually. If this is the first run it will clone the mirror repository in `$BASE_DIR/checksums` and enter a loop to regularly pull and update the index.html file generated at `$BASE_DIR/output/index.html`

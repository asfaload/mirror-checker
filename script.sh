#!/bin/bash
set -eux
#
# BASE_DIR needs to be defined in the enviroment, pointing
# to a persistent directory
[[ -d ${BASE_DIR?BASE_DIR needs to be defined and point to a persistent directory} ]] || {
  echo "BASE_DIR ${BASE_DIR} does not exist"
  exit 1
}

################################################################################
# On-time setup at startup
################################################################################
# location of the clone
GIT_DIR="$BASE_DIR/checksums"
# file registering results of the pull to be displayed
RESULTS="$BASE_DIR/results"
DIFFERING_CHECKSUMS="$BASE_DIR/differing_checksums"
# create file so an empty file returns wc -l equal to 0
touch "$DIFFERING_CHECKSUMS"
# pull calls output
LOGS="$BASE_DIR/logs"
# html file to be generated
INDEX="$BASE_DIR/output/index.html"
mkdir -p "$(dirname "$INDEX")"
# Number of lines to be displayed in "Previous statuses"
TABLE_LINES=5

# This is the cornerstone of this script: git will error out if a fast-forward
# is not possible when pulling.
git config --global pull.ff only

# Clone the repo if it isn't found locally
[[ -d "$GIT_DIR" ]] || git clone https://github.com/asfaload/checksums.git "$GIT_DIR"

# Never expire reflog, so we can report the time of the cloning
cd "$GIT_DIR"
git config gc.reflogExpire never

################################################################################
# Main function generating index.html
################################################################################
generate_index() {
  # Timestamp of this run
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%S%z)
  # record hash before the pull
  start_hash=$(git rev-parse HEAD)

  # issue the git pull and record its result
  if git pull >>"$LOGS"; then
    # pull was successfull, now check that the committed checksums are identical to released checksums
    checksums_validated="true"
    invalid_checksums=()
    pulled_hash=$(git rev-parse HEAD)
    if [[ $start_hash != "$pulled_hash" ]]; then
      # read output of the command in a bash array
      mapfile -t checksums_files < <(git diff --name-only "${start_hash}..${pulled_hash}" | grep -v asfaload.index.json)
      # iterate over files added in this pull
      for f in "${checksums_files[@]}"; do
        if ! diff "$f" <(curl -s -L "$f"); then
          checksums_validated="false"
          # collect invalid checksums
          invalid_checksums[$((${#invalid_checksums[@]} + 1))]="$f"

        fi
      done
    fi
    if [[ $checksums_validated = "true" ]]; then
      commit=$(git log -1 --pretty=format:"%h")
      commit_timestamp=$(git log -1 --pretty=format:"%ci")
      echo "<td>$timestamp</td><td>ok, commit <a href=\"https://github.com/asfaload/checksums/commit/$commit\">$commit</a> dated $commit_timestamp</td>" >>"$RESULTS"
    else
      msg="WARNING: checksums differ for these files: ${invalid_checksums[*]}"
      echo "<td>$timestamp</td><td>$msg</td>" >>"$RESULTS"
      printf '%s\n' "${invalid_checksums[@]}" >>"$DIFFERING_CHECKSUMS"
    fi
  else
    echo "<td>$timestamp</td><td>ERROR: $(git pull)</td>" >>"$RESULTS"
  fi

  # All subsequent commands will send their output to the new index file
  exec 1>>"$INDEX.new"

  # Output static part of html
  cat <<EOF
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="color-scheme" content="light dark">
    <link rel="stylesheet" href="css/pico.min.css">
    <title>Asfaload checksums repo check</title>
  </head>
  <body>
    <main class="container"><html>
<h1>Asfaload mirror integrity check</h1>
<p>This is an instance of a server keeping an eye on Asfaload's <a href="https://github.com/asfaload/checksums">checksums mirror</a>.
It pulls from the git repository, accepting only fast-forward pulls, which allows to detect if a previous commit was altered on the mirror.
</p>
<p>
In addition to that it also compares checksums files added to the repo since the previous pull against the original checksums files in their respoective releases.
A difference probably means that the release has been modified and a new checksums file was published. As the asfaload mirror is append-only, we report this
as a warning, but not as an error. Note however that these files will be rejected when downloaded with <a href="https://github.com/asfaload/asfald">asfald</a>.
</p>
<p>
All green lines report a successull pull, meaning no commit was edited after its publication.
If an error is detected, it will stay in error. It is not possible for it to go back to success and green lines if the remote repository has commit that was amended after its publication.
</p>
EOF

  # Display last status
  echo "<h1>Status</h1>"
  last=$(tail -n1 "$RESULTS")
  if [[ "$last" =~ "ERROR" ]]; then
    echo "<div style=\"background-color:lightcoral;max-width: fit-content; margin-left: auto; margin-right: auto;font-size:2em;\"><table><tr>$last</tr></table></div>"
  elif [[ "$last" =~ "WARNING" ]]; then
    echo "<div style=\"background-color:orange;max-width: fit-content; margin-left: auto; margin-right: auto;font-size:2em;\"><table><tr>$last</tr></table></div>"
  else
    echo "<div style=\"background-color:lightgreen;max-width: fit-content; margin-left: auto; margin-right: auto;font-size:2em;\"><table><tr>$last</tr></table></div>"
  fi

  # Display hashes that were different to release, meaning these were probably edited in the release

  differing_checksums_count=$(wc -l "$DIFFERING_CHECKSUMS" | cut -d ' ' -f 1)
  if [[ $differing_checksums_count -gt 0 ]]; then
    cat <<EOF
    <details><summary>Invalid checksums</summary>
    <p>Here are checksums that were detected as different on the mirror. This probably means they were updated in the release after the mirror was taken but before this
    checker ran</p>
    <pre>
    $(cat "$DIFFERING_CHECKSUMS")
    </pre>
    </details>
EOF
  fi

  # Display $TABLE_LINES previous statuses
  echo "<details><summary>Previous $TABLE_LINES statuses</summary>"
  echo "<table>"
  while read -r l; do
    if [[ "$l" =~ "ERROR" ]]; then
      echo "<tr style=\"background-color:lightcoral\">$l</tr>"
    elif [[ "$l" =~ "WARNING" ]]; then
      echo "<tr style=\"background-color:orange\">$l</tr>"
    else
      echo "<tr style=\"background-color:lightgreen\">$l</tr>"
    fi
  done < <(tac "$RESULTS" | tail -n +2 | head -n $TABLE_LINES)
  echo "</table></details>"

  # Clone information, giving date from which this instance validates the mirror
  cat <<EOF
<details><summary>Clone info</summary>
<p>
This gives you the date this instance cloned the checkums repo. It is from that time that this validator ensures there was no commit amended after its publication.
</p>
<pre>
EOF
  git reflog --date=iso | tail -n 1
  echo "</pre>"
  echo "<p>Since the clone, this instance validates $(($(git reflog | wc -l) - 1)) commits.</p>"
  echo "</details>"
  cat <<EOF
</main>
</body>
</html>
EOF

  # The index has been generated, move it to atomically replace the previous one.
  mv "$INDEX.new" "$INDEX"
}

# If althttpd is available, run it to listen on port 8080
[[ -x /usr/bin/althttpd ]] && /usr/bin/althttpd -root /data/output -port 8080 &

################################################################################
# Code running
################################################################################
while true; do
  generate_index
  sleep 60
done

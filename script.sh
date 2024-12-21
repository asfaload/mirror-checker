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

# Function to create the css file
function create_css {
  cat >"$(dirname "$INDEX")/main.css" <<EOF
// Milligram css with text color set to black
// https://github.com/milligram/milligram
*,*:after,*:before{box-sizing:inherit}html{box-sizing:border-box;font-size:62.5%}body{color:#000000;font-family:'Roboto', 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif;font-size:1.6em;font-weight:300;letter-spacing:.01em;line-height:1.6}blockquote{border-left:0.3rem solid #d1d1d1;margin-left:0;margin-right:0;padding:1rem 1.5rem}blockquote *:last-child{margin-bottom:0}.button,button,input[type='button'],input[type='reset'],input[type='submit']{background-color:#9b4dca;border:0.1rem solid #9b4dca;border-radius:.4rem;color:#fff;cursor:pointer;display:inline-block;font-size:1.1rem;font-weight:700;height:3.8rem;letter-spacing:.1rem;line-height:3.8rem;padding:0 3.0rem;text-align:center;text-decoration:none;text-transform:uppercase;white-space:nowrap}.button:focus,.button:hover,button:focus,button:hover,input[type='button']:focus,input[type='button']:hover,input[type='reset']:focus,input[type='reset']:hover,input[type='submit']:focus,input[type='submit']:hover{background-color:#606c76;border-color:#606c76;color:#fff;outline:0}.button[disabled],button[disabled],input[type='button'][disabled],input[type='reset'][disabled],input[type='submit'][disabled]{cursor:default;opacity:.5}.button[disabled]:focus,.button[disabled]:hover,button[disabled]:focus,button[disabled]:hover,input[type='button'][disabled]:focus,input[type='button'][disabled]:hover,input[type='reset'][disabled]:focus,input[type='reset'][disabled]:hover,input[type='submit'][disabled]:focus,input[type='submit'][disabled]:hover{background-color:#9b4dca;border-color:#9b4dca}.button.button-outline,button.button-outline,input[type='button'].button-outline,input[type='reset'].button-outline,input[type='submit'].button-outline{background-color:transparent;color:#9b4dca}.button.button-outline:focus,.button.button-outline:hover,button.button-outline:focus,button.button-outline:hover,input[type='button'].button-outline:focus,input[type='button'].button-outline:hover,input[type='reset'].button-outline:focus,input[type='reset'].button-outline:hover,input[type='submit'].button-outline:focus,input[type='submit'].button-outline:hover{background-color:transparent;border-color:#606c76;color:#606c76}.button.button-outline[disabled]:focus,.button.button-outline[disabled]:hover,button.button-outline[disabled]:focus,button.button-outline[disabled]:hover,input[type='button'].button-outline[disabled]:focus,input[type='button'].button-outline[disabled]:hover,input[type='reset'].button-outline[disabled]:focus,input[type='reset'].button-outline[disabled]:hover,input[type='submit'].button-outline[disabled]:focus,input[type='submit'].button-outline[disabled]:hover{border-color:inherit;color:#9b4dca}.button.button-clear,button.button-clear,input[type='button'].button-clear,input[type='reset'].button-clear,input[type='submit'].button-clear{background-color:transparent;border-color:transparent;color:#9b4dca}.button.button-clear:focus,.button.button-clear:hover,button.button-clear:focus,button.button-clear:hover,input[type='button'].button-clear:focus,input[type='button'].button-clear:hover,input[type='reset'].button-clear:focus,input[type='reset'].button-clear:hover,input[type='submit'].button-clear:focus,input[type='submit'].button-clear:hover{background-color:transparent;border-color:transparent;color:#606c76}.button.button-clear[disabled]:focus,.button.button-clear[disabled]:hover,button.button-clear[disabled]:focus,button.button-clear[disabled]:hover,input[type='button'].button-clear[disabled]:focus,input[type='button'].button-clear[disabled]:hover,input[type='reset'].button-clear[disabled]:focus,input[type='reset'].button-clear[disabled]:hover,input[type='submit'].button-clear[disabled]:focus,input[type='submit'].button-clear[disabled]:hover{color:#9b4dca}code{background:#f4f5f6;border-radius:.4rem;font-size:86%;margin:0 .2rem;padding:.2rem .5rem;white-space:nowrap}pre{background:#f4f5f6;border-left:0.3rem solid #9b4dca;overflow-y:hidden}pre>code{border-radius:0;display:block;padding:1rem 1.5rem;white-space:pre}hr{border:0;border-top:0.1rem solid #f4f5f6;margin:3.0rem 0}input[type='color'],input[type='date'],input[type='datetime'],input[type='datetime-local'],input[type='email'],input[type='month'],input[type='number'],input[type='password'],input[type='search'],input[type='tel'],input[type='text'],input[type='url'],input[type='week'],input:not([type]),textarea,select{-webkit-appearance:none;background-color:transparent;border:0.1rem solid #d1d1d1;border-radius:.4rem;box-shadow:none;box-sizing:inherit;height:3.8rem;padding:.6rem 1.0rem .7rem;width:100%}input[type='color']:focus,input[type='date']:focus,input[type='datetime']:focus,input[type='datetime-local']:focus,input[type='email']:focus,input[type='month']:focus,input[type='number']:focus,input[type='password']:focus,input[type='search']:focus,input[type='tel']:focus,input[type='text']:focus,input[type='url']:focus,input[type='week']:focus,input:not([type]):focus,textarea:focus,select:focus{border-color:#9b4dca;outline:0}select{background:url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 30 8" width="30"><path fill="%23d1d1d1" d="M0,0l6,8l6-8"/></svg>') center right no-repeat;padding-right:3.0rem}select:focus{background-image:url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 30 8" width="30"><path fill="%239b4dca" d="M0,0l6,8l6-8"/></svg>')}select[multiple]{background:none;height:auto}textarea{min-height:6.5rem}label,legend{display:block;font-size:1.6rem;font-weight:700;margin-bottom:.5rem}fieldset{border-width:0;padding:0}input[type='checkbox'],input[type='radio']{display:inline}.label-inline{display:inline-block;font-weight:normal;margin-left:.5rem}.container{margin:0 auto;max-width:112.0rem;padding:0 2.0rem;position:relative;width:100%}.row{display:flex;flex-direction:column;padding:0;width:100%}.row.row-no-padding{padding:0}.row.row-no-padding>.column{padding:0}.row.row-wrap{flex-wrap:wrap}.row.row-top{align-items:flex-start}.row.row-bottom{align-items:flex-end}.row.row-center{align-items:center}.row.row-stretch{align-items:stretch}.row.row-baseline{align-items:baseline}.row .column{display:block;flex:1 1 auto;margin-left:0;max-width:100%;width:100%}.row .column.column-offset-10{margin-left:10%}.row .column.column-offset-20{margin-left:20%}.row .column.column-offset-25{margin-left:25%}.row .column.column-offset-33,.row .column.column-offset-34{margin-left:33.3333%}.row .column.column-offset-40{margin-left:40%}.row .column.column-offset-50{margin-left:50%}.row .column.column-offset-60{margin-left:60%}.row .column.column-offset-66,.row .column.column-offset-67{margin-left:66.6666%}.row .column.column-offset-75{margin-left:75%}.row .column.column-offset-80{margin-left:80%}.row .column.column-offset-90{margin-left:90%}.row .column.column-10{flex:0 0 10%;max-width:10%}.row .column.column-20{flex:0 0 20%;max-width:20%}.row .column.column-25{flex:0 0 25%;max-width:25%}.row .column.column-33,.row .column.column-34{flex:0 0 33.3333%;max-width:33.3333%}.row .column.column-40{flex:0 0 40%;max-width:40%}.row .column.column-50{flex:0 0 50%;max-width:50%}.row .column.column-60{flex:0 0 60%;max-width:60%}.row .column.column-66,.row .column.column-67{flex:0 0 66.6666%;max-width:66.6666%}.row .column.column-75{flex:0 0 75%;max-width:75%}.row .column.column-80{flex:0 0 80%;max-width:80%}.row .column.column-90{flex:0 0 90%;max-width:90%}.row .column .column-top{align-self:flex-start}.row .column .column-bottom{align-self:flex-end}.row .column .column-center{align-self:center}@media (min-width: 40rem){.row{flex-direction:row;margin-left:-1.0rem;width:calc(100% + 2.0rem)}.row .column{margin-bottom:inherit;padding:0 1.0rem}}a{color:#9b4dca;text-decoration:none}a:focus,a:hover{color:#606c76}dl,ol,ul{list-style:none;margin-top:0;padding-left:0}dl dl,dl ol,dl ul,ol dl,ol ol,ol ul,ul dl,ul ol,ul ul{font-size:90%;margin:1.5rem 0 1.5rem 3.0rem}ol{list-style:decimal inside}ul{list-style:circle inside}.button,button,dd,dt,li{margin-bottom:1.0rem}fieldset,input,select,textarea{margin-bottom:1.5rem}blockquote,dl,figure,form,ol,p,pre,table,ul{margin-bottom:2.5rem}table{border-spacing:0;display:block;overflow-x:auto;text-align:left;width:100%}td,th{border-bottom:0.1rem solid #e1e1e1;padding:1.2rem 1.5rem}td:first-child,th:first-child{padding-left:0}td:last-child,th:last-child{padding-right:0}@media (min-width: 40rem){table{display:table;overflow-x:initial}}b,strong{font-weight:bold}p{margin-top:0}h1,h2,h3,h4,h5,h6{font-weight:300;letter-spacing:-.1rem;margin-bottom:2.0rem;margin-top:0}h1{font-size:4.6rem;line-height:1.2}h2{font-size:3.6rem;line-height:1.25}h3{font-size:2.8rem;line-height:1.3}h4{font-size:2.2rem;letter-spacing:-.08rem;line-height:1.35}h5{font-size:1.8rem;letter-spacing:-.05rem;line-height:1.5}h6{font-size:1.6rem;letter-spacing:0;line-height:1.4}img{max-width:100%}.clearfix:after{clear:both;content:' ';display:table}.float-left{float:left}.float-right{float:right}
EOF
}

create_css

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

<link rel="stylesheet" href="main.css" />
    <title>Asfaload checksums repo check</title>
  </head>
  <body>
    <main class="container">
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

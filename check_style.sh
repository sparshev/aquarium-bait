#!/bin/sh
# Copyright 2021-2025 Adobe. All rights reserved.
# Copyright 2025 Aquarium Developers. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Author: Sergei Parshev

# Script to simplify the style check process

bait_dir="$(cd $(dirname "$0"); echo "$PWD")"

# Use virtual env for yamllint and ansible-lint
. "${bait_dir}/scripts/require_venv.sh"

errors=0

echo
echo '---------------------- Custom Checks ----------------------'
echo
for f in $(git diff --name-only origin/main); do
    # Check text files
    if file "$f" | grep -q 'text'; then
        # Ends with newline as POSIX requires
        if [ -n "$(tail -c 1 "$f")" ]; then
            echo "Not ends with newline: $f"
            errors=$((${errors}+1))
        fi
        # Ansible step `register` variable starts with "reg_"
        if [ "$(grep 'register:' "$f" | grep -v 'register: reg_')" ]; then
            echo "Register variable not starts with 'reg_' prefix: $f"
            errors=$((${errors}+1))
        fi

        # Logic files: sh
        if echo "$f" | grep -q '\.\(sh\)$'; then
            # Should contain copyright
            if !(head -20 "$f" | grep -q 'Copyright 20.\+ Aquarium Developers. All rights reserved'); then
                echo "ERROR: Should contain Aquarium Developers copyright header: $f"
                errors=$((${errors} + 1))
            fi

            # Should contain license
            if !(head -20 "$f" | fgrep -q 'Apache License, Version 2.0'); then
                echo "ERROR: Should contain license name and version: $f"
                errors=$((${errors} + 1))
            fi

            #  Should contain Author
            if !(head -20 "$f" | grep -q 'Author: .\+'); then
                echo "ERROR: Should contain Author: $f"
                errors=$((${errors} + 1))
            fi

            # Copyright year in files should be the current year
            if !(head -20 "$f" | grep 'Copyright 20.\+ Aquarium Developers. All rights reserved' | fgrep -q "$(date '+%Y')"); then
                echo "ERROR: Copyright header need to be adjusted to contain current year like: 20??-$(date '+%Y') $f"
                errors=$((${errors} + 1))
            fi
        fi
    fi
done

echo
echo '---------------------- YAML Lint ----------------------'
echo
yamllint --strict playbooks specs
errors=$((${errors}+$?))

echo
echo '---------------------- Ansible Lint ----------------------'
echo
ansible-lint playbooks/*.yml
errors=$((${errors}+$?))

exit ${errors}

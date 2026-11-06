# Shared paths, sourced by the other scripts.
# The projects root is the folder that contains this repo, so the repo can be
# cloned under any name in any projects folder.

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
approved_projects_root="$(dirname "$project_dir")"
assistant_project_dir="/workspace/projects/$(basename "$project_dir")"

# Never mount the whole home directory or the filesystem root.
if [[ "$approved_projects_root" == "/" || "$approved_projects_root" == "$HOME" ]]; then
  echo "Refusing to mount $approved_projects_root. Clone this repo inside a projects folder such as ~/Projects." >&2
  exit 1
fi

# The unit file quotes the path, so these characters would break it.
if [[ "$project_dir" == *[\"\\$'\n']* ]]; then
  echo "Refusing project path with quotes, backslashes or newlines: $project_dir" >&2
  exit 1
fi

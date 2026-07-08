#!/usr/bin/env bash
# Renames this scaffold's C# namespace and project name throughout the repo.
# Run from anywhere; it always operates on the repo root (one level up from this script).
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

OLD_NAMESPACE="Scaffold"
OLD_PROJECT_NAME="godot-scaffold"
OLD_ROOT_NAMESPACE="godotscaffold"

read -rp "New C# namespace prefix (e.g. Pirate): " NEW_NAMESPACE
NEW_NAMESPACE="${NEW_NAMESPACE%.}" # tolerate a trailing dot if the user typed one

if [[ -z "$NEW_NAMESPACE" ]]; then
	echo "Namespace cannot be empty." >&2
	exit 1
fi

if [[ ! "$NEW_NAMESPACE" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
	echo "Namespace must be a valid C# identifier (letters, digits, underscore; can't start with a digit)." >&2
	exit 1
fi

read -rp "New project name (e.g. pirate-game): " NEW_PROJECT_NAME

if [[ -z "$NEW_PROJECT_NAME" ]]; then
	echo "Project name cannot be empty." >&2
	exit 1
fi

if [[ ! "$NEW_PROJECT_NAME" =~ ^[A-Za-z0-9_-]+$ ]]; then
	echo "Project name may only contain letters, digits, hyphens, and underscores." >&2
	exit 1
fi

# Mirrors Godot's own default: RootNamespace is the project name with invalid characters stripped.
NEW_ROOT_NAMESPACE="$(echo "$NEW_PROJECT_NAME" | tr -cd '[:alnum:]')"

echo
echo "This will replace, in every .cs/.csproj/.sln/.godot/.tscn/.md file:"
echo "  ${OLD_NAMESPACE}.      -> ${NEW_NAMESPACE}."
echo "  ${OLD_PROJECT_NAME}    -> ${NEW_PROJECT_NAME}"
echo "  ${OLD_ROOT_NAMESPACE}  -> ${NEW_ROOT_NAMESPACE}"
echo "and rename ${OLD_PROJECT_NAME}.csproj / .sln to match."
echo
echo "This repo has no git history to fall back on once checked out raw, so make sure"
echo "you've committed or backed up before continuing."
read -rp "Continue? [y/N] " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
	echo "Aborted."
	exit 0
fi

while IFS= read -r -d '' f; do
	sed -i \
		-e "s/${OLD_NAMESPACE}\./${NEW_NAMESPACE}./g" \
		-e "s/${OLD_PROJECT_NAME}/${NEW_PROJECT_NAME}/g" \
		-e "s/${OLD_ROOT_NAMESPACE}/${NEW_ROOT_NAMESPACE}/g" \
		"$f"
done < <(find . \( -path ./.git -o -path ./.godot -o -path ./bin -o -path ./obj \) -prune -o \
	-type f \( -name "*.cs" -o -name "*.csproj" -o -name "*.sln" -o -name "*.godot" -o -name "*.tscn" -o -name "*.md" \) -print0)

if [[ -f "${OLD_PROJECT_NAME}.csproj" ]]; then
	mv "${OLD_PROJECT_NAME}.csproj" "${NEW_PROJECT_NAME}.csproj"
fi

if [[ -f "${OLD_PROJECT_NAME}.sln" ]]; then
	mv "${OLD_PROJECT_NAME}.sln" "${NEW_PROJECT_NAME}.sln"
fi

echo
echo "Done. Renamed to project '${NEW_PROJECT_NAME}' with namespace '${NEW_NAMESPACE}.'"
echo "Re-open the project in Godot to let it regenerate the .godot/ cache."

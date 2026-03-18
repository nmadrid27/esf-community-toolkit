#!/usr/bin/env bash
# ESF Community Toolkit Installer
# Sets up a project directory with ESF templates and optional Claude Code configuration.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/nmadrid27/esf-community-toolkit/main/install.sh | bash

set -e

TOOLKIT_BASE="https://raw.githubusercontent.com/nmadrid27/esf-community-toolkit/main"
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${CYAN}Epistemic Stewardship Framework - Community Toolkit${NC}"
echo "──────────────────────────────────────────────────────"
echo ""

# Determine if we need to create a new directory or install in current
if [ -d ".git" ] || [ -f "README.md" ]; then
  echo "Installing into current directory: $(basename "$(pwd)")"
  INSTALL_DIR="."
else
  read -r -p "Project name (creates a new directory): " PROJECT_NAME
  PROJECT_NAME="${PROJECT_NAME:-my-project}"
  PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-_')

  if [ -d "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Directory '$PROJECT_NAME' already exists.${NC}"
    exit 1
  fi

  mkdir -p "$PROJECT_NAME"
  cd "$PROJECT_NAME"
  INSTALL_DIR="."

  # Initialize git
  if command -v git &> /dev/null; then
    git init -q -b main
    echo -e "${GREEN}  Git repository initialized.${NC}"
  fi
fi

echo "Installing ESF Community Toolkit..."

# Create directory structure
mkdir -p templates
mkdir -p prompts
mkdir -p projects
mkdir -p .claude/agents
mkdir -p .claude/reference

# Download templates
echo "  Fetching templates..."
curl -fsSL "$TOOLKIT_BASE/templates/position-statement.md"      -o templates/position-statement.md
curl -fsSL "$TOOLKIT_BASE/templates/record-of-resistance.md"    -o templates/record-of-resistance.md
curl -fsSL "$TOOLKIT_BASE/templates/ai-use-log.md"              -o templates/ai-use-log.md
curl -fsSL "$TOOLKIT_BASE/templates/five-questions-checklist.md" -o templates/five-questions-checklist.md
curl -fsSL "$TOOLKIT_BASE/templates/disclosure-statement.md"    -o templates/disclosure-statement.md

# Download prompt
echo "  Fetching companion prompt..."
curl -fsSL "$TOOLKIT_BASE/prompts/esf-companion.md" -o prompts/esf-companion.md

# Download Claude Code configuration
echo "  Fetching Claude Code configuration..."
curl -fsSL "$TOOLKIT_BASE/.claude/agents/esf-companion.md"   -o .claude/agents/esf-companion.md
curl -fsSL "$TOOLKIT_BASE/.claude/reference/esf-guide.md"    -o .claude/reference/esf-guide.md

# Download workflow
if [ ! -f "WORKFLOW.md" ]; then
  curl -fsSL "$TOOLKIT_BASE/WORKFLOW.md" -o WORKFLOW.md
fi

# Create .gitignore if it does not exist
if [ ! -f ".gitignore" ]; then
  cat > .gitignore << 'GITIGNORE'
.DS_Store
Thumbs.db
*.swp
*~
.vscode/
.idea/
node_modules/
.env
.env.local

# ESF session buffer (ephemeral, not versioned)
.session-buffer.md
GITIGNORE
fi

# Initial commit if git is present and no commits exist
if [ -d ".git" ] && ! git log --oneline -1 &>/dev/null 2>&1; then
  git add .
  git commit -q -m "Initial ESF toolkit setup"
  echo -e "${GREEN}  Initial commit created.${NC}"
fi

# Offer GitHub push
if command -v gh &> /dev/null && [ -d ".git" ]; then
  if ! git remote get-url origin &>/dev/null 2>&1; then
    echo ""
    if [ -t 0 ]; then
      read -r -p "Push to GitHub as a private repo? (y/N): " PUSH_GH
    else
      PUSH_GH="N"
    fi
    if [[ "$PUSH_GH" =~ ^[Yy]$ ]]; then
      REPO_NAME=$(basename "$(pwd)")
      if gh auth status &>/dev/null; then
        gh repo create "$REPO_NAME" --private --source=. --push -q 2>/dev/null && \
          echo -e "${GREEN}  GitHub repo created and pushed.${NC}" || \
          echo -e "${YELLOW}  Could not create GitHub repo. You can do this later.${NC}"
      else
        echo -e "${YELLOW}  Not logged in to GitHub CLI. Run 'gh auth login' first.${NC}"
      fi
    fi
  fi
fi

echo ""
echo -e "${GREEN}ESF Community Toolkit installed.${NC}"
echo ""
echo "──────────────────────────────────────────────────────"
echo -e "${CYAN}What to do now:${NC}"
echo ""
echo "  1. Start a new project:"
echo "     mkdir projects/my-project"
echo "     cp templates/position-statement.md projects/my-project/"
echo "     # Write your Position Statement before opening AI"
echo ""
echo "  2. If using Claude Code:"
echo "     claude"
echo "     # Claude will check for your Position Statement automatically"
echo ""
echo "  3. If using another AI tool:"
echo "     Open prompts/esf-companion.md"
echo "     Paste it as your system prompt"
echo ""
echo "  See WORKFLOW.md for the full process diagram."
echo "──────────────────────────────────────────────────────"
echo ""

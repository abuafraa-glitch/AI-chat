#!/bin/bash

# Hajeen AI Frontend - GitHub Push Script
# This script pushes the Flutter Frontend to GitHub

echo "================================"
echo "🚀 Hajeen AI Frontend Push Tool"
echo "================================"
echo ""

# Check if git is initialized
if [ ! -d .git ]; then
    echo "❌ Git not initialized. Initializing now..."
    git init
fi

# Configure git
echo "📝 Configuring Git..."
git config user.email "hajeen@ai.dev"
git config user.name "Hajeen AI Build"

# Check if remote exists
if git remote | grep -q origin; then
    echo "✅ Remote 'origin' already exists"
else
    echo "🔗 Adding remote origin..."
    git remote add origin https://github.com/raedthawaba/AI-chat.git
fi

# Show current status
echo ""
echo "📊 Current Status:"
git status --short

# Show commits to push
echo ""
echo "📝 Commits to push:"
git log --oneline -5

# Check if there are uncommitted changes
if [ -n "$(git status --short)" ]; then
    echo ""
    echo "⚠️  There are uncommitted changes. Adding them now..."
    git add -A
    git commit -m "chore: Update Hajeen AI Frontend

- Flutter frontend with 26 Dart files
- 3,875+ lines of production-ready code
- Full Arabic (RTL) and English (LTR) support
- Dark/Light theme system
- Dynamic AI model selection
- Chat with streaming support
- Subscription system
- Settings management
- File upload support"
fi

# Attempt to push
echo ""
echo "🚀 Pushing to GitHub..."

# Try with token if provided
if [ -n "$GITHUB_TOKEN" ]; then
    echo "Using provided GitHub token..."
    git push -u origin master 2>&1
elif [ -n "$GITHUB_PAT_2" ]; then
    echo "Using GITHUB_PAT_2 token..."
    git remote set-url origin "https://raedthawaba:${GITHUB_PAT_2}@github.com/raedthawaba/AI-chat.git"
    git push -u origin master 2>&1
else
    echo "⚠️  No token provided. Attempting direct push..."
    echo ""
    echo "Please provide one of:"
    echo "  export GITHUB_TOKEN=your_token"
    echo "  export GITHUB_PAT_2=your_token"
    echo ""
    echo "Then run: git push origin master"
    exit 1
fi

# Check push result
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Push successful!"
    echo ""
    echo "📍 Your project is now at:"
    echo "   https://github.com/raedthawaba/AI-chat"
    echo ""
else
    echo ""
    echo "❌ Push failed. Please check:"
    echo "  1. GitHub token is valid"
    echo "  2. You have write access to the repository"
    echo "  3. Your internet connection is working"
    exit 1
fi

echo ""
echo "✨ Done!"

#!/bin/bash

# Demo script for Nelson Elementary Watson Neovim Plugin

echo "🔥 Nelson Elementary Watson - Neovim Paraglide Plugin Demo"
echo "==========================================================="
echo ""

# Check if we're in the right directory
if [ ! -f "lua/nelementary-watson/init.lua" ]; then
    echo "❌ Error: Please run this script from the nelementary-watson directory"
    exit 1
fi

echo "📁 Plugin Structure:"
echo "--------------------"
tree -I 'node_modules|.git' --dirsfirst

echo ""
echo "📋 Test Files:"
echo "--------------"
echo "JavaScript test file (test/sample.js):"
head -10 test/sample.js

echo ""
echo "🌍 Translation Files:"
echo "--------------------"
echo "English (test/messages/en.json):"
head -5 test/messages/en.json | jq .

echo ""
echo "Spanish (test/messages/es.json):"
head -5 test/messages/es.json | jq .

echo ""
echo "⚙️  inlang Configuration (test/project.inlang/settings.json):"
echo "-----------------------------------------------------------"
cat test/project.inlang/settings.json | jq .

echo ""
echo "🚀 To test the plugin:"
echo "----------------------"
echo "1. cd $(pwd)/test"
echo "2. nvim sample.js"
echo "3. :luafile test_plugin.lua"
echo "4. You should see translation values displayed next to m.methodName() calls"
echo "5. Use :NelsonChangeLocale to switch between 'en' and 'es'"
echo ""
echo "✨ The plugin will show virtual text like:"
echo "   const title = m.hello_world(); → \"Hello World\""
echo "   const greeting = m.welcome_message(); → \"Welcome to our application\""
echo ""
echo "📚 See INSTALL.md for installation instructions"
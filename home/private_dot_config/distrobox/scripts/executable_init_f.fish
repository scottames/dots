#!/usr/bin/env fish

function install_vscode
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null

    dnf check-update
    sudo dnf install -y code
end

function install_claude_code
    npm install -g @anthropic-ai/claude-code
end

function install_gemini_cli
    npm install -g @google/gemini-cli
end

function install_openai_codex
    npm install -g @openai/codex
end

install_vscode
install_claude_code
install_gemini_cli
install_openai_codex

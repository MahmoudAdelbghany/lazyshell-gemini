# LazyShell-Gemini

LazyShell-Gemini is a fork of the archived [lazyshell](https://github.com/not-poma/lazyshell) repository. It is a Gemini-powered utility for Zsh that helps you write and modify console commands using natural language. Perfect for those times when you can't remember the command line arguments for `tar` and `ffmpeg`, or when you just want to save time by having AI do the heavy lifting. The tool uses your current command line content (if any) as a base for your query, so you can issue modification requests for it. Invoke the completion with the ALT+G hotkey; you still have to manually press enter to execute the suggested command.

It also can use Gemini to explain what the current command does. Invoke the explanation with the ALT+E hotkey.

![Screenshot](https://raw.githubusercontent.com/not-poma/lazyshell/master/screenshot.gif)

LazyShell-Gemini is in alpha stage and may contain bugs. Currently only Zsh is supported. This fork was created because the Gemini API offers a decent free tier, making it an attractive alternative to other providers.

# How to use

## Completion

1. Hit ALT+G to invoke the completion. The current command line content will be used as a base for your query.
2. Then, write a natural language version of what you want to accomplish.
3. Hit enter.
4. The suggested command will be inserted into the command line.
5. Hit enter to execute it, or continue modifying it.

### Query examples for completion:
```
Unpack download.tar.gz

Start nginx server in docker

Mount current dir

Speed up the video 2x using ffmpeg

Remove audio track
```

## Explanation

1. Write down a command you want to understand.
2. Hit ALT+E to invoke the explanation module.
3. Press any key to modify the command (the explanation will disappear).

# Installation

Get your Gemini API key from [Google AI Studio](https://aistudio.google.com/). This API provides a generous free tier for testing.

## Prerequisites
- **macOS:** Install using Homebrew:

```zsh
  brew install curl jq
```
- **Debian/Ubuntu:** Install using apt:

```zsh
sudo apt-get update && sudo apt-get install -y curl jq
```
- **fedora/CentOS:** Install using dnf or yum:

```zsh
sudo dnf install -y curl jq
```
or
```zsh
sudo yum install -y curl jq
```
## Download the script
```zsh
curl -o ~/.lazyshell-gemini.zsh https://raw.githubusercontent.com/MahmoudAdelbghany/lazyshell-gemini/master/lazyshell.zsh
```

## Configure your shell
Add the following lines to your `.zshrc`:
```zsh
export GEMINI_API_KEY=<your_api_key>
[ -f ~/.lazyshell-gemini.zsh  ] && source ~/.lazyshell-gemini.zsh 

```
After that, restart your shell. You can invoke the completion with the ALT+G hotkey and the explanation with the ALT+E hotkey.

_Note:_ If you're on macOS and your terminal prints `©` when you press the hotkey, it means the OS intercepts the key combination first and you need to disable this behavior.
# Contributing

This script is a crude hack, so any help is appreciated, especially if you can write Zsh completion scripts. Feel free to open an issue or a pull request.

Inspired by [shell_gpt](https://github.com/TheR1D/shell_gpt).
# TODO

- [ ]  support for other shells
- [ ]  support keyboard interrupts
- [ ]  make some kind of preview before replacing the buffer
- [ ]  query history
- [ ]  allow query editing while the previous one is in progress
- [ ]  add a better way to change key bindings than modifying the script directly
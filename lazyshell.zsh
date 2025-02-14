#!/usr/bin/env zsh

__lzsh_get_distribution_name() {
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "$(sw_vers -productName) $(sw_vers -productVersion)" 2>/dev/null
  else
    echo "$(cat /etc/*-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)"
  fi
}

__lzsh_get_os_prompt_injection() {
  local os=$(__lzsh_get_distribution_name)
  if [[ -n "$os" ]]; then
    echo " for $os"
  else
    echo ""
  fi
}

__lzsh_preflight_check() {
  emulate -L zsh
  if [ -z "$GEMINI_API_KEY" ]; then
    echo ""
    echo "Error: GEMINI_API_KEY is not set"
    echo "Get your Gemini API key from your account page and then run:"
    echo "export GEMINI_API_KEY=<your Gemini API key>"
    zle reset-prompt
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo ""
    echo "Error: jq is not installed"
    zle reset-prompt
    return 1
  fi

  if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    echo ""
    echo "Error: curl or wget is not installed"
    zle reset-prompt
    return 1
  fi
}

__lzsh_llm_api_call() {
  emulate -L zsh
  # This function calls the Gemini API and shows a spinner while waiting.
  # It returns the generated command in the variable 'generated_text'.

  local intro="$1"
  local prompt="$2"
  local progress_text="$3"

  local response_file=$(mktemp)

  # Combine the system (intro) and the user prompt into one block.
  local full_text="${intro}\n\n${prompt}"
  # Escape for JSON (using jq to encode as raw string)
  local escaped_full_text=$(echo "$full_text" | jq -R -s '.')

  # Build the payload in Gemini format.
  local data='{"contents": [{"parts": [{"text": '"$escaped_full_text"'}]}]}'

  # Use curl or wget to post the data to the Gemini API endpoint.
  set +m
  if command -v curl &> /dev/null; then
    { curl -s -X POST -H "Content-Type: application/json" -d "$data" "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$GEMINI_API_KEY" > "$response_file" } &>/dev/null &
  else
    { wget -qO- --header="Content-Type: application/json" --post-data="$data" "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$GEMINI_API_KEY" > "$response_file" } &>/dev/null &
  fi
  local pid=$!

  # Display a spinner while waiting
  local spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  while true; do
    for i in "${spinner[@]}"; do
      if ! kill -0 $pid 2> /dev/null; then
        break 2
      fi
      zle -R "$i $progress_text"
      sleep 0.1
    done
  done

  wait $pid
  if [ $? -ne 0 ]; then
    zle -M "Error: API request failed"
    return 1
  fi

  local response=$(cat "$response_file")
  # Remove the temporary file explicitly.
  command rm "$response_file"

  # Check for an error message in the response.
  local error=$(echo -E "$response" | jq -r '.error.message')
  # Extract the generated text from the first candidate.
  generated_text=$(echo -E "$response" | jq -r '.candidates[0].content.parts[0].text' | tr '\n' '\r' | sed -e $'s/^[ \r`]*//; s/[ \r`]*$//' | tr '\r' '\n')

  if [ $? -ne 0 ]; then
    zle -M "Error: Invalid API response format"
    return 1
  fi

  if [[ -n "$error" && "$error" != "null" ]]; then
    zle -M "API error: $error"
    return 1
  fi
}

# Read user query and generate a zsh command
__lazyshell_complete() {
  emulate -L zsh
  __lzsh_preflight_check || return 1

  local buffer_context="$BUFFER"
  local cursor_position=$CURSOR

  # Read user input (using read-from-minibuffer for simplicity)
  local REPLY
  autoload -Uz read-from-minibuffer
  read-from-minibuffer '> Query: '
  BUFFER="$buffer_context"
  CURSOR=$cursor_position

  local os=$(__lzsh_get_os_prompt_injection)
  local intro="You are a zsh autocomplete script. All your answers are a single command$os, and nothing else. You do not write any human-readable explanations. If you fail to answer, start your response with \`#\`."
  if [[ -z "$buffer_context" ]]; then
    local prompt="$REPLY"
  else
    local prompt="Alter zsh command \`$buffer_context\` to comply with query \`$REPLY\`"
  fi

  __lzsh_llm_api_call "$intro" "$prompt" "Query: $REPLY"
  if [ $? -ne 0 ]; then
    return 1
  fi

  # If the response starts with '#' it indicates an error.
  if [[ "$generated_text" == \#* ]]; then
    zle -M "$generated_text"
    return 1
  fi

  # Replace the current buffer with the generated command.
  BUFFER="$generated_text"
  CURSOR=$#BUFFER
}

# Explain the current zsh command
__lazyshell_explain() {
  emulate -L zsh
  __lzsh_preflight_check || return 1

  local buffer_context="$BUFFER"
  local os=$(__lzsh_get_os_prompt_injection)
  local intro="You are a zsh command explanation assistant$os. You write short and concise explanations of what the given zsh command does, including its arguments. You answer with no line breaks."
  local prompt="$buffer_context"

  __lzsh_llm_api_call "$intro" "$prompt" "Fetching Explanation..."
  if [ $? -ne 0 ]; then
    return 1
  fi

  zle -R "# $generated_text"
  read -k 1
}

# Check for GEMINI_API_KEY at startup and warn if not set.
if [ -z "$GEMINI_API_KEY" ]; then
  echo "Warning: GEMINI_API_KEY is not set"
  echo "Get your API key from your Gemini dashboard and then run:"
  echo "export GEMINI_API_KEY=<your Gemini API key>"
fi

# Bind the __lazyshell_complete function to the Alt-g hotkey
# Bind the __lazyshell_explain function to the Alt-e hotkey
zle -N __lazyshell_complete
zle -N __lazyshell_explain
bindkey '\eg' __lazyshell_complete
bindkey '\ee' __lazyshell_explain

typeset -ga ZSH_AUTOSUGGEST_CLEAR_WIDGETS
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=( __lazyshell_explain )

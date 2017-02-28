#!/usr/bin/env bats

load test_helper

@test "creates shims and versions directories" {
  assert [ ! -d "${RBENV_ROOT}/shims" ]
  assert [ ! -d "${RBENV_ROOT}/versions" ]
  run rbenv-init -
  assert_success
  assert [ -d "${RBENV_ROOT}/shims" ]
  assert [ -d "${RBENV_ROOT}/versions" ]
}

@test "auto rehash" {
  run rbenv-init -
  assert_success
  assert_line "command rbenv rehash 2>/dev/null"
}

@test "setup shell completions" {
  root="$(cd $BATS_TEST_DIRNAME/.. && pwd)"
  run rbenv-init - bash
  assert_success
  assert_line "source '${root}/test/../libexec/../completions/rbenv.bash'"
}

@test "detect parent shell" {
  SHELL=/bin/false run rbenv-init -
  assert_success
  assert_line "export RBENV_SHELL=bash"
}

@test "detect parent shell from script" {
  mkdir -p "$RBENV_TEST_DIR"
  cd "$RBENV_TEST_DIR"
  cat > myscript.sh <<OUT
#!/bin/sh
eval "\$(rbenv-init -)"
echo \$RBENV_SHELL
OUT
  chmod +x myscript.sh
  run ./myscript.sh /bin/zsh
  assert_success "sh"
}

@test "setup shell completions (fish)" {
  root="$(cd $BATS_TEST_DIRNAME/.. && pwd)"
  run rbenv-init - fish
  assert_success
  assert_line "source '${root}/test/../libexec/../completions/rbenv.fish'"
}

@test "fish instructions" {
  run rbenv-init fish
  assert [ "$status" -eq 1 ]
  assert_line 'status --is-interactive; and source (rbenv init -|psub)'
}

@test "rc instructions" {
  run rbenv-init rc
  assert [ "$status" -eq 1 ]
  assert_line '. <{rbenv init -}'
}

@test "option to skip rehash" {
  run rbenv-init - --no-rehash
  assert_success
  refute_line "rbenv rehash 2>/dev/null"
}

@test "adds shims to PATH" {
  export PATH="${BATS_TEST_DIRNAME}/../libexec:/usr/bin:/bin:/usr/local/bin"
  run rbenv-init - bash
  assert_success
  assert_line 0 'export PATH="'${RBENV_ROOT}'/shims:${PATH}"'
}

@test "adds shims to PATH (fish)" {
  export PATH="${BATS_TEST_DIRNAME}/../libexec:/usr/bin:/bin:/usr/local/bin"
  run rbenv-init - fish
  assert_success
  assert_line 0 "setenv PATH '${RBENV_ROOT}/shims' \$PATH"
}

@test "adds shims to PATH (rc)" {
  export PATH="${BATS_TEST_DIRNAME}/../libexec:/usr/bin:/bin:/usr/local/bin"
  run rbenv-init - rc
  assert_success
  assert_line 0 "path=($RBENV_ROOT/shims \$path)"
}

@test "can add shims to PATH more than once" {
  export PATH="${RBENV_ROOT}/shims:$PATH"
  run rbenv-init - bash
  assert_success
  assert_line 0 'export PATH="'${RBENV_ROOT}'/shims:${PATH}"'
}

@test "can add shims to PATH more than once (fish)" {
  export PATH="${RBENV_ROOT}/shims:$PATH"
  run rbenv-init - fish
  assert_success
  assert_line 0 "setenv PATH '${RBENV_ROOT}/shims' \$PATH"
}

@test "can add shims to PATH more than once (rc)" {
  export PATH="${RBENV_ROOT}/shims:$PATH"
  run rbenv-init - rc
  assert_success
  assert_line 0 "path=($RBENV_ROOT/shims \$path)"
}

@test "outputs sh-compatible syntax" {
  run rbenv-init - bash
  assert_success
  assert_line '  case "$command" in'

  run rbenv-init - zsh
  assert_success
  assert_line '  case "$command" in'
}

@test "outputs fish-specific syntax (fish)" {
  run rbenv-init - fish
  assert_success
  assert_line '  switch "$command"'
  refute_line '  case "$command" in'
}

@test "outputs rc-specific syntax (rc)" {
  run rbenv-init - rc
  assert_success
  assert_line '    switch($command) {'
  refute_line '  case "$command" in'
}

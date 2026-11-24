# psmux の .tmux.conf から run-shell -b で起動する（claude_wait_watch.py を uv の Python で動かす）
& uv run --no-project python "$PSScriptRoot/claude_wait_watch.py"

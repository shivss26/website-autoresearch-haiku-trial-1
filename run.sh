#!/bin/bash
# Autoresearch wrapper script
# Spawns a fresh Haiku agent for each experiment, waits for Pages deploy between runs.

EXPERIMENT=1

while true; do
    echo "=========================================="
    echo "  EXPERIMENT $EXPERIMENT — $(date)"
    echo "=========================================="

    "$HOME/.local/bin/claude" --model haiku --dangerously-skip-permissions --print "Read program.md and begin."

    echo ""
    echo "Agent exited. Waiting 120s for GitHub Pages deploy..."
    sleep 120

    EXPERIMENT=$((EXPERIMENT + 1))
done

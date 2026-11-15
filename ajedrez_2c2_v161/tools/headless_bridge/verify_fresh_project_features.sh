#!/usr/bin/env bash
set -euo pipefail
GODOT="$1"
PROJECT="$2"
PROBE="res://tools/headless_bridge/bridge_probe.gd"
run_probe() {
  "$GODOT" --headless --path "$PROJECT" --script "$PROBE" -- "$@"
}
run_probe inspect_resource '{"path":"res://icon.svg"}' | tee artifacts/icon-resource-inspection.log
grep -q '"ok":true' artifacts/icon-resource-inspection.log
run_probe list_project_resources | tee artifacts/project-resources.log
grep -q 'res://main.tscn' artifacts/project-resources.log
echo "FRESH_PROJECT_RESOURCE_INSPECTION_PASS"
run_probe add_node '{"type":"CharacterBody2D","name":"SandboxBody"}'
run_probe add_node '{"type":"CollisionShape2D","name":"SandboxCollision","parent_path":"SandboxBody"}'
run_probe configure_collision_shape '{"node_path":"SandboxBody/SandboxCollision","shape_type":"CircleShape2D","dimensions":{"radius":24.0}}' | tee artifacts/collision-shape-response.log
run_probe inspect_scene | tee artifacts/collision-scene-inspection.log
grep -q '"SandboxBody"' artifacts/collision-scene-inspection.log
grep -q '"SandboxCollision"' artifacts/collision-scene-inspection.log
grep -q 'CircleShape2D' artifacts/collision-scene-inspection.log
echo "FRESH_PROJECT_COLLISION_SHAPE_PASS"
run_probe focus_inspector '{"node_path":"SandboxNode","main_screen":"2D"}' | tee artifacts/inspector-focus-response.log
sleep 2
run_probe inspect_selection | tee artifacts/inspector-selection-after-focus.log
grep -q '"name":"SandboxNode"' artifacts/inspector-selection-after-focus.log
echo "FRESH_PROJECT_VISIBLE_INSPECTOR_FOCUS_PASS"

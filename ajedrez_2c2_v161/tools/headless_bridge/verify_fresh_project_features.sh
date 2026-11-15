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
sed -n 's/^BRIDGE_TEST_PASS //p' artifacts/collision-scene-inspection.log | tail -n 1 | jq -e '.result.root.children[] | select(.name == "SandboxNode") | .properties.position.x == 123.0 and .properties.position.y == 45.0' >/dev/null
echo "FRESH_PROJECT_COLLISION_SHAPE_AND_PROPERTY_PASS"
run_probe undo_bridge_action | tee artifacts/undo-bridge-action-response.log
sed -n 's/^BRIDGE_TEST_PASS //p' artifacts/undo-bridge-action-response.log | tail -n 1 | jq -e '.result.direction == "undo" and .result.action_name == "Headless Bridge: Configure collision shape SandboxCollision" and .result.version_after > .result.version_before' >/dev/null
run_probe inspect_scene | tee artifacts/undo-scene-inspection.log
sed -n 's/^BRIDGE_TEST_PASS //p' artifacts/undo-scene-inspection.log | tail -n 1 | jq -e '.result.root.children[] | select(.name == "SandboxBody") | .children[] | select(.name == "SandboxCollision") | .properties.shape == null' >/dev/null
echo "FRESH_PROJECT_REAL_UNDO_PASS"
run_probe redo_bridge_action | tee artifacts/redo-bridge-action-response.log
sed -n 's/^BRIDGE_TEST_PASS //p' artifacts/redo-bridge-action-response.log | tail -n 1 | jq -e '.result.direction == "redo" and .result.action_name == "Headless Bridge: Configure collision shape SandboxCollision" and .result.version_after > .result.version_before' >/dev/null
run_probe inspect_scene | tee artifacts/redo-scene-inspection.log
grep -q 'CircleShape2D' artifacts/redo-scene-inspection.log
echo "FRESH_PROJECT_REAL_REDO_PASS"
if run_probe add_node '{"type":"CollisionShape2D","name":"InvalidCollision"}' > artifacts/invalid-collision-parent.log 2>&1; then
  echo "CollisionShape2D invalid parent was accepted" >&2
  exit 1
else
  echo "FRESH_PROJECT_COLLISION_PARENT_GUARD_PASS"
fi
if run_probe add_node '{"type":"OS","name":"InvalidNode"}' > artifacts/invalid-node-type.log 2>&1; then
  echo "Disallowed node type was accepted" >&2
  exit 1
else
  echo "FRESH_PROJECT_NODE_ALLOWLIST_GUARD_PASS"
fi
if run_probe set_node_properties '{"node_path":"SandboxNode","properties":{"unknown_property":1}}' > artifacts/invalid-property.log 2>&1; then
  echo "Unknown node property was accepted" >&2
  exit 1
else
  echo "FRESH_PROJECT_PROPERTY_ALLOWLIST_GUARD_PASS"
fi
if run_probe open_scene '{"path":"res://../outside.tscn"}' > artifacts/invalid-scene-path.log 2>&1; then
  echo "Path traversal scene path was accepted" >&2
  exit 1
else
  echo "FRESH_PROJECT_SCENE_PATH_GUARD_PASS"
fi
run_probe inspect_undo_history | tee artifacts/undo-history-inspection.log
sed -n 's/^BRIDGE_TEST_PASS //p' artifacts/undo-history-inspection.log | tail -n 1 | jq -e '.result.has_undo == true and (.result.current_action_name | startswith("Headless Bridge:"))' >/dev/null
echo "FRESH_PROJECT_EDITOR_UNDO_HISTORY_PASS"
run_probe open_scene '{"path":"res://main.tscn"}' | tee artifacts/open-scene-response.log
grep -q 'BRIDGE_SCENE_OPEN_CONFIRMED res://main.tscn' artifacts/open-scene-response.log
echo "FRESH_PROJECT_OPEN_SCENE_PASS"
run_probe focus_inspector '{"node_path":"SandboxNode","main_screen":"2D"}' | tee artifacts/inspector-focus-response.log
grep -q '"inspector_visible":true' artifacts/inspector-focus-response.log
grep -q '"dock_visible":true' artifacts/inspector-focus-response.log
sed -n 's/^BRIDGE_TEST_PASS //p' artifacts/inspector-focus-response.log | tail -n 1 | jq -e '.result.dock_size.x > 0 and .result.dock_size.y > 0' >/dev/null
sleep 2
run_probe inspect_selection | tee artifacts/inspector-selection-after-focus.log
grep -q '"name":"SandboxNode"' artifacts/inspector-selection-after-focus.log
echo "FRESH_PROJECT_VISIBLE_INSPECTOR_FOCUS_PASS"

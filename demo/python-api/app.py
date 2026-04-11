"""
ValidationForge Demo: Minimal Flask API

Endpoints:
  GET  /health               — liveness check
  GET  /api/items            — list all items
  POST /api/items            — create a new item
  GET  /api/items/<int:id>   — get a single item by ID

Error handling:
  404 — item not found (with JSON body)
  400 — bad request / missing required fields (with JSON body)
  405 — method not allowed (with JSON body)
"""

import os

from flask import Flask, jsonify, request

app = Flask(__name__)

# In-memory store — intentionally ephemeral for demo purposes
_items: list[dict] = [
    {"id": 1, "name": "Widget A", "description": "First demo item", "in_stock": True},
    {"id": 2, "name": "Widget B", "description": "Second demo item", "in_stock": False},
    {"id": 3, "name": "Gadget X", "description": "Third demo item", "in_stock": True},
]
_next_id: int = 4


# ─── Health ──────────────────────────────────────────────────────────────────

@app.route("/health", methods=["GET"])
def health():
    """Liveness check — always returns 200 while the server is up."""
    return jsonify({"status": "ok", "items_count": len(_items)}), 200


# ─── Items collection ─────────────────────────────────────────────────────────

@app.route("/api/items", methods=["GET"])
def list_items():
    """Return the full list of items."""
    return jsonify({"items": _items, "total": len(_items)}), 200


@app.route("/api/items", methods=["POST"])
def create_item():
    """
    Create a new item.

    Required JSON body fields:
      name (str)

    Optional:
      description (str)  — defaults to empty string
      in_stock    (bool) — defaults to True
    """
    global _next_id

    body = request.get_json(silent=True)
    if body is None:
        return jsonify({"error": "Request body must be valid JSON"}), 400

    name = body.get("name", "").strip()
    if not name:
        return jsonify({"error": "Field 'name' is required and must be non-empty"}), 400

    item = {
        "id": _next_id,
        "name": name,
        "description": body.get("description", ""),
        "in_stock": bool(body.get("in_stock", True)),
    }
    _items.append(item)
    _next_id += 1

    return jsonify({"item": item}), 201


# ─── Single item ─────────────────────────────────────────────────────────────

@app.route("/api/items/<int:item_id>", methods=["GET"])
def get_item(item_id: int):
    """Return a single item by ID, or 404 if not found."""
    item = next((i for i in _items if i["id"] == item_id), None)
    if item is None:
        return jsonify({"error": f"Item with id {item_id} not found"}), 404
    return jsonify({"item": item}), 200


# ─── Generic error handlers ───────────────────────────────────────────────────

@app.errorhandler(404)
def not_found(exc):
    return jsonify({"error": "Not found", "path": request.path}), 404


@app.errorhandler(405)
def method_not_allowed(exc):
    return jsonify({
        "error": "Method not allowed",
        "method": request.method,
        "path": request.path,
    }), 405


# ─── Entry point ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=False)

import json
from pathlib import Path

from flask import Flask, jsonify


app = Flask(__name__)


# Относительный путь до файла с продукцией, который лежит в одной директории с app.py
PRODUCTS_FILE = Path(__file__).with_name("products.json")


def load_products():
    """Load products from a local JSON file."""
    with PRODUCTS_FILE.open(encoding="utf-8") as products_file:
        return json.load(products_file)


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.get("/products")
def get_products():
    return jsonify(load_products())


@app.get("/products/<int:product_id>")
def get_product(product_id):
    products = load_products()
    product = next(
        (item for item in products if item.get("id") == product_id),
        None,
    )

    if product is None:
        return jsonify({"error": "product not found"}), 404

    return jsonify(product)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

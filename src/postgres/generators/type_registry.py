"""Shared, persistent registry of composite type field lists, accumulated
across the 10.1 generator scripts, so a later file's Choice types can
correctly detect populated composite branches defined in an earlier file
(or in 10.2, seeded manually below since that script predates this fix).
"""
import json
import os

REGISTRY_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), '..', 'config', 'type_fields_registry.json'
)

def load_registry():
    seed = {
        # From 10.2 (generate_sql.py), which predates this registry mechanism
        "ActiveCurrencyAndAmount": ["Amt", "Ccy"],
        "ActiveOrHistoricCurrencyAndAmount": ["Amt", "Ccy"],
    }
    if os.path.exists(REGISTRY_PATH):
        with open(REGISTRY_PATH) as f:
            seed.update(json.load(f))
    return seed

def save_registry(type_fields):
    existing = {}
    if os.path.exists(REGISTRY_PATH):
        with open(REGISTRY_PATH) as f:
            existing = json.load(f)
    existing.update(type_fields)
    with open(REGISTRY_PATH, 'w') as f:
        json.dump(existing, f, indent=2, sort_keys=True)

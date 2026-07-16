"""
Shared helpers: SQL-literal formatting, constraint-respecting ID generators,
and a small writer class each stage uses to accumulate statements.
"""

import random
import string
from datetime import date, datetime


# ==========================================
# SQL literal formatting
# ==========================================

def sql_str(value) -> str:
    """NULL / quoted-string / raw-number literal for a single value."""
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, (date, datetime)):
        return f"'{value.isoformat(sep=' ') if isinstance(value, datetime) else value.isoformat()}'"
    # string: escape single quotes and backslashes
    escaped = str(value).replace("\\", "\\\\").replace("'", "''")
    return f"'{escaped}'"


def insert_stmt(table: str, columns: list, rows: list) -> str:
    """Build a single multi-row INSERT statement."""
    if not rows:
        return ""
    col_list = ", ".join(columns)
    value_lines = []
    for row in rows:
        vals = ", ".join(sql_str(row[c]) for c in columns)
        value_lines.append(f"    ({vals})")
    return f"INSERT INTO {table} ({col_list}) VALUES\n" + ",\n".join(value_lines) + ";\n"


# ==========================================
# Constraint-respecting ID / code generators
# ==========================================

# CHK_Vehicle_VIN_Length: ^[A-HJ-NPR-Z0-9]{17}$  (no I, O, Q)
_VIN_ALPHABET = "ABCDEFGHJKLMNPRSTUVWXYZ0123456789"

def gen_vin(rng: random.Random, used: set) -> str:
    while True:
        vin = "".join(rng.choice(_VIN_ALPHABET) for _ in range(17))
        if vin not in used:
            used.add(vin)
            return vin


# CHK_Vehicle_RegPlate: ^[0-9]{2}[A-Z]-[0-9]{3}\.[0-9]{2}$
def gen_plate(rng: random.Random, used: set) -> str:
    while True:
        plate = (
            f"{rng.randint(10, 99)}"
            f"{rng.choice(string.ascii_uppercase)}-"
            f"{rng.randint(100, 999):03d}."
            f"{rng.randint(0, 99):02d}"
        )
        if plate not in used:
            used.add(plate)
            return plate


# CHK_Driver_DriverID_Prefix: LIKE 'D-%'
def gen_driver_id(n: int) -> str:
    return f"D-{n:04d}"


# CHK_Mechanic_MechanicID_Prefix: LIKE 'ME-%'
def gen_mechanic_id(n: int) -> str:
    return f"ME-{n:04d}"


# CHK_MJ_JobID_Prefix: LIKE 'M%'  (VARCHAR(255), no format beyond the prefix)
def gen_job_id(n: int) -> str:
    return f"MJOB-{n:06d}"


# CHK_SE_EventID_Prefix: LIKE 'E%'  (VARCHAR(100))
def gen_event_id(n: int) -> str:
    return f"EVT-{n:07d}"


_STREET_NAMES = [
    "Le Loi", "Nguyen Hue", "Tran Hung Dao", "Hai Ba Trung", "Dien Bien Phu",
    "Nguyen Trai", "Vo Van Kiet", "Pham Van Dong", "Cach Mang Thang Tam",
    "Nguyen Van Linh", "Ton Duc Thang", "Le Duan", "Bach Dang", "Hung Vuong",
    "Nguyen Thi Minh Khai", "Ly Thuong Kiet",
]


def gen_local_address(rng: random.Random, city: str) -> str:
    """Simple street-number + street-name + city template.

    NOTE: Faker's vi_VN locale mixes broken English placeholder tokens into
    addresses/names (e.g. 'Thi xa JanePhuong'), so rather than rely on it we
    build a plain address ourselves, keeping the city name accurate to the
    depot's real Location and using a fixed pool of common Vietnamese street
    names for the rest.
    """
    number = rng.randint(1, 450)
    street = rng.choice(_STREET_NAMES)
    return f"{number} {street} Street, {city}"


# ==========================================
# Output writer
# ==========================================

class SqlFile:
    """Accumulates statements for one staged output file."""

    def __init__(self, title: str, description: str):
        self.title = title
        self.description = description
        self.chunks = []

    def raw(self, text: str):
        """Append a raw string to the output, no formatting."""
        if text:
            self.chunks.append(text)

    def comment(self, text: str):
        """Append a comment block to the output, with each line prefixed by '--'."""
        lines = text.split("\n")
        out = []
        for line in lines:
            out.append(f"-- {line}" if line else "")
        self.chunks.append("\n".join(out) + "\n")

    def insert(self, table: str, columns: list, rows: list):
        """Append a multi-row INSERT statement to the output."""
        stmt = insert_stmt(table, columns, rows)
        if stmt:
            self.chunks.append(stmt)

    def call(self, proc: str, raw_args: list):
        """raw_args are inserted verbatim (caller formats them, e.g. via
        sql_str() for literals or plain strings for expressions like
        MONTH(CURDATE()))."""
        self.chunks.append(f"CALL {proc}({', '.join(raw_args)});\n")

    def update(self, table: str, set_clause: str, where_clause: str):
        """Append a single-row UPDATE statement to the output."""
        self.chunks.append(f"UPDATE {table} SET {set_clause} WHERE {where_clause};\n")

    def write(self, path: str):
        """Write the accumulated output to a file, with a header comment."""
        header = (
            f"-- ==========================================================\n"
            f"-- {self.title}\n"
            f"-- ==========================================================\n"
            f"-- {self.description}\n"
            f"-- ==========================================================\n\n"
        )
        with open(path, "w") as f:
            f.write(header)
            f.write("\n".join(self.chunks))
            f.write("\n")


import os
import random
from faker import Faker

import config
import stage_01_reference
import stage_02_core_entities
import stage_03_certifications
import stage_04_score_init
import stage_05_vehicle_assignments
import stage_06_alerts_schedules
import stage_07_maintenance
import stage_08_safety_events
import stage_09_reviews_coaching
import stage_10_app_users

OUT_DIR = os.path.join(os.path.dirname(__file__), "output")
os.makedirs(OUT_DIR, exist_ok=True)

rng = random.Random(config.SEED)
faker = Faker()
Faker.seed(config.SEED)

print(f"Window: {config.WINDOW_START} .. {config.TODAY}")
print(f"Months covered: {config.MONTHS_COVERED}")

sql1, ref_state = stage_01_reference.generate(rng, faker)
sql1.write(os.path.join(OUT_DIR, "01_reference.sql"))

sql2, core_state = stage_02_core_entities.generate(rng, faker)
sql2.write(os.path.join(OUT_DIR, "02_core_entities.sql"))

print("Stage 01 + 02 written to", OUT_DIR)
print("Depots:", len(core_state["depot_ids"]))
print("Vehicles:", len(core_state["vins"]))
print("Drivers:", len(core_state["driver_ids"]))
print("Mechanics:", len(core_state["mechanic_ids"]))

sql3, cert_state = stage_03_certifications.generate(rng, core_state)
sql3.write(os.path.join(OUT_DIR, "03_certifications.sql"))
print("Stage 03 written.")
print("Driver certs generated:", sum(len(v) for v in cert_state["driver_cert_holdings"].values()), "active holdings")
print("Mechanic certs generated:", sum(len(v) for v in cert_state["mechanic_cert_holdings"].values()), "active holdings")

sql4, _ = stage_04_score_init.generate()
sql4.write(os.path.join(OUT_DIR, "04_score_init.sql"))
print("Stage 04 written.")

sql5, assign_state = stage_05_vehicle_assignments.generate(rng, core_state, cert_state)
sql5.write(os.path.join(OUT_DIR, "05_vehicle_assignments.sql"))
print("Stage 05 written.")
print("Total assignments:", assign_state["assignment_count"])
print("Live-state vehicles:", assign_state["vehicle_live_state"])

sql6, alert_state = stage_06_alerts_schedules.generate(rng, core_state)
sql6.write(os.path.join(OUT_DIR, "06_alerts_schedules.sql"))
print("Stage 06 written.")
print("Alerts:", alert_state["alert_count"], "Schedules:", alert_state["schedule_count"])
print("Open schedules for stage 07 to close:", len(alert_state["linked_open_schedules"]))

sql7, maint_state = stage_07_maintenance.generate(rng, core_state, cert_state, assign_state, alert_state, ref_state)
sql7.write(os.path.join(OUT_DIR, "07_maintenance.sql"))
print("Stage 07 written.")
print("Jobs:", maint_state["job_count"], "Open job VINs:", maint_state["open_job_vins"])

sql8, event_state = stage_08_safety_events.generate(rng, core_state, assign_state)
sql8.write(os.path.join(OUT_DIR, "08_safety_events.sql"))
print("Stage 08 written.")
print("Events:", event_state["event_count"], "Severity mix:", event_state["severity_counts"])
print("Drivers with a Critical event:", len(event_state["critical_event_driver_ids"]))

sql9, review_state = stage_09_reviews_coaching.generate(rng, core_state, ref_state, event_state)
sql9.write(os.path.join(OUT_DIR, "09_reviews_coaching.sql"))
print("Stage 09 written.")
print("Reviews:", review_state["review_count"], "Closed:", review_state["closed_review_count"])
print("CoachingRecords:", review_state["coaching_record_count"])

sql10, appuser_state = stage_10_app_users.generate(core_state, ref_state)
sql10.write(os.path.join(OUT_DIR, "10_app_users.sql"))
print("Stage 10 written.")
print("AppUsers:", appuser_state["app_user_count"])







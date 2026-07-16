-- ==========================================================
-- 01 - REFERENCE DATA (not already seeded in schema.sql)
-- ==========================================================
-- SafetyStaff, Supplier, Part, PartSupplier. All other lookup tables are seeded directly by schema.sql and referenced by ID from config.py.
-- ==========================================================

-- SafetyStaff -- reviewers who close out EventReview rows

INSERT INTO SafetyStaff (ReviewStaffID, FullName, ContactInfo) VALUES
    (1, 'Allison Hill', '321.581.9600'),
    (2, 'Lance Hoffman', '001-486-537-9402x654'),
    (3, 'Gabrielle Davis', '855-394-0781'),
    (4, 'Sandra Montgomery', '(993)710-3413x164'),
    (5, 'Henry Santiago', '001-719-228-3276x483'),
    (6, 'Andrew Stewart', '513-695-3767x242');


-- Supplier

INSERT INTO Supplier (SupplierID, SupplierName, ContactInfo, Address, DeliveryLeadTime) VALUES
    (1, 'Richards, Hurst and Ross', '828.371.0122', '13 Cach Mang Thang Tam Street, Ha Noi', 8),
    (2, 'James-Ferrell', '648.401.8451x46270', '72 Hai Ba Trung Street, Da Nang', 18),
    (3, 'Gaines, Harrell and Evans', '+1-289-332-5288x0957', '303 Hung Vuong Street, Ha Noi', 2),
    (4, 'Koch-Decker', '430-639-1171x8227', '48 Vo Van Kiet Street, Ha Noi', 8),
    (5, 'Brennan, Henderson and Lewis', '+1-534-565-7871', '288 Vo Van Kiet Street, Ha Noi', 21),
    (6, 'Morgan PLC', '+1-239-730-1031', '113 Nguyen Thi Minh Khai Street, Can Tho', 19),
    (7, 'Palmer LLC', '+1-873-782-9973x76311', '415 Le Loi Street, Ho Chi Minh City', 6),
    (8, 'Jenkins-Shields', '9104651333', '175 Cach Mang Thang Tam Street, Can Tho', 5);


-- Part

INSERT INTO Part (PartNumber, PartName, Description, CurrentStock, ReorderThreshold, UnitPrice) VALUES
    (1, 'Brake Pad Set', NULL, 32, 13, 1764803),
    (2, 'Brake Rotor', NULL, 16, 15, 1672631),
    (3, 'Engine Oil Filter', NULL, 50, 14, 10178842),
    (4, 'Air Filter', NULL, 38, 4, 12292867),
    (5, 'Cabin Air Filter', NULL, 63, 20, 2144235),
    (6, 'Timing Belt', NULL, 53, 5, 9311704),
    (7, 'Serpentine Belt', NULL, 42, 14, 9736361),
    (8, 'Spark Plug Set', NULL, 29, 5, 818805),
    (9, 'Battery (12V)', NULL, 89, 10, 13019934),
    (10, 'EV Battery Module', NULL, 42, 5, 14399850),
    (11, 'Radiator', NULL, 34, 6, 6427459),
    (12, 'Coolant (per litre)', NULL, 40, 17, 10715015),
    (13, 'Alternator', NULL, 111, 14, 2778882),
    (14, 'Starter Motor', NULL, 52, 14, 3564944),
    (15, 'Fuel Pump', NULL, 90, 11, 11824590),
    (16, 'Tire (per unit)', NULL, 92, 5, 10269522),
    (17, 'Shock Absorber', NULL, 86, 8, 9011380),
    (18, 'Wheel Bearing', NULL, 98, 10, 2791438),
    (19, 'Clutch Kit', NULL, 64, 15, 4578972),
    (20, 'Transmission Fluid', NULL, 86, 20, 3734531),
    (21, 'Refrigerant (per kg)', NULL, 92, 13, 14190708),
    (22, 'Compressor (Refrigeration Unit)', NULL, 103, 4, 3892788),
    (23, 'Evaporator Coil', NULL, 110, 4, 13556427),
    (24, 'Windshield Wiper Set', NULL, 45, 15, 4541946),
    (25, 'Headlight Assembly', NULL, 13, 9, 9565702),
    (26, 'Oxygen Sensor', NULL, 117, 13, 3617281),
    (27, 'Turbocharger', NULL, 88, 18, 6687601),
    (28, 'Exhaust Muffler', NULL, 118, 17, 2446987),
    (29, 'CV Joint', NULL, 38, 7, 4187722),
    (30, 'Power Steering Pump', NULL, 100, 20, 9092538);


-- PartSupplier -- one primary + (usually) one backup supplier per part

INSERT INTO PartSupplier (PartNumber, SupplierID, IsPrimary, UnitCost) VALUES
    (1, 5, 1, 9847725),
    (1, 6, 0, 11015072),
    (2, 7, 1, 3719591),
    (2, 3, 0, 4647200),
    (3, 3, 1, 8319821),
    (3, 5, 0, 8660177),
    (4, 1, 1, 1879607),
    (4, 7, 0, 1983273),
    (5, 3, 1, 11456580),
    (5, 7, 0, 12798108),
    (6, 2, 1, 6442509),
    (6, 4, 0, 7454332),
    (7, 8, 1, 4258028),
    (7, 5, 0, 5294210),
    (8, 1, 1, 12131705),
    (8, 6, 0, 12693971),
    (9, 5, 1, 10793554),
    (9, 7, 0, 11853916),
    (10, 5, 1, 2693446),
    (10, 4, 0, 3028393),
    (11, 5, 1, 12823604),
    (11, 8, 0, 13606997),
    (12, 2, 1, 10530796),
    (12, 7, 0, 11464269),
    (13, 4, 1, 6313233),
    (13, 2, 0, 7546696),
    (14, 1, 1, 5478436),
    (14, 5, 0, 6203667),
    (15, 2, 1, 13993032),
    (15, 3, 0, 16869414),
    (16, 4, 1, 4081154),
    (16, 1, 0, 4986934),
    (17, 2, 1, 12319371),
    (17, 1, 0, 13942790),
    (18, 2, 1, 8977326),
    (18, 7, 0, 10738155),
    (19, 3, 1, 8013915),
    (19, 6, 0, 9919425),
    (20, 3, 1, 8892897),
    (20, 8, 0, 10855200),
    (21, 7, 1, 9087886),
    (21, 2, 0, 10848309),
    (22, 4, 1, 5269731),
    (22, 6, 0, 5858719),
    (23, 6, 1, 8723481),
    (23, 4, 0, 9803812),
    (24, 4, 1, 1114176),
    (24, 2, 0, 1223097),
    (25, 4, 1, 3734634),
    (25, 5, 0, 3815503),
    (26, 1, 1, 1170789),
    (26, 2, 0, 1438017),
    (27, 6, 1, 8666108),
    (27, 1, 0, 9313822),
    (28, 8, 1, 9086844),
    (28, 2, 0, 9545109),
    (29, 8, 1, 13203729),
    (29, 2, 0, 14904155),
    (30, 7, 1, 1622524),
    (30, 2, 0, 1691147);


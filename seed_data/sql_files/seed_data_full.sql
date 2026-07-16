-- ==========================================================
-- SMART FLEET MANAGEMENT SYSTEM -- FULL SEED DATA SCRIPT
-- ==========================================================
-- Combined output of the modular seed generator (run.py).
-- Run this AFTER schema.sql and all 5 trigger/procedure files
-- (vehicle_assignment_, maintenance_and_alert_,
-- driver_eligibility_and_safety_event_, review_coaching_and_scoring_,
-- workshop_operations_triggers.sql) have already been executed.
--
-- Run order matters -- later stages depend on earlier ones (FKs,
-- trigger cascades, and the sp_InitializeMonthlyScores prerequisite
-- for any SafetyEvent insert). Do not reorder the sections below.
-- ==========================================================

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


-- ==========================================================
-- 02 - CORE ENTITIES
-- ==========================================================
-- Depot, Workshop, Vehicle, Driver, Mechanic.
-- ==========================================================

-- Depot -- 8 depots spread across the 4 existing Locations

INSERT INTO Depot (DepotID, DepotName, Address, LocationID) VALUES
    (1, 'Ha Noi Depot 1', '221 Le Duan Street, Ha Noi', 1),
    (2, 'Da Nang Depot 1', '217 Hung Vuong Street, Da Nang', 2),
    (3, 'Ho Chi Minh City Depot 1', '240 Nguyen Hue Street, Ho Chi Minh City', 3),
    (4, 'Can Tho Depot 1', '345 Hai Ba Trung Street, Can Tho', 4),
    (5, 'Ha Noi Depot 2', '32 Bach Dang Street, Ha Noi', 1),
    (6, 'Da Nang Depot 2', '373 Ton Duc Thang Street, Da Nang', 2),
    (7, 'Ho Chi Minh City Depot 2', '410 Hai Ba Trung Street, Ho Chi Minh City', 3),
    (8, 'Can Tho Depot 2', '128 Vo Van Kiet Street, Can Tho', 4);


-- Workshop -- one per depot (DepotID is UNIQUE on this table)

INSERT INTO Workshop (WorkshopID, DepotID, Name, Address) VALUES
    (1, 1, 'Ha Noi Depot 1 Workshop', '221 Le Duan Street, Ha Noi'),
    (2, 2, 'Da Nang Depot 1 Workshop', '217 Hung Vuong Street, Da Nang'),
    (3, 3, 'Ho Chi Minh City Depot 1 Workshop', '240 Nguyen Hue Street, Ho Chi Minh City'),
    (4, 4, 'Can Tho Depot 1 Workshop', '345 Hai Ba Trung Street, Can Tho'),
    (5, 5, 'Ha Noi Depot 2 Workshop', '32 Bach Dang Street, Ha Noi'),
    (6, 6, 'Da Nang Depot 2 Workshop', '373 Ton Duc Thang Street, Da Nang'),
    (7, 7, 'Ho Chi Minh City Depot 2 Workshop', '410 Hai Ba Trung Street, Ho Chi Minh City'),
    (8, 8, 'Can Tho Depot 2 Workshop', '128 Vo Van Kiet Street, Can Tho');


-- Vehicle -- 60 vehicles, all seeded Available (later stages flip status via real trigger-firing transitions)

INSERT INTO Vehicle (VIN, RegistrationNumber, CategoryID, Model, Manufacturer, YearOfManufacture, Odometer, DepotID, OperationalStatus) VALUES
    ('J4MU6SE5GDAFSL387', '37M-160.21', 1, 'Ford Transit', 'Ford', 2015, 107346, 5, 2),
    ('6V48KNVPDDXDD79LD', '75C-971.23', 5, 'Mitsubishi Fuso 300', 'Mitsubishi Fuso', 2024, 22815, 4, 2),
    ('SCF3XTPXST2JW6XEA', '68T-676.12', 2, 'Hyundai 300', 'Hyundai', 2023, 60877, 5, 2),
    ('ES0VL5WAWGJTHGKUV', '87G-834.43', 1, 'Hino NPR', 'Hino', 2025, 171261, 5, 2),
    ('DF4UCAYJTL54AHEKC', '57S-665.18', 2, 'Hino Transit', 'Hino', 2017, 15965, 5, 2),
    ('CZPSGZ3KSLM3BMY3S', '44F-906.89', 1, 'Mitsubishi Fuso 300', 'Mitsubishi Fuso', 2021, 15151, 8, 2),
    ('6ZWRRBN2YUEUZ92YB', '24I-282.74', 1, 'Mitsubishi Fuso Dutro', 'Mitsubishi Fuso', 2015, 33417, 7, 2),
    ('X49H1NTC4AN04EYXH', '48Q-416.85', 1, 'Mitsubishi Fuso Transit', 'Mitsubishi Fuso', 2020, 110486, 5, 2),
    ('31MW2AWVP4X655P97', '31V-186.36', 3, 'Isuzu H350', 'Isuzu', 2025, 170921, 6, 2),
    ('SWRNKBCS7E63N182S', '28U-804.00', 1, 'Mitsubishi Fuso Canter', 'Mitsubishi Fuso', 2016, 209058, 7, 2),
    ('6DSH6J6X5945L75TS', '91I-884.99', 1, 'Mitsubishi Fuso H350', 'Mitsubishi Fuso', 2022, 169298, 4, 2),
    ('VSUYXFJKR1KPE33Y6', '63B-311.53', 1, 'Toyota Transit', 'Toyota', 2024, 187327, 1, 2),
    ('17AZW13R8RU48B1Y2', '31O-230.79', 4, 'Mitsubishi Fuso H350', 'Mitsubishi Fuso', 2015, 108290, 1, 2),
    ('J6MDT1XP6XY1U3TF7', '12X-652.06', 1, 'Ford Dutro', 'Ford', 2018, 175431, 2, 2),
    ('CBSNBKSJ7HP6T0LHL', '49D-692.03', 4, 'VinFast Dutro', 'VinFast', 2024, 182562, 7, 2),
    ('NESGWHCZ40E9YA38G', '65L-750.58', 2, 'VinFast Model-E', 'VinFast', 2017, 119160, 3, 2),
    ('U764UXSFU5S61YB8X', '33P-317.45', 4, 'VinFast Canter', 'VinFast', 2019, 94217, 5, 2),
    ('UANFS38S785BFVR2S', '49V-695.47', 4, 'VinFast Transit', 'VinFast', 2023, 144177, 6, 2),
    ('YZ6UWTRHNXHMNP7UV', '22G-403.29', 2, 'VinFast Dutro', 'VinFast', 2017, 84237, 1, 2),
    ('UCDVJ8GAV775YMDT7', '24C-510.62', 4, 'Isuzu 300', 'Isuzu', 2024, 170005, 1, 2),
    ('WFSH3R155W4WDGPPT', '94C-260.30', 1, 'Mitsubishi Fuso NPR', 'Mitsubishi Fuso', 2023, 24677, 3, 2),
    ('7VCRVV6ERTN4HRKUK', '19B-269.39', 1, 'Ford H350', 'Ford', 2024, 80657, 8, 2),
    ('W2U985FC4XTBFRBUC', '32P-631.83', 1, 'VinFast Transit', 'VinFast', 2019, 52576, 7, 2),
    ('F7Z3YXGLY38V2C6FX', '42K-218.98', 3, 'Ford Transit', 'Ford', 2023, 5301, 8, 2),
    ('085DPUJV58HBSLWA3', '21H-961.14', 2, 'Isuzu Transit', 'Isuzu', 2016, 174793, 3, 2),
    ('V9U377S6K1N9JEU3Y', '74I-940.00', 2, 'VinFast Dutro', 'VinFast', 2019, 158862, 8, 2),
    ('7ZY16XNS1R3CX711K', '73B-229.64', 4, 'Ford H350', 'Ford', 2020, 31309, 8, 2),
    ('AK3KE7TY2FY1X8CES', '90V-394.29', 1, 'Ford Model-E', 'Ford', 2016, 118763, 2, 2),
    ('G5LWBCXDVZ04KS3ML', '32C-724.48', 4, 'VinFast H350', 'VinFast', 2025, 68132, 8, 2),
    ('R6T6TA6VLE5ZW4T6W', '35M-973.61', 4, 'Isuzu 300', 'Isuzu', 2018, 104972, 6, 2),
    ('VB2UAD8VRZRNTJGCW', '66B-693.46', 3, 'VinFast Model-E', 'VinFast', 2017, 28627, 5, 2),
    ('MNJ09ULT7VYH6EKR2', '81L-192.50', 1, 'Ford 300', 'Ford', 2019, 145659, 2, 2),
    ('T10GR7BXRE6W3HJCC', '48P-218.12', 2, 'VinFast NPR', 'VinFast', 2023, 40563, 7, 2),
    ('3K3G83UC0P55S0G0Z', '17M-382.24', 2, 'VinFast 300', 'VinFast', 2022, 29031, 4, 2),
    ('BDYSJPEPPRYKAUKJT', '32D-776.03', 3, 'Hyundai NPR', 'Hyundai', 2015, 98911, 4, 2),
    ('MTDJ3HE7509G59RCW', '68U-131.07', 3, 'Toyota Transit', 'Toyota', 2021, 116745, 2, 2),
    ('EFXKEJUX1V694GHP4', '67H-523.43', 2, 'Ford Canter', 'Ford', 2022, 109524, 7, 2),
    ('4XT0K7EFFF4G0JDYH', '62L-994.85', 4, 'Hino Canter', 'Hino', 2021, 194021, 1, 2),
    ('WZG9PK7RGZ0HUR4BU', '13F-379.89', 5, 'Hyundai Canter', 'Hyundai', 2019, 94082, 6, 2),
    ('K2EKBFP136YL0WXFD', '29F-872.79', 1, 'Mitsubishi Fuso 300', 'Mitsubishi Fuso', 2025, 26386, 5, 2),
    ('853UP9HZ4HV8WCR2D', '10G-408.27', 2, 'Ford Canter', 'Ford', 2017, 205320, 5, 2),
    ('A84MJ1R9ZE2C4B6EX', '83N-687.51', 1, 'Toyota Model-E', 'Toyota', 2025, 114495, 5, 2),
    ('XL60F4GS42F2WYRYL', '19Q-748.14', 1, 'Toyota H350', 'Toyota', 2023, 55830, 6, 2),
    ('KSGKTNMKEM865XXK5', '18P-552.80', 1, 'Mitsubishi Fuso Dutro', 'Mitsubishi Fuso', 2019, 160037, 1, 2),
    ('W65CD0VEF916C5NX7', '74E-163.57', 1, 'Toyota 300', 'Toyota', 2020, 192253, 2, 2),
    ('CS55L00V13YDYEYG1', '46I-841.84', 2, 'Isuzu H350', 'Isuzu', 2017, 92388, 2, 2),
    ('ZW2JFW1YJF490B0WM', '37K-884.62', 3, 'Isuzu NPR', 'Isuzu', 2018, 41061, 3, 2),
    ('G9CYJ1KLML5C30S5V', '67H-646.30', 1, 'Mitsubishi Fuso Dutro', 'Mitsubishi Fuso', 2022, 55860, 6, 2),
    ('56V193LNJTD70GHVF', '30I-560.65', 3, 'Hyundai NPR', 'Hyundai', 2021, 29042, 4, 2),
    ('B3D290S1F0RBXGYKJ', '14J-949.60', 4, 'Hino Model-E', 'Hino', 2017, 203925, 8, 2),
    ('FBTPK4HVSWHDS36EH', '73T-648.02', 2, 'Toyota Model-E', 'Toyota', 2023, 155745, 4, 2),
    ('4AZS3MF0E99B17C10', '42X-116.45', 4, 'Hino Canter', 'Hino', 2016, 95387, 4, 2),
    ('GYJCZYM67MJE6CVNC', '35B-423.39', 4, 'VinFast H350', 'VinFast', 2021, 218753, 8, 2),
    ('NVZDYUH04251YM880', '76I-920.10', 1, 'Mitsubishi Fuso Model-E', 'Mitsubishi Fuso', 2021, 25690, 7, 2),
    ('MVXGFXVW54L5Z5CZ4', '45U-910.07', 3, 'Mitsubishi Fuso 300', 'Mitsubishi Fuso', 2025, 172120, 7, 2),
    ('LBK5CJES001CK5005', '19S-240.67', 1, 'Mitsubishi Fuso Dutro', 'Mitsubishi Fuso', 2021, 87414, 5, 2),
    ('BM81HTT5PV8NHJE5M', '66C-929.87', 1, 'Toyota Canter', 'Toyota', 2020, 180070, 6, 2),
    ('VWLM09RHNJS8B006J', '88C-167.39', 4, 'Hyundai Transit', 'Hyundai', 2022, 142807, 7, 2),
    ('EJXE56ZJMJ49DHKWL', '30K-826.28', 4, 'Mitsubishi Fuso Dutro', 'Mitsubishi Fuso', 2023, 79461, 2, 2),
    ('UJWF9LKLYCBFCTP3B', '73U-658.37', 1, 'VinFast Model-E', 'VinFast', 2019, 131601, 4, 2);


-- Driver -- 45 drivers (DrivingEligibility left at column default)

INSERT INTO Driver (DriverID, FullName, ContactInfo, CurrentDepotID, EmploymentStatus, EmergencyContactDetails) VALUES
    ('D-0001', 'Donald Wright', '478-810-8013', 7, 'Active', 'Mr. James Brown - (206)247-4687x2343'),
    ('D-0002', 'Amy Silva', '582.208.1219x13619', 2, 'Active', 'Jennifer Silva - 954.335.3462x47510'),
    ('D-0003', 'Daniel Baker', '(613)354-2784x980', 3, 'Active', 'Brandy Wilson - 682-944-9353'),
    ('D-0004', 'Terry Williams', '+1-264-300-5242x7868', 8, 'Active', 'Stephen Mckee - +1-605-798-2620'),
    ('D-0005', 'Rebecca Valencia', '(833)215-8692x322', 6, 'Active', 'Tim Patton - (534)221-6073x37543'),
    ('D-0006', 'Jennifer Ramirez', '645-486-8501', 6, 'Active', 'Victoria Johnson - +1-265-856-9816x934'),
    ('D-0007', 'Timothy Ryan', '001-735-861-5951x4846', 6, 'On Leave', 'Kristen Lee - +1-762-999-4680x44369'),
    ('D-0008', 'Michael Dixon', '001-221-248-9513x4332', 6, 'Active', 'John Atkinson - 476-293-6763'),
    ('D-0009', 'Shannon Mcclure', '001-763-928-7083x17278', 3, 'Terminated', 'Michelle Wagner - +1-972-577-4348'),
    ('D-0010', 'Billy Mitchell', '855-881-2236x231', 2, 'Active', 'John Brown - (569)909-6705x46688'),
    ('D-0011', 'Jeffrey Johnson', '462-972-9806x99016', 8, 'Active', 'David Murphy - 755.564.6417x080'),
    ('D-0012', 'Rachael Pearson', '001-603-730-9232x71937', 8, 'Active', 'Lawrence Adkins - 824-519-0496'),
    ('D-0013', 'Michael Burton', '749-319-0586', 2, 'Active', 'Gloria Atkinson - 916.857.2628x4987'),
    ('D-0014', 'Leslie Morris', '714.273.7996', 7, 'Active', 'Frederick Freeman MD - 954-594-8083x136'),
    ('D-0015', 'Maria Henry', '9147363495', 7, 'On Leave', 'Patrick Rivera - 001-574-544-3135x182'),
    ('D-0016', 'Destiny Lawrence', '001-689-241-3435x24082', 3, 'Active', 'Kristen Terry - (771)409-4777'),
    ('D-0017', 'Dawn Hensley', '616-371-9022', 6, 'Active', 'Bailey Duran DDS - +1-238-367-7496x499'),
    ('D-0018', 'Christine Clark', '+1-212-532-8120x67974', 3, 'Active', 'Douglas Heath - 434-693-6183'),
    ('D-0019', 'Andrea Martin', '999-347-1746x4887', 8, 'Active', 'Stacy Navarro - +1-940-913-9904x902'),
    ('D-0020', 'Catherine Richards', '+1-671-875-6551x2567', 5, 'Active', 'Krista Gibson - 945-916-8087x60385'),
    ('D-0021', 'Christina Dunn', '377-510-9324x8086', 2, 'Active', 'Susan Murray MD - (974)484-6773'),
    ('D-0022', 'Thomas Romero', '(614)965-8404', 8, 'On Leave', 'Jill Washington - 988-867-5339x63605'),
    ('D-0023', 'Matthew Hoover', '(370)928-9517', 4, 'On Leave', 'Charles Pitts - (817)745-9615'),
    ('D-0024', 'Stacy Freeman', '+1-309-313-4316', 1, 'Active', 'Michael Berger - 8504455623'),
    ('D-0025', 'Bob Pitts', '+1-637-492-3747x407', 8, 'Active', 'Tony Huerta - 664-674-3671x3695'),
    ('D-0026', 'Ronald Foster', '5905974395', 8, 'Active', 'Megan Le - +1-421-504-7095x21456'),
    ('D-0027', 'Joshua Mata', '784.324.7451x71236', 1, 'Active', 'Alexis Herrera - 754.596.5137x098'),
    ('D-0028', 'Madison Marshall', '001-446-812-0047x113', 7, 'Active', 'Michael Paul - +1-669-226-1796'),
    ('D-0029', 'Claudia Wallace', '551.358.5064', 5, 'Active', 'Samantha Davis - 390.505.3293'),
    ('D-0030', 'Robin Hall', '001-729-504-2284x21020', 7, 'Active', 'Alexis Baker - (368)911-7758'),
    ('D-0031', 'Theresa Williams', '+1-784-470-0766x17711', 7, 'Active', 'Donald Schultz - +1-856-398-4789'),
    ('D-0032', 'Ashley Pena', '001-783-667-3657x66156', 4, 'Active', 'Christian Leblanc - 211-716-1528'),
    ('D-0033', 'Jennifer Russo', '001-360-749-4519x83273', 5, 'Active', 'Holly Farmer - 001-636-289-9809'),
    ('D-0034', 'Michael Parker', '850-922-9612x01836', 8, 'Active', 'Jacob Griffith - 001-999-810-2290x14767'),
    ('D-0035', 'Paul Wilson', '(614)597-8403x69003', 5, 'Active', 'Pamela Roberts - 707-362-2683'),
    ('D-0036', 'Patrick Graham', '715.496.9664x160', 2, 'Active', 'Lisa Collier - (716)513-6968x164'),
    ('D-0037', 'Christopher Dixon', '488-635-5231', 2, 'Active', 'Lance Wolf - +1-912-377-9979x9552'),
    ('D-0038', 'Mark Hogan', '001-205-781-4770', 6, 'Active', 'Angela Lin - 999-586-7980'),
    ('D-0039', 'John Hernandez', '9719518203', 6, 'Active', 'Lisa Cox - 666-459-0515x1864'),
    ('D-0040', 'Kevin Thomas', '(346)829-1486x528', 4, 'Active', 'Alicia Parker - 357.233.2214'),
    ('D-0041', 'Sherri Williamson', '+1-962-622-9270x653', 7, 'Active', 'Rachel Young - 847.835.9774'),
    ('D-0042', 'Ruth Solis', '(640)375-8181', 1, 'Active', 'Denise Whitehead - (861)737-5060'),
    ('D-0043', 'Zachary Brooks', '4519522047', 6, 'Active', 'Aaron Miller - 232-589-8614x341'),
    ('D-0044', 'Riley Bryant', '679-880-8932', 8, 'Active', 'Harry Duncan - (218)851-8888'),
    ('D-0045', 'Amanda Hughes', '(740)751-5319x520', 3, 'Active', 'Carrie Maxwell - 772.621.7043x030');


-- Mechanic -- 25 mechanics

INSERT INTO Mechanic (MechanicID, FullName, ContactInfo, WorkshopID, EmploymentStatus) VALUES
    ('ME-0001', 'Virginia Daniels', '903-845-0541x566', 6, 'Active'),
    ('ME-0002', 'Cody Holt', '(384)316-1692x845', 5, 'Active'),
    ('ME-0003', 'Edward Griffin', '001-362-875-7059x640', 8, 'Active'),
    ('ME-0004', 'Robert Shelton', '7298702135', 5, 'Active'),
    ('ME-0005', 'Amanda Hernandez', '555.371.9285x654', 1, 'Active'),
    ('ME-0006', 'Cody Holmes', '+1-514-347-3947', 2, 'Active'),
    ('ME-0007', 'Benjamin Thompson', '001-771-555-1884x422', 5, 'Terminated'),
    ('ME-0008', 'Curtis Taylor', '805.989.5782x9114', 1, 'Active'),
    ('ME-0009', 'Patricia Morrow', '425-417-7852', 5, 'Active'),
    ('ME-0010', 'Thomas Brown', '682-342-2535', 4, 'Terminated'),
    ('ME-0011', 'Mark Pierce', '(449)481-8299', 8, 'Active'),
    ('ME-0012', 'Michelle Jacobs', '001-800-210-9439', 7, 'Active'),
    ('ME-0013', 'Mr. Dylan Frye MD', '+1-464-771-0276x77359', 4, 'Active'),
    ('ME-0014', 'Emma Travis', '(962)558-8153x714', 2, 'Active'),
    ('ME-0015', 'Anthony Dougherty', '+1-963-625-9532x787', 8, 'Active'),
    ('ME-0016', 'Brandon Long MD', '939.650.0479', 3, 'Active'),
    ('ME-0017', 'Sarah Jordan', '656-350-6098x358', 4, 'Active'),
    ('ME-0018', 'Jerry Pierce', '+1-891-221-6558x523', 8, 'Active'),
    ('ME-0019', 'Chad Cook', '687.729.8259x5269', 1, 'Active'),
    ('ME-0020', 'Katrina Burns', '001-647-205-5169', 4, 'Active'),
    ('ME-0021', 'Deborah Rios', '001-399-530-9728x96230', 8, 'Active'),
    ('ME-0022', 'Erik Hernandez', '001-936-889-7028x385', 6, 'Active'),
    ('ME-0023', 'Christopher Barr', '585-949-7334x84344', 8, 'Suspended'),
    ('ME-0024', 'Gregory Peck', '001-344-719-8665x2404', 6, 'Inactive'),
    ('ME-0025', 'Mary Burgess', '538.548.4219', 5, 'Active');


-- ==========================================================
-- 03 - CERTIFICATIONS
-- ==========================================================
-- DriverCertification and MechanicCertification. Standard License is universal for drivers; specialised certs are distributed so vehicle category gating in VehicleAssignment has real winners and losers.
-- ==========================================================

-- DriverCertification

INSERT INTO DriverCertification (DriverCertificationID, DriverID, DriverCertificationTypeID, IssueDate, ExpiryDate, RevocationDate, Status, StatusNotes) VALUES
    (1, 'D-0001', 1, '2024-09-21', '2027-02-10', '2025-08-12', 'Revoked', 'Revoked following a compliance review.'),
    (2, 'D-0001', 3, '2024-10-27', '2028-03-24', NULL, 'Active', NULL),
    (3, 'D-0001', 4, '2024-03-16', '2028-06-05', NULL, 'Active', NULL),
    (4, 'D-0002', 1, '2022-12-09', '2027-12-19', NULL, 'Active', NULL),
    (5, 'D-0002', 5, '2024-01-19', '2027-10-27', '2024-07-16', 'Revoked', 'Revoked following a compliance review.'),
    (6, 'D-0003', 1, '2023-07-04', '2028-12-14', NULL, 'Active', NULL),
    (7, 'D-0003', 2, '2023-04-19', '2028-05-14', NULL, 'Active', NULL),
    (8, 'D-0003', 3, '2024-06-18', '2027-09-02', '2025-04-22', 'Revoked', 'Revoked following a compliance review.'),
    (9, 'D-0004', 1, '2023-01-03', '2027-07-06', NULL, 'Active', NULL),
    (10, 'D-0004', 2, '2025-09-09', '2027-10-14', NULL, 'Active', NULL),
    (11, 'D-0004', 5, '2023-05-03', '2027-03-30', NULL, 'Active', NULL),
    (12, 'D-0005', 1, '2023-04-26', '2027-06-02', NULL, 'Active', NULL),
    (13, 'D-0005', 2, '2024-05-16', '2028-09-01', NULL, 'Active', NULL),
    (14, 'D-0006', 1, '2025-10-10', '2026-12-09', '2026-02-23', 'Revoked', 'Revoked following a compliance review.'),
    (15, 'D-0006', 2, '2024-12-30', '2026-09-29', '2026-03-11', 'Revoked', 'Revoked following a compliance review.'),
    (16, 'D-0006', 5, '2023-03-17', '2028-12-15', NULL, 'Active', NULL),
    (17, 'D-0007', 1, '2022-10-19', '2027-10-19', NULL, 'Active', NULL),
    (18, 'D-0007', 5, '2024-05-22', '2028-08-27', NULL, 'Active', NULL),
    (19, 'D-0008', 1, '2023-05-12', '2027-03-05', NULL, 'Active', NULL),
    (20, 'D-0009', 1, '2025-11-27', '2027-09-08', NULL, 'Active', NULL),
    (21, 'D-0009', 2, '2022-10-20', '2027-05-26', NULL, 'Active', NULL),
    (22, 'D-0010', 1, '2023-02-04', '2027-12-25', NULL, 'Active', NULL),
    (23, 'D-0010', 2, '2025-06-13', '2027-04-02', NULL, 'Active', NULL),
    (24, 'D-0011', 1, '2023-06-25', '2027-10-13', NULL, 'Active', NULL),
    (25, 'D-0011', 4, '2024-04-16', '2028-06-18', NULL, 'Active', NULL),
    (26, 'D-0012', 1, '2025-04-27', '2027-04-22', NULL, 'Active', NULL),
    (27, 'D-0012', 2, '2023-09-17', '2028-10-30', NULL, 'Active', NULL),
    (28, 'D-0012', 5, '2024-03-29', '2028-08-25', NULL, 'Active', NULL),
    (29, 'D-0013', 1, '2025-03-27', '2028-02-18', NULL, 'Active', NULL),
    (30, 'D-0013', 3, '2022-08-03', '2028-10-28', NULL, 'Active', NULL),
    (31, 'D-0013', 5, '2022-11-27', '2027-10-03', '2025-12-31', 'Revoked', 'Revoked following a compliance review.'),
    (32, 'D-0014', 1, '2022-08-23', '2026-05-28', NULL, 'Expired', NULL),
    (33, 'D-0015', 1, '2025-05-10', '2028-05-23', NULL, 'Active', NULL),
    (34, 'D-0016', 1, '2023-01-25', '2028-10-06', NULL, 'Active', NULL),
    (35, 'D-0016', 3, '2024-10-31', '2028-03-24', NULL, 'Active', NULL),
    (36, 'D-0016', 5, '2025-06-22', '2025-11-22', NULL, 'Expired', NULL),
    (37, 'D-0017', 1, '2025-08-29', '2028-09-28', NULL, 'Active', NULL),
    (38, 'D-0018', 1, '2024-10-05', '2026-12-26', NULL, 'Active', NULL),
    (39, 'D-0019', 1, '2025-08-06', '2028-03-07', '2025-09-13', 'Reinstated', 'Reinstated after remedial action.'),
    (40, 'D-0019', 5, '2024-05-17', '2027-03-28', NULL, 'Active', NULL),
    (41, 'D-0020', 1, '2023-11-03', '2027-12-01', NULL, 'Active', NULL),
    (42, 'D-0021', 1, '2024-01-13', '2028-05-13', NULL, 'Active', NULL),
    (43, 'D-0021', 2, '2023-10-13', '2028-11-24', NULL, 'Active', NULL),
    (44, 'D-0022', 1, '2023-05-22', '2028-05-20', NULL, 'Active', NULL),
    (45, 'D-0023', 1, '2025-02-11', '2028-11-21', NULL, 'Active', NULL),
    (46, 'D-0023', 4, '2025-05-08', '2028-09-16', NULL, 'Active', NULL),
    (47, 'D-0024', 1, '2024-10-29', '2028-07-10', NULL, 'Active', NULL),
    (48, 'D-0024', 2, '2025-10-18', '2028-09-28', NULL, 'Active', NULL),
    (49, 'D-0024', 5, '2025-09-17', '2026-12-25', NULL, 'Active', NULL),
    (50, 'D-0025', 1, '2025-09-01', '2027-09-02', NULL, 'Active', NULL),
    (51, 'D-0025', 2, '2024-09-02', '2025-09-17', NULL, 'Expired', NULL),
    (52, 'D-0025', 3, '2024-03-12', '2028-09-28', NULL, 'Active', NULL),
    (53, 'D-0025', 4, '2024-03-09', '2027-04-05', NULL, 'Active', NULL),
    (54, 'D-0026', 1, '2022-11-11', '2027-09-22', '2023-12-04', 'Revoked', 'Revoked following a compliance review.'),
    (55, 'D-0026', 5, '2022-06-22', '2028-06-01', NULL, 'Active', NULL),
    (56, 'D-0027', 1, '2023-01-16', '2028-01-10', NULL, 'Active', NULL),
    (57, 'D-0028', 1, '2024-08-19', '2026-02-05', NULL, 'Expired', NULL),
    (58, 'D-0028', 2, '2025-03-05', '2026-06-09', NULL, 'Expired', NULL),
    (59, 'D-0028', 3, '2022-10-31', '2028-01-10', NULL, 'Active', NULL),
    (60, 'D-0028', 4, '2022-11-10', '2027-12-12', NULL, 'Active', NULL),
    (61, 'D-0029', 1, '2023-11-27', '2028-11-20', NULL, 'Active', NULL),
    (62, 'D-0029', 2, '2024-11-30', '2027-12-01', NULL, 'Active', NULL),
    (63, 'D-0029', 3, '2022-08-05', '2027-01-23', NULL, 'Active', NULL),
    (64, 'D-0030', 1, '2023-04-19', '2027-10-16', NULL, 'Active', NULL),
    (65, 'D-0030', 2, '2024-04-14', '2026-09-18', '2024-12-16', 'Revoked', 'Revoked following a compliance review.'),
    (66, 'D-0031', 1, '2023-04-20', '2027-09-02', '2024-07-11', 'Revoked', 'Revoked following a compliance review.'),
    (67, 'D-0031', 4, '2023-10-05', '2027-06-20', '2024-09-28', 'Revoked', 'Revoked following a compliance review.'),
    (68, 'D-0032', 1, '2024-07-08', '2028-04-02', NULL, 'Active', NULL),
    (69, 'D-0033', 1, '2024-03-10', '2027-03-19', '2025-02-23', 'Revoked', 'Revoked following a compliance review.'),
    (70, 'D-0034', 1, '2024-07-09', '2028-06-30', NULL, 'Active', NULL),
    (71, 'D-0034', 2, '2022-09-26', '2027-09-08', NULL, 'Active', NULL),
    (72, 'D-0034', 4, '2025-02-16', '2027-07-03', NULL, 'Active', NULL),
    (73, 'D-0034', 5, '2023-11-09', '2027-07-19', NULL, 'Active', NULL),
    (74, 'D-0035', 1, '2023-03-31', '2028-03-26', '2025-11-28', 'Reinstated', 'Reinstated after remedial action.'),
    (75, 'D-0035', 5, '2025-01-15', '2027-11-05', NULL, 'Active', NULL),
    (76, 'D-0036', 1, '2022-12-11', '2027-01-09', '2025-12-18', 'Reinstated', 'Reinstated after remedial action.'),
    (77, 'D-0036', 2, '2025-10-17', '2026-05-31', NULL, 'Expired', NULL),
    (78, 'D-0037', 1, '2022-06-13', '2028-11-03', NULL, 'Active', NULL),
    (79, 'D-0038', 1, '2022-07-12', '2027-08-14', '2025-05-06', 'Revoked', 'Revoked following a compliance review.'),
    (80, 'D-0038', 2, '2025-11-23', '2028-05-27', NULL, 'Active', NULL),
    (81, 'D-0038', 3, '2023-09-05', '2028-05-05', NULL, 'Active', NULL),
    (82, 'D-0038', 5, '2024-06-11', '2027-08-30', NULL, 'Active', NULL),
    (83, 'D-0039', 1, '2024-12-23', '2027-02-16', NULL, 'Active', NULL),
    (84, 'D-0039', 2, '2023-01-17', '2027-05-25', NULL, 'Active', NULL),
    (85, 'D-0040', 1, '2025-07-17', '2027-12-30', NULL, 'Active', NULL),
    (86, 'D-0040', 3, '2023-05-30', '2028-10-23', NULL, 'Active', NULL),
    (87, 'D-0041', 1, '2025-10-22', '2027-12-03', NULL, 'Active', NULL),
    (88, 'D-0041', 2, '2023-11-14', '2027-01-06', NULL, 'Active', NULL),
    (89, 'D-0042', 1, '2024-02-16', '2027-02-15', NULL, 'Active', NULL),
    (90, 'D-0042', 4, '2023-01-09', '2027-01-06', '2024-04-15', 'Revoked', 'Revoked following a compliance review.'),
    (91, 'D-0043', 1, '2025-07-26', '2027-08-24', NULL, 'Active', NULL),
    (92, 'D-0043', 5, '2022-12-09', '2026-12-13', NULL, 'Active', NULL),
    (93, 'D-0044', 1, '2025-03-05', '2028-11-08', NULL, 'Active', NULL),
    (94, 'D-0044', 2, '2023-10-02', '2027-02-11', '2024-04-15', 'Revoked', 'Revoked following a compliance review.'),
    (95, 'D-0044', 4, '2022-10-28', '2027-12-13', NULL, 'Active', NULL),
    (96, 'D-0044', 5, '2022-12-14', '2028-12-22', NULL, 'Active', NULL),
    (97, 'D-0045', 1, '2024-01-17', '2028-01-31', NULL, 'Active', NULL),
    (98, 'D-0045', 5, '2024-09-06', '2026-01-15', NULL, 'Expired', NULL),
    (99, 'D-0035', 2, '2025-06-17', '2028-09-26', NULL, 'Active', 'Top-up grant to guarantee category coverage.'),
    (100, 'D-0035', 3, '2024-09-22', '2028-12-18', NULL, 'Active', 'Top-up grant to guarantee category coverage.'),
    (101, 'D-0037', 2, '2024-11-03', '2027-10-26', NULL, 'Active', 'Top-up grant to guarantee category coverage.'),
    (102, 'D-0037', 3, '2025-11-29', '2027-10-12', NULL, 'Active', 'Top-up grant to guarantee category coverage.'),
    (103, 'D-0014', 1, '2024-12-28', '2027-10-16', NULL, 'Active', 'Top-up grant to guarantee category coverage.'),
    (104, 'D-0014', 2, '2025-01-27', '2028-08-10', NULL, 'Active', 'Top-up grant to guarantee category coverage.'),
    (105, 'D-0014', 3, '2025-12-13', '2028-05-06', NULL, 'Active', 'Top-up grant to guarantee category coverage.'),
    (106, 'D-0038', 1, '2024-10-28', '2028-08-13', NULL, 'Active', 'Top-up grant to guarantee category coverage.');


-- MechanicCertification

INSERT INTO MechanicCertification (MechanicCertificationID, MechanicID, MechanicCertificationTypeID, IssueDate, ExpiryDate, RevocationDate, Status, StatusNotes) VALUES
    (1, 'ME-0001', 1, '2024-08-15', '2027-05-02', NULL, 'Active', NULL),
    (2, 'ME-0002', 1, '2024-06-24', '2027-01-13', NULL, 'Active', NULL),
    (3, 'ME-0002', 3, '2025-01-17', '2028-01-15', NULL, 'Active', NULL),
    (4, 'ME-0002', 4, '2024-04-21', '2027-01-27', NULL, 'Active', NULL),
    (5, 'ME-0003', 1, '2023-03-16', '2027-05-29', NULL, 'Active', NULL),
    (6, 'ME-0004', 1, '2023-10-07', '2028-08-06', NULL, 'Active', NULL),
    (7, 'ME-0004', 3, '2023-11-08', '2026-01-21', NULL, 'Expired', NULL),
    (8, 'ME-0004', 4, '2023-07-08', '2028-09-06', NULL, 'Active', NULL),
    (9, 'ME-0005', 1, '2024-11-09', '2027-05-10', NULL, 'Active', NULL),
    (10, 'ME-0005', 3, '2023-10-02', '2027-09-04', '2025-11-22', 'Reinstated', 'Reinstated after remedial action.'),
    (11, 'ME-0006', 1, '2024-08-16', '2027-08-24', NULL, 'Active', NULL),
    (12, 'ME-0007', 1, '2022-10-28', '2028-05-21', NULL, 'Active', NULL),
    (13, 'ME-0007', 4, '2024-12-22', '2028-05-26', NULL, 'Active', NULL),
    (14, 'ME-0008', 1, '2024-10-22', '2027-09-04', NULL, 'Active', NULL),
    (15, 'ME-0008', 2, '2025-08-06', '2025-12-11', NULL, 'Expired', NULL),
    (16, 'ME-0009', 1, '2024-07-26', '2028-11-11', NULL, 'Active', NULL),
    (17, 'ME-0009', 3, '2023-08-12', '2026-06-01', NULL, 'Expired', NULL),
    (18, 'ME-0010', 1, '2022-12-27', '2028-10-18', NULL, 'Active', NULL),
    (19, 'ME-0011', 1, '2022-12-22', '2027-02-05', NULL, 'Active', NULL),
    (20, 'ME-0011', 3, '2025-05-16', '2028-09-13', NULL, 'Active', NULL),
    (21, 'ME-0012', 1, '2022-10-29', '2027-12-24', '2024-10-07', 'Reinstated', 'Reinstated after remedial action.'),
    (22, 'ME-0012', 3, '2023-07-28', '2027-02-18', NULL, 'Active', NULL),
    (23, 'ME-0013', 1, '2022-09-24', '2027-06-24', NULL, 'Active', NULL),
    (24, 'ME-0014', 1, '2022-09-07', '2027-04-13', NULL, 'Active', NULL),
    (25, 'ME-0015', 1, '2023-08-27', '2026-10-24', '2024-01-22', 'Revoked', 'Revoked following a compliance review.'),
    (26, 'ME-0015', 3, '2025-03-10', '2027-10-27', NULL, 'Active', NULL),
    (27, 'ME-0015', 4, '2023-06-07', '2025-10-15', NULL, 'Expired', NULL),
    (28, 'ME-0016', 1, '2023-06-13', '2027-09-13', NULL, 'Active', NULL),
    (29, 'ME-0017', 1, '2024-01-23', '2028-10-03', NULL, 'Active', NULL),
    (30, 'ME-0017', 2, '2025-01-23', '2027-09-25', '2025-06-26', 'Revoked', 'Revoked following a compliance review.'),
    (31, 'ME-0017', 4, '2023-02-03', '2027-04-22', NULL, 'Active', NULL),
    (32, 'ME-0018', 1, '2023-09-18', '2027-05-19', NULL, 'Active', NULL),
    (33, 'ME-0019', 1, '2022-07-17', '2025-11-20', NULL, 'Expired', NULL),
    (34, 'ME-0019', 4, '2022-08-31', '2026-11-14', NULL, 'Active', NULL),
    (35, 'ME-0020', 1, '2025-08-19', '2028-05-12', NULL, 'Active', NULL),
    (36, 'ME-0021', 1, '2024-07-06', '2028-03-25', NULL, 'Active', NULL),
    (37, 'ME-0021', 2, '2023-01-10', '2027-09-26', '2025-04-14', 'Reinstated', 'Reinstated after remedial action.'),
    (38, 'ME-0022', 1, '2023-06-02', '2028-09-29', NULL, 'Active', NULL),
    (39, 'ME-0023', 1, '2025-07-05', '2027-09-26', NULL, 'Active', NULL),
    (40, 'ME-0024', 1, '2025-03-11', '2028-01-12', NULL, 'Active', NULL),
    (41, 'ME-0024', 2, '2022-08-22', '2027-12-07', NULL, 'Active', NULL),
    (42, 'ME-0024', 4, '2023-08-12', '2028-08-21', NULL, 'Active', NULL),
    (43, 'ME-0025', 1, '2025-01-05', '2028-03-25', NULL, 'Active', NULL),
    (44, 'ME-0014', 2, '2025-10-02', '2027-08-13', NULL, 'Active', 'Top-up grant to guarantee activity-type coverage.'),
    (45, 'ME-0016', 2, '2025-05-14', '2028-05-07', NULL, 'Active', 'Top-up grant to guarantee activity-type coverage.');


-- ==========================================================
-- 04 - MONTHLY SCORE INITIALIZATION
-- ==========================================================
-- Calls sp_InitializeMonthlyScores for every calendar month touched by the 6-month window, so DriverMonthlySafetyScore rows exist before any SafetyEvent is inserted in stage 08.
-- ==========================================================

CALL sp_InitializeMonthlyScores(1, 2026);

CALL sp_InitializeMonthlyScores(2, 2026);

CALL sp_InitializeMonthlyScores(3, 2026);

CALL sp_InitializeMonthlyScores(4, 2026);

CALL sp_InitializeMonthlyScores(5, 2026);

CALL sp_InitializeMonthlyScores(6, 2026);

CALL sp_InitializeMonthlyScores(7, 2026);


-- ==========================================================
-- 05 - VEHICLE ASSIGNMENTS
-- ==========================================================
-- Per-vehicle assignment history over the 6-month window. Historical rows insert directly Completed/Cancelled (skip the live gate by design); a handful of vehicles get one live In Operation/Pending row as of today that goes through the real eligibility gate.
-- ==========================================================

-- VehicleAssignment -- 219 rows across 60 vehicles (10 live In Operation, 5 live Pending)

INSERT INTO VehicleAssignment (AssignmentID, VIN, DriverID, DepotID, IssueDate, StartDate, EndDate, AssignmentStatus) VALUES
    (1, 'J4MU6SE5GDAFSL387', 'D-0043', 5, '2026-01-23 14:00:00', '2026-01-24 23:00:00', '2026-01-27 01:00:00', 'Completed'),
    (2, 'J4MU6SE5GDAFSL387', 'D-0045', 5, '2026-02-10 03:00:00', '2026-02-11 14:00:00', '2026-02-18 17:00:00', 'Completed'),
    (3, 'J4MU6SE5GDAFSL387', 'D-0011', 5, '2026-03-02 13:00:00', '2026-03-03 00:00:00', '2026-03-04 06:00:00', 'Completed'),
    (4, 'J4MU6SE5GDAFSL387', 'D-0013', 5, '2026-07-11 17:00:00', NULL, NULL, 'Pending'),
    (5, '6V48KNVPDDXDD79LD', 'D-0012', 4, '2026-01-28 15:00:00', '2026-01-29 05:00:00', '2026-02-07 14:00:00', 'Completed'),
    (6, '6V48KNVPDDXDD79LD', 'D-0012', 4, '2026-02-20 21:00:00', '2026-02-22 05:00:00', '2026-03-01 06:00:00', 'Completed'),
    (7, '6V48KNVPDDXDD79LD', 'D-0038', 4, '2026-03-07 16:00:00', '2026-03-08 01:00:00', '2026-03-15 10:00:00', 'Completed'),
    (8, '6V48KNVPDDXDD79LD', 'D-0004', 4, '2026-03-25 12:00:00', NULL, '2026-03-30 16:00:00', 'Cancelled'),
    (9, '6V48KNVPDDXDD79LD', 'D-0034', 4, '2026-04-07 14:00:00', '2026-04-08 16:00:00', '2026-04-11 02:00:00', 'Completed'),
    (10, 'SCF3XTPXST2JW6XEA', 'D-0038', 5, '2026-01-22 12:00:00', '2026-01-22 22:00:00', '2026-02-01 03:00:00', 'Completed'),
    (11, 'SCF3XTPXST2JW6XEA', 'D-0029', 5, '2026-02-13 10:00:00', '2026-02-13 14:00:00', '2026-02-17 15:00:00', 'Completed'),
    (12, 'SCF3XTPXST2JW6XEA', 'D-0038', 5, '2026-02-23 12:00:00', NULL, '2026-02-28 13:00:00', 'Cancelled'),
    (13, 'ES0VL5WAWGJTHGKUV', 'D-0016', 5, '2026-01-23 05:00:00', '2026-01-23 22:00:00', '2026-01-27 03:00:00', 'Completed'),
    (14, 'ES0VL5WAWGJTHGKUV', 'D-0036', 5, '2026-02-03 07:00:00', '2026-02-03 19:00:00', '2026-02-05 03:00:00', 'Completed'),
    (15, 'ES0VL5WAWGJTHGKUV', 'D-0036', 5, '2026-02-18 09:00:00', '2026-02-20 08:00:00', '2026-03-01 20:00:00', 'Completed'),
    (16, 'ES0VL5WAWGJTHGKUV', 'D-0044', 5, '2026-03-04 14:00:00', '2026-03-06 03:00:00', '2026-03-07 09:00:00', 'Completed'),
    (17, 'ES0VL5WAWGJTHGKUV', 'D-0003', 5, '2026-03-22 07:00:00', '2026-03-24 04:00:00', '2026-04-03 04:00:00', 'Completed'),
    (18, 'DF4UCAYJTL54AHEKC', 'D-0038', 5, '2026-01-18 02:00:00', '2026-01-19 07:00:00', '2026-01-22 08:00:00', 'Completed'),
    (19, 'DF4UCAYJTL54AHEKC', 'D-0029', 5, '2026-01-23 13:00:00', '2026-01-25 02:00:00', '2026-02-01 13:00:00', 'Completed'),
    (20, 'DF4UCAYJTL54AHEKC', 'D-0038', 5, '2026-02-05 00:00:00', '2026-02-05 14:00:00', '2026-02-08 18:00:00', 'Completed'),
    (21, 'CZPSGZ3KSLM3BMY3S', 'D-0007', 8, '2026-01-18 21:00:00', NULL, '2026-01-29 07:00:00', 'Cancelled'),
    (22, 'CZPSGZ3KSLM3BMY3S', 'D-0011', 8, '2026-02-11 14:00:00', '2026-02-13 03:00:00', '2026-02-20 08:00:00', 'Completed'),
    (23, 'CZPSGZ3KSLM3BMY3S', 'D-0037', 8, '2026-02-22 19:00:00', NULL, '2026-03-04 02:00:00', 'Cancelled'),
    (24, 'CZPSGZ3KSLM3BMY3S', 'D-0011', 8, '2026-03-07 22:00:00', NULL, '2026-03-14 11:00:00', 'Cancelled'),
    (25, 'CZPSGZ3KSLM3BMY3S', 'D-0019', 8, '2026-03-23 13:00:00', '2026-03-24 11:00:00', '2026-04-03 20:00:00', 'Completed'),
    (26, '6ZWRRBN2YUEUZ92YB', 'D-0005', 7, '2026-01-17 11:00:00', '2026-01-19 04:00:00', '2026-01-24 05:00:00', 'Completed'),
    (27, '6ZWRRBN2YUEUZ92YB', 'D-0018', 7, '2026-02-03 02:00:00', '2026-02-04 09:00:00', '2026-02-14 12:00:00', 'Completed'),
    (28, '6ZWRRBN2YUEUZ92YB', 'D-0016', 7, '2026-02-17 16:00:00', '2026-02-19 05:00:00', '2026-03-01 14:00:00', 'Completed'),
    (29, 'X49H1NTC4AN04EYXH', 'D-0011', 5, '2026-01-16 15:00:00', '2026-01-18 15:00:00', '2026-01-27 03:00:00', 'Completed'),
    (30, 'X49H1NTC4AN04EYXH', 'D-0044', 5, '2026-02-05 15:00:00', NULL, '2026-02-09 18:00:00', 'Cancelled'),
    (31, 'X49H1NTC4AN04EYXH', 'D-0015', 5, '2026-02-22 16:00:00', '2026-02-24 10:00:00', '2026-03-01 16:00:00', 'Completed'),
    (32, '31MW2AWVP4X655P97', 'D-0025', 6, '2026-01-17 05:00:00', '2026-01-17 07:00:00', '2026-01-25 11:00:00', 'Completed'),
    (33, '31MW2AWVP4X655P97', 'D-0011', 6, '2026-02-05 09:00:00', '2026-02-06 22:00:00', '2026-02-11 03:00:00', 'Completed'),
    (34, '31MW2AWVP4X655P97', 'D-0011', 6, '2026-02-20 12:00:00', '2026-02-20 23:00:00', '2026-03-02 01:00:00', 'Completed'),
    (35, '31MW2AWVP4X655P97', 'D-0011', 6, '2026-03-14 18:00:00', NULL, '2026-03-21 16:00:00', 'Cancelled'),
    (36, '31MW2AWVP4X655P97', 'D-0025', 6, '2026-03-27 10:00:00', '2026-03-28 05:00:00', '2026-04-05 06:00:00', 'Completed'),
    (37, 'SWRNKBCS7E63N182S', 'D-0021', 7, '2026-01-16 03:00:00', '2026-01-17 04:00:00', '2026-01-26 08:00:00', 'Completed'),
    (38, 'SWRNKBCS7E63N182S', 'D-0010', 7, '2026-02-02 08:00:00', '2026-02-02 11:00:00', '2026-02-11 14:00:00', 'Completed'),
    (39, 'SWRNKBCS7E63N182S', 'D-0025', 7, '2026-02-15 21:00:00', '2026-02-17 20:00:00', '2026-02-20 23:00:00', 'Completed'),
    (40, 'SWRNKBCS7E63N182S', 'D-0014', 7, '2026-02-28 02:00:00', '2026-03-01 11:00:00', '2026-03-11 12:00:00', 'Completed'),
    (41, 'SWRNKBCS7E63N182S', 'D-0018', 7, '2026-07-12 03:00:00', NULL, NULL, 'Pending'),
    (42, '6DSH6J6X5945L75TS', 'D-0020', 4, '2026-01-25 21:00:00', '2026-01-27 00:00:00', '2026-01-30 01:00:00', 'Completed'),
    (43, '6DSH6J6X5945L75TS', 'D-0036', 4, '2026-02-07 12:00:00', '2026-02-09 07:00:00', '2026-02-16 09:00:00', 'Completed'),
    (44, '6DSH6J6X5945L75TS', 'D-0009', 4, '2026-02-18 02:00:00', '2026-02-19 14:00:00', '2026-02-20 15:00:00', 'Completed'),
    (45, '6DSH6J6X5945L75TS', 'D-0044', 4, '2026-02-22 23:00:00', '2026-02-24 15:00:00', '2026-02-28 18:00:00', 'Completed'),
    (46, 'VSUYXFJKR1KPE33Y6', 'D-0004', 1, '2026-01-24 04:00:00', '2026-01-24 20:00:00', '2026-01-30 02:00:00', 'Completed'),
    (47, 'VSUYXFJKR1KPE33Y6', 'D-0037', 1, '2026-02-02 03:00:00', '2026-02-03 22:00:00', '2026-02-05 01:00:00', 'Completed'),
    (48, 'VSUYXFJKR1KPE33Y6', 'D-0009', 1, '2026-02-19 08:00:00', '2026-02-21 01:00:00', '2026-02-27 13:00:00', 'Completed'),
    (49, 'VSUYXFJKR1KPE33Y6', 'D-0003', 1, '2026-03-08 20:00:00', '2026-03-09 08:00:00', '2026-03-18 09:00:00', 'Completed'),
    (50, '17AZW13R8RU48B1Y2', 'D-0007', 1, '2026-01-28 22:00:00', '2026-01-29 22:00:00', '2026-02-08 10:00:00', 'Completed'),
    (51, '17AZW13R8RU48B1Y2', 'D-0020', 1, '2026-02-18 17:00:00', '2026-02-19 10:00:00', '2026-02-26 16:00:00', 'Completed'),
    (52, '17AZW13R8RU48B1Y2', 'D-0039', 1, '2026-07-12 13:00:00', NULL, NULL, 'Pending'),
    (53, 'J6MDT1XP6XY1U3TF7', 'D-0034', 2, '2026-01-24 08:00:00', '2026-01-25 01:00:00', '2026-01-27 04:00:00', 'Completed'),
    (54, 'J6MDT1XP6XY1U3TF7', 'D-0017', 2, '2026-02-02 13:00:00', '2026-02-03 21:00:00', '2026-02-12 22:00:00', 'Completed'),
    (55, 'J6MDT1XP6XY1U3TF7', 'D-0005', 2, '2026-02-21 22:00:00', '2026-02-23 17:00:00', '2026-02-28 05:00:00', 'Completed'),
    (56, 'J6MDT1XP6XY1U3TF7', 'D-0027', 2, '2026-03-06 23:00:00', '2026-03-08 17:00:00', '2026-03-11 01:00:00', 'Completed'),
    (57, 'CBSNBKSJ7HP6T0LHL', 'D-0035', 7, '2026-01-17 00:00:00', '2026-01-18 14:00:00', '2026-01-21 16:00:00', 'Completed'),
    (58, 'CBSNBKSJ7HP6T0LHL', 'D-0013', 7, '2026-01-26 04:00:00', '2026-01-27 05:00:00', '2026-01-30 06:00:00', 'Cancelled'),
    (59, 'CBSNBKSJ7HP6T0LHL', 'D-0041', 7, '2026-02-09 23:00:00', '2026-02-11 02:00:00', '2026-02-16 05:00:00', 'Cancelled'),
    (60, 'NESGWHCZ40E9YA38G', 'D-0037', 3, '2026-01-20 04:00:00', NULL, '2026-01-24 16:00:00', 'Cancelled'),
    (61, 'NESGWHCZ40E9YA38G', 'D-0035', 3, '2026-02-07 02:00:00', '2026-02-08 14:00:00', '2026-02-19 01:00:00', 'Completed'),
    (62, 'NESGWHCZ40E9YA38G', 'D-0037', 3, '2026-03-04 03:00:00', '2026-03-04 13:00:00', '2026-03-12 22:00:00', 'Completed'),
    (63, 'NESGWHCZ40E9YA38G', 'D-0029', 3, '2026-03-15 17:00:00', '2026-03-15 20:00:00', '2026-03-23 02:00:00', 'Completed'),
    (64, 'NESGWHCZ40E9YA38G', 'D-0029', 3, '2026-04-05 07:00:00', '2026-04-07 00:00:00', '2026-04-15 07:00:00', 'Cancelled'),
    (65, 'U764UXSFU5S61YB8X', 'D-0040', 5, '2026-01-22 22:00:00', '2026-01-24 19:00:00', '2026-01-29 04:00:00', 'Completed'),
    (66, 'U764UXSFU5S61YB8X', 'D-0003', 5, '2026-02-07 13:00:00', '2026-02-08 11:00:00', '2026-02-10 23:00:00', 'Completed'),
    (67, 'U764UXSFU5S61YB8X', 'D-0040', 5, '2026-02-19 09:00:00', '2026-02-20 08:00:00', '2026-02-24 17:00:00', 'Completed'),
    (68, 'U764UXSFU5S61YB8X', 'D-0003', 5, '2026-02-26 09:00:00', NULL, '2026-03-07 21:00:00', 'Cancelled'),
    (69, 'U764UXSFU5S61YB8X', 'D-0004', 5, '2026-07-12 11:00:00', '2026-07-13 06:00:00', NULL, 'In Operation'),
    (70, 'UANFS38S785BFVR2S', 'D-0002', 6, '2026-01-28 02:00:00', '2026-01-28 09:00:00', '2026-02-05 20:00:00', 'Completed'),
    (71, 'UANFS38S785BFVR2S', 'D-0044', 6, '2026-02-19 22:00:00', '2026-02-20 04:00:00', '2026-02-23 09:00:00', 'Completed'),
    (72, 'UANFS38S785BFVR2S', 'D-0002', 6, '2026-02-28 16:00:00', '2026-03-01 08:00:00', '2026-03-06 15:00:00', 'Completed'),
    (73, 'UANFS38S785BFVR2S', 'D-0018', 6, '2026-03-08 07:00:00', '2026-03-08 16:00:00', '2026-03-14 20:00:00', 'Completed'),
    (74, 'YZ6UWTRHNXHMNP7UV', 'D-0035', 1, '2026-01-24 20:00:00', '2026-01-26 12:00:00', '2026-02-03 16:00:00', 'Completed'),
    (75, 'YZ6UWTRHNXHMNP7UV', 'D-0037', 1, '2026-02-06 17:00:00', '2026-02-08 04:00:00', '2026-02-09 06:00:00', 'Completed'),
    (76, 'YZ6UWTRHNXHMNP7UV', 'D-0014', 1, '2026-02-21 06:00:00', NULL, '2026-02-23 23:00:00', 'Cancelled'),
    (77, 'UCDVJ8GAV775YMDT7', 'D-0024', 1, '2026-01-25 07:00:00', '2026-01-26 05:00:00', '2026-01-28 17:00:00', 'Completed'),
    (78, 'UCDVJ8GAV775YMDT7', 'D-0038', 1, '2026-02-09 02:00:00', '2026-02-09 15:00:00', '2026-02-15 15:00:00', 'Completed'),
    (79, 'UCDVJ8GAV775YMDT7', 'D-0023', 1, '2026-02-20 01:00:00', '2026-02-21 13:00:00', '2026-02-28 01:00:00', 'Completed'),
    (80, 'UCDVJ8GAV775YMDT7', 'D-0043', 1, '2026-03-15 01:00:00', '2026-03-16 17:00:00', '2026-03-23 05:00:00', 'Completed'),
    (81, 'WFSH3R155W4WDGPPT', 'D-0022', 3, '2026-01-24 04:00:00', '2026-01-24 09:00:00', '2026-01-25 12:00:00', 'Completed'),
    (82, 'WFSH3R155W4WDGPPT', 'D-0040', 3, '2026-02-07 09:00:00', '2026-02-08 13:00:00', '2026-02-10 15:00:00', 'Completed'),
    (83, 'WFSH3R155W4WDGPPT', 'D-0040', 3, '2026-07-12 19:00:00', NULL, NULL, 'Pending'),
    (84, '7VCRVV6ERTN4HRKUK', 'D-0009', 8, '2026-01-26 00:00:00', '2026-01-26 07:00:00', '2026-02-05 17:00:00', 'Completed'),
    (85, '7VCRVV6ERTN4HRKUK', 'D-0022', 8, '2026-02-10 06:00:00', '2026-02-11 01:00:00', '2026-02-18 03:00:00', 'Completed'),
    (86, '7VCRVV6ERTN4HRKUK', 'D-0039', 8, '2026-02-24 14:00:00', '2026-02-26 05:00:00', '2026-02-27 17:00:00', 'Completed'),
    (87, '7VCRVV6ERTN4HRKUK', 'D-0042', 8, '2026-03-12 15:00:00', '2026-03-14 10:00:00', '2026-03-15 16:00:00', 'Completed'),
    (88, '7VCRVV6ERTN4HRKUK', 'D-0016', 8, '2026-03-16 23:00:00', '2026-03-18 09:00:00', '2026-03-23 14:00:00', 'Completed'),
    (89, 'W2U985FC4XTBFRBUC', 'D-0030', 7, '2026-01-19 04:00:00', '2026-01-21 02:00:00', '2026-01-30 04:00:00', 'Completed'),
    (90, 'W2U985FC4XTBFRBUC', 'D-0042', 7, '2026-02-02 20:00:00', '2026-02-04 11:00:00', '2026-02-12 22:00:00', 'Completed'),
    (91, 'W2U985FC4XTBFRBUC', 'D-0042', 7, '2026-07-12 15:00:00', '2026-07-13 07:00:00', NULL, 'In Operation'),
    (92, 'F7Z3YXGLY38V2C6FX', 'D-0044', 8, '2026-01-20 16:00:00', '2026-01-21 21:00:00', '2026-01-22 23:00:00', 'Completed'),
    (93, 'F7Z3YXGLY38V2C6FX', 'D-0034', 8, '2026-01-29 21:00:00', '2026-01-31 15:00:00', '2026-02-04 02:00:00', 'Completed'),
    (94, 'F7Z3YXGLY38V2C6FX', 'D-0034', 8, '2026-02-15 13:00:00', '2026-02-15 19:00:00', '2026-02-25 06:00:00', 'Completed'),
    (95, 'F7Z3YXGLY38V2C6FX', 'D-0034', 8, '2026-02-26 11:00:00', '2026-02-27 09:00:00', '2026-03-09 19:00:00', 'Completed'),
    (96, '085DPUJV58HBSLWA3', 'D-0014', 3, '2026-01-18 15:00:00', '2026-01-20 14:00:00', '2026-01-28 18:00:00', 'Completed'),
    (97, '085DPUJV58HBSLWA3', 'D-0014', 3, '2026-02-08 02:00:00', '2026-02-08 03:00:00', '2026-02-16 10:00:00', 'Completed'),
    (98, '085DPUJV58HBSLWA3', 'D-0035', 3, '2026-02-20 16:00:00', '2026-02-22 06:00:00', '2026-03-02 13:00:00', 'Completed'),
    (99, '085DPUJV58HBSLWA3', 'D-0037', 3, '2026-07-12 10:00:00', '2026-07-13 06:00:00', NULL, 'In Operation'),
    (100, 'V9U377S6K1N9JEU3Y', 'D-0037', 8, '2026-01-15 02:00:00', '2026-01-16 01:00:00', '2026-01-17 03:00:00', 'Completed'),
    (101, 'V9U377S6K1N9JEU3Y', 'D-0029', 8, '2026-01-18 06:00:00', '2026-01-19 09:00:00', '2026-01-22 11:00:00', 'Completed'),
    (102, 'V9U377S6K1N9JEU3Y', 'D-0014', 8, '2026-07-13 04:00:00', '2026-07-13 08:00:00', NULL, 'In Operation'),
    (103, '7ZY16XNS1R3CX711K', 'D-0043', 8, '2026-01-26 19:00:00', '2026-01-28 07:00:00', '2026-01-30 11:00:00', 'Completed'),
    (104, '7ZY16XNS1R3CX711K', 'D-0003', 8, '2026-02-03 11:00:00', '2026-02-03 19:00:00', '2026-02-05 02:00:00', 'Completed'),
    (105, '7ZY16XNS1R3CX711K', 'D-0010', 8, '2026-02-13 06:00:00', '2026-02-14 23:00:00', '2026-02-23 07:00:00', 'Completed'),
    (106, 'AK3KE7TY2FY1X8CES', 'D-0044', 2, '2026-01-22 15:00:00', '2026-01-23 03:00:00', '2026-01-25 08:00:00', 'Completed'),
    (107, 'AK3KE7TY2FY1X8CES', 'D-0032', 2, '2026-01-27 02:00:00', '2026-01-27 22:00:00', '2026-02-01 03:00:00', 'Completed'),
    (108, 'AK3KE7TY2FY1X8CES', 'D-0020', 2, '2026-02-03 15:00:00', '2026-02-03 19:00:00', '2026-02-06 01:00:00', 'Completed'),
    (109, 'G5LWBCXDVZ04KS3ML', 'D-0002', 8, '2026-01-15 17:00:00', '2026-01-17 00:00:00', '2026-01-25 02:00:00', 'Completed'),
    (110, 'G5LWBCXDVZ04KS3ML', 'D-0008', 8, '2026-02-07 00:00:00', '2026-02-08 13:00:00', '2026-02-16 14:00:00', 'Completed'),
    (111, 'G5LWBCXDVZ04KS3ML', 'D-0018', 8, '2026-02-22 08:00:00', '2026-02-24 04:00:00', '2026-03-01 10:00:00', 'Completed'),
    (112, 'G5LWBCXDVZ04KS3ML', 'D-0004', 8, '2026-03-07 07:00:00', NULL, '2026-03-10 16:00:00', 'Cancelled'),
    (113, 'R6T6TA6VLE5ZW4T6W', 'D-0023', 6, '2026-01-22 08:00:00', '2026-01-23 18:00:00', '2026-02-02 19:00:00', 'Completed'),
    (114, 'R6T6TA6VLE5ZW4T6W', 'D-0020', 6, '2026-02-06 14:00:00', NULL, '2026-02-12 12:00:00', 'Cancelled'),
    (115, 'R6T6TA6VLE5ZW4T6W', 'D-0042', 6, '2026-02-25 05:00:00', '2026-02-25 20:00:00', '2026-03-05 06:00:00', 'Completed'),
    (116, 'R6T6TA6VLE5ZW4T6W', 'D-0018', 6, '2026-03-17 04:00:00', NULL, '2026-03-24 00:00:00', 'Cancelled'),
    (117, 'VB2UAD8VRZRNTJGCW', 'D-0044', 5, '2026-01-26 19:00:00', '2026-01-28 16:00:00', '2026-02-03 20:00:00', 'Completed'),
    (118, 'VB2UAD8VRZRNTJGCW', 'D-0025', 5, '2026-02-11 06:00:00', '2026-02-11 10:00:00', '2026-02-16 14:00:00', 'Completed'),
    (119, 'VB2UAD8VRZRNTJGCW', 'D-0025', 5, '2026-02-20 10:00:00', '2026-02-21 18:00:00', '2026-02-23 20:00:00', 'Completed'),
    (120, 'VB2UAD8VRZRNTJGCW', 'D-0025', 5, '2026-07-12 15:00:00', '2026-07-13 06:00:00', NULL, 'In Operation'),
    (121, 'MNJ09ULT7VYH6EKR2', 'D-0013', 2, '2026-01-16 00:00:00', '2026-01-17 23:00:00', '2026-01-23 11:00:00', 'Completed'),
    (122, 'MNJ09ULT7VYH6EKR2', 'D-0030', 2, '2026-01-30 04:00:00', '2026-01-31 02:00:00', '2026-02-02 09:00:00', 'Completed'),
    (123, 'MNJ09ULT7VYH6EKR2', 'D-0032', 2, '2026-02-03 19:00:00', '2026-02-05 18:00:00', '2026-02-07 00:00:00', 'Cancelled'),
    (124, 'T10GR7BXRE6W3HJCC', 'D-0014', 7, '2026-02-01 20:00:00', '2026-02-02 04:00:00', '2026-02-07 06:00:00', 'Completed'),
    (125, 'T10GR7BXRE6W3HJCC', 'D-0037', 7, '2026-02-15 13:00:00', '2026-02-17 03:00:00', '2026-02-18 05:00:00', 'Cancelled'),
    (126, 'T10GR7BXRE6W3HJCC', 'D-0038', 7, '2026-03-05 20:00:00', '2026-03-06 02:00:00', '2026-03-07 02:00:00', 'Completed'),
    (127, '3K3G83UC0P55S0G0Z', 'D-0029', 4, '2026-02-01 11:00:00', '2026-02-03 09:00:00', '2026-02-11 18:00:00', 'Completed'),
    (128, '3K3G83UC0P55S0G0Z', 'D-0029', 4, '2026-02-21 01:00:00', '2026-02-21 14:00:00', '2026-02-23 22:00:00', 'Completed'),
    (129, '3K3G83UC0P55S0G0Z', 'D-0035', 4, '2026-03-04 18:00:00', NULL, '2026-03-10 17:00:00', 'Cancelled'),
    (130, '3K3G83UC0P55S0G0Z', 'D-0014', 4, '2026-03-14 14:00:00', '2026-03-14 17:00:00', '2026-03-16 03:00:00', 'Completed'),
    (131, 'BDYSJPEPPRYKAUKJT', 'D-0025', 4, '2026-01-26 20:00:00', '2026-01-26 23:00:00', '2026-01-29 10:00:00', 'Cancelled'),
    (132, 'BDYSJPEPPRYKAUKJT', 'D-0025', 4, '2026-01-31 17:00:00', '2026-02-02 16:00:00', '2026-02-11 01:00:00', 'Completed'),
    (133, 'BDYSJPEPPRYKAUKJT', 'D-0044', 4, '2026-02-15 04:00:00', '2026-02-16 01:00:00', '2026-02-20 02:00:00', 'Completed'),
    (134, 'BDYSJPEPPRYKAUKJT', 'D-0025', 4, '2026-02-22 17:00:00', '2026-02-24 07:00:00', '2026-03-04 07:00:00', 'Completed'),
    (135, 'BDYSJPEPPRYKAUKJT', 'D-0023', 4, '2026-03-07 19:00:00', '2026-03-08 19:00:00', '2026-03-12 02:00:00', 'Completed'),
    (136, 'MTDJ3HE7509G59RCW', 'D-0011', 2, '2026-01-15 04:00:00', '2026-01-16 17:00:00', '2026-01-17 21:00:00', 'Completed'),
    (137, 'MTDJ3HE7509G59RCW', 'D-0011', 2, '2026-01-31 07:00:00', '2026-01-31 22:00:00', '2026-02-06 07:00:00', 'Completed'),
    (138, 'MTDJ3HE7509G59RCW', 'D-0023', 2, '2026-02-08 20:00:00', '2026-02-10 06:00:00', '2026-02-18 09:00:00', 'Completed'),
    (139, 'EFXKEJUX1V694GHP4', 'D-0037', 7, '2026-01-27 13:00:00', '2026-01-28 05:00:00', '2026-02-03 11:00:00', 'Completed'),
    (140, 'EFXKEJUX1V694GHP4', 'D-0029', 7, '2026-02-28 00:00:00', '2026-02-28 07:00:00', '2026-03-08 14:00:00', 'Completed'),
    (141, 'EFXKEJUX1V694GHP4', 'D-0037', 7, '2026-03-12 18:00:00', '2026-03-13 17:00:00', '2026-03-18 20:00:00', 'Completed'),
    (142, 'EFXKEJUX1V694GHP4', 'D-0035', 7, '2026-03-22 18:00:00', '2026-03-24 00:00:00', '2026-04-03 11:00:00', 'Completed'),
    (143, '4XT0K7EFFF4G0JDYH', 'D-0039', 1, '2026-01-26 17:00:00', '2026-01-28 10:00:00', '2026-02-05 21:00:00', 'Completed'),
    (144, '4XT0K7EFFF4G0JDYH', 'D-0008', 1, '2026-02-15 00:00:00', '2026-02-16 18:00:00', '2026-02-25 05:00:00', 'Completed'),
    (145, '4XT0K7EFFF4G0JDYH', 'D-0005', 1, '2026-03-02 08:00:00', '2026-03-04 05:00:00', '2026-03-07 12:00:00', 'Completed'),
    (146, 'WZG9PK7RGZ0HUR4BU', 'D-0004', 6, '2026-01-19 15:00:00', '2026-01-19 19:00:00', '2026-01-23 00:00:00', 'Completed'),
    (147, 'WZG9PK7RGZ0HUR4BU', 'D-0034', 6, '2026-01-26 05:00:00', '2026-01-28 03:00:00', '2026-01-31 05:00:00', 'Completed'),
    (148, 'WZG9PK7RGZ0HUR4BU', 'D-0004', 6, '2026-02-06 10:00:00', NULL, '2026-02-16 11:00:00', 'Cancelled'),
    (149, 'WZG9PK7RGZ0HUR4BU', 'D-0004', 6, '2026-02-25 20:00:00', '2026-02-26 04:00:00', '2026-02-27 10:00:00', 'Completed'),
    (150, 'K2EKBFP136YL0WXFD', 'D-0027', 5, '2026-01-22 22:00:00', '2026-01-23 20:00:00', '2026-01-29 03:00:00', 'Completed'),
    (151, 'K2EKBFP136YL0WXFD', 'D-0015', 5, '2026-02-04 22:00:00', '2026-02-06 13:00:00', '2026-02-15 13:00:00', 'Completed'),
    (152, 'K2EKBFP136YL0WXFD', 'D-0041', 5, '2026-02-17 13:00:00', '2026-02-18 16:00:00', '2026-02-23 22:00:00', 'Completed'),
    (153, 'K2EKBFP136YL0WXFD', 'D-0024', 5, '2026-03-04 00:00:00', '2026-03-05 15:00:00', '2026-03-12 00:00:00', 'Completed'),
    (154, 'K2EKBFP136YL0WXFD', 'D-0032', 5, '2026-03-26 10:00:00', '2026-03-28 06:00:00', '2026-04-02 10:00:00', 'Completed'),
    (155, '853UP9HZ4HV8WCR2D', 'D-0037', 5, '2026-01-25 15:00:00', '2026-01-25 17:00:00', '2026-01-27 20:00:00', 'Completed'),
    (156, '853UP9HZ4HV8WCR2D', 'D-0035', 5, '2026-07-12 05:00:00', NULL, NULL, 'Pending'),
    (157, 'A84MJ1R9ZE2C4B6EX', 'D-0018', 5, '2026-01-23 00:00:00', '2026-01-23 04:00:00', '2026-01-31 05:00:00', 'Completed'),
    (158, 'A84MJ1R9ZE2C4B6EX', 'D-0002', 5, '2026-02-07 03:00:00', '2026-02-08 17:00:00', '2026-02-12 00:00:00', 'Completed'),
    (159, 'A84MJ1R9ZE2C4B6EX', 'D-0043', 5, '2026-02-26 02:00:00', '2026-02-27 09:00:00', '2026-03-05 11:00:00', 'Cancelled'),
    (160, 'A84MJ1R9ZE2C4B6EX', 'D-0020', 5, '2026-03-09 01:00:00', '2026-03-09 08:00:00', '2026-03-11 12:00:00', 'Completed'),
    (161, 'A84MJ1R9ZE2C4B6EX', 'D-0044', 5, '2026-03-18 00:00:00', '2026-03-19 05:00:00', '2026-03-27 05:00:00', 'Cancelled'),
    (162, 'XL60F4GS42F2WYRYL', 'D-0016', 6, '2026-01-27 05:00:00', '2026-01-28 19:00:00', '2026-01-30 07:00:00', 'Completed'),
    (163, 'XL60F4GS42F2WYRYL', 'D-0019', 6, '2026-02-09 19:00:00', '2026-02-10 16:00:00', '2026-02-20 17:00:00', 'Completed'),
    (164, 'XL60F4GS42F2WYRYL', 'D-0040', 6, '2026-03-05 19:00:00', '2026-03-07 13:00:00', '2026-03-12 21:00:00', 'Completed'),
    (165, 'XL60F4GS42F2WYRYL', 'D-0010', 6, '2026-07-12 16:00:00', '2026-07-13 07:00:00', NULL, 'In Operation'),
    (166, 'KSGKTNMKEM865XXK5', 'D-0045', 1, '2026-01-21 06:00:00', '2026-01-21 10:00:00', '2026-01-23 15:00:00', 'Completed'),
    (167, 'KSGKTNMKEM865XXK5', 'D-0016', 1, '2026-02-07 09:00:00', '2026-02-07 13:00:00', '2026-02-15 21:00:00', 'Completed'),
    (168, 'KSGKTNMKEM865XXK5', 'D-0009', 1, '2026-03-03 04:00:00', '2026-03-04 00:00:00', '2026-03-08 02:00:00', 'Completed'),
    (169, 'KSGKTNMKEM865XXK5', 'D-0041', 1, '2026-03-10 07:00:00', '2026-03-10 23:00:00', '2026-03-20 10:00:00', 'Completed'),
    (170, 'KSGKTNMKEM865XXK5', 'D-0013', 1, '2026-03-30 18:00:00', '2026-03-31 04:00:00', '2026-04-02 09:00:00', 'Completed'),
    (171, 'W65CD0VEF916C5NX7', 'D-0017', 2, '2026-01-14 21:00:00', '2026-01-15 06:00:00', '2026-01-21 17:00:00', 'Completed'),
    (172, 'W65CD0VEF916C5NX7', 'D-0045', 2, '2026-01-24 03:00:00', '2026-01-26 01:00:00', '2026-02-04 07:00:00', 'Completed'),
    (173, 'W65CD0VEF916C5NX7', 'D-0030', 2, '2026-02-05 21:00:00', '2026-02-06 20:00:00', '2026-02-16 03:00:00', 'Completed'),
    (174, 'ZW2JFW1YJF490B0WM', 'D-0034', 3, '2026-02-03 01:00:00', '2026-02-04 02:00:00', '2026-02-12 06:00:00', 'Completed'),
    (175, 'ZW2JFW1YJF490B0WM', 'D-0011', 3, '2026-07-12 10:00:00', '2026-07-13 08:00:00', NULL, 'In Operation'),
    (176, 'G9CYJ1KLML5C30S5V', 'D-0042', 6, '2026-01-14 22:00:00', '2026-01-15 20:00:00', '2026-01-24 06:00:00', 'Completed'),
    (177, 'G9CYJ1KLML5C30S5V', 'D-0015', 6, '2026-01-27 05:00:00', '2026-01-29 00:00:00', '2026-02-06 02:00:00', 'Completed'),
    (178, 'G9CYJ1KLML5C30S5V', 'D-0019', 6, '2026-02-18 23:00:00', '2026-02-20 20:00:00', '2026-02-28 08:00:00', 'Completed'),
    (179, '56V193LNJTD70GHVF', 'D-0025', 4, '2026-03-15 03:00:00', '2026-03-16 21:00:00', '2026-03-23 04:00:00', 'Completed'),
    (180, '56V193LNJTD70GHVF', 'D-0034', 4, '2026-07-12 14:00:00', '2026-07-13 07:00:00', NULL, 'In Operation'),
    (181, 'B3D290S1F0RBXGYKJ', 'D-0019', 8, '2026-01-29 03:00:00', '2026-01-30 01:00:00', '2026-02-09 12:00:00', 'Completed'),
    (182, 'B3D290S1F0RBXGYKJ', 'D-0015', 8, '2026-02-16 15:00:00', '2026-02-18 07:00:00', '2026-02-22 08:00:00', 'Completed'),
    (183, 'B3D290S1F0RBXGYKJ', 'D-0032', 8, '2026-02-24 14:00:00', '2026-02-25 19:00:00', '2026-03-05 07:00:00', 'Completed'),
    (184, 'B3D290S1F0RBXGYKJ', 'D-0036', 8, '2026-03-11 19:00:00', '2026-03-12 06:00:00', '2026-03-19 06:00:00', 'Completed'),
    (185, 'B3D290S1F0RBXGYKJ', 'D-0043', 8, '2026-03-27 05:00:00', '2026-03-29 04:00:00', '2026-04-01 12:00:00', 'Completed'),
    (186, 'FBTPK4HVSWHDS36EH', 'D-0035', 4, '2026-03-13 06:00:00', '2026-03-14 11:00:00', '2026-03-22 22:00:00', 'Completed'),
    (187, '4AZS3MF0E99B17C10', 'D-0008', 4, '2026-01-25 20:00:00', NULL, '2026-02-04 13:00:00', 'Cancelled'),
    (188, '4AZS3MF0E99B17C10', 'D-0012', 4, '2026-02-06 14:00:00', '2026-02-07 17:00:00', '2026-02-16 02:00:00', 'Completed'),
    (189, '4AZS3MF0E99B17C10', 'D-0007', 4, '2026-02-20 21:00:00', '2026-02-22 08:00:00', '2026-03-04 20:00:00', 'Cancelled'),
    (190, '4AZS3MF0E99B17C10', 'D-0045', 4, '2026-03-10 00:00:00', NULL, '2026-03-16 00:00:00', 'Cancelled'),
    (191, 'GYJCZYM67MJE6CVNC', 'D-0005', 8, '2026-01-24 03:00:00', '2026-01-24 10:00:00', '2026-01-28 22:00:00', 'Completed'),
    (192, 'GYJCZYM67MJE6CVNC', 'D-0005', 8, '2026-02-10 15:00:00', '2026-02-12 04:00:00', '2026-02-14 08:00:00', 'Cancelled'),
    (193, 'GYJCZYM67MJE6CVNC', 'D-0022', 8, '2026-02-23 08:00:00', '2026-02-25 03:00:00', '2026-03-05 13:00:00', 'Completed'),
    (194, 'GYJCZYM67MJE6CVNC', 'D-0012', 8, '2026-03-09 06:00:00', '2026-03-09 19:00:00', '2026-03-20 05:00:00', 'Completed'),
    (195, 'GYJCZYM67MJE6CVNC', 'D-0036', 8, '2026-07-12 13:00:00', '2026-07-13 08:00:00', NULL, 'In Operation'),
    (196, 'NVZDYUH04251YM880', 'D-0040', 7, '2026-01-21 13:00:00', '2026-01-22 11:00:00', '2026-01-23 16:00:00', 'Completed'),
    (197, 'NVZDYUH04251YM880', 'D-0013', 7, '2026-02-01 05:00:00', '2026-02-02 21:00:00', '2026-02-12 22:00:00', 'Completed'),
    (198, 'MVXGFXVW54L5Z5CZ4', 'D-0023', 7, '2026-02-05 06:00:00', '2026-02-06 18:00:00', '2026-02-08 20:00:00', 'Completed'),
    (199, 'MVXGFXVW54L5Z5CZ4', 'D-0044', 7, '2026-07-12 23:00:00', '2026-07-13 08:00:00', NULL, 'In Operation'),
    (200, 'LBK5CJES001CK5005', 'D-0041', 5, '2026-01-25 11:00:00', '2026-01-26 09:00:00', '2026-02-04 12:00:00', 'Completed'),
    (201, 'LBK5CJES001CK5005', 'D-0004', 5, '2026-02-19 05:00:00', '2026-02-20 00:00:00', '2026-02-23 05:00:00', 'Completed'),
    (202, 'LBK5CJES001CK5005', 'D-0015', 5, '2026-02-28 18:00:00', '2026-03-01 19:00:00', '2026-03-11 21:00:00', 'Completed'),
    (203, 'LBK5CJES001CK5005', 'D-0018', 5, '2026-03-25 05:00:00', NULL, '2026-03-27 21:00:00', 'Cancelled'),
    (204, 'BM81HTT5PV8NHJE5M', 'D-0017', 6, '2026-01-26 08:00:00', '2026-01-27 05:00:00', '2026-01-31 11:00:00', 'Completed'),
    (205, 'BM81HTT5PV8NHJE5M', 'D-0027', 6, '2026-02-02 21:00:00', '2026-02-04 10:00:00', '2026-02-12 20:00:00', 'Completed'),
    (206, 'BM81HTT5PV8NHJE5M', 'D-0030', 6, '2026-02-27 02:00:00', '2026-02-27 22:00:00', '2026-03-07 09:00:00', 'Completed'),
    (207, 'BM81HTT5PV8NHJE5M', 'D-0039', 6, '2026-03-23 06:00:00', '2026-03-23 18:00:00', '2026-04-02 19:00:00', 'Completed'),
    (208, 'VWLM09RHNJS8B006J', 'D-0009', 7, '2026-01-16 04:00:00', '2026-01-16 13:00:00', '2026-01-22 23:00:00', 'Completed'),
    (209, 'VWLM09RHNJS8B006J', 'D-0022', 7, '2026-02-06 19:00:00', '2026-02-08 05:00:00', '2026-02-10 11:00:00', 'Completed'),
    (210, 'VWLM09RHNJS8B006J', 'D-0039', 7, '2026-02-12 22:00:00', '2026-02-13 19:00:00', '2026-02-16 19:00:00', 'Completed'),
    (211, 'VWLM09RHNJS8B006J', 'D-0024', 7, '2026-02-18 14:00:00', '2026-02-20 04:00:00', '2026-02-28 10:00:00', 'Completed'),
    (212, 'EJXE56ZJMJ49DHKWL', 'D-0036', 2, '2026-01-18 05:00:00', '2026-01-19 03:00:00', '2026-01-25 06:00:00', 'Completed'),
    (213, 'EJXE56ZJMJ49DHKWL', 'D-0021', 2, '2026-02-04 20:00:00', '2026-02-06 13:00:00', '2026-02-10 17:00:00', 'Completed'),
    (214, 'EJXE56ZJMJ49DHKWL', 'D-0040', 2, '2026-02-25 23:00:00', '2026-02-26 00:00:00', '2026-02-27 08:00:00', 'Completed'),
    (215, 'UJWF9LKLYCBFCTP3B', 'D-0022', 4, '2026-01-25 02:00:00', '2026-01-25 12:00:00', '2026-01-30 21:00:00', 'Completed'),
    (216, 'UJWF9LKLYCBFCTP3B', 'D-0020', 4, '2026-02-01 02:00:00', '2026-02-02 10:00:00', '2026-02-03 11:00:00', 'Cancelled'),
    (217, 'UJWF9LKLYCBFCTP3B', 'D-0024', 4, '2026-02-05 21:00:00', '2026-02-05 23:00:00', '2026-02-16 02:00:00', 'Completed'),
    (218, 'UJWF9LKLYCBFCTP3B', 'D-0019', 4, '2026-02-28 06:00:00', '2026-02-28 08:00:00', '2026-03-10 09:00:00', 'Completed'),
    (219, 'UJWF9LKLYCBFCTP3B', 'D-0023', 4, '2026-03-23 11:00:00', '2026-03-24 07:00:00', '2026-04-02 14:00:00', 'Completed');


-- ==========================================================
-- 06 - PREDICTIVE ALERTS & SCHEDULED SERVICES
-- ==========================================================
-- PredictiveAlert history plus both alert-linked and standalone ScheduledService rows. Historical escalations are inserted Resolved-with-manual-schedule to avoid sp_AutoScheduleFromAlert's CURDATE()-based ScheduledDate; only a few live-today alerts go through the real trigger.
-- ==========================================================

-- PredictiveAlert -- 90 rows (14 live escalations that will fire sp_AutoScheduleFromAlert for real)

INSERT INTO PredictiveAlert (AlertID, VIN, AlertTypeID, DateGenerated, ActionTaken, AlertStatus, ResolutionDate) VALUES
    (1, 'A84MJ1R9ZE2C4B6EX', 6, '2026-06-14 16:44:48', 'Escalated for inspection; corrective maintenance performed.', 'Resolved', '2026-06-22 16:44:48'),
    (2, 'CBSNBKSJ7HP6T0LHL', 3, '2026-02-04 17:09:15', 'Monitored; no corrective action required.', 'Resolved', '2026-02-08 17:09:15'),
    (3, 'CZPSGZ3KSLM3BMY3S', 3, '2026-06-06 01:21:31', 'Escalated for inspection; corrective maintenance performed.', 'Resolved', '2026-06-10 01:21:31'),
    (4, 'EFXKEJUX1V694GHP4', 3, '2026-07-03 09:00:00', 'Acknowledged, pending review.', 'Acknowledged', NULL),
    (5, 'G9CYJ1KLML5C30S5V', 1, '2026-03-14 14:25:40', 'Monitored; no corrective action required.', 'Resolved', '2026-04-01 14:25:40'),
    (6, '17AZW13R8RU48B1Y2', 7, '2026-07-11 09:00:00', 'Escalated -- awaiting workshop slot.', 'Urgent Repair Standby', NULL),
    (7, '4AZS3MF0E99B17C10', 6, '2026-06-16 22:15:48', 'Monitored; no corrective action required.', 'Resolved', '2026-07-06 22:15:48'),
    (8, '4XT0K7EFFF4G0JDYH', 2, '2026-02-02 22:43:35', 'Monitored; no corrective action required.', 'Resolved', '2026-02-20 22:43:35'),
    (9, 'MVXGFXVW54L5Z5CZ4', 4, '2026-03-15 14:19:22', 'Monitored; no corrective action required.', 'Resolved', '2026-03-25 14:19:22'),
    (10, 'NVZDYUH04251YM880', 2, '2026-04-20 07:23:20', 'Escalated for inspection; corrective maintenance performed.', 'Resolved', '2026-05-02 07:23:20'),
    (11, 'YZ6UWTRHNXHMNP7UV', 2, '2026-06-07 07:33:05', 'Escalated for inspection; corrective maintenance performed.', 'Resolved', '2026-06-18 07:33:05'),
    (12, 'WFSH3R155W4WDGPPT', 3, '2026-07-11 09:00:00', 'Escalated -- awaiting workshop slot.', 'Scheduled For Inspection', NULL),
    (13, 'MVXGFXVW54L5Z5CZ4', 6, '2026-05-04 16:54:11', 'Monitored; no corrective action required.', 'Resolved', '2026-05-11 16:54:11'),
    (14, 'MNJ09ULT7VYH6EKR2', 3, '2026-07-11 09:00:00', 'Escalated -- awaiting workshop slot.', 'Scheduled For Inspection', NULL),
    (15, 'SWRNKBCS7E63N182S', 7, '2026-06-01 10:22:23', 'Monitored; no corrective action required.', 'Resolved', '2026-06-09 10:22:23'),
    (16, 'W65CD0VEF916C5NX7', 6, '2026-07-10 09:00:00', 'Escalated -- awaiting workshop slot.', 'Scheduled For Inspection', NULL),
    (17, 'ZW2JFW1YJF490B0WM', 4, '2026-07-13 09:00:00', 'Escalated -- awaiting workshop slot.', 'Scheduled For Inspection', NULL),
    (18, 'MTDJ3HE7509G59RCW', 4, '2026-03-19 18:26:42', 'Monitored; no corrective action required.', 'Resolved', '2026-04-04 18:26:42'),
    (19, 'W2U985FC4XTBFRBUC', 7, '2026-03-30 05:52:56', 'Monitored; no corrective action required.', 'Resolved', '2026-04-16 05:52:56'),
    (20, 'ZW2JFW1YJF490B0WM', 3, '2026-03-09 01:54:43', 'Escalated for inspection; corrective maintenance performed.', 'Resolved', '2026-03-20 01:54:43'),
    (21, 'V9U377S6K1N9JEU3Y', 1, '2026-02-07 16:02:29', 'Monitored; no corrective action required.', 'Resolved', '2026-02-26 16:02:29'),
    (22, 'LBK5CJES001CK5005', 7, '2026-07-05 09:00:00', 'Acknowledged, pending review.', 'Acknowledged', NULL),
    (23, 'A84MJ1R9ZE2C4B6EX', 2, '2026-05-05 07:44:54', 'Monitored; no corrective action required.', 'Resolved', '2026-05-21 07:44:54'),
    (24, 'YZ6UWTRHNXHMNP7UV', 2, '2026-02-22 23:34:55', 'Monitored; no corrective action required.', 'Resolved', '2026-03-01 23:34:55'),
    (25, 'G9CYJ1KLML5C30S5V', 6, '2026-01-15 00:33:38', 'Monitored; no corrective action required.', 'Resolved', '2026-02-03 00:33:38'),
    (26, '6ZWRRBN2YUEUZ92YB', 6, '2026-07-10 09:00:00', 'Escalated -- awaiting workshop slot.', 'Scheduled For Inspection', NULL),
    (27, 'AK3KE7TY2FY1X8CES', 6, '2026-06-25 16:25:13', 'Monitored; no corrective action required.', 'Resolved', '2026-06-27 16:25:13'),
    (28, '6ZWRRBN2YUEUZ92YB', 3, '2026-04-15 06:25:15', 'Monitored; no corrective action required.', 'Resolved', '2026-04-17 06:25:15'),
    (29, 'X49H1NTC4AN04EYXH', 5, '2026-05-19 11:40:31', 'Monitored; no corrective action required.', 'Resolved', '2026-06-02 11:40:31'),
    (30, 'SWRNKBCS7E63N182S', 6, '2026-06-02 13:19:44', 'Monitored; no corrective action required.', 'Resolved', '2026-06-04 13:19:44'),
    (31, 'X49H1NTC4AN04EYXH', 2, '2026-03-31 06:29:55', 'Monitored; no corrective action required.', 'Resolved', '2026-04-20 06:29:55'),
    (32, 'VSUYXFJKR1KPE33Y6', 6, '2026-06-06 22:53:05', 'Monitored; no corrective action required.', 'Resolved', '2026-06-09 22:53:05'),
    (33, 'B3D290S1F0RBXGYKJ', 4, '2026-07-08 09:00:00', 'Acknowledged, pending review.', 'Acknowledged', NULL),
    (34, '853UP9HZ4HV8WCR2D', 6, '2026-04-09 16:24:05', 'Monitored; no corrective action required.', 'Resolved', '2026-04-13 16:24:05'),
    (35, 'X49H1NTC4AN04EYXH', 1, '2026-02-05 22:48:05', 'Monitored; no corrective action required.', 'Resolved', '2026-02-22 22:48:05'),
    (36, 'CBSNBKSJ7HP6T0LHL', 1, '2026-05-07 04:55:17', 'Escalated for inspection; corrective maintenance performed.', 'Resolved', '2026-05-20 04:55:17'),
    (37, 'UANFS38S785BFVR2S', 6, '2026-06-06 23:37:33', 'Monitored; no corrective action required.', 'Resolved', '2026-06-25 23:37:33'),
    (38, 'VSUYXFJKR1KPE33Y6', 4, '2026-07-11 09:00:00', 'Escalated -- awaiting workshop slot.', 'Urgent Repair Standby', NULL),
    (39, 'EFXKEJUX1V694GHP4', 2, '2026-02-01 13:25:47', 'Monitored; no corrective action required.', 'Resolved', '2026-02-19 13:25:47'),
    (40, 'VSUYXFJKR1KPE33Y6', 4, '2026-06-20 02:14:20', 'Escalated for inspection; corrective maintenance performed.', 'Resolved', '2026-07-03 02:14:20'),
    (41, 'GYJCZYM67MJE6CVNC', 5, '2026-07-11 09:00:00', 'Acknowledged, pending review.', 'Acknowledged', NULL),
    (42, '3K3G83UC0P55S0G0Z', 7, '2026-05-06 18:59:59', 'Monitored; no corrective action required.', 'Resolved', '2026-05-10 18:59:59'),
    (43, '56V193LNJTD70GHVF', 7, '2026-07-12 09:00:00', 'Escalated -- awaiting workshop slot.', 'Scheduled For Inspection', NULL),
    (44, 'LBK5CJES001CK5005', 5, '2026-05-28 05:56:27', 'Monitored; no corrective action required.', 'Resolved', '2026-06-15 05:56:27'),
    (45, 'G5LWBCXDVZ04KS3ML', 7, '2026-03-15 06:43:33', 'Monitored; no corrective action required.', 'Resolved', '2026-03-20 06:43:33'),
    (46, 'EFXKEJUX1V694GHP4', 2, '2026-05-19 23:31:30', 'Monitored; no corrective action required.', 'Resolved', '2026-06-06 23:31:30'),
    (47, 'U764UXSFU5S61YB8X', 7, '2026-06-08 11:33:16', 'Monitored; no corrective action required.', 'Resolved', '2026-06-12 11:33:16'),
    (48, 'T10GR7BXRE6W3HJCC', 3, '2026-07-10 09:00:00', 'Escalated -- awaiting workshop slot.', 'Scheduled For Inspection', NULL),
    (49, 'XL60F4GS42F2WYRYL', 1, '2026-03-02 11:20:04', 'Monitored; no corrective action required.', 'Resolved', '2026-03-19 11:20:04'),
    (50, 'VWLM09RHNJS8B006J', 7, '2026-03-11 05:19:41', 'Escalated for inspection; corrective maintenance performed.', 'Resolved', '2026-03-18 05:19:41'),
    (51, 'EFXKEJUX1V694GHP4', 4, '2026-05-28 05:24:27', 'Monitored; no corrective action required.', 'Resolved', '2026-06-09 05:24:27'),
    (52, 'WZG9PK7RGZ0HUR4BU', 5, '2026-04-22 09:31:24', 'Monitored; no corrective action required.', 'Resolved', '2026-04-26 09:31:24'),
    (53, 'XL60F4GS42F2WYRYL', 7, '2026-01-21 22:28:58', 'Monitored; no corrective action required.', 'Resolved', '2026-01-28 22:28:58'),
    (54, 'SWRNKBCS7E63N182S', 3, '2026-07-03 09:00:00', NULL, 'Unresolved', NULL),
    (55, 'MTDJ3HE7509G59RCW', 2, '2026-05-08 03:54:33', 'Monitored; no corrective action required.', 'Resolved', '2026-05-13 03:54:33'),
    (56, 'ZW2JFW1YJF490B0WM', 5, '2026-04-05 04:43:57', 'Monitored; no corrective action required.', 'Resolved', '2026-04-14 04:43:57'),
    (57, 'U764UXSFU5S61YB8X', 4, '2026-07-05 09:00:00', 'Acknowledged, pending review.', 'Acknowledged', NULL),
    (58, 'CZPSGZ3KSLM3BMY3S', 3, '2026-05-24 14:50:17', 'Monitored; no corrective action required.', 'Resolved', '2026-05-29 14:50:17'),
    (59, 'BDYSJPEPPRYKAUKJT', 2, '2026-01-26 22:49:27', 'Escalated for inspection; corrective maintenance performed.', 'Resolved', '2026-02-02 22:49:27'),
    (60, 'CS55L00V13YDYEYG1', 3, '2026-05-02 16:45:46', 'Escalated for inspection; corrective maintenance performed.', 'Resolved', '2026-05-17 16:45:46'),
    (61, '6DSH6J6X5945L75TS', 4, '2026-06-21 18:47:00', 'Monitored; no corrective action required.', 'Resolved', '2026-07-05 18:47:00'),
    (62, '085DPUJV58HBSLWA3', 1, '2026-05-10 11:00:49', 'Monitored; no corrective action required.', 'Resolved', '2026-05-19 11:00:49'),
    (63, 'X49H1NTC4AN04EYXH', 5, '2026-02-03 14:35:28', 'Escalated for inspection; corrective maintenance performed.', 'Resolved', '2026-02-09 14:35:28'),
    (64, '7VCRVV6ERTN4HRKUK', 6, '2026-01-30 12:38:58', 'Monitored; no corrective action required.', 'Resolved', '2026-02-10 12:38:58'),
    (65, 'B3D290S1F0RBXGYKJ', 3, '2026-07-08 09:00:00', NULL, 'Unresolved', NULL),
    (66, 'J4MU6SE5GDAFSL387', 1, '2026-07-10 09:00:00', 'Escalated -- awaiting workshop slot.', 'Scheduled For Inspection', NULL),
    (67, '6ZWRRBN2YUEUZ92YB', 7, '2026-02-06 05:34:04', 'Monitored; no corrective action required.', 'Resolved', '2026-02-16 05:34:04'),
    (68, '4XT0K7EFFF4G0JDYH', 7, '2026-06-18 21:57:07', 'Monitored; no corrective action required.', 'Resolved', '2026-07-05 21:57:07'),
    (69, 'W2U985FC4XTBFRBUC', 6, '2026-07-03 09:00:00', 'Acknowledged, pending review.', 'Acknowledged', NULL),
    (70, '6ZWRRBN2YUEUZ92YB', 1, '2026-02-15 09:44:26', 'Monitored; no corrective action required.', 'Resolved', '2026-02-28 09:44:26'),
    (71, 'VSUYXFJKR1KPE33Y6', 3, '2026-06-18 18:37:42', 'Escalated for inspection; corrective maintenance performed.', 'Resolved', '2026-07-02 18:37:42'),
    (72, 'WZG9PK7RGZ0HUR4BU', 7, '2026-04-01 10:29:27', 'Monitored; no corrective action required.', 'Resolved', '2026-04-06 10:29:27'),
    (73, 'U764UXSFU5S61YB8X', 1, '2026-05-26 14:03:35', 'Monitored; no corrective action required.', 'Resolved', '2026-05-31 14:03:35'),
    (74, 'XL60F4GS42F2WYRYL', 2, '2026-02-09 22:53:27', 'Monitored; no corrective action required.', 'Resolved', '2026-02-18 22:53:27'),
    (75, 'ES0VL5WAWGJTHGKUV', 6, '2026-07-10 09:00:00', 'Escalated -- awaiting workshop slot.', 'Scheduled For Inspection', NULL),
    (76, 'CS55L00V13YDYEYG1', 4, '2026-02-17 19:19:44', 'Monitored; no corrective action required.', 'Resolved', '2026-03-01 19:19:44'),
    (77, '4AZS3MF0E99B17C10', 4, '2026-04-20 18:33:28', 'Monitored; no corrective action required.', 'Resolved', '2026-05-04 18:33:28'),
    (78, '3K3G83UC0P55S0G0Z', 6, '2026-07-11 09:00:00', 'Escalated -- awaiting workshop slot.', 'Scheduled For Inspection', NULL),
    (79, '853UP9HZ4HV8WCR2D', 7, '2026-07-11 09:00:00', 'Escalated -- awaiting workshop slot.', 'Urgent Repair Standby', NULL),
    (80, 'MVXGFXVW54L5Z5CZ4', 1, '2026-05-16 11:48:27', 'Monitored; no corrective action required.', 'Resolved', '2026-05-24 11:48:27'),
    (81, 'CZPSGZ3KSLM3BMY3S', 2, '2026-05-04 23:10:12', 'Monitored; no corrective action required.', 'Resolved', '2026-05-14 23:10:12'),
    (82, 'MTDJ3HE7509G59RCW', 4, '2026-07-02 09:00:00', 'Acknowledged, pending review.', 'Acknowledged', NULL),
    (83, 'T10GR7BXRE6W3HJCC', 6, '2026-02-08 17:48:08', 'Monitored; no corrective action required.', 'Resolved', '2026-02-25 17:48:08'),
    (84, 'KSGKTNMKEM865XXK5', 6, '2026-07-04 16:45:18', 'Monitored; no corrective action required.', 'Resolved', '2026-07-08 16:45:18'),
    (85, 'V9U377S6K1N9JEU3Y', 1, '2026-05-12 22:06:13', 'Monitored; no corrective action required.', 'Resolved', '2026-05-13 22:06:13'),
    (86, 'CS55L00V13YDYEYG1', 4, '2026-05-29 16:18:52', 'Monitored; no corrective action required.', 'Resolved', '2026-06-10 16:18:52'),
    (87, 'NESGWHCZ40E9YA38G', 6, '2026-07-10 09:00:00', 'Escalated -- awaiting workshop slot.', 'Scheduled For Inspection', NULL),
    (88, '6DSH6J6X5945L75TS', 6, '2026-07-03 12:05:39', 'Escalated for inspection; corrective maintenance performed.', 'Resolved', '2026-07-08 12:05:39'),
    (89, 'DF4UCAYJTL54AHEKC', 3, '2026-06-25 05:55:45', 'Monitored; no corrective action required.', 'Resolved', '2026-07-07 05:55:45'),
    (90, 'ES0VL5WAWGJTHGKUV', 4, '2026-04-19 11:14:02', 'Monitored; no corrective action required.', 'Resolved', '2026-05-01 11:14:02');


-- ScheduledService -- 28 rows (23 left open for stage 07 to close via a real MaintenanceJob)

INSERT INTO ScheduledService (ScheduleID, VIN, ScheduledDate, Reason, AlertID, CompletionDate, Status) VALUES
    (1, 'A84MJ1R9ZE2C4B6EX', '2026-06-18', 'Auto-flagged by PredictiveAlert #1 (Cooling System Anomaly)', 1, NULL, 'Scheduled'),
    (2, 'CZPSGZ3KSLM3BMY3S', '2026-06-08', 'Auto-flagged by PredictiveAlert #3 (Battery Degradation)', 3, NULL, 'Scheduled'),
    (3, 'NVZDYUH04251YM880', '2026-04-22', 'Auto-flagged by PredictiveAlert #10 (Engine Overheating Risk)', 10, NULL, 'Scheduled'),
    (4, 'YZ6UWTRHNXHMNP7UV', '2026-06-08', 'Auto-flagged by PredictiveAlert #11 (Engine Overheating Risk)', 11, NULL, 'Scheduled'),
    (5, 'ZW2JFW1YJF490B0WM', '2026-03-11', 'Auto-flagged by PredictiveAlert #20 (Battery Degradation)', 20, NULL, 'Scheduled'),
    (6, 'CBSNBKSJ7HP6T0LHL', '2026-05-12', 'Auto-flagged by PredictiveAlert #36 (Brake Wear Warning)', 36, NULL, 'Scheduled'),
    (7, 'VSUYXFJKR1KPE33Y6', '2026-06-24', 'Auto-flagged by PredictiveAlert #40 (Oil Quality Deterioration)', 40, NULL, 'Scheduled'),
    (8, 'VWLM09RHNJS8B006J', '2026-03-15', 'Auto-flagged by PredictiveAlert #50 (Tire Pressure Irregularity)', 50, NULL, 'Scheduled'),
    (9, 'BDYSJPEPPRYKAUKJT', '2026-01-29', 'Auto-flagged by PredictiveAlert #59 (Engine Overheating Risk)', 59, NULL, 'Scheduled'),
    (10, 'CS55L00V13YDYEYG1', '2026-05-07', 'Auto-flagged by PredictiveAlert #60 (Battery Degradation)', 60, NULL, 'Scheduled'),
    (11, 'X49H1NTC4AN04EYXH', '2026-02-07', 'Auto-flagged by PredictiveAlert #63 (Transmission Fault Warning)', 63, NULL, 'Scheduled'),
    (12, 'VSUYXFJKR1KPE33Y6', '2026-06-23', 'Auto-flagged by PredictiveAlert #71 (Battery Degradation)', 71, NULL, 'Scheduled'),
    (13, '6DSH6J6X5945L75TS', '2026-07-05', 'Auto-flagged by PredictiveAlert #88 (Cooling System Anomaly)', 88, NULL, 'Scheduled'),
    (14, 'X49H1NTC4AN04EYXH', '2026-03-27', 'Routine preventative maintenance interval.', NULL, NULL, 'Scheduled'),
    (15, 'NVZDYUH04251YM880', '2026-07-23', 'Routine preventative maintenance interval.', NULL, NULL, 'Scheduled'),
    (16, 'YZ6UWTRHNXHMNP7UV', '2026-04-08', 'Routine preventative maintenance interval.', NULL, NULL, 'Scheduled'),
    (17, 'U764UXSFU5S61YB8X', '2026-05-03', 'Routine preventative maintenance interval.', NULL, NULL, 'Scheduled'),
    (18, 'J6MDT1XP6XY1U3TF7', '2026-06-03', 'Routine preventative maintenance interval.', NULL, NULL, 'Cancelled'),
    (19, 'GYJCZYM67MJE6CVNC', '2026-05-21', 'Routine preventative maintenance interval.', NULL, NULL, 'Cancelled'),
    (20, 'VWLM09RHNJS8B006J', '2026-08-16', 'Routine preventative maintenance interval.', NULL, NULL, 'Scheduled'),
    (21, 'ES0VL5WAWGJTHGKUV', '2026-05-20', 'Routine preventative maintenance interval.', NULL, NULL, 'Scheduled'),
    (22, '7VCRVV6ERTN4HRKUK', '2026-02-19', 'Routine preventative maintenance interval.', NULL, NULL, 'Scheduled'),
    (23, 'J4MU6SE5GDAFSL387', '2026-03-11', 'Routine preventative maintenance interval.', NULL, NULL, 'Scheduled'),
    (24, 'V9U377S6K1N9JEU3Y', '2026-02-17', 'Routine preventative maintenance interval.', NULL, NULL, 'Scheduled'),
    (25, 'AK3KE7TY2FY1X8CES', '2026-02-13', 'Routine preventative maintenance interval.', NULL, NULL, 'Scheduled'),
    (26, '3K3G83UC0P55S0G0Z', '2026-07-25', 'Routine preventative maintenance interval.', NULL, NULL, 'Scheduled'),
    (27, '7ZY16XNS1R3CX711K', '2026-05-27', 'Routine preventative maintenance interval.', NULL, NULL, 'Scheduled'),
    (28, 'J4MU6SE5GDAFSL387', '2026-03-28', 'Routine preventative maintenance interval.', NULL, NULL, 'Scheduled');


-- ==========================================================
-- 07 - MAINTENANCE OPERATIONS
-- ==========================================================
-- MaintenanceJob, MaintenanceActivity, MechanicWorkSession, ActivityPart, WarrantyClaim. Schedule-linked jobs close their ScheduledService for real; a few vehicles get a genuinely open job as of today.
-- ==========================================================

-- MaintenanceJob -- 79 jobs (3 currently open, 23 schedule-linked)

INSERT INTO MaintenanceJob (JobID, VIN, WorkshopID, ScheduleID, DateOpened, DateClosed, Downtime, TotalCost) VALUES
    ('MJOB-000001', 'A84MJ1R9ZE2C4B6EX', 5, 1, '2026-06-18 16:44:48', '2026-06-22 00:44:48', 80.0, 1215965),
    ('MJOB-000002', 'CZPSGZ3KSLM3BMY3S', 8, 2, '2026-06-08 01:21:31', '2026-06-13 10:21:31', 129.0, 12459337),
    ('MJOB-000003', 'NVZDYUH04251YM880', 7, 3, '2026-04-22 07:23:20', '2026-04-27 10:23:20', 123.0, 6402573),
    ('MJOB-000004', 'YZ6UWTRHNXHMNP7UV', 1, 4, '2026-06-08 07:33:05', '2026-06-11 08:33:05', 73.0, 18368799),
    ('MJOB-000005', 'YZ6UWTRHNXHMNP7UV', 1, 16, '2026-04-08 06:00:00', '2026-04-09 07:00:00', 25.0, 1216813),
    ('MJOB-000006', 'ZW2JFW1YJF490B0WM', 3, 5, '2026-03-11 01:54:43', '2026-03-14 08:54:43', 79.0, 42569500),
    ('MJOB-000007', 'CBSNBKSJ7HP6T0LHL', 7, 6, '2026-05-12 04:55:17', '2026-05-14 13:55:17', 57.0, 14916828),
    ('MJOB-000008', 'VSUYXFJKR1KPE33Y6', 1, 7, '2026-06-24 02:14:20', '2026-06-27 07:14:20', 77.0, 4142883),
    ('MJOB-000009', 'VSUYXFJKR1KPE33Y6', 1, 12, '2026-06-23 18:37:42', '2026-06-26 04:37:42', 58.0, 19227669),
    ('MJOB-000010', 'VWLM09RHNJS8B006J', 7, 8, '2026-03-15 05:19:41', '2026-03-19 05:19:41', 96.0, 7684358),
    ('MJOB-000011', 'BDYSJPEPPRYKAUKJT', 4, 9, '2026-01-29 22:49:27', '2026-01-31 06:49:27', 32.0, 23008962),
    ('MJOB-000012', 'CS55L00V13YDYEYG1', 2, 10, '2026-05-07 16:45:46', '2026-05-10 21:45:46', 77.0, 5419731),
    ('MJOB-000013', 'X49H1NTC4AN04EYXH', 5, 11, '2026-02-07 14:35:28', '2026-02-12 01:35:28', 107.0, 32407028),
    ('MJOB-000014', 'X49H1NTC4AN04EYXH', 5, 14, '2026-03-27 06:00:00', '2026-03-30 13:00:00', 79.0, 28742888),
    ('MJOB-000015', '6DSH6J6X5945L75TS', 4, 13, '2026-07-05 12:05:39', '2026-07-06 17:05:39', 29.0, 37771876),
    ('MJOB-000016', 'U764UXSFU5S61YB8X', 5, 17, '2026-05-03 06:00:00', '2026-05-04 13:00:00', 31.0, 40157675),
    ('MJOB-000017', 'ES0VL5WAWGJTHGKUV', 5, 21, '2026-05-20 06:00:00', '2026-05-21 10:00:00', 28.0, 7766979),
    ('MJOB-000018', '7VCRVV6ERTN4HRKUK', 8, 22, '2026-02-19 06:00:00', '2026-02-22 17:00:00', 83.0, 15554841),
    ('MJOB-000019', 'J4MU6SE5GDAFSL387', 5, 23, '2026-03-11 06:00:00', '2026-03-15 09:00:00', 99.0, 18413995),
    ('MJOB-000020', 'J4MU6SE5GDAFSL387', 5, 28, '2026-03-28 06:00:00', '2026-03-30 15:00:00', 57.0, 1036654),
    ('MJOB-000021', 'V9U377S6K1N9JEU3Y', 8, 24, '2026-02-17 06:00:00', '2026-02-18 11:00:00', 29.0, 27632538),
    ('MJOB-000022', 'AK3KE7TY2FY1X8CES', 2, 25, '2026-02-13 06:00:00', '2026-02-17 06:00:00', 96.0, 26313695),
    ('MJOB-000023', '7ZY16XNS1R3CX711K', 8, 27, '2026-05-27 06:00:00', '2026-05-28 13:00:00', 31.0, 6615883),
    ('MJOB-000024', '6V48KNVPDDXDD79LD', 4, NULL, '2026-05-08 14:00:00', '2026-05-14 14:00:00', 144.0, 41948681),
    ('MJOB-000025', '6V48KNVPDDXDD79LD', 4, NULL, '2026-04-05 00:00:00', '2026-04-06 09:00:00', 33.0, 25820482),
    ('MJOB-000026', 'SCF3XTPXST2JW6XEA', 5, NULL, '2026-04-26 08:00:00', '2026-04-29 19:00:00', 83.0, 30594345),
    ('MJOB-000027', 'DF4UCAYJTL54AHEKC', 5, NULL, '2026-06-06 01:00:00', '2026-06-08 02:00:00', 49.0, 39121763),
    ('MJOB-000028', '6ZWRRBN2YUEUZ92YB', 7, NULL, '2026-01-17 15:00:00', '2026-01-20 23:00:00', 80.0, 8671518),
    ('MJOB-000029', '31MW2AWVP4X655P97', 6, NULL, '2026-02-08 21:00:00', '2026-02-15 09:00:00', 156.0, 42164233),
    ('MJOB-000030', 'SWRNKBCS7E63N182S', 7, NULL, '2026-06-15 16:00:00', '2026-06-18 18:00:00', 74.0, 38698849),
    ('MJOB-000031', 'SWRNKBCS7E63N182S', 7, NULL, '2026-06-03 11:00:00', '2026-06-06 14:00:00', 75.0, 6558198),
    ('MJOB-000032', '6DSH6J6X5945L75TS', 4, NULL, '2026-04-14 11:00:00', '2026-04-16 21:00:00', 58.0, 15181741),
    ('MJOB-000033', '17AZW13R8RU48B1Y2', 1, NULL, '2026-03-21 11:00:00', '2026-03-22 12:00:00', 25.0, 33468223),
    ('MJOB-000034', 'J6MDT1XP6XY1U3TF7', 2, NULL, '2026-07-01 00:00:00', '2026-07-07 09:00:00', 153.0, 2410605),
    ('MJOB-000035', 'NESGWHCZ40E9YA38G', 3, NULL, '2026-01-20 23:00:00', '2026-01-22 07:00:00', 32.0, 34642606),
    ('MJOB-000036', 'NESGWHCZ40E9YA38G', 3, NULL, '2026-05-19 19:00:00', '2026-05-25 01:00:00', 126.0, 13255650),
    ('MJOB-000037', 'UANFS38S785BFVR2S', 6, NULL, '2026-03-06 00:00:00', '2026-03-09 05:00:00', 77.0, 42759675),
    ('MJOB-000038', 'UCDVJ8GAV775YMDT7', 1, NULL, '2026-01-15 16:00:00', '2026-01-21 16:00:00', 144.0, 22370051),
    ('MJOB-000039', 'WFSH3R155W4WDGPPT', 3, NULL, '2026-03-26 04:00:00', '2026-03-31 16:00:00', 132.0, 5321366),
    ('MJOB-000040', 'WFSH3R155W4WDGPPT', 3, NULL, '2026-02-02 23:00:00', '2026-02-06 06:00:00', 79.0, 41392143),
    ('MJOB-000041', 'W2U985FC4XTBFRBUC', 7, NULL, '2026-01-15 10:00:00', '2026-01-16 15:00:00', 29.0, 29538155),
    ('MJOB-000042', 'F7Z3YXGLY38V2C6FX', 8, NULL, '2026-03-31 08:00:00', '2026-04-03 13:00:00', 77.0, 41420998),
    ('MJOB-000043', '085DPUJV58HBSLWA3', 3, NULL, '2026-02-03 17:00:00', '2026-02-08 20:00:00', 123.0, 44557005),
    ('MJOB-000044', '7ZY16XNS1R3CX711K', 8, NULL, '2026-06-27 09:00:00', '2026-06-29 16:00:00', 55.0, 7492284),
    ('MJOB-000045', 'AK3KE7TY2FY1X8CES', 2, NULL, '2026-05-03 09:00:00', '2026-05-09 09:00:00', 144.0, 43675469),
    ('MJOB-000046', 'G5LWBCXDVZ04KS3ML', 8, NULL, '2026-03-22 21:00:00', '2026-03-24 23:00:00', 50.0, 13961719),
    ('MJOB-000047', 'R6T6TA6VLE5ZW4T6W', 6, NULL, '2026-04-13 21:00:00', '2026-04-18 21:00:00', 120.0, 33069750),
    ('MJOB-000048', 'R6T6TA6VLE5ZW4T6W', 6, NULL, '2026-04-01 05:00:00', '2026-04-04 12:00:00', 79.0, 33227759),
    ('MJOB-000049', 'VB2UAD8VRZRNTJGCW', 5, NULL, '2026-03-25 02:00:00', '2026-03-31 10:00:00', 152.0, 30449955),
    ('MJOB-000050', 'MNJ09ULT7VYH6EKR2', 2, NULL, '2026-03-29 06:00:00', '2026-04-02 06:00:00', 96.0, 14884454),
    ('MJOB-000051', 'T10GR7BXRE6W3HJCC', 7, NULL, '2026-02-02 15:00:00', '2026-02-04 15:00:00', 48.0, 32054422),
    ('MJOB-000052', 'T10GR7BXRE6W3HJCC', 7, NULL, '2026-06-08 02:00:00', '2026-06-12 10:00:00', 104.0, 12605898),
    ('MJOB-000053', '3K3G83UC0P55S0G0Z', 4, NULL, '2026-06-20 23:00:00', '2026-06-26 03:00:00', 124.0, 3892741),
    ('MJOB-000054', 'MTDJ3HE7509G59RCW', 2, NULL, '2026-02-14 05:00:00', '2026-02-19 15:00:00', 130.0, 34580608),
    ('MJOB-000055', 'EFXKEJUX1V694GHP4', 7, NULL, '2026-02-20 02:00:00', '2026-02-21 04:00:00', 26.0, 9808398),
    ('MJOB-000056', '4XT0K7EFFF4G0JDYH', 1, NULL, '2026-02-17 20:00:00', '2026-02-24 03:00:00', 151.0, 18882715),
    ('MJOB-000057', 'WZG9PK7RGZ0HUR4BU', 6, NULL, '2026-06-29 10:00:00', '2026-07-02 20:00:00', 82.0, 38092206),
    ('MJOB-000058', 'K2EKBFP136YL0WXFD', 5, NULL, '2026-01-30 07:00:00', '2026-01-31 18:00:00', 35.0, 10982367),
    ('MJOB-000059', '853UP9HZ4HV8WCR2D', 5, NULL, '2026-04-30 08:00:00', '2026-05-01 17:00:00', 33.0, 17109686),
    ('MJOB-000060', 'XL60F4GS42F2WYRYL', 6, NULL, '2026-02-23 19:00:00', '2026-03-01 07:00:00', 132.0, 13204753),
    ('MJOB-000061', 'KSGKTNMKEM865XXK5', 1, NULL, '2026-04-28 00:00:00', '2026-05-03 01:00:00', 121.0, 23164749),
    ('MJOB-000062', 'W65CD0VEF916C5NX7', 2, NULL, '2026-01-30 20:00:00', '2026-02-04 06:00:00', 106.0, 25540866),
    ('MJOB-000063', 'G9CYJ1KLML5C30S5V', 6, NULL, '2026-03-28 14:00:00', '2026-04-02 01:00:00', 107.0, 24318611),
    ('MJOB-000064', '56V193LNJTD70GHVF', 4, NULL, '2026-03-05 16:00:00', '2026-03-06 18:00:00', 26.0, 14005865),
    ('MJOB-000065', 'B3D290S1F0RBXGYKJ', 8, NULL, '2026-01-19 12:00:00', '2026-01-24 21:00:00', 129.0, 25760323),
    ('MJOB-000066', 'FBTPK4HVSWHDS36EH', 4, NULL, '2026-01-27 10:00:00', '2026-01-31 12:00:00', 98.0, 19264695),
    ('MJOB-000067', '4AZS3MF0E99B17C10', 4, NULL, '2026-03-06 21:00:00', '2026-03-13 08:00:00', 155.0, 24255066),
    ('MJOB-000068', '4AZS3MF0E99B17C10', 4, NULL, '2026-05-21 09:00:00', '2026-05-22 14:00:00', 29.0, 27870593),
    ('MJOB-000069', 'GYJCZYM67MJE6CVNC', 8, NULL, '2026-03-06 18:00:00', '2026-03-09 04:00:00', 58.0, 29229622),
    ('MJOB-000070', 'MVXGFXVW54L5Z5CZ4', 7, NULL, '2026-05-13 05:00:00', '2026-05-15 07:00:00', 50.0, 1318941),
    ('MJOB-000071', 'LBK5CJES001CK5005', 5, NULL, '2026-06-08 03:00:00', '2026-06-11 07:00:00', 76.0, 12298017),
    ('MJOB-000072', 'BM81HTT5PV8NHJE5M', 6, NULL, '2026-06-21 02:00:00', '2026-06-22 05:00:00', 27.0, 7980378),
    ('MJOB-000073', 'EJXE56ZJMJ49DHKWL', 2, NULL, '2026-04-29 08:00:00', '2026-05-05 14:00:00', 150.0, 19297472),
    ('MJOB-000074', 'EJXE56ZJMJ49DHKWL', 2, NULL, '2026-03-28 10:00:00', '2026-04-02 10:00:00', 120.0, 7429115),
    ('MJOB-000075', 'UJWF9LKLYCBFCTP3B', 4, NULL, '2026-03-15 20:00:00', '2026-03-22 02:00:00', 150.0, 24585433),
    ('MJOB-000076', 'UJWF9LKLYCBFCTP3B', 4, NULL, '2026-02-02 19:00:00', '2026-02-07 03:00:00', 104.0, 10258859),
    ('MJOB-000077', 'VB2UAD8VRZRNTJGCW', 5, NULL, '2026-07-13 01:00:00', NULL, 8.0, NULL),
    ('MJOB-000078', 'W65CD0VEF916C5NX7', 2, NULL, '2026-07-11 17:00:00', NULL, 40.0, NULL),
    ('MJOB-000079', 'YZ6UWTRHNXHMNP7UV', 1, NULL, '2026-07-11 19:00:00', NULL, 38.0, NULL);


-- MaintenanceActivity -- 157 rows

INSERT INTO MaintenanceActivity (ActivityID, JobID, ActivityTypeID, DiagnosticResult, RepeatedFaultFlag, WarrantyFlag, LinkedAlertID) VALUES
    (1, 'MJOB-000001', 2, 'Preventative service performed per manufacturer interval.', 0, 0, 1),
    (2, 'MJOB-000001', 1, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (3, 'MJOB-000001', 3, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (4, 'MJOB-000002', 5, 'Visual and diagnostic inspection completed; findings addressed.', 0, 1, 3),
    (5, 'MJOB-000003', 4, 'Follow-up inspection following prior repair.', 0, 0, 10),
    (6, 'MJOB-000004', 3, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, 11),
    (7, 'MJOB-000004', 7, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (8, 'MJOB-000005', 5, 'Follow-up inspection following prior repair.', 0, 0, NULL),
    (9, 'MJOB-000005', 2, 'Follow-up inspection following prior repair.', 0, 1, NULL),
    (10, 'MJOB-000005', 3, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (11, 'MJOB-000006', 1, 'Preventative service performed per manufacturer interval.', 0, 0, 20),
    (12, 'MJOB-000006', 4, 'Fault confirmed via diagnostic scan; component serviced.', 1, 0, NULL),
    (13, 'MJOB-000006', 6, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (14, 'MJOB-000007', 1, 'Routine wear-and-tear identified during scheduled check.', 0, 0, 36),
    (15, 'MJOB-000007', 4, 'Fault confirmed via diagnostic scan; component serviced.', 0, 1, NULL),
    (16, 'MJOB-000007', 3, 'Fault confirmed via diagnostic scan; component serviced.', 0, 1, NULL),
    (17, 'MJOB-000008', 1, 'Routine wear-and-tear identified during scheduled check.', 0, 0, 40),
    (18, 'MJOB-000008', 3, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (19, 'MJOB-000008', 5, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (20, 'MJOB-000009', 3, 'Customer-reported issue reproduced and resolved.', 0, 1, 71),
    (21, 'MJOB-000010', 1, 'Routine wear-and-tear identified during scheduled check.', 0, 0, 50),
    (22, 'MJOB-000011', 1, 'Customer-reported issue reproduced and resolved.', 0, 0, 59),
    (23, 'MJOB-000011', 2, 'Visual and diagnostic inspection completed; findings addressed.', 0, 1, NULL),
    (24, 'MJOB-000011', 5, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (25, 'MJOB-000012', 3, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, 60),
    (26, 'MJOB-000012', 1, 'Follow-up inspection following prior repair.', 0, 0, NULL),
    (27, 'MJOB-000012', 7, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (28, 'MJOB-000013', 1, 'Routine wear-and-tear identified during scheduled check.', 0, 0, 63),
    (29, 'MJOB-000014', 4, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (30, 'MJOB-000014', 3, 'Follow-up inspection following prior repair.', 0, 0, NULL),
    (31, 'MJOB-000015', 2, 'Fault confirmed via diagnostic scan; component serviced.', 1, 0, 88),
    (32, 'MJOB-000015', 1, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (33, 'MJOB-000016', 1, 'Fault confirmed via diagnostic scan; component serviced.', 0, 1, NULL),
    (34, 'MJOB-000017', 1, 'Fault confirmed via diagnostic scan; component serviced.', 0, 1, NULL),
    (35, 'MJOB-000018', 2, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (36, 'MJOB-000018', 3, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (37, 'MJOB-000019', 1, 'Routine wear-and-tear identified during scheduled check.', 1, 0, NULL),
    (38, 'MJOB-000020', 2, 'Routine wear-and-tear identified during scheduled check.', 0, 1, NULL),
    (39, 'MJOB-000020', 5, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (40, 'MJOB-000021', 5, 'Customer-reported issue reproduced and resolved.', 1, 0, NULL),
    (41, 'MJOB-000021', 1, 'Follow-up inspection following prior repair.', 0, 1, NULL),
    (42, 'MJOB-000021', 2, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (43, 'MJOB-000022', 2, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (44, 'MJOB-000023', 3, 'Routine wear-and-tear identified during scheduled check.', 0, 1, NULL),
    (45, 'MJOB-000023', 2, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (46, 'MJOB-000024', 1, 'Customer-reported issue reproduced and resolved.', 0, 1, NULL),
    (47, 'MJOB-000024', 2, 'Follow-up inspection following prior repair.', 1, 0, NULL),
    (48, 'MJOB-000024', 8, 'Customer-reported issue reproduced and resolved.', 0, 1, NULL),
    (49, 'MJOB-000025', 3, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (50, 'MJOB-000026', 5, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (51, 'MJOB-000026', 2, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (52, 'MJOB-000027', 2, 'Fault confirmed via diagnostic scan; component serviced.', 1, 0, NULL),
    (53, 'MJOB-000027', 3, 'Customer-reported issue reproduced and resolved.', 0, 1, NULL),
    (54, 'MJOB-000027', 5, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (55, 'MJOB-000028', 4, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (56, 'MJOB-000028', 5, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (57, 'MJOB-000028', 2, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (58, 'MJOB-000029', 1, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (59, 'MJOB-000029', 4, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (60, 'MJOB-000029', 6, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (61, 'MJOB-000030', 2, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (62, 'MJOB-000030', 4, 'Follow-up inspection following prior repair.', 0, 0, NULL),
    (63, 'MJOB-000031', 1, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (64, 'MJOB-000032', 2, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (65, 'MJOB-000032', 5, 'Visual and diagnostic inspection completed; findings addressed.', 1, 0, NULL),
    (66, 'MJOB-000033', 2, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (67, 'MJOB-000033', 4, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (68, 'MJOB-000034', 3, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (69, 'MJOB-000035', 2, 'Fault confirmed via diagnostic scan; component serviced.', 0, 1, NULL),
    (70, 'MJOB-000036', 2, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (71, 'MJOB-000036', 7, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (72, 'MJOB-000037', 4, 'Preventative service performed per manufacturer interval.', 0, 1, NULL),
    (73, 'MJOB-000038', 4, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (74, 'MJOB-000039', 4, 'Visual and diagnostic inspection completed; findings addressed.', 0, 1, NULL),
    (75, 'MJOB-000039', 5, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (76, 'MJOB-000039', 2, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (77, 'MJOB-000040', 4, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (78, 'MJOB-000041', 2, 'Routine wear-and-tear identified during scheduled check.', 1, 0, NULL),
    (79, 'MJOB-000042', 3, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (80, 'MJOB-000042', 2, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (81, 'MJOB-000043', 7, 'Fault confirmed via diagnostic scan; component serviced.', 1, 0, NULL),
    (82, 'MJOB-000043', 2, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (83, 'MJOB-000043', 1, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (84, 'MJOB-000044', 1, 'Visual and diagnostic inspection completed; findings addressed.', 0, 1, NULL),
    (85, 'MJOB-000044', 2, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (86, 'MJOB-000044', 5, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (87, 'MJOB-000045', 1, 'Visual and diagnostic inspection completed; findings addressed.', 0, 1, NULL),
    (88, 'MJOB-000046', 3, 'Preventative service performed per manufacturer interval.', 0, 1, NULL),
    (89, 'MJOB-000046', 5, 'Customer-reported issue reproduced and resolved.', 1, 1, NULL),
    (90, 'MJOB-000047', 4, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (91, 'MJOB-000048', 3, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (92, 'MJOB-000048', 5, 'Fault confirmed via diagnostic scan; component serviced.', 1, 0, NULL),
    (93, 'MJOB-000048', 4, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (94, 'MJOB-000049', 2, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (95, 'MJOB-000049', 3, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (96, 'MJOB-000049', 5, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (97, 'MJOB-000050', 5, 'Customer-reported issue reproduced and resolved.', 1, 0, NULL),
    (98, 'MJOB-000050', 1, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (99, 'MJOB-000051', 2, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (100, 'MJOB-000051', 4, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (101, 'MJOB-000052', 4, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (102, 'MJOB-000052', 1, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (103, 'MJOB-000053', 2, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (104, 'MJOB-000053', 4, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (105, 'MJOB-000054', 6, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (106, 'MJOB-000054', 1, 'Customer-reported issue reproduced and resolved.', 0, 1, NULL),
    (107, 'MJOB-000054', 2, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (108, 'MJOB-000055', 7, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (109, 'MJOB-000055', 2, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (110, 'MJOB-000055', 5, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (111, 'MJOB-000056', 2, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (112, 'MJOB-000057', 4, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (113, 'MJOB-000057', 2, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (114, 'MJOB-000058', 1, 'Follow-up inspection following prior repair.', 0, 0, NULL),
    (115, 'MJOB-000059', 1, 'Routine wear-and-tear identified during scheduled check.', 0, 1, NULL),
    (116, 'MJOB-000060', 5, 'Visual and diagnostic inspection completed; findings addressed.', 1, 0, NULL),
    (117, 'MJOB-000061', 5, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (118, 'MJOB-000062', 5, 'Routine wear-and-tear identified during scheduled check.', 1, 0, NULL),
    (119, 'MJOB-000063', 2, 'Preventative service performed per manufacturer interval.', 0, 1, NULL),
    (120, 'MJOB-000064', 6, 'Preventative service performed per manufacturer interval.', 0, 1, NULL),
    (121, 'MJOB-000064', 3, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (122, 'MJOB-000064', 1, 'Follow-up inspection following prior repair.', 1, 0, NULL),
    (123, 'MJOB-000065', 1, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (124, 'MJOB-000065', 4, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (125, 'MJOB-000065', 5, 'Preventative service performed per manufacturer interval.', 1, 0, NULL),
    (126, 'MJOB-000066', 3, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (127, 'MJOB-000067', 4, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (128, 'MJOB-000068', 5, 'Preventative service performed per manufacturer interval.', 1, 0, NULL),
    (129, 'MJOB-000068', 4, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (130, 'MJOB-000068', 2, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (131, 'MJOB-000069', 1, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (132, 'MJOB-000069', 3, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (133, 'MJOB-000069', 5, 'Follow-up inspection following prior repair.', 0, 0, NULL),
    (134, 'MJOB-000070', 6, 'Preventative service performed per manufacturer interval.', 1, 0, NULL),
    (135, 'MJOB-000070', 3, 'Follow-up inspection following prior repair.', 0, 0, NULL),
    (136, 'MJOB-000071', 4, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (137, 'MJOB-000071', 1, 'Fault confirmed via diagnostic scan; component serviced.', 0, 1, NULL),
    (138, 'MJOB-000072', 1, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (139, 'MJOB-000072', 2, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (140, 'MJOB-000072', 3, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (141, 'MJOB-000073', 1, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (142, 'MJOB-000074', 2, 'Preventative service performed per manufacturer interval.', 0, 0, NULL),
    (143, 'MJOB-000074', 3, 'Follow-up inspection following prior repair.', 0, 1, NULL),
    (144, 'MJOB-000074', 4, 'Routine wear-and-tear identified during scheduled check.', 0, 0, NULL),
    (145, 'MJOB-000075', 3, 'Routine wear-and-tear identified during scheduled check.', 0, 1, NULL),
    (146, 'MJOB-000076', 4, 'Visual and diagnostic inspection completed; findings addressed.', 0, 1, NULL),
    (147, 'MJOB-000076', 2, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (148, 'MJOB-000076', 1, 'Routine wear-and-tear identified during scheduled check.', 0, 1, NULL),
    (149, 'MJOB-000077', 3, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (150, 'MJOB-000077', 4, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (151, 'MJOB-000077', 5, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (152, 'MJOB-000078', 5, 'Fault confirmed via diagnostic scan; component serviced.', 0, 0, NULL),
    (153, 'MJOB-000078', 4, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL),
    (154, 'MJOB-000078', 2, 'Routine wear-and-tear identified during scheduled check.', 0, 1, NULL),
    (155, 'MJOB-000079', 2, 'Fault confirmed via diagnostic scan; component serviced.', 0, 1, NULL),
    (156, 'MJOB-000079', 1, 'Customer-reported issue reproduced and resolved.', 0, 0, NULL),
    (157, 'MJOB-000079', 4, 'Visual and diagnostic inspection completed; findings addressed.', 0, 0, NULL);


-- MechanicWorkSession -- 157 rows

INSERT INTO MechanicWorkSession (SessionID, MechanicID, ActivityID, StartTime, EndTime) VALUES
    (1, 'ME-0002', 1, '2026-06-18 20:44:48', '2026-06-19 04:44:48'),
    (2, 'ME-0004', 2, '2026-06-18 18:44:48', '2026-06-18 23:44:48'),
    (3, 'ME-0025', 3, '2026-06-18 18:44:48', '2026-06-19 02:44:48'),
    (4, 'ME-0011', 4, '2026-06-08 05:21:31', '2026-06-08 06:21:31'),
    (5, 'ME-0012', 5, '2026-04-22 09:23:20', '2026-04-22 15:23:20'),
    (6, 'ME-0005', 6, '2026-06-08 08:33:05', '2026-06-08 09:33:05'),
    (7, 'ME-0005', 7, '2026-06-08 10:33:05', '2026-06-08 12:33:05'),
    (8, 'ME-0008', 8, '2026-04-08 08:00:00', '2026-04-08 13:00:00'),
    (9, 'ME-0005', 9, '2026-04-08 07:00:00', '2026-04-08 11:00:00'),
    (10, 'ME-0005', 10, '2026-04-08 08:00:00', '2026-04-08 15:00:00'),
    (11, 'ME-0016', 11, '2026-03-11 03:54:43', '2026-03-11 08:54:43'),
    (12, 'ME-0016', 12, '2026-03-11 05:54:43', '2026-03-11 07:54:43'),
    (13, 'ME-0016', 13, '2026-03-11 03:54:43', '2026-03-11 06:54:43'),
    (14, 'ME-0012', 14, '2026-05-12 07:55:17', '2026-05-12 12:55:17'),
    (15, 'ME-0012', 15, '2026-05-12 05:55:17', '2026-05-12 08:55:17'),
    (16, 'ME-0012', 16, '2026-05-12 09:55:17', '2026-05-12 11:55:17'),
    (17, 'ME-0005', 17, '2026-06-24 07:14:20', '2026-06-24 09:14:20'),
    (18, 'ME-0008', 18, '2026-06-24 04:14:20', '2026-06-24 11:14:20'),
    (19, 'ME-0005', 19, '2026-06-24 06:14:20', '2026-06-24 09:14:20'),
    (20, 'ME-0005', 20, '2026-06-23 19:37:42', '2026-06-23 22:37:42'),
    (21, 'ME-0012', 21, '2026-03-15 11:19:41', '2026-03-15 12:19:41'),
    (22, 'ME-0013', 22, '2026-01-30 01:49:27', '2026-01-30 07:49:27'),
    (23, 'ME-0013', 23, '2026-01-30 03:49:27', '2026-01-30 08:49:27'),
    (24, 'ME-0013', 24, '2026-01-29 23:49:27', '2026-01-30 03:49:27'),
    (25, 'ME-0006', 25, '2026-05-07 18:45:46', '2026-05-08 01:45:46'),
    (26, 'ME-0014', 26, '2026-05-07 21:45:46', '2026-05-08 02:45:46'),
    (27, 'ME-0002', 27, '2026-05-07 17:45:46', '2026-05-07 20:45:46'),
    (28, 'ME-0004', 28, '2026-02-07 15:35:28', '2026-02-07 21:35:28'),
    (29, 'ME-0025', 29, '2026-03-27 10:00:00', '2026-03-27 18:00:00'),
    (30, 'ME-0004', 30, '2026-03-27 12:00:00', '2026-03-27 14:00:00'),
    (31, 'ME-0017', 31, '2026-07-05 16:05:39', '2026-07-05 19:05:39'),
    (32, 'ME-0017', 32, '2026-07-05 18:05:39', '2026-07-05 19:05:39'),
    (33, 'ME-0002', 33, '2026-05-03 07:00:00', '2026-05-03 14:00:00'),
    (34, 'ME-0004', 34, '2026-05-20 07:00:00', '2026-05-20 14:00:00'),
    (35, 'ME-0011', 35, '2026-02-19 10:00:00', '2026-02-19 11:00:00'),
    (36, 'ME-0021', 36, '2026-02-19 10:00:00', '2026-02-19 16:00:00'),
    (37, 'ME-0002', 37, '2026-03-11 08:00:00', '2026-03-11 13:00:00'),
    (38, 'ME-0002', 38, '2026-03-28 11:00:00', '2026-03-28 12:00:00'),
    (39, 'ME-0004', 39, '2026-03-28 09:00:00', '2026-03-28 16:00:00'),
    (40, 'ME-0003', 40, '2026-02-17 09:00:00', '2026-02-17 12:00:00'),
    (41, 'ME-0011', 41, '2026-02-17 08:00:00', '2026-02-17 11:00:00'),
    (42, 'ME-0021', 42, '2026-02-17 08:00:00', '2026-02-17 14:00:00'),
    (43, 'ME-0014', 43, '2026-02-13 07:00:00', '2026-02-13 08:00:00'),
    (44, 'ME-0018', 44, '2026-05-27 09:00:00', '2026-05-27 11:00:00'),
    (45, 'ME-0011', 45, '2026-05-27 10:00:00', '2026-05-27 16:00:00'),
    (46, 'ME-0013', 46, '2026-05-08 19:00:00', '2026-05-09 02:00:00'),
    (47, 'ME-0020', 47, '2026-05-08 18:00:00', '2026-05-08 20:00:00'),
    (48, 'ME-0017', 48, '2026-05-08 16:00:00', '2026-05-08 23:00:00'),
    (49, 'ME-0013', 49, '2026-04-05 02:00:00', '2026-04-05 03:00:00'),
    (50, 'ME-0002', 50, '2026-04-26 12:00:00', '2026-04-26 18:00:00'),
    (51, 'ME-0004', 51, '2026-04-26 14:00:00', '2026-04-26 21:00:00'),
    (52, 'ME-0025', 52, '2026-06-06 04:00:00', '2026-06-06 06:00:00'),
    (53, 'ME-0002', 53, '2026-06-06 02:00:00', '2026-06-06 06:00:00'),
    (54, 'ME-0009', 54, '2026-06-06 03:00:00', '2026-06-06 07:00:00'),
    (55, 'ME-0012', 55, '2026-01-17 20:00:00', '2026-01-18 02:00:00'),
    (56, 'ME-0012', 56, '2026-01-17 20:00:00', '2026-01-17 23:00:00'),
    (57, 'ME-0012', 57, '2026-01-17 16:00:00', '2026-01-17 18:00:00'),
    (58, 'ME-0001', 58, '2026-02-09 01:00:00', '2026-02-09 08:00:00'),
    (59, 'ME-0022', 59, '2026-02-09 01:00:00', '2026-02-09 08:00:00'),
    (60, 'ME-0021', 60, '2026-02-08 23:00:00', '2026-02-09 00:00:00'),
    (61, 'ME-0012', 61, '2026-06-15 18:00:00', '2026-06-16 01:00:00'),
    (62, 'ME-0012', 62, '2026-06-15 21:00:00', '2026-06-15 23:00:00'),
    (63, 'ME-0012', 63, '2026-06-03 12:00:00', '2026-06-03 14:00:00'),
    (64, 'ME-0017', 64, '2026-04-14 17:00:00', '2026-04-14 18:00:00'),
    (65, 'ME-0013', 65, '2026-04-14 15:00:00', '2026-04-14 17:00:00'),
    (66, 'ME-0005', 66, '2026-03-21 15:00:00', '2026-03-21 17:00:00'),
    (67, 'ME-0005', 67, '2026-03-21 13:00:00', '2026-03-21 18:00:00'),
    (68, 'ME-0006', 68, '2026-07-01 02:00:00', '2026-07-01 07:00:00'),
    (69, 'ME-0016', 69, '2026-01-21 02:00:00', '2026-01-21 05:00:00'),
    (70, 'ME-0016', 70, '2026-05-19 20:00:00', '2026-05-20 01:00:00'),
    (71, 'ME-0015', 71, '2026-05-20 01:00:00', '2026-05-20 06:00:00'),
    (72, 'ME-0022', 72, '2026-03-06 05:00:00', '2026-03-06 12:00:00'),
    (73, 'ME-0005', 73, '2026-01-15 20:00:00', '2026-01-16 01:00:00'),
    (74, 'ME-0016', 74, '2026-03-26 08:00:00', '2026-03-26 09:00:00'),
    (75, 'ME-0016', 75, '2026-03-26 10:00:00', '2026-03-26 11:00:00'),
    (76, 'ME-0016', 76, '2026-03-26 08:00:00', '2026-03-26 10:00:00'),
    (77, 'ME-0016', 77, '2026-02-03 02:00:00', '2026-02-03 04:00:00'),
    (78, 'ME-0012', 78, '2026-01-15 16:00:00', '2026-01-15 17:00:00'),
    (79, 'ME-0011', 79, '2026-03-31 11:00:00', '2026-03-31 14:00:00'),
    (80, 'ME-0018', 80, '2026-03-31 11:00:00', '2026-03-31 19:00:00'),
    (81, 'ME-0002', 81, '2026-02-03 23:00:00', '2026-02-04 03:00:00'),
    (82, 'ME-0016', 82, '2026-02-03 20:00:00', '2026-02-04 04:00:00'),
    (83, 'ME-0016', 83, '2026-02-03 21:00:00', '2026-02-04 01:00:00'),
    (84, 'ME-0021', 84, '2026-06-27 15:00:00', '2026-06-27 23:00:00'),
    (85, 'ME-0018', 85, '2026-06-27 12:00:00', '2026-06-27 14:00:00'),
    (86, 'ME-0011', 86, '2026-06-27 12:00:00', '2026-06-27 16:00:00'),
    (87, 'ME-0014', 87, '2026-05-03 11:00:00', '2026-05-03 13:00:00'),
    (88, 'ME-0021', 88, '2026-03-23 03:00:00', '2026-03-23 08:00:00'),
    (89, 'ME-0011', 89, '2026-03-22 22:00:00', '2026-03-23 06:00:00'),
    (90, 'ME-0022', 90, '2026-04-13 23:00:00', '2026-04-14 02:00:00'),
    (91, 'ME-0022', 91, '2026-04-01 08:00:00', '2026-04-01 14:00:00'),
    (92, 'ME-0001', 92, '2026-04-01 08:00:00', '2026-04-01 16:00:00'),
    (93, 'ME-0022', 93, '2026-04-01 07:00:00', '2026-04-01 09:00:00'),
    (94, 'ME-0009', 94, '2026-03-25 05:00:00', '2026-03-25 09:00:00'),
    (95, 'ME-0002', 95, '2026-03-25 06:00:00', '2026-03-25 14:00:00'),
    (96, 'ME-0004', 96, '2026-03-25 07:00:00', '2026-03-25 12:00:00'),
    (97, 'ME-0014', 97, '2026-03-29 12:00:00', '2026-03-29 13:00:00'),
    (98, 'ME-0006', 98, '2026-03-29 07:00:00', '2026-03-29 12:00:00'),
    (99, 'ME-0012', 99, '2026-02-02 18:00:00', '2026-02-02 23:00:00'),
    (100, 'ME-0012', 100, '2026-02-02 18:00:00', '2026-02-02 21:00:00'),
    (101, 'ME-0012', 101, '2026-06-08 06:00:00', '2026-06-08 12:00:00'),
    (102, 'ME-0012', 102, '2026-06-08 04:00:00', '2026-06-08 09:00:00'),
    (103, 'ME-0017', 103, '2026-06-21 00:00:00', '2026-06-21 02:00:00'),
    (104, 'ME-0017', 104, '2026-06-21 04:00:00', '2026-06-21 06:00:00'),
    (105, 'ME-0014', 105, '2026-02-14 07:00:00', '2026-02-14 10:00:00'),
    (106, 'ME-0006', 106, '2026-02-14 06:00:00', '2026-02-14 08:00:00'),
    (107, 'ME-0014', 107, '2026-02-14 10:00:00', '2026-02-14 18:00:00'),
    (108, 'ME-0012', 108, '2026-02-20 06:00:00', '2026-02-20 11:00:00'),
    (109, 'ME-0012', 109, '2026-02-20 08:00:00', '2026-02-20 10:00:00'),
    (110, 'ME-0012', 110, '2026-02-20 03:00:00', '2026-02-20 11:00:00'),
    (111, 'ME-0005', 111, '2026-02-17 23:00:00', '2026-02-18 06:00:00'),
    (112, 'ME-0022', 112, '2026-06-29 11:00:00', '2026-06-29 19:00:00'),
    (113, 'ME-0022', 113, '2026-06-29 12:00:00', '2026-06-29 18:00:00'),
    (114, 'ME-0025', 114, '2026-01-30 10:00:00', '2026-01-30 14:00:00'),
    (115, 'ME-0002', 115, '2026-04-30 10:00:00', '2026-04-30 16:00:00'),
    (116, 'ME-0001', 116, '2026-02-23 20:00:00', '2026-02-23 23:00:00'),
    (117, 'ME-0008', 117, '2026-04-28 05:00:00', '2026-04-28 11:00:00'),
    (118, 'ME-0006', 118, '2026-01-30 21:00:00', '2026-01-31 05:00:00'),
    (119, 'ME-0001', 119, '2026-03-28 19:00:00', '2026-03-29 00:00:00'),
    (120, 'ME-0021', 120, '2026-03-05 22:00:00', '2026-03-05 23:00:00'),
    (121, 'ME-0017', 121, '2026-03-05 22:00:00', '2026-03-05 23:00:00'),
    (122, 'ME-0017', 122, '2026-03-05 20:00:00', '2026-03-06 04:00:00'),
    (123, 'ME-0021', 123, '2026-01-19 18:00:00', '2026-01-20 01:00:00'),
    (124, 'ME-0018', 124, '2026-01-19 14:00:00', '2026-01-19 20:00:00'),
    (125, 'ME-0003', 125, '2026-01-19 13:00:00', '2026-01-19 17:00:00'),
    (126, 'ME-0017', 126, '2026-01-27 12:00:00', '2026-01-27 19:00:00'),
    (127, 'ME-0017', 127, '2026-03-07 03:00:00', '2026-03-07 07:00:00'),
    (128, 'ME-0013', 128, '2026-05-21 12:00:00', '2026-05-21 16:00:00'),
    (129, 'ME-0013', 129, '2026-05-21 11:00:00', '2026-05-21 19:00:00'),
    (130, 'ME-0013', 130, '2026-05-21 12:00:00', '2026-05-21 19:00:00'),
    (131, 'ME-0018', 131, '2026-03-06 21:00:00', '2026-03-07 01:00:00'),
    (132, 'ME-0021', 132, '2026-03-07 00:00:00', '2026-03-07 01:00:00'),
    (133, 'ME-0018', 133, '2026-03-06 23:00:00', '2026-03-07 07:00:00'),
    (134, 'ME-0016', 134, '2026-05-13 08:00:00', '2026-05-13 15:00:00'),
    (135, 'ME-0012', 135, '2026-05-13 11:00:00', '2026-05-13 12:00:00'),
    (136, 'ME-0025', 136, '2026-06-08 09:00:00', '2026-06-08 13:00:00'),
    (137, 'ME-0009', 137, '2026-06-08 06:00:00', '2026-06-08 11:00:00'),
    (138, 'ME-0001', 138, '2026-06-21 07:00:00', '2026-06-21 11:00:00'),
    (139, 'ME-0001', 139, '2026-06-21 08:00:00', '2026-06-21 14:00:00'),
    (140, 'ME-0022', 140, '2026-06-21 03:00:00', '2026-06-21 05:00:00'),
    (141, 'ME-0014', 141, '2026-04-29 14:00:00', '2026-04-29 20:00:00'),
    (142, 'ME-0014', 142, '2026-03-28 12:00:00', '2026-03-28 19:00:00'),
    (143, 'ME-0006', 143, '2026-03-28 11:00:00', '2026-03-28 15:00:00'),
    (144, 'ME-0006', 144, '2026-03-28 14:00:00', '2026-03-28 20:00:00'),
    (145, 'ME-0020', 145, '2026-03-16 00:00:00', '2026-03-16 04:00:00'),
    (146, 'ME-0017', 146, '2026-02-02 22:00:00', '2026-02-03 06:00:00'),
    (147, 'ME-0013', 147, '2026-02-03 00:00:00', '2026-02-03 07:00:00'),
    (148, 'ME-0020', 148, '2026-02-03 00:00:00', '2026-02-03 02:00:00'),
    (149, 'ME-0009', 149, '2026-07-13 05:00:00', '2026-07-13 09:00:00'),
    (150, 'ME-0002', 150, '2026-07-13 06:00:00', '2026-07-13 09:00:00'),
    (151, 'ME-0004', 151, '2026-07-13 04:00:00', NULL),
    (152, 'ME-0006', 152, '2026-07-11 18:00:00', '2026-07-12 00:00:00'),
    (153, 'ME-0014', 153, '2026-07-11 20:00:00', NULL),
    (154, 'ME-0006', 154, '2026-07-11 19:00:00', '2026-07-11 21:00:00'),
    (155, 'ME-0008', 155, '2026-07-12 00:00:00', NULL),
    (156, 'ME-0008', 156, '2026-07-11 22:00:00', NULL),
    (157, 'ME-0005', 157, '2026-07-12 01:00:00', NULL);


-- WarrantyClaim -- 22 rows

INSERT INTO WarrantyClaim (ClaimID, ActivityID, ClaimSource, ClaimDate, Status, ResolutionDate) VALUES
    (1, 4, 'Parts Supplier', '2026-06-09 01:21:31', 'Pending', NULL),
    (2, 9, 'Vehicle Manufacturer', '2026-04-11 06:00:00', 'Pending', NULL),
    (3, 16, 'Vehicle Manufacturer', '2026-05-14 04:55:17', 'Rejected', '2026-05-27 04:55:17'),
    (4, 20, 'Internal Claim', '2026-06-24 18:37:42', 'Approved', '2026-07-08 18:37:42'),
    (5, 23, 'Vehicle Manufacturer', '2026-02-01 22:49:27', 'Approved', '2026-02-10 22:49:27'),
    (6, 33, 'Internal Claim', '2026-05-04 06:00:00', 'Settled', '2026-05-10 06:00:00'),
    (7, 38, 'Parts Supplier', '2026-03-31 06:00:00', 'Approved', '2026-04-12 06:00:00'),
    (8, 44, 'Parts Supplier', '2026-05-30 06:00:00', 'Rejected', '2026-06-16 06:00:00'),
    (9, 48, 'Internal Claim', '2026-05-10 14:00:00', 'Approved', '2026-05-27 14:00:00'),
    (10, 69, 'Vehicle Manufacturer', '2026-01-21 23:00:00', 'Approved', '2026-02-07 23:00:00'),
    (11, 72, 'Parts Supplier', '2026-03-08 00:00:00', 'Approved', '2026-03-13 00:00:00'),
    (12, 84, 'Vehicle Manufacturer', '2026-06-27 09:00:00', 'Pending', NULL),
    (13, 87, 'Parts Supplier', '2026-05-05 09:00:00', 'Rejected', '2026-05-19 09:00:00'),
    (14, 89, 'Vehicle Manufacturer', '2026-03-22 21:00:00', 'Approved', '2026-04-01 21:00:00'),
    (15, 106, 'Vehicle Manufacturer', '2026-02-14 05:00:00', 'Approved', '2026-02-23 05:00:00'),
    (16, 115, 'Vehicle Manufacturer', '2026-05-03 08:00:00', 'Settled', '2026-05-23 08:00:00'),
    (17, 119, 'Parts Supplier', '2026-03-28 14:00:00', 'Settled', '2026-04-02 14:00:00'),
    (18, 120, 'Internal Claim', '2026-03-05 16:00:00', 'Pending', NULL),
    (19, 143, 'Vehicle Manufacturer', '2026-03-31 10:00:00', 'Settled', '2026-04-05 10:00:00'),
    (20, 145, 'Vehicle Manufacturer', '2026-03-18 20:00:00', 'Settled', '2026-03-24 20:00:00'),
    (21, 154, 'Vehicle Manufacturer', '2026-07-12 17:00:00', 'Pending', NULL),
    (22, 155, 'Parts Supplier', '2026-07-12 19:00:00', 'Pending', NULL);


-- ActivityPart -- 157 rows (stock tracked locally, never oversold)

INSERT INTO ActivityPart (ActivityID, PartNumber, ClaimID, QuantityUsed, UnitCost) VALUES
    (1, 10, NULL, 2, 733023),
    (5, 16, NULL, 3, 3622546),
    (5, 2, NULL, 3, 473317),
    (7, 6, NULL, 2, 3089940),
    (7, 9, NULL, 2, 2593129),
    (8, 19, NULL, 2, 771748),
    (9, 10, 2, 3, 6423630),
    (10, 29, NULL, 3, 2953695),
    (11, 10, NULL, 1, 4789418),
    (12, 15, NULL, 3, 3262487),
    (15, 30, NULL, 1, 2308571),
    (16, 24, 3, 1, 5169483),
    (17, 21, NULL, 3, 5360940),
    (17, 9, NULL, 3, 4661097),
    (18, 15, NULL, 1, 6162105),
    (19, 6, NULL, 1, 1624271),
    (19, 27, NULL, 3, 4154766),
    (20, 24, NULL, 1, 3209846),
    (22, 5, NULL, 1, 4599430),
    (22, 8, NULL, 3, 2283588),
    (23, 13, NULL, 2, 1934855),
    (23, 5, 5, 3, 7457407),
    (25, 20, NULL, 1, 5739499),
    (26, 29, NULL, 1, 2314095),
    (27, 11, NULL, 1, 3316586),
    (28, 6, NULL, 2, 2997896),
    (29, 18, NULL, 1, 3266487),
    (29, 27, NULL, 1, 4913478),
    (30, 12, NULL, 1, 1745233),
    (31, 8, NULL, 1, 508635),
    (31, 7, NULL, 3, 1195961),
    (32, 12, NULL, 3, 929274),
    (32, 2, NULL, 3, 4918873),
    (33, 16, NULL, 2, 3764320),
    (34, 18, NULL, 2, 7750390),
    (34, 23, NULL, 3, 4250011),
    (35, 13, NULL, 1, 6939671),
    (36, 27, NULL, 1, 498619),
    (36, 13, NULL, 2, 5464469),
    (37, 18, NULL, 1, 587936),
    (39, 5, NULL, 3, 5699679),
    (40, 22, NULL, 2, 700626),
    (41, 17, NULL, 3, 6152951),
    (42, 12, NULL, 3, 7220250),
    (43, 25, NULL, 2, 4629709),
    (44, 4, 8, 3, 3089025),
    (45, 12, NULL, 1, 5762715),
    (46, 13, NULL, 2, 5653241),
    (48, 4, 9, 2, 1346451),
    (48, 9, 9, 2, 1830717),
    (49, 9, NULL, 1, 741214),
    (49, 21, NULL, 1, 620987),
    (50, 6, NULL, 1, 2969941),
    (51, 30, NULL, 3, 4824164),
    (52, 9, NULL, 3, 70843),
    (52, 17, NULL, 2, 7953173),
    (53, 14, NULL, 3, 4620903),
    (56, 13, NULL, 3, 5815981),
    (56, 10, NULL, 3, 3709962),
    (59, 1, NULL, 1, 4297728),
    (59, 12, NULL, 2, 2284868),
    (60, 2, NULL, 1, 1326605),
    (60, 1, NULL, 2, 7092886),
    (61, 13, NULL, 2, 4379234),
    (62, 27, NULL, 3, 7729546),
    (62, 25, NULL, 2, 7064099),
    (63, 1, NULL, 3, 1135116),
    (63, 24, NULL, 2, 5362262),
    (64, 3, NULL, 1, 5303331),
    (66, 22, NULL, 2, 3187861),
    (69, 23, NULL, 3, 3957846),
    (70, 26, NULL, 1, 6097081),
    (71, 20, NULL, 1, 5134365),
    (72, 26, 11, 2, 1845095),
    (72, 6, 11, 3, 1256680),
    (73, 17, NULL, 1, 903357),
    (74, 4, NULL, 1, 5085166),
    (74, 15, NULL, 2, 4999102),
    (75, 10, NULL, 2, 350447),
    (75, 5, NULL, 3, 7741031),
    (76, 24, NULL, 2, 2700779),
    (76, 10, NULL, 2, 3398331),
    (78, 29, NULL, 1, 969487),
    (79, 21, NULL, 3, 1066541),
    (79, 15, NULL, 3, 4465736),
    (80, 3, NULL, 2, 6467368),
    (81, 27, NULL, 1, 4130667),
    (81, 13, NULL, 1, 2895902),
    (82, 28, NULL, 3, 926344),
    (83, 7, NULL, 2, 3589169),
    (83, 3, NULL, 1, 5796816),
    (84, 14, 12, 1, 4252678),
    (86, 6, NULL, 2, 4482294),
    (86, 20, NULL, 3, 4180753),
    (88, 6, NULL, 2, 5756353),
    (90, 25, NULL, 1, 878797),
    (91, 4, NULL, 3, 4396278),
    (91, 9, NULL, 3, 5407034),
    (93, 30, NULL, 2, 5398087),
    (95, 10, NULL, 1, 109918),
    (96, 10, NULL, 2, 2458099),
    (98, 24, NULL, 1, 3664304),
    (99, 19, NULL, 2, 5735220),
    (100, 18, NULL, 2, 2598492),
    (100, 7, NULL, 1, 2534219),
    (101, 15, NULL, 2, 3909530),
    (101, 14, NULL, 1, 7695093),
    (102, 19, NULL, 3, 3169883),
    (104, 19, NULL, 2, 5833113),
    (105, 21, NULL, 2, 6072600),
    (106, 1, 15, 3, 506852),
    (106, 27, 15, 1, 4097733),
    (108, 22, NULL, 1, 4978908),
    (109, 14, NULL, 2, 1282910),
    (109, 27, NULL, 1, 2417517),
    (112, 16, NULL, 3, 1553091),
    (112, 20, NULL, 3, 5983330),
    (113, 19, NULL, 3, 7001590),
    (114, 4, NULL, 1, 6148275),
    (115, 9, 16, 2, 2439891),
    (117, 20, NULL, 3, 7199019),
    (118, 2, NULL, 3, 4574361),
    (119, 21, 17, 1, 3575007),
    (122, 26, NULL, 1, 219879),
    (123, 4, NULL, 2, 1029793),
    (124, 30, NULL, 1, 1986437),
    (124, 2, NULL, 1, 4977681),
    (126, 22, NULL, 3, 684277),
    (126, 4, NULL, 1, 2138820),
    (127, 11, NULL, 3, 4581753),
    (129, 4, NULL, 2, 7055604),
    (129, 1, NULL, 1, 2307428),
    (130, 1, NULL, 2, 3266789),
    (130, 28, NULL, 2, 412584),
    (133, 19, NULL, 3, 6490943),
    (133, 24, NULL, 3, 2221882),
    (136, 2, NULL, 1, 2358994),
    (136, 19, NULL, 3, 4665880),
    (137, 8, NULL, 3, 1503772),
    (140, 7, NULL, 2, 4824575),
    (141, 10, NULL, 1, 1384801),
    (141, 20, NULL, 2, 414220),
    (143, 22, 19, 3, 2298068),
    (143, 17, NULL, 1, 2498409),
    (145, 22, 20, 3, 2223378),
    (145, 19, 20, 2, 1029553),
    (146, 28, NULL, 1, 7034912),
    (147, 12, NULL, 2, 5886261),
    (147, 5, NULL, 3, 2065302),
    (149, 24, NULL, 3, 7726832),
    (150, 13, NULL, 2, 1522453),
    (150, 11, NULL, 3, 6101047),
    (152, 14, NULL, 3, 2374182),
    (153, 9, NULL, 2, 3721900),
    (155, 30, NULL, 1, 7750671),
    (156, 9, NULL, 3, 5649592),
    (157, 17, NULL, 2, 2356162);


-- ==========================================================
-- 08 - SAFETY EVENTS
-- ==========================================================
-- SafetyEvent only -- DriverScorePenalty, CoachingRecord, and DrivingEligibility all cascade automatically via triggers. Rows sorted chronologically so Conditional PenaltyRule thresholds land on the realistic Nth event of the month.
-- ==========================================================

-- SafetyEvent -- 597 rows across 44 eligible drivers (excludes Terminated). Severity mix: {'Low': 271, 'High': 110, 'Medium': 179, 'Critical': 37}. ReviewState omitted -- column DEFAULT / TRG_SafetyEvent_BeforeInsert handle it correctly for every severity without an explicit value.

INSERT INTO SafetyEvent (EventID, DriverID, VIN, DepotID, EventTimestamp, EventTypeID, SeverityID, Odometer) VALUES
    ('EVT-0000001', 'D-0038', 'UANFS38S785BFVR2S', 6, '2026-01-13 05:26:30', 2, 1, 136482),
    ('EVT-0000002', 'D-0021', 'W65CD0VEF916C5NX7', 2, '2026-01-13 06:17:18', 7, 3, 185572),
    ('EVT-0000003', 'D-0020', '853UP9HZ4HV8WCR2D', 5, '2026-01-13 09:44:12', 2, 1, 200039),
    ('EVT-0000004', 'D-0010', 'EJXE56ZJMJ49DHKWL', 2, '2026-01-13 12:05:49', 6, 2, 72503),
    ('EVT-0000005', 'D-0030', '6ZWRRBN2YUEUZ92YB', 7, '2026-01-13 21:44:01', 3, 3, 30190),
    ('EVT-0000006', 'D-0012', 'GYJCZYM67MJE6CVNC', 8, '2026-01-14 00:48:33', 7, 1, 215797),
    ('EVT-0000007', 'D-0031', 'T10GR7BXRE6W3HJCC', 7, '2026-01-14 02:12:52', 3, 3, 37423),
    ('EVT-0000008', 'D-0031', 'CBSNBKSJ7HP6T0LHL', 7, '2026-01-14 08:38:12', 7, 2, 176332),
    ('EVT-0000009', 'D-0020', 'LBK5CJES001CK5005', 5, '2026-01-14 19:29:38', 6, 1, 81652),
    ('EVT-0000010', 'D-0017', 'W65CD0VEF916C5NX7', 2, '2026-01-15 12:08:48', 2, 1, 188688),
    ('EVT-0000011', 'D-0017', 'W65CD0VEF916C5NX7', 2, '2026-01-16 01:56:27', 8, 2, 188877),
    ('EVT-0000012', 'D-0044', 'B3D290S1F0RBXGYKJ', 8, '2026-01-16 12:08:20', 3, 3, 197098),
    ('EVT-0000013', 'D-0016', 'WFSH3R155W4WDGPPT', 3, '2026-01-16 17:10:13', 8, 3, 21563),
    ('EVT-0000014', 'D-0022', 'F7Z3YXGLY38V2C6FX', 8, '2026-01-16 23:13:17', 2, 1, 0),
    ('EVT-0000015', 'D-0029', 'K2EKBFP136YL0WXFD', 5, '2026-01-17 02:26:53', 1, 3, 20261),
    ('EVT-0000016', 'D-0019', 'G5LWBCXDVZ04KS3ML', 8, '2026-01-17 05:33:45', 1, 3, 63205),
    ('EVT-0000017', 'D-0003', 'NESGWHCZ40E9YA38G', 3, '2026-01-17 06:40:56', 4, 1, 114224),
    ('EVT-0000018', 'D-0042', 'G9CYJ1KLML5C30S5V', 6, '2026-01-17 11:29:25', 1, 1, 49659),
    ('EVT-0000019', 'D-0026', '7VCRVV6ERTN4HRKUK', 8, '2026-01-17 13:35:28', 5, 2, 75051),
    ('EVT-0000020', 'D-0044', 'B3D290S1F0RBXGYKJ', 8, '2026-01-18 07:23:23', 1, 1, 196521),
    ('EVT-0000021', 'D-0042', 'G9CYJ1KLML5C30S5V', 6, '2026-01-18 09:19:05', 4, 1, 51001),
    ('EVT-0000022', 'D-0024', '17AZW13R8RU48B1Y2', 1, '2026-01-18 15:55:00', 1, 1, 102961),
    ('EVT-0000023', 'D-0010', 'AK3KE7TY2FY1X8CES', 2, '2026-01-18 17:13:49', 6, 2, 112834),
    ('EVT-0000024', 'D-0031', 'NVZDYUH04251YM880', 7, '2026-01-18 18:46:23', 7, 2, 18698),
    ('EVT-0000025', 'D-0030', 'EFXKEJUX1V694GHP4', 7, '2026-01-18 21:17:54', 3, 1, 106821),
    ('EVT-0000026', 'D-0034', 'F7Z3YXGLY38V2C6FX', 8, '2026-01-18 23:05:11', 1, 1, 0),
    ('EVT-0000027', 'D-0034', 'B3D290S1F0RBXGYKJ', 8, '2026-01-19 23:48:47', 1, 1, 197539),
    ('EVT-0000028', 'D-0042', 'G9CYJ1KLML5C30S5V', 6, '2026-01-20 04:43:35', 6, 3, 53165),
    ('EVT-0000029', 'D-0017', 'W65CD0VEF916C5NX7', 2, '2026-01-20 10:29:45', 2, 2, 184843),
    ('EVT-0000030', 'D-0002', 'G5LWBCXDVZ04KS3ML', 8, '2026-01-20 21:12:16', 8, 2, 61361),
    ('EVT-0000031', 'D-0034', '7ZY16XNS1R3CX711K', 8, '2026-01-21 04:36:20', 4, 1, 24074),
    ('EVT-0000032', 'D-0015', 'NVZDYUH04251YM880', 7, '2026-01-21 15:18:58', 4, 2, 23033),
    ('EVT-0000033', 'D-0008', 'R6T6TA6VLE5ZW4T6W', 6, '2026-01-21 15:46:14', 1, 1, 100010),
    ('EVT-0000034', 'D-0028', 'T10GR7BXRE6W3HJCC', 7, '2026-01-21 20:30:25', 5, 1, 34769),
    ('EVT-0000035', 'D-0035', 'A84MJ1R9ZE2C4B6EX', 5, '2026-01-21 22:28:16', 6, 1, 110110),
    ('EVT-0000036', 'D-0012', 'CZPSGZ3KSLM3BMY3S', 8, '2026-01-22 00:14:40', 4, 3, 11097),
    ('EVT-0000037', 'D-0011', 'X49H1NTC4AN04EYXH', 5, '2026-01-22 05:58:23', 4, 1, 105016),
    ('EVT-0000038', 'D-0035', 'SCF3XTPXST2JW6XEA', 5, '2026-01-22 06:21:44', 5, 4, 55602),
    ('EVT-0000039', 'D-0013', 'MNJ09ULT7VYH6EKR2', 2, '2026-01-22 10:27:32', 5, 2, 141616),
    ('EVT-0000040', 'D-0006', '31MW2AWVP4X655P97', 6, '2026-01-22 13:28:20', 7, 1, 167413),
    ('EVT-0000041', 'D-0008', 'WZG9PK7RGZ0HUR4BU', 6, '2026-01-23 08:43:20', 8, 1, 89385),
    ('EVT-0000042', 'D-0018', 'A84MJ1R9ZE2C4B6EX', 5, '2026-01-23 19:56:23', 3, 2, 111238),
    ('EVT-0000043', 'D-0026', 'G5LWBCXDVZ04KS3ML', 8, '2026-01-24 05:01:55', 8, 1, 61821),
    ('EVT-0000044', 'D-0034', '7ZY16XNS1R3CX711K', 8, '2026-01-24 14:05:56', 4, 2, 24553),
    ('EVT-0000045', 'D-0004', 'V9U377S6K1N9JEU3Y', 8, '2026-01-24 15:33:42', 5, 4, 151921),
    ('EVT-0000046', 'D-0019', 'G5LWBCXDVZ04KS3ML', 8, '2026-01-24 16:38:16', 4, 2, 60938),
    ('EVT-0000047', 'D-0007', 'BM81HTT5PV8NHJE5M', 6, '2026-01-24 22:25:45', 8, 1, 173441),
    ('EVT-0000048', 'D-0035', 'U764UXSFU5S61YB8X', 5, '2026-01-25 04:34:36', 7, 1, 88481),
    ('EVT-0000049', 'D-0015', 'T10GR7BXRE6W3HJCC', 7, '2026-01-25 07:28:23', 2, 2, 36404),
    ('EVT-0000050', 'D-0022', 'WFSH3R155W4WDGPPT', 3, '2026-01-25 08:35:34', 4, 2, 21689),
    ('EVT-0000051', 'D-0040', 'U764UXSFU5S61YB8X', 5, '2026-01-25 09:02:59', 2, 3, 89646),
    ('EVT-0000052', 'D-0023', 'R6T6TA6VLE5ZW4T6W', 6, '2026-01-25 10:36:49', 5, 3, 97625),
    ('EVT-0000053', 'D-0015', 'W2U985FC4XTBFRBUC', 7, '2026-01-25 11:48:34', 8, 2, 47018),
    ('EVT-0000054', 'D-0040', 'U764UXSFU5S61YB8X', 5, '2026-01-25 15:53:15', 6, 1, 88659),
    ('EVT-0000055', 'D-0012', '7VCRVV6ERTN4HRKUK', 8, '2026-01-25 20:25:08', 5, 3, 77764),
    ('EVT-0000056', 'D-0012', '7VCRVV6ERTN4HRKUK', 8, '2026-01-26 00:00:47', 3, 3, 74429),
    ('EVT-0000057', 'D-0016', 'ES0VL5WAWGJTHGKUV', 5, '2026-01-26 00:17:44', 8, 1, 165972),
    ('EVT-0000058', 'D-0016', 'ES0VL5WAWGJTHGKUV', 5, '2026-01-26 09:47:21', 1, 3, 167165),
    ('EVT-0000059', 'D-0017', 'G9CYJ1KLML5C30S5V', 6, '2026-01-26 12:00:18', 5, 1, 48767),
    ('EVT-0000060', 'D-0044', 'CZPSGZ3KSLM3BMY3S', 8, '2026-01-26 19:25:34', 8, 1, 11569),
    ('EVT-0000061', 'D-0007', 'BM81HTT5PV8NHJE5M', 6, '2026-01-26 21:15:01', 4, 1, 173520),
    ('EVT-0000062', 'D-0030', 'W2U985FC4XTBFRBUC', 7, '2026-01-26 23:40:34', 3, 1, 49747),
    ('EVT-0000063', 'D-0036', 'MTDJ3HE7509G59RCW', 2, '2026-01-27 08:02:59', 3, 1, 113590),
    ('EVT-0000064', 'D-0045', 'W65CD0VEF916C5NX7', 2, '2026-01-28 06:02:13', 2, 1, 188139),
    ('EVT-0000065', 'D-0023', 'R6T6TA6VLE5ZW4T6W', 6, '2026-01-28 06:10:00', 4, 3, 102085),
    ('EVT-0000066', 'D-0025', 'B3D290S1F0RBXGYKJ', 8, '2026-01-28 10:19:32', 4, 3, 199554),
    ('EVT-0000067', 'D-0025', 'V9U377S6K1N9JEU3Y', 8, '2026-01-28 11:19:53', 2, 2, 151677),
    ('EVT-0000068', 'D-0004', 'VSUYXFJKR1KPE33Y6', 1, '2026-01-28 15:50:40', 6, 1, 182106),
    ('EVT-0000069', 'D-0016', 'NESGWHCZ40E9YA38G', 3, '2026-01-28 16:46:53', 4, 2, 112813),
    ('EVT-0000070', 'D-0043', '7ZY16XNS1R3CX711K', 8, '2026-01-28 17:43:25', 8, 2, 25509),
    ('EVT-0000071', 'D-0029', 'DF4UCAYJTL54AHEKC', 5, '2026-01-28 19:40:29', 8, 2, 9806),
    ('EVT-0000072', 'D-0011', 'B3D290S1F0RBXGYKJ', 8, '2026-01-29 06:23:34', 3, 1, 197153),
    ('EVT-0000073', 'D-0042', 'VSUYXFJKR1KPE33Y6', 1, '2026-01-29 06:36:48', 6, 1, 180028),
    ('EVT-0000074', 'D-0001', '6ZWRRBN2YUEUZ92YB', 7, '2026-01-29 10:12:53', 1, 2, 29775),
    ('EVT-0000075', 'D-0035', 'YZ6UWTRHNXHMNP7UV', 1, '2026-01-29 14:53:40', 3, 2, 81630),
    ('EVT-0000076', 'D-0001', '6ZWRRBN2YUEUZ92YB', 7, '2026-01-29 21:49:04', 6, 2, 28877),
    ('EVT-0000077', 'D-0029', 'DF4UCAYJTL54AHEKC', 5, '2026-01-30 03:02:23', 3, 1, 9979),
    ('EVT-0000078', 'D-0039', '4XT0K7EFFF4G0JDYH', 1, '2026-01-30 05:48:01', 8, 1, 188718),
    ('EVT-0000079', 'D-0026', 'V9U377S6K1N9JEU3Y', 8, '2026-01-30 06:24:23', 1, 1, 154261),
    ('EVT-0000080', 'D-0030', 'EFXKEJUX1V694GHP4', 7, '2026-01-30 08:54:12', 1, 2, 102926),
    ('EVT-0000081', 'D-0032', 'AK3KE7TY2FY1X8CES', 2, '2026-01-30 11:07:21', 2, 2, 113536),
    ('EVT-0000082', 'D-0003', '085DPUJV58HBSLWA3', 3, '2026-01-30 19:13:45', 7, 1, 169377),
    ('EVT-0000083', 'D-0030', 'MNJ09ULT7VYH6EKR2', 2, '2026-01-31 02:05:44', 3, 1, 142208),
    ('EVT-0000084', 'D-0027', '4XT0K7EFFF4G0JDYH', 1, '2026-01-31 09:21:06', 5, 3, 187125),
    ('EVT-0000085', 'D-0041', 'LBK5CJES001CK5005', 5, '2026-01-31 12:37:01', 3, 1, 80511),
    ('EVT-0000086', 'D-0037', 'EFXKEJUX1V694GHP4', 7, '2026-01-31 12:42:37', 6, 3, 103711),
    ('EVT-0000087', 'D-0015', 'G9CYJ1KLML5C30S5V', 6, '2026-01-31 15:24:18', 4, 1, 48730),
    ('EVT-0000088', 'D-0029', 'DF4UCAYJTL54AHEKC', 5, '2026-02-01 06:37:19', 1, 1, 12359),
    ('EVT-0000089', 'D-0043', 'BM81HTT5PV8NHJE5M', 6, '2026-02-01 10:27:50', 4, 1, 176624),
    ('EVT-0000090', 'D-0006', 'R6T6TA6VLE5ZW4T6W', 6, '2026-02-01 14:20:19', 2, 2, 99021),
    ('EVT-0000091', 'D-0020', 'LBK5CJES001CK5005', 5, '2026-02-01 17:53:21', 3, 3, 80573),
    ('EVT-0000092', 'D-0025', 'B3D290S1F0RBXGYKJ', 8, '2026-02-01 23:02:43', 8, 2, 201160),
    ('EVT-0000093', 'D-0044', 'VB2UAD8VRZRNTJGCW', 5, '2026-02-02 03:03:40', 6, 1, 24068),
    ('EVT-0000094', 'D-0005', 'XL60F4GS42F2WYRYL', 6, '2026-02-02 03:55:31', 1, 2, 50064),
    ('EVT-0000095', 'D-0007', '17AZW13R8RU48B1Y2', 1, '2026-02-02 04:38:46', 2, 2, 104116),
    ('EVT-0000096', 'D-0025', 'G5LWBCXDVZ04KS3ML', 8, '2026-02-02 09:51:25', 1, 3, 63818),
    ('EVT-0000097', 'D-0032', '56V193LNJTD70GHVF', 4, '2026-02-03 01:28:36', 4, 2, 22762),
    ('EVT-0000098', 'D-0036', 'AK3KE7TY2FY1X8CES', 2, '2026-02-03 06:30:07', 8, 1, 115934),
    ('EVT-0000099', 'D-0013', 'NVZDYUH04251YM880', 7, '2026-02-03 19:18:46', 8, 2, 20531),
    ('EVT-0000100', 'D-0004', 'F7Z3YXGLY38V2C6FX', 8, '2026-02-04 05:27:34', 2, 3, 2964),
    ('EVT-0000101', 'D-0044', 'B3D290S1F0RBXGYKJ', 8, '2026-02-04 15:08:56', 6, 2, 197547),
    ('EVT-0000102', 'D-0018', '6ZWRRBN2YUEUZ92YB', 7, '2026-02-04 18:18:11', 7, 3, 28399),
    ('EVT-0000103', 'D-0001', '6ZWRRBN2YUEUZ92YB', 7, '2026-02-05 09:19:24', 8, 2, 29817),
    ('EVT-0000104', 'D-0014', 'T10GR7BXRE6W3HJCC', 7, '2026-02-05 14:54:47', 3, 2, 34969),
    ('EVT-0000105', 'D-0038', 'DF4UCAYJTL54AHEKC', 5, '2026-02-06 05:04:48', 5, 1, 13178),
    ('EVT-0000106', 'D-0041', 'T10GR7BXRE6W3HJCC', 7, '2026-02-06 10:33:30', 7, 2, 37098),
    ('EVT-0000107', 'D-0026', 'GYJCZYM67MJE6CVNC', 8, '2026-02-07 08:06:21', 2, 2, 212230),
    ('EVT-0000108', 'D-0005', 'WZG9PK7RGZ0HUR4BU', 6, '2026-02-07 16:52:39', 8, 2, 91487),
    ('EVT-0000109', 'D-0036', 'EJXE56ZJMJ49DHKWL', 2, '2026-02-07 19:31:19', 7, 2, 72970),
    ('EVT-0000110', 'D-0030', 'W65CD0VEF916C5NX7', 2, '2026-02-08 04:17:38', 2, 3, 186897),
    ('EVT-0000111', 'D-0007', '17AZW13R8RU48B1Y2', 1, '2026-02-08 05:05:34', 3, 1, 103032),
    ('EVT-0000112', 'D-0034', 'ZW2JFW1YJF490B0WM', 3, '2026-02-08 18:48:37', 2, 2, 36340),
    ('EVT-0000113', 'D-0011', '31MW2AWVP4X655P97', 6, '2026-02-09 00:26:13', 7, 1, 165545),
    ('EVT-0000114', 'D-0033', 'ES0VL5WAWGJTHGKUV', 5, '2026-02-09 02:47:12', 2, 2, 166452),
    ('EVT-0000115', 'D-0007', '31MW2AWVP4X655P97', 6, '2026-02-09 11:29:44', 8, 2, 168253),
    ('EVT-0000116', 'D-0011', '31MW2AWVP4X655P97', 6, '2026-02-09 14:38:50', 6, 4, 168120),
    ('EVT-0000117', 'D-0027', 'BM81HTT5PV8NHJE5M', 6, '2026-02-09 19:02:48', 5, 1, 177635),
    ('EVT-0000118', 'D-0025', 'BDYSJPEPPRYKAUKJT', 4, '2026-02-09 22:34:07', 1, 2, 94661),
    ('EVT-0000119', 'D-0010', 'SWRNKBCS7E63N182S', 7, '2026-02-09 23:44:49', 1, 1, 203901),
    ('EVT-0000120', 'D-0028', 'T10GR7BXRE6W3HJCC', 7, '2026-02-10 04:47:51', 3, 2, 34290),
    ('EVT-0000121', 'D-0037', 'CS55L00V13YDYEYG1', 2, '2026-02-10 08:55:34', 5, 1, 87496),
    ('EVT-0000122', 'D-0039', '31MW2AWVP4X655P97', 6, '2026-02-10 16:19:20', 8, 3, 165540),
    ('EVT-0000123', 'D-0030', 'W65CD0VEF916C5NX7', 2, '2026-02-11 16:23:24', 8, 3, 187051),
    ('EVT-0000124', 'D-0038', 'UCDVJ8GAV775YMDT7', 1, '2026-02-11 20:43:34', 4, 3, 164269),
    ('EVT-0000125', 'D-0015', 'K2EKBFP136YL0WXFD', 5, '2026-02-12 09:18:48', 8, 1, 24047),
    ('EVT-0000126', 'D-0003', 'ZW2JFW1YJF490B0WM', 3, '2026-02-13 00:10:20', 7, 1, 38826),
    ('EVT-0000127', 'D-0031', 'VWLM09RHNJS8B006J', 7, '2026-02-13 20:06:21', 5, 2, 136319),
    ('EVT-0000128', 'D-0002', 'MNJ09ULT7VYH6EKR2', 2, '2026-02-13 21:33:53', 2, 1, 140247),
    ('EVT-0000129', 'D-0019', 'XL60F4GS42F2WYRYL', 6, '2026-02-14 19:17:20', 2, 3, 50701),
    ('EVT-0000130', 'D-0042', 'KSGKTNMKEM865XXK5', 1, '2026-02-15 08:01:52', 4, 2, 154610),
    ('EVT-0000131', 'D-0043', 'G9CYJ1KLML5C30S5V', 6, '2026-02-15 08:06:04', 6, 1, 51595),
    ('EVT-0000132', 'D-0036', '6DSH6J6X5945L75TS', 4, '2026-02-15 20:12:37', 8, 3, 162637),
    ('EVT-0000133', 'D-0030', 'EFXKEJUX1V694GHP4', 7, '2026-02-16 05:30:57', 2, 1, 106280),
    ('EVT-0000134', 'D-0041', 'EFXKEJUX1V694GHP4', 7, '2026-02-16 09:23:09', 6, 1, 105344),
    ('EVT-0000135', 'D-0019', 'XL60F4GS42F2WYRYL', 6, '2026-02-16 14:18:52', 3, 3, 49496),
    ('EVT-0000136', 'D-0021', 'MNJ09ULT7VYH6EKR2', 2, '2026-02-17 02:38:36', 1, 2, 140741),
    ('EVT-0000137', 'D-0022', '7VCRVV6ERTN4HRKUK', 8, '2026-02-17 06:54:58', 6, 1, 75261),
    ('EVT-0000138', 'D-0029', 'U764UXSFU5S61YB8X', 5, '2026-02-17 23:55:33', 3, 1, 89257),
    ('EVT-0000139', 'D-0014', 'EFXKEJUX1V694GHP4', 7, '2026-02-18 12:30:59', 6, 2, 105972),
    ('EVT-0000140', 'D-0016', 'ZW2JFW1YJF490B0WM', 3, '2026-02-18 23:31:15', 3, 1, 36177),
    ('EVT-0000141', 'D-0026', 'F7Z3YXGLY38V2C6FX', 8, '2026-02-19 03:46:10', 6, 1, 0),
    ('EVT-0000142', 'D-0045', '085DPUJV58HBSLWA3', 3, '2026-02-19 06:35:05', 6, 1, 170203),
    ('EVT-0000143', 'D-0043', 'UANFS38S785BFVR2S', 6, '2026-02-19 15:02:49', 8, 2, 140862),
    ('EVT-0000144', 'D-0020', '17AZW13R8RU48B1Y2', 1, '2026-02-19 20:26:26', 1, 1, 103392),
    ('EVT-0000145', 'D-0021', 'J6MDT1XP6XY1U3TF7', 2, '2026-02-19 20:30:43', 6, 1, 170129),
    ('EVT-0000146', 'D-0031', 'W2U985FC4XTBFRBUC', 7, '2026-02-19 20:58:00', 4, 3, 48754),
    ('EVT-0000147', 'D-0037', 'W65CD0VEF916C5NX7', 2, '2026-02-20 08:31:40', 8, 1, 188956),
    ('EVT-0000148', 'D-0016', '6ZWRRBN2YUEUZ92YB', 7, '2026-02-20 11:36:27', 1, 1, 28021),
    ('EVT-0000149', 'D-0037', 'J6MDT1XP6XY1U3TF7', 2, '2026-02-21 14:07:48', 8, 4, 171972),
    ('EVT-0000150', 'D-0019', 'G9CYJ1KLML5C30S5V', 6, '2026-02-21 20:20:32', 7, 2, 52775),
    ('EVT-0000151', 'D-0025', 'VB2UAD8VRZRNTJGCW', 5, '2026-02-21 20:28:27', 2, 3, 25843),
    ('EVT-0000152', 'D-0040', 'U764UXSFU5S61YB8X', 5, '2026-02-22 04:20:10', 7, 1, 88719),
    ('EVT-0000153', 'D-0006', 'UANFS38S785BFVR2S', 6, '2026-02-22 09:49:52', 5, 1, 140828),
    ('EVT-0000154', 'D-0003', '085DPUJV58HBSLWA3', 3, '2026-02-22 12:27:49', 7, 1, 169469),
    ('EVT-0000155', 'D-0015', 'SWRNKBCS7E63N182S', 7, '2026-02-22 18:05:40', 6, 2, 206101),
    ('EVT-0000156', 'D-0024', 'VWLM09RHNJS8B006J', 7, '2026-02-22 19:28:15', 8, 3, 138505),
    ('EVT-0000157', 'D-0045', '085DPUJV58HBSLWA3', 3, '2026-02-23 00:08:49', 6, 3, 168906),
    ('EVT-0000158', 'D-0023', 'UCDVJ8GAV775YMDT7', 1, '2026-02-23 06:20:08', 1, 1, 167054),
    ('EVT-0000159', 'D-0028', 'MVXGFXVW54L5Z5CZ4', 7, '2026-02-23 09:19:45', 5, 1, 167098),
    ('EVT-0000160', 'D-0032', '3K3G83UC0P55S0G0Z', 4, '2026-02-23 20:54:15', 8, 1, 26818),
    ('EVT-0000161', 'D-0010', 'CS55L00V13YDYEYG1', 2, '2026-02-24 09:27:25', 5, 1, 87501),
    ('EVT-0000162', 'D-0026', 'G5LWBCXDVZ04KS3ML', 8, '2026-02-25 07:48:16', 8, 1, 62882),
    ('EVT-0000163', 'D-0042', 'UCDVJ8GAV775YMDT7', 1, '2026-02-25 13:00:48', 1, 4, 166407),
    ('EVT-0000164', 'D-0004', 'WZG9PK7RGZ0HUR4BU', 6, '2026-02-26 14:32:23', 6, 3, 88551),
    ('EVT-0000165', 'D-0024', 'VWLM09RHNJS8B006J', 7, '2026-02-26 19:53:21', 3, 3, 139830),
    ('EVT-0000166', 'D-0010', 'MNJ09ULT7VYH6EKR2', 2, '2026-02-27 13:07:50', 5, 1, 141146),
    ('EVT-0000167', 'D-0010', 'AK3KE7TY2FY1X8CES', 2, '2026-02-28 07:44:51', 8, 1, 113669),
    ('EVT-0000168', 'D-0005', 'BM81HTT5PV8NHJE5M', 6, '2026-03-01 00:14:20', 5, 1, 177236),
    ('EVT-0000169', 'D-0008', 'BM81HTT5PV8NHJE5M', 6, '2026-03-01 04:56:57', 2, 4, 174155),
    ('EVT-0000170', 'D-0015', 'X49H1NTC4AN04EYXH', 5, '2026-03-01 15:13:19', 6, 1, 104789),
    ('EVT-0000171', 'D-0033', 'LBK5CJES001CK5005', 5, '2026-03-02 12:52:51', 7, 2, 81751),
    ('EVT-0000172', 'D-0002', 'UANFS38S785BFVR2S', 6, '2026-03-02 16:55:51', 8, 1, 141040),
    ('EVT-0000173', 'D-0027', 'KSGKTNMKEM865XXK5', 1, '2026-03-03 07:17:08', 2, 3, 155200),
    ('EVT-0000174', 'D-0022', 'GYJCZYM67MJE6CVNC', 8, '2026-03-03 11:27:41', 3, 1, 216416),
    ('EVT-0000175', 'D-0016', 'ZW2JFW1YJF490B0WM', 3, '2026-03-03 13:04:07', 8, 4, 35728),
    ('EVT-0000176', 'D-0003', 'NESGWHCZ40E9YA38G', 3, '2026-03-03 18:59:29', 4, 2, 114153),
    ('EVT-0000177', 'D-0030', 'BM81HTT5PV8NHJE5M', 6, '2026-03-03 23:38:38', 4, 3, 174718),
    ('EVT-0000178', 'D-0037', 'EJXE56ZJMJ49DHKWL', 2, '2026-03-04 06:37:19', 5, 3, 75241),
    ('EVT-0000179', 'D-0028', 'EFXKEJUX1V694GHP4', 7, '2026-03-04 17:47:39', 2, 2, 104030),
    ('EVT-0000180', 'D-0020', 'U764UXSFU5S61YB8X', 5, '2026-03-04 23:17:41', 6, 3, 88283),
    ('EVT-0000181', 'D-0027', 'VSUYXFJKR1KPE33Y6', 1, '2026-03-05 06:28:09', 6, 2, 182927),
    ('EVT-0000182', 'D-0016', 'ZW2JFW1YJF490B0WM', 3, '2026-03-05 10:42:34', 2, 1, 37236),
    ('EVT-0000183', 'D-0010', 'CS55L00V13YDYEYG1', 2, '2026-03-06 06:07:31', 6, 2, 86607),
    ('EVT-0000184', 'D-0019', 'UJWF9LKLYCBFCTP3B', 4, '2026-03-06 12:20:00', 8, 2, 126295),
    ('EVT-0000185', 'D-0003', 'NESGWHCZ40E9YA38G', 3, '2026-03-06 20:36:21', 7, 2, 115647),
    ('EVT-0000186', 'D-0001', 'EFXKEJUX1V694GHP4', 7, '2026-03-07 05:20:29', 6, 1, 106920),
    ('EVT-0000187', 'D-0010', 'MNJ09ULT7VYH6EKR2', 2, '2026-03-07 06:05:51', 8, 2, 141802),
    ('EVT-0000188', 'D-0008', 'XL60F4GS42F2WYRYL', 6, '2026-03-07 12:37:52', 3, 1, 50488),
    ('EVT-0000189', 'D-0023', '6V48KNVPDDXDD79LD', 4, '2026-03-08 00:12:46', 3, 2, 17854),
    ('EVT-0000190', 'D-0040', 'XL60F4GS42F2WYRYL', 6, '2026-03-08 14:52:02', 3, 1, 51352),
    ('EVT-0000191', 'D-0017', 'G9CYJ1KLML5C30S5V', 6, '2026-03-08 16:08:51', 4, 4, 53566),
    ('EVT-0000192', 'D-0024', 'K2EKBFP136YL0WXFD', 5, '2026-03-08 22:09:34', 7, 4, 21182),
    ('EVT-0000193', 'D-0001', 'SWRNKBCS7E63N182S', 7, '2026-03-09 08:38:47', 3, 4, 204750),
    ('EVT-0000194', 'D-0031', 'EFXKEJUX1V694GHP4', 7, '2026-03-09 20:32:21', 5, 1, 107245),
    ('EVT-0000195', 'D-0036', 'MNJ09ULT7VYH6EKR2', 2, '2026-03-09 22:31:22', 8, 1, 140859),
    ('EVT-0000196', 'D-0027', 'J6MDT1XP6XY1U3TF7', 2, '2026-03-10 16:06:49', 8, 2, 172698),
    ('EVT-0000197', 'D-0018', 'UANFS38S785BFVR2S', 6, '2026-03-10 19:06:15', 3, 1, 139542),
    ('EVT-0000198', 'D-0035', 'U764UXSFU5S61YB8X', 5, '2026-03-11 11:39:34', 4, 2, 89200),
    ('EVT-0000199', 'D-0018', 'UANFS38S785BFVR2S', 6, '2026-03-11 13:23:42', 1, 1, 139533),
    ('EVT-0000200', 'D-0043', 'R6T6TA6VLE5ZW4T6W', 6, '2026-03-11 17:22:04', 3, 4, 99993),
    ('EVT-0000201', 'D-0018', 'UANFS38S785BFVR2S', 6, '2026-03-11 22:29:42', 5, 2, 139424),
    ('EVT-0000202', 'D-0039', 'XL60F4GS42F2WYRYL', 6, '2026-03-12 12:08:58', 5, 1, 51803),
    ('EVT-0000203', 'D-0045', 'ZW2JFW1YJF490B0WM', 3, '2026-03-12 22:44:41', 4, 4, 38136),
    ('EVT-0000204', 'D-0026', 'GYJCZYM67MJE6CVNC', 8, '2026-03-13 09:24:57', 7, 2, 215145),
    ('EVT-0000205', 'D-0001', 'VWLM09RHNJS8B006J', 7, '2026-03-13 15:51:03', 1, 3, 139655),
    ('EVT-0000206', 'D-0033', 'K2EKBFP136YL0WXFD', 5, '2026-03-14 12:45:47', 8, 1, 22523),
    ('EVT-0000207', 'D-0012', 'GYJCZYM67MJE6CVNC', 8, '2026-03-14 12:54:06', 5, 1, 213913),
    ('EVT-0000208', 'D-0016', '085DPUJV58HBSLWA3', 3, '2026-03-15 04:54:38', 1, 3, 171244),
    ('EVT-0000209', 'D-0008', 'WZG9PK7RGZ0HUR4BU', 6, '2026-03-15 23:54:47', 1, 1, 90654),
    ('EVT-0000210', 'D-0032', '56V193LNJTD70GHVF', 4, '2026-03-16 07:37:31', 7, 1, 26985),
    ('EVT-0000211', 'D-0030', 'T10GR7BXRE6W3HJCC', 7, '2026-03-16 22:27:26', 2, 1, 35858),
    ('EVT-0000212', 'D-0013', 'J6MDT1XP6XY1U3TF7', 2, '2026-03-17 04:08:44', 1, 2, 171504),
    ('EVT-0000213', 'D-0014', 'EFXKEJUX1V694GHP4', 7, '2026-03-17 04:47:51', 3, 3, 104571),
    ('EVT-0000214', 'D-0044', 'G5LWBCXDVZ04KS3ML', 8, '2026-03-18 18:08:06', 8, 4, 66064),
    ('EVT-0000215', 'D-0033', 'X49H1NTC4AN04EYXH', 5, '2026-03-19 05:01:40', 2, 4, 105450),
    ('EVT-0000216', 'D-0043', 'UCDVJ8GAV775YMDT7', 1, '2026-03-19 12:40:36', 7, 3, 165747),
    ('EVT-0000217', 'D-0032', 'FBTPK4HVSWHDS36EH', 4, '2026-03-19 20:06:36', 4, 1, 152068),
    ('EVT-0000218', 'D-0026', 'GYJCZYM67MJE6CVNC', 8, '2026-03-20 02:03:48', 3, 1, 214286),
    ('EVT-0000219', 'D-0015', 'MVXGFXVW54L5Z5CZ4', 7, '2026-03-20 10:01:50', 1, 1, 170213),
    ('EVT-0000220', 'D-0002', 'W65CD0VEF916C5NX7', 2, '2026-03-21 02:47:04', 2, 2, 190033),
    ('EVT-0000221', 'D-0013', 'MTDJ3HE7509G59RCW', 2, '2026-03-21 09:14:44', 7, 1, 114951),
    ('EVT-0000222', 'D-0035', 'FBTPK4HVSWHDS36EH', 4, '2026-03-21 10:47:25', 3, 3, 151069),
    ('EVT-0000223', 'D-0007', 'UANFS38S785BFVR2S', 6, '2026-03-22 06:12:19', 5, 1, 139263),
    ('EVT-0000224', 'D-0038', 'BM81HTT5PV8NHJE5M', 6, '2026-03-23 02:12:05', 7, 1, 177589),
    ('EVT-0000225', 'D-0042', '17AZW13R8RU48B1Y2', 1, '2026-03-23 07:15:56', 4, 1, 106531),
    ('EVT-0000226', 'D-0024', 'KSGKTNMKEM865XXK5', 1, '2026-03-23 16:10:23', 3, 1, 156284),
    ('EVT-0000227', 'D-0026', 'V9U377S6K1N9JEU3Y', 8, '2026-03-24 09:00:04', 5, 1, 154180),
    ('EVT-0000228', 'D-0033', 'U764UXSFU5S61YB8X', 5, '2026-03-24 14:54:57', 6, 1, 89273),
    ('EVT-0000229', 'D-0013', 'AK3KE7TY2FY1X8CES', 2, '2026-03-24 20:57:20', 4, 1, 115150),
    ('EVT-0000230', 'D-0005', 'BM81HTT5PV8NHJE5M', 6, '2026-03-25 10:34:29', 4, 2, 175699),
    ('EVT-0000231', 'D-0034', 'F7Z3YXGLY38V2C6FX', 8, '2026-03-26 01:20:29', 5, 2, 3079),
    ('EVT-0000232', 'D-0019', 'CZPSGZ3KSLM3BMY3S', 8, '2026-03-26 06:11:00', 1, 1, 10745),
    ('EVT-0000233', 'D-0026', 'B3D290S1F0RBXGYKJ', 8, '2026-03-26 07:25:50', 7, 1, 200320),
    ('EVT-0000234', 'D-0043', 'R6T6TA6VLE5ZW4T6W', 6, '2026-03-26 11:51:51', 6, 1, 100354),
    ('EVT-0000235', 'D-0021', 'CS55L00V13YDYEYG1', 2, '2026-03-26 15:49:35', 2, 2, 88049),
    ('EVT-0000236', 'D-0022', 'G5LWBCXDVZ04KS3ML', 8, '2026-03-27 03:07:35', 3, 2, 65529),
    ('EVT-0000237', 'D-0003', 'ES0VL5WAWGJTHGKUV', 5, '2026-03-27 08:29:28', 3, 3, 167452),
    ('EVT-0000238', 'D-0020', 'A84MJ1R9ZE2C4B6EX', 5, '2026-03-27 18:25:28', 8, 4, 112036),
    ('EVT-0000239', 'D-0032', '4AZS3MF0E99B17C10', 4, '2026-03-27 22:31:35', 7, 2, 93558),
    ('EVT-0000240', 'D-0007', 'R6T6TA6VLE5ZW4T6W', 6, '2026-03-28 01:49:08', 2, 2, 100531),
    ('EVT-0000241', 'D-0043', 'WZG9PK7RGZ0HUR4BU', 6, '2026-03-28 19:30:53', 4, 1, 91912),
    ('EVT-0000242', 'D-0013', 'EJXE56ZJMJ49DHKWL', 2, '2026-03-28 23:42:18', 7, 1, 77295),
    ('EVT-0000243', 'D-0029', 'K2EKBFP136YL0WXFD', 5, '2026-03-29 08:07:40', 3, 2, 22342),
    ('EVT-0000244', 'D-0005', 'UANFS38S785BFVR2S', 6, '2026-03-29 22:55:36', 3, 1, 141532),
    ('EVT-0000245', 'D-0015', 'CBSNBKSJ7HP6T0LHL', 7, '2026-03-30 13:02:34', 3, 1, 180661),
    ('EVT-0000246', 'D-0035', 'EFXKEJUX1V694GHP4', 7, '2026-03-30 23:05:40', 8, 1, 106028),
    ('EVT-0000247', 'D-0023', 'UJWF9LKLYCBFCTP3B', 4, '2026-03-31 02:55:32', 4, 1, 129673),
    ('EVT-0000248', 'D-0040', '3K3G83UC0P55S0G0Z', 4, '2026-04-01 04:51:48', 2, 1, 26272),
    ('EVT-0000249', 'D-0042', 'KSGKTNMKEM865XXK5', 1, '2026-04-01 13:50:43', 1, 1, 158229),
    ('EVT-0000250', 'D-0005', 'UANFS38S785BFVR2S', 6, '2026-04-01 18:36:23', 3, 3, 140693),
    ('EVT-0000251', 'D-0024', 'UCDVJ8GAV775YMDT7', 1, '2026-04-02 04:57:06', 1, 2, 168379),
    ('EVT-0000252', 'D-0005', '31MW2AWVP4X655P97', 6, '2026-04-02 21:23:06', 1, 1, 168369),
    ('EVT-0000253', 'D-0042', '17AZW13R8RU48B1Y2', 1, '2026-04-02 22:08:12', 2, 3, 106403),
    ('EVT-0000254', 'D-0002', 'W65CD0VEF916C5NX7', 2, '2026-04-02 22:48:22', 2, 2, 190534),
    ('EVT-0000255', 'D-0041', 'EFXKEJUX1V694GHP4', 7, '2026-04-03 04:37:40', 8, 4, 105555),
    ('EVT-0000256', 'D-0016', 'ZW2JFW1YJF490B0WM', 3, '2026-04-03 05:34:20', 5, 1, 38657),
    ('EVT-0000257', 'D-0020', 'K2EKBFP136YL0WXFD', 5, '2026-04-03 07:27:39', 3, 1, 22973),
    ('EVT-0000258', 'D-0011', 'B3D290S1F0RBXGYKJ', 8, '2026-04-05 14:48:12', 7, 1, 201069),
    ('EVT-0000259', 'D-0016', 'NESGWHCZ40E9YA38G', 3, '2026-04-05 21:44:14', 2, 1, 117228),
    ('EVT-0000260', 'D-0034', '7VCRVV6ERTN4HRKUK', 8, '2026-04-06 04:39:19', 3, 2, 76339),
    ('EVT-0000261', 'D-0030', 'T10GR7BXRE6W3HJCC', 7, '2026-04-06 14:01:44', 3, 1, 36276),
    ('EVT-0000262', 'D-0005', 'XL60F4GS42F2WYRYL', 6, '2026-04-06 17:13:22', 3, 1, 53205),
    ('EVT-0000263', 'D-0045', 'WFSH3R155W4WDGPPT', 3, '2026-04-07 05:54:20', 4, 3, 22125),
    ('EVT-0000264', 'D-0043', 'XL60F4GS42F2WYRYL', 6, '2026-04-07 15:52:12', 8, 2, 52340),
    ('EVT-0000265', 'D-0014', 'EFXKEJUX1V694GHP4', 7, '2026-04-07 22:07:59', 4, 1, 105204),
    ('EVT-0000266', 'D-0041', 'EFXKEJUX1V694GHP4', 7, '2026-04-08 02:55:04', 1, 1, 105636),
    ('EVT-0000267', 'D-0022', 'CZPSGZ3KSLM3BMY3S', 8, '2026-04-08 05:40:12', 8, 1, 11119),
    ('EVT-0000268', 'D-0040', 'FBTPK4HVSWHDS36EH', 4, '2026-04-09 02:58:28', 2, 3, 151794),
    ('EVT-0000269', 'D-0045', 'NESGWHCZ40E9YA38G', 3, '2026-04-09 04:56:34', 4, 2, 115651),
    ('EVT-0000270', 'D-0021', 'MTDJ3HE7509G59RCW', 2, '2026-04-09 05:22:29', 1, 1, 114211),
    ('EVT-0000271', 'D-0015', 'W2U985FC4XTBFRBUC', 7, '2026-04-09 13:43:36', 5, 2, 48539),
    ('EVT-0000272', 'D-0004', 'V9U377S6K1N9JEU3Y', 8, '2026-04-09 15:05:11', 4, 1, 156502),
    ('EVT-0000273', 'D-0002', 'MTDJ3HE7509G59RCW', 2, '2026-04-09 18:16:57', 8, 2, 113247),
    ('EVT-0000274', 'D-0033', 'K2EKBFP136YL0WXFD', 5, '2026-04-10 02:23:39', 8, 3, 23966),
    ('EVT-0000275', 'D-0029', 'X49H1NTC4AN04EYXH', 5, '2026-04-10 06:25:09', 8, 2, 106623),
    ('EVT-0000276', 'D-0033', 'ES0VL5WAWGJTHGKUV', 5, '2026-04-10 09:06:51', 3, 2, 168717),
    ('EVT-0000277', 'D-0045', 'ZW2JFW1YJF490B0WM', 3, '2026-04-10 19:26:32', 4, 2, 38932),
    ('EVT-0000278', 'D-0012', 'V9U377S6K1N9JEU3Y', 8, '2026-04-10 21:44:03', 1, 2, 154761),
    ('EVT-0000279', 'D-0043', 'WZG9PK7RGZ0HUR4BU', 6, '2026-04-10 23:43:37', 1, 3, 92052),
    ('EVT-0000280', 'D-0010', 'AK3KE7TY2FY1X8CES', 2, '2026-04-11 07:23:09', 8, 1, 115063),
    ('EVT-0000281', 'D-0010', 'EJXE56ZJMJ49DHKWL', 2, '2026-04-12 01:58:58', 2, 2, 76716),
    ('EVT-0000282', 'D-0026', 'CZPSGZ3KSLM3BMY3S', 8, '2026-04-12 23:01:27', 3, 3, 12583),
    ('EVT-0000283', 'D-0013', 'CS55L00V13YDYEYG1', 2, '2026-04-13 06:22:34', 7, 1, 89581),
    ('EVT-0000284', 'D-0002', 'MNJ09ULT7VYH6EKR2', 2, '2026-04-13 06:42:28', 5, 1, 143690),
    ('EVT-0000285', 'D-0039', 'R6T6TA6VLE5ZW4T6W', 6, '2026-04-13 12:02:44', 7, 2, 102637),
    ('EVT-0000286', 'D-0034', 'GYJCZYM67MJE6CVNC', 8, '2026-04-13 15:10:49', 6, 1, 215738),
    ('EVT-0000287', 'D-0030', 'NVZDYUH04251YM880', 7, '2026-04-14 01:12:13', 3, 1, 21820),
    ('EVT-0000288', 'D-0002', 'EJXE56ZJMJ49DHKWL', 2, '2026-04-14 04:49:34', 6, 4, 78149),
    ('EVT-0000289', 'D-0037', 'W65CD0VEF916C5NX7', 2, '2026-04-14 05:23:54', 5, 1, 188368),
    ('EVT-0000290', 'D-0037', 'CS55L00V13YDYEYG1', 2, '2026-04-14 10:02:17', 8, 2, 90863),
    ('EVT-0000291', 'D-0024', 'KSGKTNMKEM865XXK5', 1, '2026-04-14 16:34:01', 3, 2, 156163),
    ('EVT-0000292', 'D-0034', '7VCRVV6ERTN4HRKUK', 8, '2026-04-15 00:31:42', 6, 2, 76873),
    ('EVT-0000293', 'D-0001', '6ZWRRBN2YUEUZ92YB', 7, '2026-04-15 15:37:27', 3, 1, 30630),
    ('EVT-0000294', 'D-0010', 'J6MDT1XP6XY1U3TF7', 2, '2026-04-15 21:35:53', 8, 1, 172227),
    ('EVT-0000295', 'D-0012', '7ZY16XNS1R3CX711K', 8, '2026-04-16 03:20:35', 7, 2, 28773),
    ('EVT-0000296', 'D-0016', 'NESGWHCZ40E9YA38G', 3, '2026-04-16 08:38:00', 7, 2, 116017),
    ('EVT-0000297', 'D-0037', 'CS55L00V13YDYEYG1', 2, '2026-04-16 10:57:10', 4, 1, 90273),
    ('EVT-0000298', 'D-0018', 'NESGWHCZ40E9YA38G', 3, '2026-04-17 01:30:30', 4, 1, 115628),
    ('EVT-0000299', 'D-0013', 'J6MDT1XP6XY1U3TF7', 2, '2026-04-17 11:43:44', 4, 1, 172880),
    ('EVT-0000300', 'D-0030', 'CBSNBKSJ7HP6T0LHL', 7, '2026-04-19 04:41:25', 4, 2, 180258),
    ('EVT-0000301', 'D-0017', '31MW2AWVP4X655P97', 6, '2026-04-19 08:06:48', 4, 1, 168259),
    ('EVT-0000302', 'D-0008', 'XL60F4GS42F2WYRYL', 6, '2026-04-19 16:10:57', 4, 1, 54216),
    ('EVT-0000303', 'D-0001', 'SWRNKBCS7E63N182S', 7, '2026-04-21 01:57:22', 3, 2, 206031),
    ('EVT-0000304', 'D-0004', 'CZPSGZ3KSLM3BMY3S', 8, '2026-04-21 02:21:28', 5, 3, 11632),
    ('EVT-0000305', 'D-0035', 'U764UXSFU5S61YB8X', 5, '2026-04-21 10:18:45', 2, 3, 91497),
    ('EVT-0000306', 'D-0010', 'EJXE56ZJMJ49DHKWL', 2, '2026-04-21 10:58:33', 7, 2, 76807),
    ('EVT-0000307', 'D-0034', 'F7Z3YXGLY38V2C6FX', 8, '2026-04-22 04:58:28', 1, 1, 1927),
    ('EVT-0000308', 'D-0027', '17AZW13R8RU48B1Y2', 1, '2026-04-22 12:08:46', 4, 2, 105353),
    ('EVT-0000309', 'D-0025', 'GYJCZYM67MJE6CVNC', 8, '2026-04-22 15:39:16', 8, 1, 215201),
    ('EVT-0000310', 'D-0020', 'J4MU6SE5GDAFSL387', 5, '2026-04-22 16:49:12', 6, 3, 104656),
    ('EVT-0000311', 'D-0014', '6ZWRRBN2YUEUZ92YB', 7, '2026-04-23 10:04:45', 4, 1, 32090),
    ('EVT-0000312', 'D-0003', '085DPUJV58HBSLWA3', 3, '2026-04-23 15:08:54', 2, 1, 172796),
    ('EVT-0000313', 'D-0003', 'ZW2JFW1YJF490B0WM', 3, '2026-04-24 03:21:05', 7, 1, 37927),
    ('EVT-0000314', 'D-0031', 'SWRNKBCS7E63N182S', 7, '2026-04-24 04:48:59', 1, 2, 205891),
    ('EVT-0000315', 'D-0003', 'WFSH3R155W4WDGPPT', 3, '2026-04-24 06:15:38', 3, 3, 23433),
    ('EVT-0000316', 'D-0045', '085DPUJV58HBSLWA3', 3, '2026-04-24 07:33:00', 5, 2, 171699),
    ('EVT-0000317', 'D-0015', 'NVZDYUH04251YM880', 7, '2026-04-24 08:26:44', 7, 1, 23771),
    ('EVT-0000318', 'D-0013', 'W65CD0VEF916C5NX7', 2, '2026-04-24 18:34:11', 1, 2, 190963),
    ('EVT-0000319', 'D-0025', '7VCRVV6ERTN4HRKUK', 8, '2026-04-25 18:07:54', 1, 1, 79447),
    ('EVT-0000320', 'D-0008', '31MW2AWVP4X655P97', 6, '2026-04-26 03:51:59', 5, 1, 168881),
    ('EVT-0000321', 'D-0014', 'CBSNBKSJ7HP6T0LHL', 7, '2026-04-27 07:23:58', 1, 3, 181043),
    ('EVT-0000322', 'D-0022', 'F7Z3YXGLY38V2C6FX', 8, '2026-04-27 07:38:33', 3, 1, 2864),
    ('EVT-0000323', 'D-0033', 'DF4UCAYJTL54AHEKC', 5, '2026-04-28 01:21:54', 6, 1, 13084),
    ('EVT-0000324', 'D-0027', '17AZW13R8RU48B1Y2', 1, '2026-04-28 07:25:08', 6, 3, 105010),
    ('EVT-0000325', 'D-0039', 'G9CYJ1KLML5C30S5V', 6, '2026-04-28 13:26:45', 6, 1, 54073),
    ('EVT-0000326', 'D-0028', 'VWLM09RHNJS8B006J', 7, '2026-04-28 23:42:50', 8, 2, 139705),
    ('EVT-0000327', 'D-0026', 'B3D290S1F0RBXGYKJ', 8, '2026-04-29 11:14:09', 3, 1, 200493),
    ('EVT-0000328', 'D-0027', 'UCDVJ8GAV775YMDT7', 1, '2026-04-29 13:29:46', 7, 2, 168045),
    ('EVT-0000329', 'D-0005', 'XL60F4GS42F2WYRYL', 6, '2026-04-29 14:45:54', 3, 3, 54384),
    ('EVT-0000330', 'D-0025', 'GYJCZYM67MJE6CVNC', 8, '2026-04-30 18:41:24', 7, 1, 215583),
    ('EVT-0000331', 'D-0039', 'WZG9PK7RGZ0HUR4BU', 6, '2026-04-30 19:00:47', 5, 2, 92549),
    ('EVT-0000332', 'D-0033', 'X49H1NTC4AN04EYXH', 5, '2026-04-30 19:26:10', 8, 2, 107808),
    ('EVT-0000333', 'D-0037', 'EJXE56ZJMJ49DHKWL', 2, '2026-05-01 00:01:18', 3, 1, 76585),
    ('EVT-0000334', 'D-0005', '31MW2AWVP4X655P97', 6, '2026-05-01 12:30:09', 4, 1, 168677),
    ('EVT-0000335', 'D-0024', '4XT0K7EFFF4G0JDYH', 1, '2026-05-01 16:48:18', 7, 2, 192729),
    ('EVT-0000336', 'D-0017', 'R6T6TA6VLE5ZW4T6W', 6, '2026-05-01 20:27:41', 3, 1, 102629),
    ('EVT-0000337', 'D-0041', 'VWLM09RHNJS8B006J', 7, '2026-05-01 21:08:37', 1, 3, 140767),
    ('EVT-0000338', 'D-0033', 'K2EKBFP136YL0WXFD', 5, '2026-05-02 09:23:05', 8, 2, 24125),
    ('EVT-0000339', 'D-0029', 'U764UXSFU5S61YB8X', 5, '2026-05-02 11:13:41', 7, 1, 92979),
    ('EVT-0000340', 'D-0021', 'CS55L00V13YDYEYG1', 2, '2026-05-03 15:25:34', 7, 1, 89718),
    ('EVT-0000341', 'D-0039', 'R6T6TA6VLE5ZW4T6W', 6, '2026-05-04 13:22:42', 5, 1, 103061),
    ('EVT-0000342', 'D-0020', 'U764UXSFU5S61YB8X', 5, '2026-05-04 16:10:45', 6, 1, 92462),
    ('EVT-0000343', 'D-0030', 'CBSNBKSJ7HP6T0LHL', 7, '2026-05-04 20:47:43', 8, 3, 181404),
    ('EVT-0000344', 'D-0031', '6ZWRRBN2YUEUZ92YB', 7, '2026-05-05 06:04:25', 1, 2, 31372),
    ('EVT-0000345', 'D-0007', 'WZG9PK7RGZ0HUR4BU', 6, '2026-05-05 07:33:31', 7, 3, 92999),
    ('EVT-0000346', 'D-0016', '085DPUJV58HBSLWA3', 3, '2026-05-05 14:40:24', 8, 2, 173505),
    ('EVT-0000347', 'D-0034', 'F7Z3YXGLY38V2C6FX', 8, '2026-05-05 19:21:34', 3, 2, 2196),
    ('EVT-0000348', 'D-0041', 'T10GR7BXRE6W3HJCC', 7, '2026-05-06 14:17:44', 1, 2, 38427),
    ('EVT-0000349', 'D-0042', '4XT0K7EFFF4G0JDYH', 1, '2026-05-06 14:18:54', 5, 1, 192253),
    ('EVT-0000350', 'D-0012', 'GYJCZYM67MJE6CVNC', 8, '2026-05-07 08:45:09', 1, 1, 217315),
    ('EVT-0000351', 'D-0045', 'ZW2JFW1YJF490B0WM', 3, '2026-05-07 14:42:34', 5, 1, 39990),
    ('EVT-0000352', 'D-0027', 'YZ6UWTRHNXHMNP7UV', 1, '2026-05-07 16:01:19', 3, 1, 82902),
    ('EVT-0000353', 'D-0015', 'T10GR7BXRE6W3HJCC', 7, '2026-05-07 20:12:59', 2, 2, 38172),
    ('EVT-0000354', 'D-0036', 'MTDJ3HE7509G59RCW', 2, '2026-05-07 22:00:57', 2, 3, 115368),
    ('EVT-0000355', 'D-0019', 'CZPSGZ3KSLM3BMY3S', 8, '2026-05-08 10:23:42', 6, 3, 13379),
    ('EVT-0000356', 'D-0019', 'GYJCZYM67MJE6CVNC', 8, '2026-05-08 13:38:54', 6, 3, 216444),
    ('EVT-0000357', 'D-0041', 'W2U985FC4XTBFRBUC', 7, '2026-05-08 19:30:02', 8, 1, 50295),
    ('EVT-0000358', 'D-0012', 'GYJCZYM67MJE6CVNC', 8, '2026-05-08 22:37:39', 4, 1, 216552),
    ('EVT-0000359', 'D-0035', 'K2EKBFP136YL0WXFD', 5, '2026-05-09 17:42:10', 6, 2, 25271),
    ('EVT-0000360', 'D-0030', 'MVXGFXVW54L5Z5CZ4', 7, '2026-05-10 01:57:07', 5, 1, 169327),
    ('EVT-0000361', 'D-0037', 'W65CD0VEF916C5NX7', 2, '2026-05-10 07:48:25', 4, 1, 190016),
    ('EVT-0000362', 'D-0015', 'NVZDYUH04251YM880', 7, '2026-05-10 08:13:09', 1, 1, 24598),
    ('EVT-0000363', 'D-0039', 'G9CYJ1KLML5C30S5V', 6, '2026-05-10 13:39:37', 1, 3, 53865),
    ('EVT-0000364', 'D-0028', 'MVXGFXVW54L5Z5CZ4', 7, '2026-05-11 14:25:38', 8, 3, 170089),
    ('EVT-0000365', 'D-0012', 'G5LWBCXDVZ04KS3ML', 8, '2026-05-11 16:56:06', 3, 1, 67059),
    ('EVT-0000366', 'D-0011', 'G5LWBCXDVZ04KS3ML', 8, '2026-05-11 18:50:21', 3, 2, 65756),
    ('EVT-0000367', 'D-0008', 'XL60F4GS42F2WYRYL', 6, '2026-05-11 20:19:43', 2, 2, 54613),
    ('EVT-0000368', 'D-0008', 'R6T6TA6VLE5ZW4T6W', 6, '2026-05-11 23:23:51', 3, 2, 102980),
    ('EVT-0000369', 'D-0040', '6DSH6J6X5945L75TS', 4, '2026-05-12 00:16:44', 7, 2, 167632),
    ('EVT-0000370', 'D-0035', '853UP9HZ4HV8WCR2D', 5, '2026-05-13 02:52:26', 1, 3, 204117),
    ('EVT-0000371', 'D-0025', 'B3D290S1F0RBXGYKJ', 8, '2026-05-13 03:41:18', 8, 2, 202564),
    ('EVT-0000372', 'D-0019', 'CZPSGZ3KSLM3BMY3S', 8, '2026-05-13 23:02:35', 6, 1, 13006),
    ('EVT-0000373', 'D-0031', 'T10GR7BXRE6W3HJCC', 7, '2026-05-14 05:00:36', 2, 3, 38470),
    ('EVT-0000374', 'D-0011', 'GYJCZYM67MJE6CVNC', 8, '2026-05-14 07:13:20', 6, 2, 216479),
    ('EVT-0000375', 'D-0002', 'CS55L00V13YDYEYG1', 2, '2026-05-15 00:47:43', 6, 1, 90371),
    ('EVT-0000376', 'D-0003', 'NESGWHCZ40E9YA38G', 3, '2026-05-15 04:09:47', 7, 3, 116711),
    ('EVT-0000377', 'D-0016', 'WFSH3R155W4WDGPPT', 3, '2026-05-15 08:12:45', 5, 2, 22736),
    ('EVT-0000378', 'D-0031', 'MVXGFXVW54L5Z5CZ4', 7, '2026-05-15 18:44:35', 1, 1, 171200),
    ('EVT-0000379', 'D-0012', '7VCRVV6ERTN4HRKUK', 8, '2026-05-15 19:57:57', 5, 4, 79076),
    ('EVT-0000380', 'D-0041', 'MVXGFXVW54L5Z5CZ4', 7, '2026-05-16 08:34:05', 2, 1, 170576),
    ('EVT-0000381', 'D-0025', '7ZY16XNS1R3CX711K', 8, '2026-05-17 05:25:13', 1, 1, 29995),
    ('EVT-0000382', 'D-0025', 'G5LWBCXDVZ04KS3ML', 8, '2026-05-17 12:10:53', 5, 1, 66909),
    ('EVT-0000383', 'D-0023', 'UJWF9LKLYCBFCTP3B', 4, '2026-05-18 00:03:41', 4, 3, 130646),
    ('EVT-0000384', 'D-0044', 'G5LWBCXDVZ04KS3ML', 8, '2026-05-18 22:27:04', 5, 1, 66524),
    ('EVT-0000385', 'D-0024', 'YZ6UWTRHNXHMNP7UV', 1, '2026-05-19 01:13:14', 1, 2, 82302),
    ('EVT-0000386', 'D-0003', 'ZW2JFW1YJF490B0WM', 3, '2026-05-19 08:46:53', 6, 1, 39601),
    ('EVT-0000387', 'D-0033', 'ES0VL5WAWGJTHGKUV', 5, '2026-05-19 12:23:29', 5, 4, 169185),
    ('EVT-0000388', 'D-0043', '31MW2AWVP4X655P97', 6, '2026-05-19 15:14:45', 2, 1, 169758),
    ('EVT-0000389', 'D-0019', 'GYJCZYM67MJE6CVNC', 8, '2026-05-19 18:02:56', 3, 2, 217740),
    ('EVT-0000390', 'D-0040', '6V48KNVPDDXDD79LD', 4, '2026-05-20 11:43:31', 7, 4, 20540),
    ('EVT-0000391', 'D-0014', 'MVXGFXVW54L5Z5CZ4', 7, '2026-05-20 15:35:09', 6, 3, 169768),
    ('EVT-0000392', 'D-0032', 'UJWF9LKLYCBFCTP3B', 4, '2026-05-21 01:55:36', 7, 3, 129630),
    ('EVT-0000393', 'D-0043', 'UANFS38S785BFVR2S', 6, '2026-05-21 05:49:24', 3, 1, 142916),
    ('EVT-0000394', 'D-0007', 'G9CYJ1KLML5C30S5V', 6, '2026-05-22 01:22:06', 6, 1, 54311),
    ('EVT-0000395', 'D-0042', '17AZW13R8RU48B1Y2', 1, '2026-05-22 04:53:04', 8, 1, 107600),
    ('EVT-0000396', 'D-0029', 'J4MU6SE5GDAFSL387', 5, '2026-05-22 07:04:39', 1, 1, 105502),
    ('EVT-0000397', 'D-0033', 'LBK5CJES001CK5005', 5, '2026-05-22 11:46:35', 6, 2, 86038),
    ('EVT-0000398', 'D-0034', '7ZY16XNS1R3CX711K', 8, '2026-05-22 17:26:23', 2, 4, 29134),
    ('EVT-0000399', 'D-0003', 'ZW2JFW1YJF490B0WM', 3, '2026-05-23 11:26:29', 6, 3, 39605),
    ('EVT-0000400', 'D-0027', 'KSGKTNMKEM865XXK5', 1, '2026-05-24 06:12:48', 5, 2, 158327),
    ('EVT-0000401', 'D-0043', 'BM81HTT5PV8NHJE5M', 6, '2026-05-24 19:36:01', 6, 1, 178177),
    ('EVT-0000402', 'D-0036', 'EJXE56ZJMJ49DHKWL', 2, '2026-05-25 03:14:40', 3, 2, 77798),
    ('EVT-0000403', 'D-0023', 'FBTPK4HVSWHDS36EH', 4, '2026-05-25 07:09:55', 6, 1, 154503),
    ('EVT-0000404', 'D-0003', 'WFSH3R155W4WDGPPT', 3, '2026-05-25 15:20:34', 4, 4, 22989),
    ('EVT-0000405', 'D-0032', 'BDYSJPEPPRYKAUKJT', 4, '2026-05-26 08:01:42', 4, 1, 97098),
    ('EVT-0000406', 'D-0022', '7ZY16XNS1R3CX711K', 8, '2026-05-27 02:52:13', 2, 1, 30198),
    ('EVT-0000407', 'D-0027', '4XT0K7EFFF4G0JDYH', 1, '2026-05-27 09:23:29', 4, 1, 192025),
    ('EVT-0000408', 'D-0035', 'DF4UCAYJTL54AHEKC', 5, '2026-05-27 11:35:59', 7, 1, 14538),
    ('EVT-0000409', 'D-0004', 'F7Z3YXGLY38V2C6FX', 8, '2026-05-28 20:09:25', 7, 1, 4350),
    ('EVT-0000410', 'D-0015', 'NVZDYUH04251YM880', 7, '2026-05-29 06:33:51', 4, 2, 24346),
    ('EVT-0000411', 'D-0044', 'GYJCZYM67MJE6CVNC', 8, '2026-05-29 22:23:40', 7, 2, 218044),
    ('EVT-0000412', 'D-0002', 'J6MDT1XP6XY1U3TF7', 2, '2026-05-29 23:03:39', 7, 3, 173930),
    ('EVT-0000413', 'D-0044', 'CZPSGZ3KSLM3BMY3S', 8, '2026-05-30 07:58:59', 2, 3, 14324),
    ('EVT-0000414', 'D-0034', 'CZPSGZ3KSLM3BMY3S', 8, '2026-05-30 11:41:29', 3, 2, 14098),
    ('EVT-0000415', 'D-0016', '085DPUJV58HBSLWA3', 3, '2026-05-31 00:07:03', 8, 3, 174050),
    ('EVT-0000416', 'D-0029', 'A84MJ1R9ZE2C4B6EX', 5, '2026-05-31 08:59:00', 7, 1, 112535),
    ('EVT-0000417', 'D-0006', 'WZG9PK7RGZ0HUR4BU', 6, '2026-05-31 17:17:14', 8, 1, 92816),
    ('EVT-0000418', 'D-0014', 'NVZDYUH04251YM880', 7, '2026-06-01 03:21:39', 5, 2, 24713),
    ('EVT-0000419', 'D-0043', '31MW2AWVP4X655P97', 6, '2026-06-02 02:03:37', 3, 3, 169011),
    ('EVT-0000420', 'D-0026', '7VCRVV6ERTN4HRKUK', 8, '2026-06-02 06:04:38', 5, 4, 79304),
    ('EVT-0000421', 'D-0012', 'CZPSGZ3KSLM3BMY3S', 8, '2026-06-03 08:07:24', 7, 3, 14437),
    ('EVT-0000422', 'D-0029', 'J4MU6SE5GDAFSL387', 5, '2026-06-03 11:21:12', 3, 1, 105493),
    ('EVT-0000423', 'D-0005', 'BM81HTT5PV8NHJE5M', 6, '2026-06-03 17:05:45', 3, 3, 178695),
    ('EVT-0000424', 'D-0013', 'EJXE56ZJMJ49DHKWL', 2, '2026-06-04 11:48:51', 1, 4, 78721),
    ('EVT-0000425', 'D-0003', 'WFSH3R155W4WDGPPT', 3, '2026-06-05 02:30:32', 2, 4, 23918),
    ('EVT-0000426', 'D-0003', 'WFSH3R155W4WDGPPT', 3, '2026-06-05 10:58:15', 4, 3, 23372),
    ('EVT-0000427', 'D-0005', 'G9CYJ1KLML5C30S5V', 6, '2026-06-05 15:39:50', 7, 2, 54359),
    ('EVT-0000428', 'D-0043', 'XL60F4GS42F2WYRYL', 6, '2026-06-05 23:04:18', 6, 3, 55011),
    ('EVT-0000429', 'D-0015', 'MVXGFXVW54L5Z5CZ4', 7, '2026-06-06 02:36:47', 5, 2, 171390),
    ('EVT-0000430', 'D-0005', 'WZG9PK7RGZ0HUR4BU', 6, '2026-06-06 07:38:33', 2, 1, 92868),
    ('EVT-0000431', 'D-0010', 'W65CD0VEF916C5NX7', 2, '2026-06-07 10:33:43', 5, 1, 191324),
    ('EVT-0000432', 'D-0010', 'AK3KE7TY2FY1X8CES', 2, '2026-06-07 19:56:50', 5, 1, 117473),
    ('EVT-0000433', 'D-0023', '6V48KNVPDDXDD79LD', 4, '2026-06-08 00:20:54', 5, 1, 21679),
    ('EVT-0000434', 'D-0032', 'BDYSJPEPPRYKAUKJT', 4, '2026-06-08 01:02:19', 3, 1, 97896),
    ('EVT-0000435', 'D-0016', 'WFSH3R155W4WDGPPT', 3, '2026-06-08 07:29:39', 3, 1, 23759),
    ('EVT-0000436', 'D-0020', 'ES0VL5WAWGJTHGKUV', 5, '2026-06-08 08:23:58', 8, 4, 170609),
    ('EVT-0000437', 'D-0045', 'WFSH3R155W4WDGPPT', 3, '2026-06-08 16:38:31', 4, 4, 23811),
    ('EVT-0000438', 'D-0020', 'VB2UAD8VRZRNTJGCW', 5, '2026-06-08 20:44:04', 1, 2, 27494),
    ('EVT-0000439', 'D-0016', 'ZW2JFW1YJF490B0WM', 3, '2026-06-08 21:19:27', 7, 2, 40237),
    ('EVT-0000440', 'D-0035', 'DF4UCAYJTL54AHEKC', 5, '2026-06-09 03:52:09', 4, 2, 14921),
    ('EVT-0000441', 'D-0023', '3K3G83UC0P55S0G0Z', 4, '2026-06-09 05:34:07', 6, 3, 28313),
    ('EVT-0000442', 'D-0019', 'GYJCZYM67MJE6CVNC', 8, '2026-06-09 07:45:18', 7, 3, 217339),
    ('EVT-0000443', 'D-0045', 'WFSH3R155W4WDGPPT', 3, '2026-06-09 13:05:31', 6, 3, 24060),
    ('EVT-0000444', 'D-0024', 'KSGKTNMKEM865XXK5', 1, '2026-06-09 14:15:29', 2, 1, 159337),
    ('EVT-0000445', 'D-0006', 'R6T6TA6VLE5ZW4T6W', 6, '2026-06-09 14:41:51', 6, 4, 103663),
    ('EVT-0000446', 'D-0035', 'U764UXSFU5S61YB8X', 5, '2026-06-10 02:15:10', 2, 2, 92720),
    ('EVT-0000447', 'D-0041', 'CBSNBKSJ7HP6T0LHL', 7, '2026-06-10 04:04:29', 5, 2, 181509),
    ('EVT-0000448', 'D-0022', 'V9U377S6K1N9JEU3Y', 8, '2026-06-10 04:54:27', 3, 1, 157904),
    ('EVT-0000449', 'D-0036', 'W65CD0VEF916C5NX7', 2, '2026-06-10 07:31:56', 7, 4, 191557),
    ('EVT-0000450', 'D-0037', 'W65CD0VEF916C5NX7', 2, '2026-06-10 07:39:51', 3, 1, 191431),
    ('EVT-0000451', 'D-0040', '6V48KNVPDDXDD79LD', 4, '2026-06-10 10:06:02', 2, 4, 21661),
    ('EVT-0000452', 'D-0027', '17AZW13R8RU48B1Y2', 1, '2026-06-10 11:01:20', 1, 2, 107427),
    ('EVT-0000453', 'D-0029', 'LBK5CJES001CK5005', 5, '2026-06-10 11:03:22', 7, 2, 85975),
    ('EVT-0000454', 'D-0007', 'WZG9PK7RGZ0HUR4BU', 6, '2026-06-10 15:32:31', 3, 1, 93331),
    ('EVT-0000455', 'D-0008', 'G9CYJ1KLML5C30S5V', 6, '2026-06-11 17:33:39', 5, 2, 55092),
    ('EVT-0000456', 'D-0030', 'EFXKEJUX1V694GHP4', 7, '2026-06-11 19:29:22', 5, 2, 109028),
    ('EVT-0000457', 'D-0002', 'W65CD0VEF916C5NX7', 2, '2026-06-12 01:32:50', 5, 1, 191272),
    ('EVT-0000458', 'D-0036', 'CS55L00V13YDYEYG1', 2, '2026-06-12 01:50:40', 3, 2, 90929),
    ('EVT-0000459', 'D-0044', 'CZPSGZ3KSLM3BMY3S', 8, '2026-06-12 05:25:12', 1, 1, 13868),
    ('EVT-0000460', 'D-0036', 'J6MDT1XP6XY1U3TF7', 2, '2026-06-12 10:24:43', 3, 2, 174256),
    ('EVT-0000461', 'D-0020', 'SCF3XTPXST2JW6XEA', 5, '2026-06-13 00:31:27', 7, 2, 60023),
    ('EVT-0000462', 'D-0023', 'BDYSJPEPPRYKAUKJT', 4, '2026-06-13 04:10:03', 3, 2, 97680),
    ('EVT-0000463', 'D-0044', 'G5LWBCXDVZ04KS3ML', 8, '2026-06-13 05:52:31', 7, 2, 67261),
    ('EVT-0000464', 'D-0025', 'G5LWBCXDVZ04KS3ML', 8, '2026-06-13 17:34:46', 8, 1, 67022),
    ('EVT-0000465', 'D-0001', 'T10GR7BXRE6W3HJCC', 7, '2026-06-14 03:35:02', 3, 1, 40092),
    ('EVT-0000466', 'D-0042', '17AZW13R8RU48B1Y2', 1, '2026-06-14 07:50:54', 6, 1, 107584),
    ('EVT-0000467', 'D-0043', 'G9CYJ1KLML5C30S5V', 6, '2026-06-14 13:07:59', 5, 2, 55264),
    ('EVT-0000468', 'D-0013', 'AK3KE7TY2FY1X8CES', 2, '2026-06-15 17:37:52', 7, 1, 118129),
    ('EVT-0000469', 'D-0028', 'NVZDYUH04251YM880', 7, '2026-06-15 18:50:48', 5, 2, 24969),
    ('EVT-0000470', 'D-0031', 'W2U985FC4XTBFRBUC', 7, '2026-06-15 23:46:40', 3, 1, 52076),
    ('EVT-0000471', 'D-0034', 'G5LWBCXDVZ04KS3ML', 8, '2026-06-16 03:05:42', 6, 2, 67005),
    ('EVT-0000472', 'D-0003', 'WFSH3R155W4WDGPPT', 3, '2026-06-16 06:06:11', 2, 1, 23762),
    ('EVT-0000473', 'D-0034', 'CZPSGZ3KSLM3BMY3S', 8, '2026-06-16 08:21:32', 7, 1, 13951),
    ('EVT-0000474', 'D-0018', '085DPUJV58HBSLWA3', 3, '2026-06-16 16:39:24', 4, 3, 174190),
    ('EVT-0000475', 'D-0022', 'F7Z3YXGLY38V2C6FX', 8, '2026-06-17 02:14:55', 1, 1, 4707),
    ('EVT-0000476', 'D-0041', '6ZWRRBN2YUEUZ92YB', 7, '2026-06-17 03:31:38', 5, 1, 32707),
    ('EVT-0000477', 'D-0017', 'BM81HTT5PV8NHJE5M', 6, '2026-06-18 08:13:56', 7, 2, 179026),
    ('EVT-0000478', 'D-0013', 'AK3KE7TY2FY1X8CES', 2, '2026-06-18 17:17:08', 7, 3, 118428),
    ('EVT-0000479', 'D-0030', 'VWLM09RHNJS8B006J', 7, '2026-06-19 03:56:28', 7, 3, 142520),
    ('EVT-0000480', 'D-0036', 'MTDJ3HE7509G59RCW', 2, '2026-06-19 17:30:18', 3, 1, 116106),
    ('EVT-0000481', 'D-0034', 'G5LWBCXDVZ04KS3ML', 8, '2026-06-19 17:35:56', 6, 3, 67463),
    ('EVT-0000482', 'D-0024', 'UCDVJ8GAV775YMDT7', 1, '2026-06-20 01:04:24', 5, 1, 169321),
    ('EVT-0000483', 'D-0029', 'J4MU6SE5GDAFSL387', 5, '2026-06-20 09:22:52', 8, 2, 106379),
    ('EVT-0000484', 'D-0014', 'W2U985FC4XTBFRBUC', 7, '2026-06-20 19:36:48', 6, 1, 52168),
    ('EVT-0000485', 'D-0004', 'B3D290S1F0RBXGYKJ', 8, '2026-06-21 11:14:52', 1, 1, 203549),
    ('EVT-0000486', 'D-0011', 'GYJCZYM67MJE6CVNC', 8, '2026-06-21 15:23:15', 5, 1, 218006),
    ('EVT-0000487', 'D-0013', 'MNJ09ULT7VYH6EKR2', 2, '2026-06-21 15:38:06', 7, 2, 145197),
    ('EVT-0000488', 'D-0020', 'VB2UAD8VRZRNTJGCW', 5, '2026-06-21 16:38:33', 1, 3, 28151),
    ('EVT-0000489', 'D-0034', 'V9U377S6K1N9JEU3Y', 8, '2026-06-22 22:37:33', 4, 2, 158045),
    ('EVT-0000490', 'D-0021', 'MNJ09ULT7VYH6EKR2', 2, '2026-06-23 05:05:39', 1, 2, 145277),
    ('EVT-0000491', 'D-0045', 'NESGWHCZ40E9YA38G', 3, '2026-06-23 13:42:20', 3, 4, 118281),
    ('EVT-0000492', 'D-0042', 'YZ6UWTRHNXHMNP7UV', 1, '2026-06-23 15:51:28', 5, 1, 83547),
    ('EVT-0000493', 'D-0010', 'W65CD0VEF916C5NX7', 2, '2026-06-23 17:35:20', 8, 1, 191571),
    ('EVT-0000494', 'D-0019', 'V9U377S6K1N9JEU3Y', 8, '2026-06-23 21:24:10', 4, 3, 158377),
    ('EVT-0000495', 'D-0025', 'F7Z3YXGLY38V2C6FX', 8, '2026-06-23 23:25:48', 7, 1, 4727),
    ('EVT-0000496', 'D-0031', 'NVZDYUH04251YM880', 7, '2026-06-24 18:32:04', 3, 4, 25299),
    ('EVT-0000497', 'D-0029', 'LBK5CJES001CK5005', 5, '2026-06-24 22:35:17', 4, 1, 86738),
    ('EVT-0000498', 'D-0010', 'W65CD0VEF916C5NX7', 2, '2026-06-24 23:56:18', 4, 2, 191504),
    ('EVT-0000499', 'D-0015', 'W2U985FC4XTBFRBUC', 7, '2026-06-25 07:10:51', 7, 4, 51918),
    ('EVT-0000500', 'D-0036', 'J6MDT1XP6XY1U3TF7', 2, '2026-06-25 09:16:10', 3, 2, 174804),
    ('EVT-0000501', 'D-0004', 'B3D290S1F0RBXGYKJ', 8, '2026-06-25 12:01:12', 6, 2, 203370),
    ('EVT-0000502', 'D-0033', 'J4MU6SE5GDAFSL387', 5, '2026-06-27 04:27:35', 4, 2, 106572),
    ('EVT-0000503', 'D-0039', 'G9CYJ1KLML5C30S5V', 6, '2026-06-27 11:43:43', 6, 3, 55256),
    ('EVT-0000504', 'D-0036', 'MNJ09ULT7VYH6EKR2', 2, '2026-06-27 13:09:26', 1, 2, 144899),
    ('EVT-0000505', 'D-0033', 'DF4UCAYJTL54AHEKC', 5, '2026-06-28 01:16:46', 2, 2, 15472),
    ('EVT-0000506', 'D-0037', 'AK3KE7TY2FY1X8CES', 2, '2026-06-28 02:06:05', 1, 1, 118321),
    ('EVT-0000507', 'D-0016', 'ZW2JFW1YJF490B0WM', 3, '2026-06-28 02:26:45', 3, 1, 40546),
    ('EVT-0000508', 'D-0008', 'UANFS38S785BFVR2S', 6, '2026-06-28 09:38:32', 6, 1, 143687),
    ('EVT-0000509', 'D-0037', 'J6MDT1XP6XY1U3TF7', 2, '2026-06-29 02:59:50', 3, 3, 175166),
    ('EVT-0000510', 'D-0023', '6DSH6J6X5945L75TS', 4, '2026-06-29 05:15:01', 4, 3, 168985),
    ('EVT-0000511', 'D-0028', 'W2U985FC4XTBFRBUC', 7, '2026-06-29 06:29:08', 1, 1, 52031),
    ('EVT-0000512', 'D-0028', 'MVXGFXVW54L5Z5CZ4', 7, '2026-06-29 07:57:28', 7, 1, 171606),
    ('EVT-0000513', 'D-0041', 'VWLM09RHNJS8B006J', 7, '2026-06-29 12:52:31', 5, 1, 142623),
    ('EVT-0000514', 'D-0035', 'VB2UAD8VRZRNTJGCW', 5, '2026-06-30 03:44:34', 7, 2, 28253),
    ('EVT-0000515', 'D-0025', 'F7Z3YXGLY38V2C6FX', 8, '2026-07-01 03:25:37', 5, 1, 4978),
    ('EVT-0000516', 'D-0034', 'G5LWBCXDVZ04KS3ML', 8, '2026-07-01 04:01:20', 7, 3, 67901),
    ('EVT-0000517', 'D-0023', '56V193LNJTD70GHVF', 4, '2026-07-01 15:51:23', 2, 1, 28848),
    ('EVT-0000518', 'D-0017', 'G9CYJ1KLML5C30S5V', 6, '2026-07-01 21:59:23', 7, 2, 55359),
    ('EVT-0000519', 'D-0042', 'UCDVJ8GAV775YMDT7', 1, '2026-07-02 02:48:10', 3, 1, 169763),
    ('EVT-0000520', 'D-0034', 'F7Z3YXGLY38V2C6FX', 8, '2026-07-02 07:57:18', 4, 1, 4964),
    ('EVT-0000521', 'D-0031', '6ZWRRBN2YUEUZ92YB', 7, '2026-07-02 09:09:18', 7, 1, 33191),
    ('EVT-0000522', 'D-0040', '6V48KNVPDDXDD79LD', 4, '2026-07-02 16:37:14', 5, 3, 22499),
    ('EVT-0000523', 'D-0044', 'CZPSGZ3KSLM3BMY3S', 8, '2026-07-02 17:30:25', 3, 3, 14853),
    ('EVT-0000524', 'D-0044', 'V9U377S6K1N9JEU3Y', 8, '2026-07-02 18:07:50', 1, 2, 158490),
    ('EVT-0000525', 'D-0021', 'J6MDT1XP6XY1U3TF7', 2, '2026-07-02 21:21:17', 3, 2, 175285),
    ('EVT-0000526', 'D-0031', 'VWLM09RHNJS8B006J', 7, '2026-07-03 01:50:56', 8, 3, 142576),
    ('EVT-0000527', 'D-0034', '7ZY16XNS1R3CX711K', 8, '2026-07-03 03:46:19', 7, 2, 30920),
    ('EVT-0000528', 'D-0041', 'W2U985FC4XTBFRBUC', 7, '2026-07-03 05:14:47', 3, 1, 52128),
    ('EVT-0000529', 'D-0041', 'CBSNBKSJ7HP6T0LHL', 7, '2026-07-03 09:29:03', 4, 2, 182488),
    ('EVT-0000530', 'D-0003', 'ZW2JFW1YJF490B0WM', 3, '2026-07-03 10:43:42', 5, 3, 40696),
    ('EVT-0000531', 'D-0014', '6ZWRRBN2YUEUZ92YB', 7, '2026-07-03 12:51:12', 5, 2, 33052),
    ('EVT-0000532', 'D-0012', '7ZY16XNS1R3CX711K', 8, '2026-07-03 13:13:46', 2, 1, 31105),
    ('EVT-0000533', 'D-0042', '4XT0K7EFFF4G0JDYH', 1, '2026-07-03 15:24:00', 1, 1, 193826),
    ('EVT-0000534', 'D-0028', 'SWRNKBCS7E63N182S', 7, '2026-07-04 08:07:36', 4, 1, 208602),
    ('EVT-0000535', 'D-0035', 'DF4UCAYJTL54AHEKC', 5, '2026-07-04 10:02:54', 8, 1, 15713),
    ('EVT-0000536', 'D-0013', 'MNJ09ULT7VYH6EKR2', 2, '2026-07-04 12:22:40', 3, 2, 145586),
    ('EVT-0000537', 'D-0011', 'F7Z3YXGLY38V2C6FX', 8, '2026-07-04 15:01:06', 5, 1, 5060),
    ('EVT-0000538', 'D-0015', 'EFXKEJUX1V694GHP4', 7, '2026-07-04 15:59:48', 1, 2, 109252),
    ('EVT-0000539', 'D-0043', 'WZG9PK7RGZ0HUR4BU', 6, '2026-07-04 23:51:49', 4, 3, 93965),
    ('EVT-0000540', 'D-0006', 'UANFS38S785BFVR2S', 6, '2026-07-05 00:33:14', 8, 1, 143972),
    ('EVT-0000541', 'D-0019', '7VCRVV6ERTN4HRKUK', 8, '2026-07-05 10:54:26', 6, 4, 80507),
    ('EVT-0000542', 'D-0019', 'F7Z3YXGLY38V2C6FX', 8, '2026-07-05 13:01:01', 6, 4, 4946),
    ('EVT-0000543', 'D-0042', 'KSGKTNMKEM865XXK5', 1, '2026-07-05 20:46:16', 6, 2, 159896),
    ('EVT-0000544', 'D-0038', '31MW2AWVP4X655P97', 6, '2026-07-06 03:02:16', 7, 1, 170672),
    ('EVT-0000545', 'D-0029', 'U764UXSFU5S61YB8X', 5, '2026-07-06 06:28:09', 2, 1, 94049),
    ('EVT-0000546', 'D-0019', '7VCRVV6ERTN4HRKUK', 8, '2026-07-06 10:56:07', 4, 1, 80474),
    ('EVT-0000547', 'D-0045', 'WFSH3R155W4WDGPPT', 3, '2026-07-06 16:34:05', 6, 1, 24310),
    ('EVT-0000548', 'D-0002', 'EJXE56ZJMJ49DHKWL', 2, '2026-07-06 19:23:21', 8, 1, 79211),
    ('EVT-0000549', 'D-0015', 'W2U985FC4XTBFRBUC', 7, '2026-07-07 03:51:32', 7, 3, 52514),
    ('EVT-0000550', 'D-0033', 'SCF3XTPXST2JW6XEA', 5, '2026-07-07 07:35:32', 3, 2, 60733),
    ('EVT-0000551', 'D-0042', 'VSUYXFJKR1KPE33Y6', 1, '2026-07-07 08:53:33', 6, 2, 187112),
    ('EVT-0000552', 'D-0018', 'WFSH3R155W4WDGPPT', 3, '2026-07-07 09:02:54', 5, 1, 24459),
    ('EVT-0000553', 'D-0016', 'NESGWHCZ40E9YA38G', 3, '2026-07-07 10:41:23', 1, 1, 118889),
    ('EVT-0000554', 'D-0045', 'NESGWHCZ40E9YA38G', 3, '2026-07-07 15:54:53', 4, 1, 119036),
    ('EVT-0000555', 'D-0010', 'J6MDT1XP6XY1U3TF7', 2, '2026-07-07 17:46:21', 4, 1, 175138),
    ('EVT-0000556', 'D-0037', 'CS55L00V13YDYEYG1', 2, '2026-07-07 17:47:04', 8, 1, 92362),
    ('EVT-0000557', 'D-0024', 'KSGKTNMKEM865XXK5', 1, '2026-07-07 18:18:17', 2, 1, 159937),
    ('EVT-0000558', 'D-0029', 'LBK5CJES001CK5005', 5, '2026-07-07 21:33:43', 4, 1, 87297),
    ('EVT-0000559', 'D-0017', 'XL60F4GS42F2WYRYL', 6, '2026-07-08 02:08:53', 2, 1, 55761),
    ('EVT-0000560', 'D-0039', '31MW2AWVP4X655P97', 6, '2026-07-08 06:05:21', 2, 3, 170779),
    ('EVT-0000561', 'D-0032', '3K3G83UC0P55S0G0Z', 4, '2026-07-08 12:17:10', 8, 2, 28914),
    ('EVT-0000562', 'D-0010', 'EJXE56ZJMJ49DHKWL', 2, '2026-07-08 18:13:34', 5, 2, 79329),
    ('EVT-0000563', 'D-0036', 'AK3KE7TY2FY1X8CES', 2, '2026-07-09 00:44:04', 3, 1, 118565),
    ('EVT-0000564', 'D-0014', 'EFXKEJUX1V694GHP4', 7, '2026-07-09 03:30:42', 2, 2, 109360),
    ('EVT-0000565', 'D-0013', 'W65CD0VEF916C5NX7', 2, '2026-07-09 04:25:24', 3, 1, 192184),
    ('EVT-0000566', 'D-0042', 'VSUYXFJKR1KPE33Y6', 1, '2026-07-09 05:08:04', 6, 3, 187147),
    ('EVT-0000567', 'D-0033', 'VB2UAD8VRZRNTJGCW', 5, '2026-07-09 08:44:06', 5, 1, 28610),
    ('EVT-0000568', 'D-0004', 'G5LWBCXDVZ04KS3ML', 8, '2026-07-09 09:34:48', 5, 2, 68120),
    ('EVT-0000569', 'D-0013', 'J6MDT1XP6XY1U3TF7', 2, '2026-07-09 13:29:01', 3, 2, 175200),
    ('EVT-0000570', 'D-0010', 'EJXE56ZJMJ49DHKWL', 2, '2026-07-09 17:26:01', 5, 2, 79242),
    ('EVT-0000571', 'D-0019', '7VCRVV6ERTN4HRKUK', 8, '2026-07-09 19:38:54', 2, 1, 80577),
    ('EVT-0000572', 'D-0021', 'MNJ09ULT7VYH6EKR2', 2, '2026-07-09 21:19:06', 1, 3, 145496),
    ('EVT-0000573', 'D-0039', 'G9CYJ1KLML5C30S5V', 6, '2026-07-09 23:40:48', 8, 1, 55709),
    ('EVT-0000574', 'D-0018', '085DPUJV58HBSLWA3', 3, '2026-07-09 23:48:21', 1, 1, 174741),
    ('EVT-0000575', 'D-0025', 'V9U377S6K1N9JEU3Y', 8, '2026-07-10 03:42:15', 1, 1, 158818),
    ('EVT-0000576', 'D-0004', 'GYJCZYM67MJE6CVNC', 8, '2026-07-10 06:27:49', 1, 4, 218673),
    ('EVT-0000577', 'D-0043', 'R6T6TA6VLE5ZW4T6W', 6, '2026-07-10 06:28:27', 8, 1, 104954),
    ('EVT-0000578', 'D-0034', '7VCRVV6ERTN4HRKUK', 8, '2026-07-10 06:40:25', 6, 2, 80637),
    ('EVT-0000579', 'D-0005', 'BM81HTT5PV8NHJE5M', 6, '2026-07-10 07:28:16', 1, 1, 180053),
    ('EVT-0000580', 'D-0032', 'BDYSJPEPPRYKAUKJT', 4, '2026-07-10 14:22:19', 8, 2, 98775),
    ('EVT-0000581', 'D-0024', 'VSUYXFJKR1KPE33Y6', 1, '2026-07-10 23:49:53', 4, 1, 187300),
    ('EVT-0000582', 'D-0013', 'AK3KE7TY2FY1X8CES', 2, '2026-07-11 02:04:09', 1, 3, 118827),
    ('EVT-0000583', 'D-0024', '17AZW13R8RU48B1Y2', 1, '2026-07-11 12:12:52', 6, 2, 108287),
    ('EVT-0000584', 'D-0030', 'NVZDYUH04251YM880', 7, '2026-07-11 21:15:31', 5, 2, 25558),
    ('EVT-0000585', 'D-0023', '4AZS3MF0E99B17C10', 4, '2026-07-12 04:10:47', 4, 4, 95405),
    ('EVT-0000586', 'D-0042', 'UCDVJ8GAV775YMDT7', 1, '2026-07-12 05:17:45', 6, 2, 170038),
    ('EVT-0000587', 'D-0041', 'NVZDYUH04251YM880', 7, '2026-07-12 06:23:40', 5, 3, 25587),
    ('EVT-0000588', 'D-0040', '4AZS3MF0E99B17C10', 4, '2026-07-12 23:00:59', 4, 3, 95271),
    ('EVT-0000589', 'D-0015', 'VWLM09RHNJS8B006J', 7, '2026-07-13 02:04:10', 3, 1, 142843),
    ('EVT-0000590', 'D-0005', 'XL60F4GS42F2WYRYL', 6, '2026-07-13 02:30:53', 8, 3, 55810),
    ('EVT-0000591', 'D-0045', 'WFSH3R155W4WDGPPT', 3, '2026-07-13 04:15:58', 2, 1, 24598),
    ('EVT-0000592', 'D-0023', '6V48KNVPDDXDD79LD', 4, '2026-07-13 07:05:21', 2, 1, 22901),
    ('EVT-0000593', 'D-0013', 'J6MDT1XP6XY1U3TF7', 2, '2026-07-13 08:11:07', 6, 3, 175530),
    ('EVT-0000594', 'D-0013', 'EJXE56ZJMJ49DHKWL', 2, '2026-07-13 09:32:39', 3, 2, 79458),
    ('EVT-0000595', 'D-0041', '6ZWRRBN2YUEUZ92YB', 7, '2026-07-13 14:35:44', 2, 1, 33366),
    ('EVT-0000596', 'D-0020', '853UP9HZ4HV8WCR2D', 5, '2026-07-13 17:48:34', 2, 3, 205396),
    ('EVT-0000597', 'D-0016', 'ZW2JFW1YJF490B0WM', 3, '2026-07-13 18:47:44', 4, 1, 41078);


-- ==========================================================
-- 09 - EVENT REVIEW & COACHING PROGRESSION
-- ==========================================================
-- EventReview rows for every High/Critical SafetyEvent, progressed via sequential UPDATEs respecting the close-guard. Plus a handful of manually-enrolled CoachingRecord rows outside the automatic cascade.
-- ==========================================================

-- EventReview -- 140 review chains started (69 fully Closed, rest Assigned/In Review) out of 147 High/Critical events

INSERT INTO EventReview (ReviewID, EventID, ReviewerStaffID, Comments, Recommendations, Status, DateReviewed) VALUES
    (1, 'EVT-0000002', 5, NULL, NULL, 'Unread', NULL),
    (2, 'EVT-0000005', 2, NULL, NULL, 'Unread', NULL),
    (3, 'EVT-0000007', 2, NULL, NULL, 'Unread', NULL),
    (4, 'EVT-0000012', 5, NULL, NULL, 'Unread', NULL),
    (5, 'EVT-0000013', 2, NULL, NULL, 'Unread', NULL),
    (6, 'EVT-0000015', 2, NULL, NULL, 'Unread', NULL),
    (7, 'EVT-0000016', 1, NULL, NULL, 'Unread', NULL),
    (8, 'EVT-0000028', 3, NULL, NULL, 'Unread', NULL),
    (9, 'EVT-0000036', 6, NULL, NULL, 'Unread', NULL),
    (10, 'EVT-0000038', 6, NULL, NULL, 'Unread', NULL),
    (11, 'EVT-0000045', 3, NULL, NULL, 'Unread', NULL),
    (12, 'EVT-0000051', 1, NULL, NULL, 'Unread', NULL),
    (13, 'EVT-0000052', 2, NULL, NULL, 'Unread', NULL),
    (14, 'EVT-0000055', 6, NULL, NULL, 'Unread', NULL),
    (15, 'EVT-0000056', 6, NULL, NULL, 'Unread', NULL),
    (16, 'EVT-0000058', 5, NULL, NULL, 'Unread', NULL),
    (17, 'EVT-0000065', 2, NULL, NULL, 'Unread', NULL),
    (18, 'EVT-0000066', 1, NULL, NULL, 'Unread', NULL),
    (19, 'EVT-0000084', 1, NULL, NULL, 'Unread', NULL),
    (20, 'EVT-0000086', 1, NULL, NULL, 'Unread', NULL),
    (21, 'EVT-0000091', 1, NULL, NULL, 'Unread', NULL),
    (22, 'EVT-0000096', 5, NULL, NULL, 'Unread', NULL),
    (23, 'EVT-0000100', 1, NULL, NULL, 'Unread', NULL),
    (24, 'EVT-0000102', 5, NULL, NULL, 'Unread', NULL),
    (25, 'EVT-0000110', 4, NULL, NULL, 'Unread', NULL),
    (26, 'EVT-0000116', 5, NULL, NULL, 'Unread', NULL),
    (27, 'EVT-0000122', 3, NULL, NULL, 'Unread', NULL),
    (28, 'EVT-0000123', 5, NULL, NULL, 'Unread', NULL),
    (29, 'EVT-0000124', 3, NULL, NULL, 'Unread', NULL),
    (30, 'EVT-0000129', 2, NULL, NULL, 'Unread', NULL),
    (31, 'EVT-0000132', 2, NULL, NULL, 'Unread', NULL),
    (32, 'EVT-0000135', 1, NULL, NULL, 'Unread', NULL),
    (33, 'EVT-0000146', 6, NULL, NULL, 'Unread', NULL),
    (34, 'EVT-0000149', 4, NULL, NULL, 'Unread', NULL),
    (35, 'EVT-0000151', 6, NULL, NULL, 'Unread', NULL),
    (36, 'EVT-0000156', 1, NULL, NULL, 'Unread', NULL),
    (37, 'EVT-0000157', 2, NULL, NULL, 'Unread', NULL),
    (38, 'EVT-0000163', 4, NULL, NULL, 'Unread', NULL),
    (39, 'EVT-0000164', 2, NULL, NULL, 'Unread', NULL),
    (40, 'EVT-0000165', 4, NULL, NULL, 'Unread', NULL),
    (41, 'EVT-0000169', 4, NULL, NULL, 'Unread', NULL),
    (42, 'EVT-0000173', 5, NULL, NULL, 'Unread', NULL),
    (43, 'EVT-0000175', 3, NULL, NULL, 'Unread', NULL),
    (44, 'EVT-0000177', 3, NULL, NULL, 'Unread', NULL),
    (45, 'EVT-0000178', 2, NULL, NULL, 'Unread', NULL),
    (46, 'EVT-0000180', 3, NULL, NULL, 'Unread', NULL),
    (47, 'EVT-0000191', 5, NULL, NULL, 'Unread', NULL),
    (48, 'EVT-0000192', 2, NULL, NULL, 'Unread', NULL),
    (49, 'EVT-0000193', 2, NULL, NULL, 'Unread', NULL),
    (50, 'EVT-0000200', 6, NULL, NULL, 'Unread', NULL),
    (51, 'EVT-0000203', 6, NULL, NULL, 'Unread', NULL),
    (52, 'EVT-0000205', 5, NULL, NULL, 'Unread', NULL),
    (53, 'EVT-0000208', 3, NULL, NULL, 'Unread', NULL),
    (54, 'EVT-0000213', 2, NULL, NULL, 'Unread', NULL),
    (55, 'EVT-0000214', 4, NULL, NULL, 'Unread', NULL),
    (56, 'EVT-0000215', 1, NULL, NULL, 'Unread', NULL),
    (57, 'EVT-0000216', 1, NULL, NULL, 'Unread', NULL),
    (58, 'EVT-0000222', 3, NULL, NULL, 'Unread', NULL),
    (59, 'EVT-0000237', 3, NULL, NULL, 'Unread', NULL),
    (60, 'EVT-0000238', 4, NULL, NULL, 'Unread', NULL),
    (61, 'EVT-0000250', 4, NULL, NULL, 'Unread', NULL),
    (62, 'EVT-0000253', 5, NULL, NULL, 'Unread', NULL),
    (63, 'EVT-0000255', 5, NULL, NULL, 'Unread', NULL),
    (64, 'EVT-0000263', 2, NULL, NULL, 'Unread', NULL),
    (65, 'EVT-0000268', 4, NULL, NULL, 'Unread', NULL),
    (66, 'EVT-0000274', 5, NULL, NULL, 'Unread', NULL),
    (67, 'EVT-0000279', 3, NULL, NULL, 'Unread', NULL),
    (68, 'EVT-0000282', 1, NULL, NULL, 'Unread', NULL),
    (69, 'EVT-0000288', 5, NULL, NULL, 'Unread', NULL),
    (70, 'EVT-0000304', 4, NULL, NULL, 'Unread', NULL),
    (71, 'EVT-0000305', 1, NULL, NULL, 'Unread', NULL),
    (72, 'EVT-0000310', 1, NULL, NULL, 'Unread', NULL),
    (73, 'EVT-0000315', 4, NULL, NULL, 'Unread', NULL),
    (74, 'EVT-0000321', 6, NULL, NULL, 'Unread', NULL),
    (75, 'EVT-0000324', 3, NULL, NULL, 'Unread', NULL),
    (76, 'EVT-0000329', 4, NULL, NULL, 'Unread', NULL),
    (77, 'EVT-0000337', 3, NULL, NULL, 'Unread', NULL),
    (78, 'EVT-0000343', 6, NULL, NULL, 'Unread', NULL),
    (79, 'EVT-0000345', 5, NULL, NULL, 'Unread', NULL),
    (80, 'EVT-0000354', 3, NULL, NULL, 'Unread', NULL),
    (81, 'EVT-0000355', 3, NULL, NULL, 'Unread', NULL),
    (82, 'EVT-0000356', 3, NULL, NULL, 'Unread', NULL),
    (83, 'EVT-0000363', 2, NULL, NULL, 'Unread', NULL),
    (84, 'EVT-0000364', 5, NULL, NULL, 'Unread', NULL),
    (85, 'EVT-0000370', 2, NULL, NULL, 'Unread', NULL),
    (86, 'EVT-0000373', 3, NULL, NULL, 'Unread', NULL),
    (87, 'EVT-0000376', 5, NULL, NULL, 'Unread', NULL),
    (88, 'EVT-0000379', 5, NULL, NULL, 'Unread', NULL),
    (89, 'EVT-0000383', 5, NULL, NULL, 'Unread', NULL),
    (90, 'EVT-0000387', 4, NULL, NULL, 'Unread', NULL),
    (91, 'EVT-0000390', 1, NULL, NULL, 'Unread', NULL),
    (92, 'EVT-0000391', 1, NULL, NULL, 'Unread', NULL),
    (93, 'EVT-0000392', 2, NULL, NULL, 'Unread', NULL),
    (94, 'EVT-0000398', 5, NULL, NULL, 'Unread', NULL),
    (95, 'EVT-0000399', 4, NULL, NULL, 'Unread', NULL),
    (96, 'EVT-0000404', 2, NULL, NULL, 'Unread', NULL),
    (97, 'EVT-0000412', 1, NULL, NULL, 'Unread', NULL),
    (98, 'EVT-0000413', 5, NULL, NULL, 'Unread', NULL),
    (99, 'EVT-0000415', 1, NULL, NULL, 'Unread', NULL),
    (100, 'EVT-0000419', 4, NULL, NULL, 'Unread', NULL),
    (101, 'EVT-0000420', 5, NULL, NULL, 'Unread', NULL),
    (102, 'EVT-0000421', 1, NULL, NULL, 'Unread', NULL),
    (103, 'EVT-0000423', 3, NULL, NULL, 'Unread', NULL),
    (104, 'EVT-0000424', 6, NULL, NULL, 'Unread', NULL),
    (105, 'EVT-0000425', 5, NULL, NULL, 'Unread', NULL),
    (106, 'EVT-0000426', 4, NULL, NULL, 'Unread', NULL),
    (107, 'EVT-0000428', 5, NULL, NULL, 'Unread', NULL),
    (108, 'EVT-0000436', 2, NULL, NULL, 'Unread', NULL),
    (109, 'EVT-0000437', 4, NULL, NULL, 'Unread', NULL),
    (110, 'EVT-0000441', 5, NULL, NULL, 'Unread', NULL),
    (111, 'EVT-0000442', 2, NULL, NULL, 'Unread', NULL),
    (112, 'EVT-0000443', 1, NULL, NULL, 'Unread', NULL),
    (113, 'EVT-0000445', 6, NULL, NULL, 'Unread', NULL),
    (114, 'EVT-0000449', 5, NULL, NULL, 'Unread', NULL),
    (115, 'EVT-0000451', 6, NULL, NULL, 'Unread', NULL),
    (116, 'EVT-0000474', 3, NULL, NULL, 'Unread', NULL),
    (117, 'EVT-0000478', 1, NULL, NULL, 'Unread', NULL),
    (118, 'EVT-0000479', 4, NULL, NULL, 'Unread', NULL),
    (119, 'EVT-0000481', 2, NULL, NULL, 'Unread', NULL),
    (120, 'EVT-0000488', 4, NULL, NULL, 'Unread', NULL),
    (121, 'EVT-0000491', 1, NULL, NULL, 'Unread', NULL),
    (122, 'EVT-0000494', 1, NULL, NULL, 'Unread', NULL),
    (123, 'EVT-0000496', 4, NULL, NULL, 'Unread', NULL),
    (124, 'EVT-0000499', 5, NULL, NULL, 'Unread', NULL),
    (125, 'EVT-0000503', 2, NULL, NULL, 'Unread', NULL),
    (126, 'EVT-0000510', 6, NULL, NULL, 'Unread', NULL),
    (127, 'EVT-0000516', 2, NULL, NULL, 'Unread', NULL),
    (128, 'EVT-0000522', 3, NULL, NULL, 'Unread', NULL),
    (129, 'EVT-0000523', 4, NULL, NULL, 'Unread', NULL),
    (130, 'EVT-0000526', 6, NULL, NULL, 'Unread', NULL),
    (131, 'EVT-0000530', 6, NULL, NULL, 'Unread', NULL),
    (132, 'EVT-0000541', 2, NULL, NULL, 'Unread', NULL),
    (133, 'EVT-0000542', 4, NULL, NULL, 'Unread', NULL),
    (134, 'EVT-0000549', 5, NULL, NULL, 'Unread', NULL),
    (135, 'EVT-0000560', 6, NULL, NULL, 'Unread', NULL),
    (136, 'EVT-0000566', 5, NULL, NULL, 'Unread', NULL),
    (137, 'EVT-0000572', 2, NULL, NULL, 'Unread', NULL),
    (138, 'EVT-0000587', 2, NULL, NULL, 'Unread', NULL),
    (139, 'EVT-0000593', 3, NULL, NULL, 'Unread', NULL),
    (140, 'EVT-0000596', 2, NULL, NULL, 'Unread', NULL);


-- Progress each review sequentially -- Read, then optionally Commented, then optionally Closed. One UPDATE per step, since TRG_EventReview_BeforeUpdate enforces the ordering.

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-15 12:17:18' WHERE ReviewID = 1;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-19 07:44:01' WHERE ReviewID = 2;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-01-21 07:44:01', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 2;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-01-23 07:44:01' WHERE ReviewID = 2;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-18 11:12:52' WHERE ReviewID = 3;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-01-24 11:12:52' WHERE ReviewID = 3;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-19 18:08:20' WHERE ReviewID = 4;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-01-19 18:08:20', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 4;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-01-23 18:08:20' WHERE ReviewID = 4;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-20 04:10:13' WHERE ReviewID = 5;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-18 06:26:53' WHERE ReviewID = 6;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-01-21 06:26:53' WHERE ReviewID = 6;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-21 09:33:45' WHERE ReviewID = 7;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-01-27 09:33:45' WHERE ReviewID = 7;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-23 16:43:35' WHERE ReviewID = 8;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-01-23 16:43:35', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 8;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-01-27 16:43:35' WHERE ReviewID = 8;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-25 05:14:40' WHERE ReviewID = 9;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-01-26 05:14:40', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 9;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-23 16:21:44' WHERE ReviewID = 10;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-01-26 16:21:44', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 10;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-01-30 16:21:44' WHERE ReviewID = 10;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-30 00:33:42' WHERE ReviewID = 11;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-27 20:02:59' WHERE ReviewID = 12;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-01-28 20:02:59', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 12;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-03 20:02:59' WHERE ReviewID = 12;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-28 15:36:49' WHERE ReviewID = 13;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-01-30 15:36:49' WHERE ReviewID = 13;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-27 06:25:08' WHERE ReviewID = 14;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-01-28 06:25:08' WHERE ReviewID = 14;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-27 04:00:47' WHERE ReviewID = 15;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-01-28 04:00:47', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 15;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-01-31 04:00:47' WHERE ReviewID = 15;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-29 18:47:21' WHERE ReviewID = 16;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-01-29 18:47:21', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 16;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-04 18:47:21' WHERE ReviewID = 16;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-01-29 07:10:00' WHERE ReviewID = 17;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-02-01 07:10:00', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 17;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-05 07:10:00' WHERE ReviewID = 17;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-02 10:19:32' WHERE ReviewID = 18;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-04 10:19:32' WHERE ReviewID = 18;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-02 16:21:06' WHERE ReviewID = 19;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-02-05 16:21:06', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 19;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-08 16:21:06' WHERE ReviewID = 19;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-04 12:42:37' WHERE ReviewID = 20;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-07 05:53:21' WHERE ReviewID = 21;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-02-09 05:53:21', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 21;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-10 05:53:21' WHERE ReviewID = 21;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-06 21:51:25' WHERE ReviewID = 22;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-02-06 21:51:25', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 22;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-08 21:51:25' WHERE ReviewID = 22;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-05 14:27:34' WHERE ReviewID = 23;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-02-08 14:27:34', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 23;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-13 14:27:34' WHERE ReviewID = 23;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-09 18:18:11' WHERE ReviewID = 24;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-02-12 18:18:11', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 24;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-16 18:18:11' WHERE ReviewID = 24;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-11 15:17:38' WHERE ReviewID = 25;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-02-11 15:17:38', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 25;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-15 15:17:38' WHERE ReviewID = 25;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-11 20:38:50' WHERE ReviewID = 26;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-12 16:19:20' WHERE ReviewID = 27;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-02-12 16:19:20', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 27;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-17 16:19:20' WHERE ReviewID = 27;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-14 17:23:24' WHERE ReviewID = 28;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-02-15 17:23:24', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 28;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-19 17:23:24' WHERE ReviewID = 28;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-13 05:43:34' WHERE ReviewID = 29;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-02-16 05:43:34', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 29;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-18 05:43:34' WHERE ReviewID = 29;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-17 04:17:20' WHERE ReviewID = 30;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-20 00:12:37' WHERE ReviewID = 31;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-02-23 00:12:37', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 31;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-24 00:12:37' WHERE ReviewID = 31;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-19 16:18:52' WHERE ReviewID = 32;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-02-22 16:18:52', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 32;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-23 16:18:52' WHERE ReviewID = 32;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-21 08:58:00' WHERE ReviewID = 33;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-25 20:07:48' WHERE ReviewID = 34;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-03-03 20:07:48' WHERE ReviewID = 34;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-22 21:28:27' WHERE ReviewID = 35;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-26 21:28:27' WHERE ReviewID = 35;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-23 22:28:15' WHERE ReviewID = 36;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-26 06:08:49' WHERE ReviewID = 37;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-02-26 06:08:49', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 37;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-03-02 06:08:49' WHERE ReviewID = 37;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-26 18:00:48' WHERE ReviewID = 38;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-02-28 18:00:48' WHERE ReviewID = 38;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-02-28 18:32:23' WHERE ReviewID = 39;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-03-03 18:32:23' WHERE ReviewID = 39;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-04 03:53:21' WHERE ReviewID = 40;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-03-04 03:53:21', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 40;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-03-10 03:53:21' WHERE ReviewID = 40;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-06 14:56:57' WHERE ReviewID = 41;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-06 11:17:08' WHERE ReviewID = 42;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-03-07 11:17:08' WHERE ReviewID = 42;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-08 13:04:07' WHERE ReviewID = 43;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-03-12 13:04:07' WHERE ReviewID = 43;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-07 02:38:38' WHERE ReviewID = 44;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-03-08 02:38:38', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 44;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-07 15:37:19' WHERE ReviewID = 45;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-03-08 15:37:19' WHERE ReviewID = 45;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-09 10:17:41' WHERE ReviewID = 46;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-03-14 10:17:41' WHERE ReviewID = 46;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-12 01:08:51' WHERE ReviewID = 47;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-03-12 01:08:51', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 47;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-10 09:09:34' WHERE ReviewID = 48;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-03-13 09:09:34' WHERE ReviewID = 48;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-13 20:38:47' WHERE ReviewID = 49;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-03-16 20:38:47', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 49;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-03-21 20:38:47' WHERE ReviewID = 49;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-15 01:22:04' WHERE ReviewID = 50;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-16 23:44:41' WHERE ReviewID = 51;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-17 00:51:03' WHERE ReviewID = 52;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-03-18 00:51:03', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 52;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-03-21 00:51:03' WHERE ReviewID = 52;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-16 16:54:38' WHERE ReviewID = 53;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-03-18 16:54:38', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 53;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-03-23 16:54:38' WHERE ReviewID = 53;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-19 07:47:51' WHERE ReviewID = 54;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-03-20 07:47:51', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 54;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-23 03:08:06' WHERE ReviewID = 55;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-03-23 03:08:06', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 55;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-24 12:01:40' WHERE ReviewID = 56;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-03-24 12:01:40', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 56;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-03-28 12:01:40' WHERE ReviewID = 56;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-23 14:40:36' WHERE ReviewID = 57;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-26 21:47:25' WHERE ReviewID = 58;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-03-27 21:47:25', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 58;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-04-02 21:47:25' WHERE ReviewID = 58;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-29 16:29:28' WHERE ReviewID = 59;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-03-29 16:29:28', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 59;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-03-30 16:29:28' WHERE ReviewID = 59;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-03-28 20:25:28' WHERE ReviewID = 60;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-04 18:36:23' WHERE ReviewID = 61;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-04-05 18:36:23', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 61;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-04-10 18:36:23' WHERE ReviewID = 61;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-05 04:08:12' WHERE ReviewID = 62;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-07 13:37:40' WHERE ReviewID = 63;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-04-10 13:37:40', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 63;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-04-11 13:37:40' WHERE ReviewID = 63;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-08 13:54:20' WHERE ReviewID = 64;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-10 12:58:28' WHERE ReviewID = 65;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-04-12 12:58:28' WHERE ReviewID = 65;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-13 11:23:39' WHERE ReviewID = 66;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-04-13 11:23:39', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 66;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-15 07:43:37' WHERE ReviewID = 67;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-04-17 07:43:37', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 67;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-14 01:01:27' WHERE ReviewID = 68;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-04-15 01:01:27', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 68;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-04-16 01:01:27' WHERE ReviewID = 68;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-18 13:49:34' WHERE ReviewID = 69;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-04-21 13:49:34', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 69;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-04-22 13:49:34' WHERE ReviewID = 69;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-26 05:21:28' WHERE ReviewID = 70;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-04-27 05:21:28', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 70;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-04-30 05:21:28' WHERE ReviewID = 70;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-22 11:18:45' WHERE ReviewID = 71;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-04-22 11:18:45', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 71;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-26 02:49:12' WHERE ReviewID = 72;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-05-02 02:49:12' WHERE ReviewID = 72;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-28 18:15:38' WHERE ReviewID = 73;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-04-29 18:15:38', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 73;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-05-03 18:15:38' WHERE ReviewID = 73;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-29 07:23:58' WHERE ReviewID = 74;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-05-01 07:23:58' WHERE ReviewID = 74;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-04-29 14:25:08' WHERE ReviewID = 75;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-05-01 14:25:08', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 75;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-05-03 14:25:08' WHERE ReviewID = 75;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-02 01:45:54' WHERE ReviewID = 76;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-05-05 01:45:54', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 76;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-05-07 01:45:54' WHERE ReviewID = 76;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-03 05:08:37' WHERE ReviewID = 77;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-05-09 05:08:37' WHERE ReviewID = 77;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-09 02:47:43' WHERE ReviewID = 78;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-10 08:33:31' WHERE ReviewID = 79;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-09 04:00:57' WHERE ReviewID = 80;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-09 13:23:42' WHERE ReviewID = 81;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-05-12 13:23:42', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 81;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-05-13 13:23:42' WHERE ReviewID = 81;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-12 00:38:54' WHERE ReviewID = 82;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-13 19:39:37' WHERE ReviewID = 83;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-12 21:25:38' WHERE ReviewID = 84;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-05-13 21:25:38', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 84;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-05-14 21:25:38' WHERE ReviewID = 84;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-14 08:52:26' WHERE ReviewID = 85;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-05-17 08:52:26', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 85;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-05-22 08:52:26' WHERE ReviewID = 85;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-16 12:00:36' WHERE ReviewID = 86;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-18 10:09:47' WHERE ReviewID = 87;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-05-19 10:09:47', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 87;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-05-20 10:09:47' WHERE ReviewID = 87;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-18 23:57:57' WHERE ReviewID = 88;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-05-18 23:57:57', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 88;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-21 00:03:41' WHERE ReviewID = 89;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-22 20:23:29' WHERE ReviewID = 90;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-05-22 20:23:29', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 90;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-05-25 20:23:29' WHERE ReviewID = 90;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-22 18:43:31' WHERE ReviewID = 91;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-05-24 18:43:31', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 91;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-05-28 18:43:31' WHERE ReviewID = 91;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-22 22:35:09' WHERE ReviewID = 92;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-05-26 22:35:09' WHERE ReviewID = 92;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-23 02:55:36' WHERE ReviewID = 93;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-05-24 02:55:36', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 93;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-05-25 02:55:36' WHERE ReviewID = 93;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-27 19:26:23' WHERE ReviewID = 94;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-05-28 19:26:23', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 94;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-25 20:26:29' WHERE ReviewID = 95;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-05-28 20:26:29', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 95;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-06-03 20:26:29' WHERE ReviewID = 95;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-05-29 18:20:34' WHERE ReviewID = 96;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-06-03 18:20:34' WHERE ReviewID = 96;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-04 01:03:39' WHERE ReviewID = 97;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-06-06 01:03:39', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 97;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-06-07 01:03:39' WHERE ReviewID = 97;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-03 18:58:59' WHERE ReviewID = 98;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-06-06 18:58:59', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 98;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-04 07:07:03' WHERE ReviewID = 99;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-06 05:03:37' WHERE ReviewID = 100;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-04 18:04:38' WHERE ReviewID = 101;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-07 16:07:24' WHERE ReviewID = 102;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-06-08 16:07:24', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 102;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-06-10 16:07:24' WHERE ReviewID = 102;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-05 18:05:45' WHERE ReviewID = 103;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-07 11:48:51' WHERE ReviewID = 104;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-09 03:30:32' WHERE ReviewID = 105;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-10 12:58:15' WHERE ReviewID = 106;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-08 00:04:18' WHERE ReviewID = 107;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-11 17:23:58' WHERE ReviewID = 108;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-13 16:38:31' WHERE ReviewID = 109;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-06-15 16:38:31', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 109;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-14 09:34:07' WHERE ReviewID = 110;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-11 07:45:18' WHERE ReviewID = 111;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-15 00:05:31' WHERE ReviewID = 112;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-14 20:41:51' WHERE ReviewID = 113;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-13 15:31:56' WHERE ReviewID = 114;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-12 14:06:02' WHERE ReviewID = 115;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-22 00:39:24' WHERE ReviewID = 116;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-19 21:17:08' WHERE ReviewID = 117;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-06-22 21:17:08', Comments = 'Reviewed telemetry; driver coaching recommended.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 117;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-20 08:56:28' WHERE ReviewID = 118;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-24 23:35:56' WHERE ReviewID = 119;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-24 00:38:33' WHERE ReviewID = 120;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-28 20:42:20' WHERE ReviewID = 121;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-28 22:24:10' WHERE ReviewID = 122;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-07-04 22:24:10' WHERE ReviewID = 122;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-30 02:32:04' WHERE ReviewID = 123;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-27 16:10:51' WHERE ReviewID = 124;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-06-30 16:10:51', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 124;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-06-29 16:43:43' WHERE ReviewID = 125;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-06-30 16:43:43', Comments = 'Consistent with prior pattern; escalate to retraining track.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 125;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-04 10:15:01' WHERE ReviewID = 126;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-07-05 10:15:01' WHERE ReviewID = 126;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-03 09:01:20' WHERE ReviewID = 127;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-04 02:37:14' WHERE ReviewID = 128;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-07 04:30:25' WHERE ReviewID = 129;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-07 10:50:56' WHERE ReviewID = 130;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-04 12:43:42' WHERE ReviewID = 131;

UPDATE EventReview SET Status = 'Commented', DateReviewed = '2026-07-05 12:43:42', Comments = 'Isolated incident; no further action beyond standard coaching.', Recommendations = 'Recommend standard safety coaching follow-up.' WHERE ReviewID = 131;

UPDATE EventReview SET Status = 'Closed', DateReviewed = '2026-07-08 12:43:42' WHERE ReviewID = 131;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-10 16:54:26' WHERE ReviewID = 132;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-07 15:01:01' WHERE ReviewID = 133;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-10 05:51:32' WHERE ReviewID = 134;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-10 16:05:21' WHERE ReviewID = 135;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-12 17:08:04' WHERE ReviewID = 136;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-12 05:19:06' WHERE ReviewID = 137;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-15 07:23:40' WHERE ReviewID = 138;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-17 10:11:07' WHERE ReviewID = 139;

UPDATE EventReview SET Status = 'Read', DateReviewed = '2026-07-18 19:48:34' WHERE ReviewID = 140;


-- CoachingRecord -- 10 manually-enrolled rows (Licence Review, plus Retraining enrolled directly by staff outside the DriverScorePenalty cascade)

INSERT INTO CoachingRecord (CoachingRecordID, DriverID, CoachingType, CoachingDate, CompletionDate, Outcome) VALUES
    (1, 'D-0031', 'Licence Review', '2026-06-12', '2026-06-22', 'Failed'),
    (2, 'D-0039', 'Licence Review', '2026-06-17', NULL, 'In Progress'),
    (3, 'D-0008', 'Licence Review', '2026-03-11', NULL, 'Pending'),
    (4, 'D-0041', 'Licence Review', '2026-04-23', '2026-04-26', 'Failed'),
    (5, 'D-0039', 'Licence Review', '2026-03-21', NULL, 'In Progress'),
    (6, 'D-0002', 'Licence Review', '2026-06-18', '2026-07-06', 'Failed'),
    (7, 'D-0020', 'Retraining', '2026-06-19', NULL, 'Pending'),
    (8, 'D-0018', 'Retraining', '2026-07-01', NULL, 'Pending'),
    (9, 'D-0001', 'Retraining', '2026-06-06', NULL, 'Pending'),
    (10, 'D-0016', 'Retraining', '2026-07-04', NULL, 'Pending');



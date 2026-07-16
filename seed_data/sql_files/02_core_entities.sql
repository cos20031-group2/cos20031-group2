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


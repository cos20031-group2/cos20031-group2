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


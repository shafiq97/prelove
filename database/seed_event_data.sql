-- Seed data for the events table
-- This script adds sample events that reference the outfits from seed_outfit_data.sql

-- Optional: Clear existing events data
-- DELETE FROM events;

-- Insert events for user ID 1 (development bypass user)
-- Events with reference to outfits
INSERT INTO events (user_id, title, description, event_date, location, outfit_id, created_at, updated_at)
VALUES
-- Upcoming events (future dates)
(1, 'Coffee with Friends', 'Casual meetup at Starbucks', DATE_ADD(CURDATE(), INTERVAL 2 DAY), 'Starbucks Downtown', 1, NOW(), NOW()),
(1, 'Business Conference', 'Annual industry conference', DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'Convention Center', 3, NOW(), NOW()),
(1, 'Birthday Party', 'John\'s birthday celebration', DATE_ADD(CURDATE(), INTERVAL 10 DAY), 'John\'s House', 2, NOW(), NOW()),
(1, 'Gym Session', 'Weekly workout routine', DATE_ADD(CURDATE(), INTERVAL 1 DAY), 'Fitness First', 4, NOW(), NOW()),
(1, 'Beach Day', 'Day trip to the beach', DATE_ADD(CURDATE(), INTERVAL 14 DAY), 'Sunny Beach', 5, NOW(), NOW()),

-- Current day event
(1, 'Team Meeting', 'Discuss project progress', CURDATE(), 'Office Room 302', 3, NOW(), NOW()),

-- Events happening within the next few weeks
(1, 'Movie Night', 'Watch the new blockbuster', DATE_ADD(CURDATE(), INTERVAL 5 DAY), 'Cinema City', 1, NOW(), NOW()),
(1, 'Dinner Reservation', 'Anniversary dinner', DATE_ADD(CURDATE(), INTERVAL 12 DAY), 'Fancy Restaurant', 2, NOW(), NOW()),
(1, 'Job Interview', 'Interview for software developer position', DATE_ADD(CURDATE(), INTERVAL 6 DAY), 'Tech Company HQ', 3, NOW(), NOW()),
(1, 'Yoga Class', 'Morning yoga session', DATE_ADD(CURDATE(), INTERVAL 3 DAY), 'Zen Yoga Studio', 4, NOW(), NOW()),

-- Events without outfit reference
(1, 'Doctor Appointment', 'Annual checkup', DATE_ADD(CURDATE(), INTERVAL 9 DAY), 'City Medical Center', NULL, NOW(), NOW()),
(1, 'Grocery Shopping', 'Weekly grocery run', DATE_ADD(CURDATE(), INTERVAL 4 DAY), 'Supermarket', NULL, NOW(), NOW()),
(1, 'Library Visit', 'Return books and pick up new ones', DATE_ADD(CURDATE(), INTERVAL 8 DAY), 'Public Library', NULL, NOW(), NOW());

-- You can run this script after executing seed_outfit_data.sql to ensure outfit references are valid
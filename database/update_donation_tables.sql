ALTER TABLE donation_centers 
ADD COLUMN location VARCHAR(255) AFTER address,
ADD COLUMN operating_hours VARCHAR(255) AFTER phone,
ADD COLUMN accepted_items TEXT AFTER email,
ADD COLUMN status VARCHAR(20) DEFAULT 'active' AFTER image_url;

-- Modify the donations table to use DATETIME instead of DATE
ALTER TABLE donations 
MODIFY COLUMN scheduled_date DATETIME NOT NULL;


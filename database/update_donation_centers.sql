-- Update donation_centers table to add missing columns
ALTER TABLE donation_centers 
ADD COLUMN operating_hours TEXT AFTER description,
ADD COLUMN accepted_items JSON AFTER operating_hours,
ADD COLUMN status VARCHAR(20) DEFAULT 'active' AFTER accepted_items;

-- Update existing donation centers with sample data
UPDATE donation_centers SET 
  operating_hours = 'Monday-Friday: 9am-5pm, Saturday: 10am-4pm, Sunday: Closed',
  accepted_items = '["Clothing", "Shoes", "Accessories", "Books", "Household items"]',
  status = 'active';
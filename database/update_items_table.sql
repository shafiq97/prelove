-- Add missing columns to the items table
ALTER TABLE items 
ADD COLUMN size VARCHAR(20) DEFAULT 'One Size' AFTER category,
ADD COLUMN color VARCHAR(30) DEFAULT 'Not specified' AFTER size,
ADD COLUMN brand VARCHAR(50) DEFAULT 'Unbranded' AFTER color;

-- Update existing items with some sample values
UPDATE items SET size = 'L', color = 'Blue', brand = 'Levi\'s' WHERE id = 1;
UPDATE items SET size = 'M', color = 'White', brand = 'H&M' WHERE id = 2;
UPDATE items SET size = '32', color = 'Black', brand = 'Zara' WHERE id = 3;
UPDATE items SET size = 'S', color = 'Red', brand = 'Forever 21' WHERE id = 4;
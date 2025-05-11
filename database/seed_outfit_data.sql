-- Clear existing data (optional, remove if you want to keep existing data)
-- DELETE FROM outfit_items;
-- DELETE FROM outfits;

-- Insert outfits for user ID 1 (development bypass user)
INSERT INTO outfits (id, user_id, name, description, created_at, updated_at)
VALUES 
(1, 1, 'Casual Weekend', 'Perfect for a relaxed weekend', NOW(), NOW()),
(2, 1, 'Evening Out', 'Elegant outfit for dinner', NOW(), NOW()),
(3, 1, 'Business Meeting', 'Professional attire for important meetings', NOW(), NOW()),
(4, 1, 'Workout Ready', 'Comfortable clothes for the gym', NOW(), NOW()),
(5, 1, 'Summer Beach', 'Light and breezy for hot days', NOW(), NOW());

-- Insert outfit items (assumes items with IDs 1-10 exist)
INSERT INTO outfit_items (outfit_id, item_id, position, created_at)
VALUES
-- Casual Weekend outfit
(1, 1, 1, NOW()),
(1, 2, 2, NOW()),
(1, 3, 3, NOW()),

-- Evening Out outfit
(2, 4, 1, NOW()),
(2, 5, 2, NOW()),
(2, 6, 3, NOW()),

-- Business Meeting outfit
(3, 7, 1, NOW()),
(3, 8, 2, NOW()),
(3, 9, 3, NOW()),

-- Workout Ready outfit
(4, 10, 1, NOW()),
(4, 1, 2, NOW()),

-- Summer Beach outfit
(5, 3, 1, NOW()),
(5, 6, 2, NOW());

-- If you need to add items first, uncomment and modify this:
-- INSERT INTO items (id, user_id, name, description, price, category, condition_value, brand, size, color, image_url, created_at, updated_at)
-- VALUES
-- (1, 1, 'Blue Jeans', 'Comfortable denim jeans', 45.00, 'Bottoms', 'New', 'Levi\'s', 'M', 'Blue', 'images/items/jeans1.jpg', NOW(), NOW()),
-- (2, 1, 'White T-shirt', 'Basic cotton t-shirt', 15.00, 'Tops', 'New', 'H&M', 'L', 'White', 'images/items/tshirt1.jpg', NOW(), NOW()),
-- (3, 1, 'Sneakers', 'Casual sneakers', 60.00, 'Footwear', 'Good', 'Nike', '42', 'Black', 'images/items/sneakers1.jpg', NOW(), NOW()),
-- (4, 1, 'Black Dress', 'Elegant evening dress', 85.00, 'Dresses', 'New', 'Zara', 'S', 'Black', 'images/items/dress1.jpg', NOW(), NOW()),
-- (5, 1, 'Heels', 'Classic high heels', 75.00, 'Footwear', 'Good', 'Nine West', '39', 'Red', 'images/items/heels1.jpg', NOW(), NOW()),
-- (6, 1, 'Clutch Bag', 'Small evening bag', 30.00, 'Accessories', 'Good', 'ALDO', 'One Size', 'Silver', 'images/items/bag1.jpg', NOW(), NOW()),
-- (7, 1, 'Blazer', 'Professional blazer', 120.00, 'Outerwear', 'New', 'Calvin Klein', 'M', 'Navy', 'images/items/blazer1.jpg', NOW(), NOW()),
-- (8, 1, 'Dress Shirt', 'Button-up dress shirt', 45.00, 'Tops', 'New', 'Ralph Lauren', 'M', 'Light Blue', 'images/items/shirt1.jpg', NOW(), NOW()),
-- (9, 1, 'Dress Pants', 'Formal trousers', 65.00, 'Bottoms', 'New', 'Banana Republic', '32', 'Charcoal', 'images/items/pants1.jpg', NOW(), NOW()),
-- (10, 1, 'Workout Leggings', 'Stretchy workout pants', 40.00, 'Activewear', 'Good', 'Nike', 'M', 'Black', 'images/items/leggings1.jpg', NOW(), NOW());

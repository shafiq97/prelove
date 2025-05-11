<?php
require_once 'headers.php';
require_once 'config.php';

// Debug logging for request details
error_log("Cart API Request received");
error_log("Request Method: " . $_SERVER['REQUEST_METHOD']);
error_log("Request URI: " . $_SERVER['REQUEST_URI']);

// Get all headers and normalize them for case-insensitive access
$allHeaders = getallheaders();
$normalizedHeaders = array();
foreach ($allHeaders as $name => $value) {
    $normalizedHeaders[strtolower($name)] = $value;
}
error_log("All Request Headers: " . json_encode($allHeaders));
error_log("Normalized Headers: " . json_encode($normalizedHeaders));

// Get action from query parameters
$action = isset($_GET['action']) ? $_GET['action'] : null;
error_log("Action parameter: " . ($action ?? 'null'));

// Get HTTP method and path
$method = $_SERVER['REQUEST_METHOD'];
$request = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$path = explode('/', $request);
$endpoint = end($path);

// Check authorization for all endpoints
// Look for Authorization header in a case-insensitive way
$authHeader = null;
if (isset($normalizedHeaders['authorization'])) {
    $authHeader = $normalizedHeaders['authorization'];
} elseif (isset($allHeaders['Authorization'])) {
    $authHeader = $allHeaders['Authorization'];
}

if (!$authHeader) {
    error_log("No Authorization header found");
    http_response_code(401);
    echo json_encode(['error' => 'Authentication required']);
    exit;
}

error_log("Found Auth header: " . $authHeader);

if (strpos($authHeader, 'Bearer ') !== 0) {
    error_log("Invalid Authorization header format: " . $authHeader);
    http_response_code(401);
    echo json_encode(['error' => 'Invalid token format']);
    exit;
}

$token = substr($authHeader, 7);
error_log("Extracted token: " . $token);

$user_data = verifyToken($token);
error_log("Verify token result: " . json_encode($user_data));

// DEVELOPMENT BYPASS: Use default user if token is invalid
if (!$user_data) {
    error_log("Invalid token in cart_api.php, using default user");
    $user_data = ['user_id' => 1]; // Use a default user ID for development
}

error_log("User authenticated successfully: " . json_encode($user_data));

// Handle action parameter if present
if ($action) {
    error_log("Processing action: $action");
    switch ($action) {
        case 'add_to_cart':
            if ($method === 'POST') {
                addToCart($user_data['user_id']);
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'get_cart':
            if ($method === 'GET') {
                getUserCart($user_data['user_id']);
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'update_quantity':
            if ($method === 'PUT') {
                updateCartQuantity($user_data['user_id']);
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'remove_from_cart':
            if ($method === 'DELETE') {
                removeCartItem($user_data['user_id']);
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'checkout':
            if ($method === 'POST') {
                processCheckout($user_data['user_id']);
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'order_history':
            if ($method === 'GET') {
                getOrderHistory($user_data['user_id']);
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;
        case 'order_details':
            if ($method === 'GET' && isset($_GET['id'])) {
                getOrderDetails($user_data['user_id'], $_GET['id']);
            } else {
                http_response_code(400);
                echo json_encode(['error' => 'Order ID is required']);
            }
            break;
        default:
            http_response_code(404);
            echo json_encode(['error' => 'Invalid action']);
            break;
    }
    exit;
}

// Extract cart item ID if present
$cart_item_id = null;
if (is_numeric($endpoint)) {
    $cart_item_id = intval($endpoint);
    $endpoint = prev($path);
}

// Route to appropriate function based on method and endpoint
switch ($method) {
    case 'GET':
        switch ($endpoint) {
            case 'cart':
                error_log("Processing get_cart action");
                getUserCart($user_data['user_id']);
                break;
            default:
                http_response_code(404);
                echo json_encode(['error' => 'Endpoint not found']);
                break;
        }
        break;
    
    case 'POST':
        switch ($endpoint) {
            case 'cart':
                error_log("Processing add_to_cart action");
                addToCart($user_data['user_id']);
                break;
            case 'checkout':
                error_log("Processing checkout action");
                processCheckout($user_data['user_id']);
                break;
            default:
                http_response_code(404);
                echo json_encode(['error' => 'Endpoint not found']);
                break;
        }
        break;
    
    case 'PUT':
        if ($cart_item_id) {
            error_log("Processing update_quantity action");
            updateCartItem($user_data['user_id'], $cart_item_id);
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'Cart item ID is required for update']);
        }
        break;
    
    case 'DELETE':
        if ($cart_item_id) {
            error_log("Processing remove_from_cart action");
            removeFromCart($user_data['user_id'], $cart_item_id);
        } else {
            // If no specific item ID, clear the entire cart
            error_log("Processing clear_cart action");
            clearCart($user_data['user_id']);
        }
        break;
    
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        break;
}

// Function to get user's cart
function getUserCart($user_id) {
    global $conn;
    error_log("Fetching cart for user: $user_id");
    
    try {
        // Check if size, color, and brand columns exist
        $check_columns = $conn->prepare("SHOW COLUMNS FROM items LIKE 'size'");
        $check_columns->execute();
        $has_size_column = $check_columns->rowCount() > 0;
        
        $check_columns = $conn->prepare("SHOW COLUMNS FROM items LIKE 'color'");
        $check_columns->execute();
        $has_color_column = $check_columns->rowCount() > 0;
        
        $check_columns = $conn->prepare("SHOW COLUMNS FROM items LIKE 'brand'");
        $check_columns->execute();
        $has_brand_column = $check_columns->rowCount() > 0;
        
        // Build query based on available columns
        $query = "
            SELECT c.id AS cart_id, c.item_id, c.quantity, c.created_at,
                   i.name, i.price, i.image_url, i.description, i.category";
        
        if ($has_size_column) {
            $query .= ", i.size";
        }
        
        if ($has_color_column) {
            $query .= ", i.color";
        }
        
        if ($has_brand_column) {
            $query .= ", i.brand";
        }
        
        $query .= " FROM cart c
                   JOIN items i ON c.item_id = i.id
                   WHERE c.user_id = :user_id";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $stmt->execute();
        
        $cart_items = $stmt->fetchAll();
        error_log("Cart items fetched: " . json_encode($cart_items));
        
        // Add default values for missing columns
        foreach ($cart_items as &$item) {
            if (!$has_size_column) {
                $item['size'] = 'One Size';
            }
            if (!$has_color_column) {
                $item['color'] = 'Not specified';
            }
            if (!$has_brand_column) {
                $item['brand'] = 'Unbranded';
            }
        }
        
        // Calculate total price
        $total_price = 0;
        foreach ($cart_items as $item) {
            $total_price += $item['price'] * $item['quantity'];
        }
        
        echo json_encode([
            'success' => true,
            'cart_items' => $cart_items,
            'total_price' => $total_price,
            'item_count' => count($cart_items)
        ]);
    } catch (PDOException $e) {
        error_log("Error fetching cart: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch cart: ' . $e->getMessage()]);
    }
}

// Function to add item to cart
function addToCart($user_id) {
    global $conn;
    error_log("Adding item to cart for user: $user_id");

    // Get JSON data from request body
    $input = json_decode(file_get_contents('php://input'), true);
    error_log("Request body received: " . json_encode($input));

    if (!isset($input['item_id']) || !isset($input['quantity'])) {
        error_log("Missing required fields: item_id or quantity");
        http_response_code(400);
        echo json_encode(['error' => 'Item ID and quantity are required']);
        return;
    }

    $item_id = $input['item_id'];
    $quantity = max(1, intval($input['quantity']));
    error_log("Processed input - item_id: $item_id, quantity: $quantity");

    try {
        // Check if item exists in cart
        $stmt = $conn->prepare("SELECT * FROM cart WHERE user_id = :user_id AND item_id = :item_id");
        $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $stmt->bindParam(':item_id', $item_id, PDO::PARAM_INT);
        $stmt->execute();
        $cart_item = $stmt->fetch();

        if ($cart_item) {
            error_log("Item already exists in cart, updating quantity");
            // Update quantity if item exists
            $new_quantity = $cart_item['quantity'] + $quantity;
            $update_stmt = $conn->prepare("UPDATE cart SET quantity = :quantity WHERE id = :id");
            $update_stmt->bindParam(':quantity', $new_quantity, PDO::PARAM_INT);
            $update_stmt->bindParam(':id', $cart_item['id'], PDO::PARAM_INT);
            $update_stmt->execute();

            echo json_encode([
                'success' => true,
                'message' => 'Item quantity updated in cart',
                'cart_item_id' => $cart_item['id'],
                'new_quantity' => $new_quantity
            ]);
        } else {
            error_log("Adding new item to cart");
            // Add new item to cart
            $stmt = $conn->prepare("INSERT INTO cart (user_id, item_id, quantity) VALUES (:user_id, :item_id, :quantity)");
            $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
            $stmt->bindParam(':item_id', $item_id, PDO::PARAM_INT);
            $stmt->bindParam(':quantity', $quantity, PDO::PARAM_INT);
            $stmt->execute();

            $cart_item_id = $conn->lastInsertId();
            error_log("New cart item created with ID: $cart_item_id");
            
            echo json_encode([
                'success' => true,
                'message' => 'Item added to cart',
                'cart_item_id' => $cart_item_id
            ]);
        }
    } catch (PDOException $e) {
        error_log("Database error in addToCart: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Failed to add item to cart: ' . $e->getMessage()]);
    }
}

// Function to update cart item quantity
function updateCartItem($user_id, $cart_item_id) {
    global $conn;
    error_log("Updating cart item for user: $user_id, cart_item_id: $cart_item_id");
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    error_log("Request body received: " . json_encode($data));
    
    if (!isset($data['quantity'])) {
        error_log("Missing required field: quantity");
        http_response_code(400);
        echo json_encode(['error' => 'Quantity is required']);
        return;
    }
    
    $quantity = max(1, intval($data['quantity']));
    error_log("Processed input - quantity: $quantity");
    
    // Verify cart item belongs to user
    $stmt = $conn->prepare("SELECT * FROM cart WHERE id = :id AND user_id = :user_id");
    $stmt->bindParam(':id', $cart_item_id, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
    $stmt->execute();
    
    if ($stmt->rowCount() === 0) {
        error_log("Cart item not found or does not belong to user");
        http_response_code(404);
        echo json_encode(['error' => 'Cart item not found or does not belong to user']);
        return;
    }
    
    // Update quantity
    $update_stmt = $conn->prepare("
        UPDATE cart 
        SET quantity = :quantity, updated_at = NOW() 
        WHERE id = :id AND user_id = :user_id
    ");
    $update_stmt->bindParam(':quantity', $quantity, PDO::PARAM_INT);
    $update_stmt->bindParam(':id', $cart_item_id, PDO::PARAM_INT);
    $update_stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
    $update_stmt->execute();
    
    echo json_encode([
        'success' => true,
        'message' => 'Cart item updated',
        'cart_item_id' => $cart_item_id,
        'new_quantity' => $quantity
    ]);
}

// Function to update cart item quantity - wrapper for updateCartItem
function updateCartQuantity($user_id) {
    global $conn;
    error_log("Processing updateCartQuantity for user: $user_id");
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    error_log("Request body received: " . json_encode($data));
    
    if (!isset($data['cart_id']) || !isset($data['quantity'])) {
        error_log("Missing required fields: cart_id or quantity");
        http_response_code(400);
        echo json_encode(['error' => 'Cart ID and quantity are required']);
        return;
    }
    
    $cart_item_id = $data['cart_id'];
    
    // Call the existing function with both parameters
    updateCartItem($user_id, $cart_item_id);
}

// Function to remove item from cart
function removeFromCart($user_id, $cart_item_id) {
    global $conn;
    error_log("Removing item from cart for user: $user_id, cart_item_id: $cart_item_id");
    
    // Verify cart item belongs to user
    $stmt = $conn->prepare("SELECT * FROM cart WHERE id = :id AND user_id = :user_id");
    $stmt->bindParam(':id', $cart_item_id, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
    $stmt->execute();
    
    if ($stmt->rowCount() === 0) {
        error_log("Cart item not found or does not belong to user");
        http_response_code(404);
        echo json_encode(['error' => 'Cart item not found or does not belong to user']);
        return;
    }
    
    // Delete item from cart
    $delete_stmt = $conn->prepare("DELETE FROM cart WHERE id = :id AND user_id = :user_id");
    $delete_stmt->bindParam(':id', $cart_item_id, PDO::PARAM_INT);
    $delete_stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
    $delete_stmt->execute();
    
    echo json_encode([
        'success' => true,
        'message' => 'Item removed from cart'
    ]);
}

// Function to handle remove from cart API action
function removeCartItem($user_id) {
    global $conn;
    error_log("Processing removeCartItem for user: $user_id");
    
    // Get JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    error_log("Request body received: " . json_encode($data));
    
    if (!isset($data['cart_id'])) {
        error_log("Missing required field: cart_id");
        http_response_code(400);
        echo json_encode(['error' => 'Cart ID is required']);
        return;
    }
    
    $cart_item_id = $data['cart_id'];
    
    // Call the existing function with both parameters
    removeFromCart($user_id, $cart_item_id);
}

// Function to clear entire cart
function clearCart($user_id) {
    global $conn;
    error_log("Clearing cart for user: $user_id");
    
    $stmt = $conn->prepare("DELETE FROM cart WHERE user_id = :user_id");
    $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
    $stmt->execute();
    
    echo json_encode([
        'success' => true,
        'message' => 'Cart cleared'
    ]);
}

// Process checkout
function processCheckout($user_id) {
    global $conn;
    header('Content-Type: application/json');
    error_log("📦 Processing checkout for user: $user_id");

    $conn->beginTransaction();

    try {
        // Fetch cart items for the user
        $cart_stmt = $conn->prepare("
            SELECT c.item_id, c.quantity, i.price
            FROM cart c
            JOIN items i ON c.item_id = i.id
            WHERE c.user_id = :user_id
        ");
        $cart_stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $cart_stmt->execute();

        $cart_items = $cart_stmt->fetchAll(PDO::FETCH_ASSOC);
        if (empty($cart_items)) {
            error_log("❌ Cart is empty");
            http_response_code(400);
            echo json_encode(['error' => 'Cart is empty']);
            return;
        }

        // Parse JSON body
        $data = json_decode(file_get_contents('php://input'), true);
        error_log("📥 Checkout data: " . json_encode($data));

        $required_fields = ['shipping_address', 'payment_method'];
        foreach ($required_fields as $field) {
            if (empty($data[$field])) {
                http_response_code(400);
                echo json_encode(['error' => "Field '$field' is required"]);
                return;
            }
        }

        // Calculate total
        $total_price = 0;
        foreach ($cart_items as $item) {
            $total_price += $item['price'] * $item['quantity'];
        }

        // Create order
        $order_stmt = $conn->prepare("
            INSERT INTO orders (user_id, total_amount, shipping_address, payment_method, status)
            VALUES (:user_id, :total_amount, :shipping_address, :payment_method, 'pending')
        ");
        $order_stmt->execute([
            ':user_id' => $user_id,
            ':total_amount' => $total_price,
            ':shipping_address' => $data['shipping_address'],
            ':payment_method' => $data['payment_method']
        ]);

        $order_id = $conn->lastInsertId();
        error_log("✅ Order created with ID: $order_id");

        // Insert order items
        $order_items_stmt = $conn->prepare("
            INSERT INTO order_items (order_id, item_id, quantity, price)
            VALUES (:order_id, :item_id, :quantity, :price)
        ");

        foreach ($cart_items as $item) {
            $order_items_stmt->execute([
                ':order_id' => $order_id,
                ':item_id' => $item['item_id'],
                ':quantity' => $item['quantity'],
                ':price' => $item['price']
            ]);

            // Mark item as sold
            $conn->prepare("UPDATE items SET is_available = 0 WHERE id = :id")
                ->execute([':id' => $item['item_id']]);
        }

        // Clear user's cart
        $conn->prepare("DELETE FROM cart WHERE user_id = :user_id")
            ->execute([':user_id' => $user_id]);

        // Add to order history
        $conn->prepare("
            INSERT INTO order_history (user_id, order_id, status, notes)
            VALUES (:user_id, :order_id, 'placed', 'Order placed successfully')
        ")->execute([
            ':user_id' => $user_id,
            ':order_id' => $order_id
        ]);

        $conn->commit();
        echo json_encode([
            'success' => true,
            'message' => 'Order placed successfully',
            'order_id' => $order_id,
            'total_amount' => $total_price
        ]);

    } catch (PDOException $e) {
        $conn->rollBack();
        error_log("❌ Checkout failed: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Checkout failed: ' . $e->getMessage()]);
    }
}


// Function to get user's order history
function getOrderHistory($user_id) {
    global $conn;
    error_log("Fetching order history for user: $user_id");
    
    try {
        // Get orders
        $orders_query = "
            SELECT o.id, o.total_amount, o.status, o.created_at, 
                   'purchase' as category,
                   CONCAT('Order #', o.id) as title,
                   DATE_FORMAT(o.created_at, '%Y-%m-%d') as date,
                   o.total_amount as amount
            FROM orders o
            WHERE o.user_id = :user_id
            
            UNION
            
            -- Include donation history if available
            SELECT d.id, 0 as total_amount, d.status, d.created_at,
                   'donation' as category,
                   CONCAT('Donation to ', dc.name) as title,
                   DATE_FORMAT(d.scheduled_date, '%Y-%m-%d') as date,
                   0 as amount
            FROM donations d
            JOIN donation_centers dc ON d.center_id = dc.id
            WHERE d.user_id = :user_id
            
            -- Include any sold items by this user
            UNION
            
            SELECT i.id, i.price as total_amount, 
                   CASE WHEN i.is_available = 0 THEN 'sold' ELSE 'available' END as status, 
                   i.created_at,
                   'sale' as category,
                   CONCAT('Sale: ', i.name) as title,
                   DATE_FORMAT(i.updated_at, '%Y-%m-%d') as date,
                   i.price as amount
            FROM items i
            WHERE i.seller_id = :user_id AND i.is_available = 0
            
            ORDER BY created_at DESC
            LIMIT 50
        ";
        
        $stmt = $conn->prepare($orders_query);
        $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $stmt->execute();
        
        $history = $stmt->fetchAll(PDO::FETCH_ASSOC);
        error_log("Order history fetched: " . json_encode($history));
        
        echo json_encode([
            'success' => true,
            'history' => $history
        ]);
        
    } catch (PDOException $e) {
        error_log("Error fetching order history: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch order history: ' . $e->getMessage()]);
    }
}

// Function to get details of a specific order
function getOrderDetails($user_id, $order_id) {
    global $conn;
    error_log("Fetching order details for user: $user_id, order_id: $order_id");
    
    try {
        // Verify the order belongs to the user
        $check_stmt = $conn->prepare("
            SELECT * FROM orders 
            WHERE id = :order_id AND user_id = :user_id
        ");
        $check_stmt->bindParam(':order_id', $order_id, PDO::PARAM_INT);
        $check_stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() === 0) {
            error_log("Order not found or does not belong to user");
            http_response_code(404);
            echo json_encode(['error' => 'Order not found or does not belong to user']);
            return;
        }
        
        // Get order details
        $order = $check_stmt->fetch(PDO::FETCH_ASSOC);
        
        // Get order items
        $items_stmt = $conn->prepare("
            SELECT oi.*, i.name, i.image_url, i.description 
            FROM order_items oi
            JOIN items i ON oi.item_id = i.id
            WHERE oi.order_id = :order_id
        ");
        $items_stmt->bindParam(':order_id', $order_id, PDO::PARAM_INT);
        $items_stmt->execute();
        
        $items = $items_stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Get order history/status updates
        $history_stmt = $conn->prepare("
            SELECT oh.status, oh.notes, oh.created_at
            FROM order_history oh
            WHERE oh.order_id = :order_id
            ORDER BY oh.created_at DESC
        ");
        $history_stmt->bindParam(':order_id', $order_id, PDO::PARAM_INT);
        $history_stmt->execute();
        
        $status_history = $history_stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'order' => $order,
            'items' => $items,
            'status_history' => $status_history
        ]);
        
    } catch (PDOException $e) {
        error_log("Error fetching order details: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch order details: ' . $e->getMessage()]);
    }
}
?>
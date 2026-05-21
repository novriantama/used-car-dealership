package handlers

import (
	"database/sql"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"backend/internal/database"
	"backend/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

// Handler holds dependencies like the JWT secret.
type Handler struct {
	JWTSecret []byte
}

// NewHandler creates a new Handler instance.
func NewHandler(secret string) *Handler {
	return &Handler{JWTSecret: []byte(secret)}
}

// Login authenticates admin users and returns a JWT.
func (h *Handler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username and password are required"})
		return
	}

	var dbAdmin models.Admin
	query := "SELECT id, username, password_hash, name, created_at FROM admins WHERE username = $1"
	err := database.DB.QueryRow(query, req.Username).Scan(
		&dbAdmin.ID, &dbAdmin.Username, &dbAdmin.PasswordHash, &dbAdmin.Name, &dbAdmin.CreatedAt,
	)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid username or password"})
		return
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	// Compare passwords
	err = bcrypt.CompareHashAndPassword([]byte(dbAdmin.PasswordHash), []byte(req.Password))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid username or password"})
		return
	}

	// Create JWT token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub":  dbAdmin.Username,
		"name": dbAdmin.Name,
		"exp":  time.Now().Add(time.Hour * 24).Unix(), // 24 hours
		"iat":  time.Now().Unix(),
	})

	tokenString, err := token.SignedString(h.JWTSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, models.LoginResponse{
		Token: tokenString,
		Name:  dbAdmin.Name,
	})
}

// GetVehicles fetches vehicle listings with dynamic filtering and pagination.
func (h *Handler) GetVehicles(c *gin.Context) {
	// 1. Parsing query parameters
	search := c.Query("search")
	makeFilter := c.Query("make")
	modelFilter := c.Query("model")
	transmission := c.Query("transmission")
	plateType := c.Query("plate_type")
	taxStatus := c.Query("tax_status")

	priceMinStr := c.Query("price_min")
	priceMaxStr := c.Query("price_max")
	yearMinStr := c.Query("year_min")
	yearMaxStr := c.Query("year_max")

	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "10")

	// Parse pagination
	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 1 {
		page = 1
	}
	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit < 1 {
		limit = 10
	}
	if limit > 100 {
		limit = 100
	}
	offset := (page - 1) * limit

	// Build SQL query dynamically
	query := `SELECT id, make, model, year, price, transmission, fuel_type, mileage, 
	                 engine_capacity, color, plate_type, tax_status, tax_expiry_date, 
	                 location, inspection_engine, inspection_interior, inspection_exterior, 
	                 inspection_notes, status, image_urls, created_at, updated_at 
	          FROM vehicles WHERE 1=1`
	
	countQuery := `SELECT COUNT(*) FROM vehicles WHERE 1=1`

	var args []interface{}
	placeholderIdx := 1

	addFilter := func(condition string, arg interface{}) {
		query += fmt.Sprintf(" AND %s", fmt.Sprintf(condition, fmt.Sprintf("$%d", placeholderIdx)))
		countQuery += fmt.Sprintf(" AND %s", fmt.Sprintf(condition, fmt.Sprintf("$%d", placeholderIdx)))
		args = append(args, arg)
		placeholderIdx++
	}

	if search != "" {
		// General search across make and model
		addFilter("(make ILIKE %s OR model ILIKE %s)", "%"+search+"%")
	}
	if makeFilter != "" {
		addFilter("make ILIKE %s", "%"+makeFilter+"%")
	}
	if modelFilter != "" {
		addFilter("model ILIKE %s", "%"+modelFilter+"%")
	}
	if transmission != "" {
		addFilter("transmission = %s", transmission)
	}
	if plateType != "" {
		addFilter("plate_type = %s", plateType)
	}
	if taxStatus != "" {
		addFilter("tax_status = %s", taxStatus)
	}

	if priceMinStr != "" {
		if pMin, err := strconv.ParseInt(priceMinStr, 10, 64); err == nil {
			addFilter("price >= %s", pMin)
		}
	}
	if priceMaxStr != "" {
		if pMax, err := strconv.ParseInt(priceMaxStr, 10, 64); err == nil {
			addFilter("price <= %s", pMax)
		}
	}
	if yearMinStr != "" {
		if yMin, err := strconv.Atoi(yearMinStr); err == nil {
			addFilter("year >= %s", yMin)
		}
	}
	if yearMaxStr != "" {
		if yMax, err := strconv.Atoi(yearMaxStr); err == nil {
			addFilter("year <= %s", yMax)
		}
	}

	// Fetch Total Count
	var total int
	err = database.DB.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to count listings: " + err.Error()})
		return
	}

	// Add ordering, limit, offset to the main query
	query += fmt.Sprintf(" ORDER BY created_at DESC LIMIT $%d OFFSET $%d", placeholderIdx, placeholderIdx+1)
	args = append(args, limit, offset)

	rows, err := database.DB.Query(query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch vehicles: " + err.Error()})
		return
	}
	defer rows.Close()

	vehicles := []models.Vehicle{}
	for rows.Next() {
		var v models.Vehicle
		var imageURLs pq.StringArray
		var taxExpiry time.Time

		err := rows.Scan(
			&v.ID, &v.Make, &v.Model, &v.Year, &v.Price, &v.Transmission,
			&v.FuelType, &v.Mileage, &v.EngineCapacity, &v.Color, &v.PlateType,
			&v.TaxStatus, &taxExpiry, &v.Location, &v.InspectionEngine,
			&v.InspectionInterior, &v.InspectionExterior, &v.InspectionNotes,
			&v.Status, &imageURLs, &v.CreatedAt, &v.UpdatedAt,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error parsing vehicles: " + err.Error()})
			return
		}

		v.TaxExpiryDate = taxExpiry.Format("2006-01-02")
		v.ImageURLs = database.ConvertPQArray(imageURLs)
		vehicles = append(vehicles, v)
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  vehicles,
		"page":  page,
		"limit": limit,
		"total": total,
	})
}

// GetVehicleByID fetches a single vehicle listing by its unique ID.
func (h *Handler) GetVehicleByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vehicle ID format"})
		return
	}

	query := `SELECT id, make, model, year, price, transmission, fuel_type, mileage, 
	                 engine_capacity, color, plate_type, tax_status, tax_expiry_date, 
	                 location, inspection_engine, inspection_interior, inspection_exterior, 
	                 inspection_notes, status, image_urls, created_at, updated_at 
	          FROM vehicles WHERE id = $1`

	row := database.DB.QueryRow(query, id)
	v, err := database.QueryRowScanVehicle(row)
	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vehicle listing not found"})
		return
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, v)
}

// CreateVehicle inserts a new vehicle listing into the database.
func (h *Handler) CreateVehicle(c *gin.Context) {
	var req models.Vehicle
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	taxExpiry, err := time.Parse("2006-01-02", req.TaxExpiryDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid tax expiry date format (use YYYY-MM-DD)"})
		return
	}

	if req.Status == "" {
		req.Status = "Available"
	}
	if req.ImageURLs == nil {
		req.ImageURLs = []string{}
	}

	query := `INSERT INTO vehicles (
		make, model, year, price, transmission, fuel_type, mileage, engine_capacity,
		color, plate_type, tax_status, tax_expiry_date, location,
		inspection_engine, inspection_interior, inspection_exterior, inspection_notes,
		status, image_urls, created_at, updated_at
	) VALUES (
		$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, NOW(), NOW()
	) RETURNING id`

	var newID int
	err = database.DB.QueryRow(
		query, req.Make, req.Model, req.Year, req.Price, req.Transmission, req.FuelType,
		req.Mileage, req.EngineCapacity, req.Color, req.PlateType, req.TaxStatus,
		taxExpiry, req.Location, req.InspectionEngine, req.InspectionInterior,
		req.InspectionExterior, req.InspectionNotes, req.Status, pq.Array(req.ImageURLs),
	).Scan(&newID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create vehicle listing: " + err.Error()})
		return
	}

	// Fetch and return the newly created vehicle listing
	req.ID = newID
	req.CreatedAt = time.Now()
	req.UpdatedAt = time.Now()
	c.JSON(http.StatusCreated, req)
}

// UpdateVehicle updates an existing vehicle listing.
func (h *Handler) UpdateVehicle(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vehicle ID format"})
		return
	}

	var req models.Vehicle
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	taxExpiry, err := time.Parse("2006-01-02", req.TaxExpiryDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid tax expiry date format (use YYYY-MM-DD)"})
		return
	}

	query := `UPDATE vehicles SET 
		make = $1, model = $2, year = $3, price = $4, transmission = $5, fuel_type = $6,
		mileage = $7, engine_capacity = $8, color = $9, plate_type = $10, tax_status = $11,
		tax_expiry_date = $12, location = $13, inspection_engine = $14, inspection_interior = $15,
		inspection_exterior = $16, inspection_notes = $17, status = $18, image_urls = $19, updated_at = NOW()
		WHERE id = $20`

	result, err := database.DB.Exec(
		query, req.Make, req.Model, req.Year, req.Price, req.Transmission, req.FuelType,
		req.Mileage, req.EngineCapacity, req.Color, req.PlateType, req.TaxStatus,
		taxExpiry, req.Location, req.InspectionEngine, req.InspectionInterior,
		req.InspectionExterior, req.InspectionNotes, req.Status, pq.Array(req.ImageURLs), id,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update listing: " + err.Error()})
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil || rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vehicle listing not found or no changes made"})
		return
	}

	// Fetch updated vehicle
	vQuery := `SELECT id, make, model, year, price, transmission, fuel_type, mileage, 
	                  engine_capacity, color, plate_type, tax_status, tax_expiry_date, 
	                  location, inspection_engine, inspection_interior, inspection_exterior, 
	                  inspection_notes, status, image_urls, created_at, updated_at 
	           FROM vehicles WHERE id = $1`
	row := database.DB.QueryRow(vQuery, id)
	v, err := database.QueryRowScanVehicle(row)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch updated listing details"})
		return
	}

	c.JSON(http.StatusOK, v)
}

// DeleteVehicle removes a vehicle listing from the database.
func (h *Handler) DeleteVehicle(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid vehicle ID format"})
		return
	}

	query := "DELETE FROM vehicles WHERE id = $1"
	result, err := database.DB.Exec(query, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete listing: " + err.Error()})
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil || rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vehicle listing not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Vehicle listing deleted successfully"})
}

// CreateTransaction records a new vehicle sale and marks the vehicle as Sold.
func (h *Handler) CreateTransaction(c *gin.Context) {
	// Extract admin username from JWT claims
	claimsRaw, exists := c.Get("claims")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	claims, ok := claimsRaw.(jwt.MapClaims)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token claims"})
		return
	}
	adminUsername, _ := claims["sub"].(string)

	var req models.CreateTransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate payment method
	validMethods := map[string]bool{"Cash": true, "KPR": true, "Leasing": true}
	if !validMethods[req.PaymentMethod] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid payment method. Use: Cash, KPR, or Leasing"})
		return
	}

	// Check vehicle exists and is available
	var vehicleStatus string
	err := database.DB.QueryRow("SELECT status FROM vehicles WHERE id = $1", req.VehicleID).Scan(&vehicleStatus)
	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Vehicle not found"})
		return
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error: " + err.Error()})
		return
	}
	if vehicleStatus != "Available" {
		c.JSON(http.StatusConflict, gin.H{"error": "Vehicle is not available for sale (status: " + vehicleStatus + ")"})
		return
	}

	// Execute in a transaction to ensure atomicity
	tx, err := database.DB.Begin()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start transaction"})
		return
	}
	defer tx.Rollback()

	// Insert the sales transaction
	var txID int64
	insertQuery := `INSERT INTO transactions 
		(vehicle_id, buyer_name, buyer_phone, buyer_id_number, payment_method, 
		 sale_price, down_payment, installment_months, installment_amount, notes, created_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING id`
	err = tx.QueryRow(insertQuery,
		req.VehicleID, req.BuyerName, req.BuyerPhone, req.BuyerIDNumber,
		req.PaymentMethod, req.SalePrice, req.DownPayment,
		req.InstallmentMonths, req.InstallmentAmount, req.Notes, adminUsername,
	).Scan(&txID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to record transaction: " + err.Error()})
		return
	}

	// Mark vehicle as Sold
	_, err = tx.Exec("UPDATE vehicles SET status = 'Sold', updated_at = NOW() WHERE id = $1", req.VehicleID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update vehicle status: " + err.Error()})
		return
	}

	if err = tx.Commit(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit transaction"})
		return
	}

	// Return full transaction details with vehicle info
	result, err := h.fetchTransactionByID(txID)
	if err != nil {
		c.JSON(http.StatusCreated, gin.H{"message": "Transaction recorded successfully", "id": txID})
		return
	}
	c.JSON(http.StatusCreated, result)
}

// GetTransactions returns all transactions with vehicle info, paginated.
func (h *Handler) GetTransactions(c *gin.Context) {
	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "20")
	page, _ := strconv.Atoi(pageStr)
	limit, _ := strconv.Atoi(limitStr)
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	var total int
	database.DB.QueryRow("SELECT COUNT(*) FROM transactions").Scan(&total)

	query := `SELECT t.id, t.vehicle_id, v.make, v.model, v.year, v.color,
		t.buyer_name, t.buyer_phone, t.buyer_id_number, t.payment_method,
		t.sale_price, t.down_payment, t.installment_months, t.installment_amount,
		t.notes, t.created_by, t.sold_at
		FROM transactions t
		JOIN vehicles v ON t.vehicle_id = v.id
		ORDER BY t.sold_at DESC
		LIMIT $1 OFFSET $2`

	rows, err := database.DB.Query(query, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch transactions: " + err.Error()})
		return
	}
	defer rows.Close()

	transactions := []models.Transaction{}
	for rows.Next() {
		var t models.Transaction
		if err := rows.Scan(
			&t.ID, &t.VehicleID, &t.VehicleMake, &t.VehicleModel, &t.VehicleYear, &t.VehicleColor,
			&t.BuyerName, &t.BuyerPhone, &t.BuyerIDNumber, &t.PaymentMethod,
			&t.SalePrice, &t.DownPayment, &t.InstallmentMonths, &t.InstallmentAmount,
			&t.Notes, &t.CreatedBy, &t.SoldAt,
		); err != nil {
			continue
		}
		transactions = append(transactions, t)
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  transactions,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

// GetTransactionByID returns a single transaction by ID.
func (h *Handler) GetTransactionByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid transaction ID"})
		return
	}
	t, err := h.fetchTransactionByID(id)
	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Transaction not found"})
		return
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, t)
}

// fetchTransactionByID is a shared helper to fetch full transaction details.
func (h *Handler) fetchTransactionByID(id int64) (*models.Transaction, error) {
	query := `SELECT t.id, t.vehicle_id, v.make, v.model, v.year, v.color,
		t.buyer_name, t.buyer_phone, t.buyer_id_number, t.payment_method,
		t.sale_price, t.down_payment, t.installment_months, t.installment_amount,
		t.notes, t.created_by, t.sold_at
		FROM transactions t
		JOIN vehicles v ON t.vehicle_id = v.id
		WHERE t.id = $1`
	var t models.Transaction
	err := database.DB.QueryRow(query, id).Scan(
		&t.ID, &t.VehicleID, &t.VehicleMake, &t.VehicleModel, &t.VehicleYear, &t.VehicleColor,
		&t.BuyerName, &t.BuyerPhone, &t.BuyerIDNumber, &t.PaymentMethod,
		&t.SalePrice, &t.DownPayment, &t.InstallmentMonths, &t.InstallmentAmount,
		&t.Notes, &t.CreatedBy, &t.SoldAt,
	)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

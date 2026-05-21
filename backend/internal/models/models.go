package models

import "time"

// Admin represents a dealership staff user who can manage inventory.
type Admin struct {
	ID           int       `json:"id" db:"id"`
	Username     string    `json:"username" db:"username"`
	PasswordHash string    `json:"-" db:"password_hash"`
	Name         string    `json:"name" db:"name"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
}

// Vehicle represents a used car listing in our inventory.
type Vehicle struct {
	ID                 int       `json:"id" db:"id"`
	Make               string    `json:"make" db:"make" binding:"required"`
	Model              string    `json:"model" db:"model" binding:"required"`
	Year               int       `json:"year" db:"year" binding:"required"`
	Price              int64     `json:"price" db:"price" binding:"required"`
	Transmission       string    `json:"transmission" db:"transmission" binding:"required"`
	FuelType           string    `json:"fuel_type" db:"fuel_type" binding:"required"`
	Mileage            int       `json:"mileage" db:"mileage" binding:"required"`
	EngineCapacity     int       `json:"engine_capacity" db:"engine_capacity" binding:"required"`
	Color              string    `json:"color" db:"color" binding:"required"`
	PlateType          string    `json:"plate_type" db:"plate_type" binding:"required"`
	TaxStatus          string    `json:"tax_status" db:"tax_status" binding:"required"`
	TaxExpiryDate      string    `json:"tax_expiry_date" db:"tax_expiry_date" binding:"required"`
	Location           string    `json:"location" db:"location" binding:"required"`
	InspectionEngine   int       `json:"inspection_engine" db:"inspection_engine"`
	InspectionInterior int       `json:"inspection_interior" db:"inspection_interior"`
	InspectionExterior int       `json:"inspection_exterior" db:"inspection_exterior"`
	InspectionNotes    string    `json:"inspection_notes" db:"inspection_notes"`
	Status             string    `json:"status" db:"status"` // 'Available', 'Reserved', 'Sold'
	ImageURLs          []string  `json:"image_urls" db:"image_urls"`
	CreatedAt          time.Time `json:"created_at" db:"created_at"`
	UpdatedAt          time.Time `json:"updated_at" db:"updated_at"`
}

// LoginRequest defines the expected fields for admin authentication.
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// LoginResponse defines the JWT token response.
type LoginResponse struct {
	Token string `json:"token"`
	Name  string `json:"name"`
}

// Transaction represents a completed vehicle sale transaction.
type Transaction struct {
	ID                int64     `json:"id"`
	VehicleID         int       `json:"vehicle_id"`
	VehicleMake       string    `json:"vehicle_make"`
	VehicleModel      string    `json:"vehicle_model"`
	VehicleYear       int       `json:"vehicle_year"`
	VehicleColor      string    `json:"vehicle_color"`
	BuyerName         string    `json:"buyer_name"`
	BuyerPhone        string    `json:"buyer_phone"`
	BuyerIDNumber     string    `json:"buyer_id_number"`
	PaymentMethod     string    `json:"payment_method"`
	SalePrice         int64     `json:"sale_price"`
	DownPayment       int64     `json:"down_payment"`
	InstallmentMonths int       `json:"installment_months"`
	InstallmentAmount int64     `json:"installment_amount"`
	Notes             string    `json:"notes"`
	CreatedBy         string    `json:"created_by"`
	SoldAt            time.Time `json:"sold_at"`
}

// CreateTransactionRequest is the body for creating a new POS transaction.
type CreateTransactionRequest struct {
	VehicleID         int    `json:"vehicle_id" binding:"required"`
	BuyerName         string `json:"buyer_name" binding:"required"`
	BuyerPhone        string `json:"buyer_phone" binding:"required"`
	BuyerIDNumber     string `json:"buyer_id_number" binding:"required"`
	PaymentMethod     string `json:"payment_method" binding:"required"`
	SalePrice         int64  `json:"sale_price" binding:"required"`
	DownPayment       int64  `json:"down_payment"`
	InstallmentMonths int    `json:"installment_months"`
	InstallmentAmount int64  `json:"installment_amount"`
	Notes             string `json:"notes"`
}

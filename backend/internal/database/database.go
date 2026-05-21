package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"time"

	"backend/internal/models"

	"github.com/lib/pq"
	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

var DB *sql.DB

// InitDB initializes connection to the Postgres database with retries.
func InitDB() {
	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "5432")
	user := getEnv("DB_USER", "postgres")
	password := getEnv("DB_PASSWORD", "postgres")
	dbname := getEnv("DB_NAME", "used_car_dealership")

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	var err error
	for i := 1; i <= 10; i++ {
		log.Printf("Connecting to database (attempt %d/10)...", i)
		DB, err = sql.Open("postgres", connStr)
		if err == nil {
			err = DB.Ping()
			if err == nil {
				log.Println("Successfully connected to database")
				break
			}
		}
		log.Printf("Database connection failed: %v. Retrying in 3 seconds...", err)
		time.Sleep(3 * time.Second)
	}

	if err != nil {
		log.Fatalf("Could not connect to database: %v", err)
	}

	seedDefaultAdmin()
}

// seedDefaultAdmin checks if the admins table is empty and seeds a default admin.
func seedDefaultAdmin() {
	var count int
	err := DB.QueryRow("SELECT COUNT(*) FROM admins").Scan(&count)
	if err != nil {
		log.Printf("Warning: Failed to check admins count: %v", err)
		return
	}

	if count == 0 {
		log.Println("No admin users found. Seeding default admin user...")
		username := "admin"
		password := "admin"
		name := "Dealership Manager"

		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
		if err != nil {
			log.Fatalf("Failed to hash default admin password: %v", err)
		}

		_, err = DB.Exec(
			"INSERT INTO admins (username, password_hash, name) VALUES ($1, $2, $3)",
			username, string(hashedPassword), name,
		)
		if err != nil {
			log.Printf("Warning: Failed to seed default admin: %v", err)
		} else {
			log.Printf("Successfully seeded default admin user. Username: '%s', Password: '%s'", username, password)
		}
	}
}

// ConvertPQArray converts a pq.StringArray to a standard slice of strings.
func ConvertPQArray(arr pq.StringArray) []string {
	return []string(arr)
}

// QueryRowScanVehicle helper function to scan a single row into a Vehicle struct.
func QueryRowScanVehicle(row *sql.Row) (*models.Vehicle, error) {
	var v models.Vehicle
	var imageURLs pq.StringArray
	var taxExpiry time.Time

	err := row.Scan(
		&v.ID, &v.Make, &v.Model, &v.Year, &v.Price, &v.Transmission,
		&v.FuelType, &v.Mileage, &v.EngineCapacity, &v.Color, &v.PlateType,
		&v.TaxStatus, &taxExpiry, &v.Location, &v.InspectionEngine,
		&v.InspectionInterior, &v.InspectionExterior, &v.InspectionNotes,
		&v.Status, &imageURLs, &v.CreatedAt, &v.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	v.TaxExpiryDate = taxExpiry.Format("2006-01-02")
	v.ImageURLs = ConvertPQArray(imageURLs)
	return &v, nil
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}

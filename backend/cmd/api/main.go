package main

import (
	"log"
	"os"

	"backend/internal/database"
	"backend/internal/handlers"
	"backend/internal/middleware"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables from .env file if it exists
	_ = godotenv.Load("../../.env")
	_ = godotenv.Load(".env")

	log.Println("Starting Used Car Digital Storefront Backend...")

	// 1. Initialize Database
	database.InitDB()
	defer database.DB.Close()

	// 2. Setup JWT configuration
	jwtSecret := getEnv("JWT_SECRET", "super-secret-key-123")

	// 3. Setup Handlers
	h := handlers.NewHandler(jwtSecret)

	// 4. Setup Router
	router := gin.Default()

	// Apply CORS middleware globally
	router.Use(middleware.CORSMiddleware())

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "UP"})
	})

	// Public API routes
	api := router.Group("/api")
	{
		// Serve uploaded images statically
		api.Static("/uploads", "./uploads")

		api.POST("/admin/login", h.Login)
		api.GET("/vehicles", h.GetVehicles)
		api.GET("/vehicles/:id", h.GetVehicleByID)

		// Protected API routes (require JWT)
		protected := api.Group("")
		protected.Use(middleware.AuthMiddleware([]byte(jwtSecret)))
		{
			protected.POST("/vehicles", h.CreateVehicle)
			protected.PUT("/vehicles/:id", h.UpdateVehicle)
			protected.DELETE("/vehicles/:id", h.DeleteVehicle)

			protected.POST("/upload", h.UploadImages)

			// POS / Transactions
			protected.POST("/transactions", h.CreateTransaction)
			protected.GET("/transactions", h.GetTransactions)
			protected.GET("/transactions/:id", h.GetTransactionByID)
		}
	}

	// 5. Start Server
	port := getEnv("PORT", "8080")
	log.Printf("Server is running on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Server failed to run: %v", err)
	}
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}

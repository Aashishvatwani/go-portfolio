package main

import (
	"log"
	"os"

	"github.com/Aashishvatwani/newproject32/routes"
	"github.com/Aashishvatwani/newproject32/utils"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}
	// fail fast when JWT_SECRET is missing to avoid runtime errors for auth
	if os.Getenv("JWT_SECRET") == "" {
		log.Fatal("Missing required environment variable: JWT_SECRET. Please set it in your environment or .env file.")
	}

	// ensure DB_NAME is set; handlers assume a non-empty database name
	if os.Getenv("DB_NAME") == "" {
		log.Fatal("Missing required environment variable: DB_NAME. Please set it in your environment or .env file to your MongoDB database name.")
	}

	utils.InitMongo()

	r := gin.Default()

	// Prevent automatic redirects between trailing-slash variants which can
	// interfere with CORS preflight and cause extra 301/307 logs.
	r.RedirectTrailingSlash = false
	r.HandleMethodNotAllowed = true
	// Use a single explicit CORS configuration that includes Authorization in allowed headers
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:3000"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		AllowCredentials: true,
	}))
	routes.RegisterRoutes(r)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	r.Run(":" + port)
}

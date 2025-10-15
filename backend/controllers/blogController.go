package controllers

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/Aashishvatwani/newproject32/models"
	"github.com/Aashishvatwani/newproject32/utils"

	"strings"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func CreateBlog(c *gin.Context) {
	// Authentication: require valid bearer token
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "missing or invalid authorization header"})
		return
	}
	token := strings.TrimPrefix(authHeader, "Bearer ")
	if _, err := utils.ValidateToken(token); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
		return
	}
	_ = godotenv.Load()
	dbName := os.Getenv("DB_NAME")
	collection := utils.Client.Database(dbName).Collection("blogs")

	title := c.PostForm("title")
	description := c.PostForm("description")

	// Check if frontend uploaded image directly to Cloudinary and sent image_url
	imageURL := c.PostForm("image_url")

	// Or accept file upload and upload server-side
	file, err := c.FormFile("image")
	if imageURL == "" && err == nil {
		// save temp file
		tempPath := fmt.Sprintf("/tmp/%s", file.Filename)
		if err := c.SaveUploadedFile(file, tempPath); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "failed to save uploaded file"})
			return
		}
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		uploadedURL, err := utils.UploadToCloudinary(ctx, tempPath)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "cloudinary upload failed"})
			return
		}
		imageURL = uploadedURL
	}

	if title == "" || description == "" || imageURL == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "title, description and image are required"})
		return
	}

	blog := models.Blog{
		ID:          primitive.NewObjectID(),
		Title:       title,
		Description: description,
		ImageURL:    imageURL,
		CreatedAt:   time.Now(),
	}

	res, err := collection.InsertOne(context.Background(), blog)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to insert blog"})
		return
	}

	// set the inserted ID on the response object if needed
	if oid, ok := res.InsertedID.(primitive.ObjectID); ok {
		blog.ID = oid
	}

	// cleanup temp file if it was created
	if file != nil {
		tempPath := filepath.Join(os.TempDir(), file.Filename)
		_ = os.Remove(tempPath)
	}

	c.JSON(http.StatusCreated, blog)
}

func GetAllBlogs(c *gin.Context) {
	_ = godotenv.Load()
	dbName := os.Getenv("DB_NAME")
	collection := utils.Client.Database(dbName).Collection("blogs")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cursor, err := collection.Find(ctx, bson.D{})
	if err != nil {
		log.Printf("GetAllBlogs: collection.Find error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch blogs"})
		return
	}
	defer cursor.Close(ctx)

	var blogs []models.Blog
	if err := cursor.All(ctx, &blogs); err != nil {
		log.Printf("GetAllBlogs: cursor.All error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to decode blogs"})
		return
	}
	c.JSON(http.StatusOK, blogs)
}

func GetBlogByID(c *gin.Context) {
	id := c.Param("id")
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	_ = godotenv.Load()
	dbName := os.Getenv("DB_NAME")
	collection := utils.Client.Database(dbName).Collection("blogs")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	var blog models.Blog
	if err := collection.FindOne(ctx, bson.M{"_id": oid}).Decode(&blog); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "blog not found"})
		return
	}
	c.JSON(http.StatusOK, blog)
}

func DeleteBlog(c *gin.Context) {
	id := c.Param("id")
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	_ = godotenv.Load()
	dbName := os.Getenv("DB_NAME")
	collection := utils.Client.Database(dbName).Collection("blogs")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	res, err := collection.DeleteOne(ctx, bson.M{"_id": oid})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete blog"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"deletedCount": res.DeletedCount})
}

func GetBlogsByDate(c *gin.Context) {
	// expected date format: YYYY-MM-DD
	dateStr := c.Param("date")
	t, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid date format, expected YYYY-MM-DD"})
		return
	}
	start := time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, t.Location())
	end := start.Add(24 * time.Hour)

	_ = godotenv.Load()
	dbName := os.Getenv("DB_NAME")
	collection := utils.Client.Database(dbName).Collection("blogs")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	filter := bson.M{"created_at": bson.M{"$gte": start, "$lt": end}}
	cursor, err := collection.Find(ctx, filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch blogs by date"})
		return
	}
	defer cursor.Close(ctx)

	var blogs []models.Blog
	if err := cursor.All(ctx, &blogs); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to decode blogs"})
		return
	}
	c.JSON(http.StatusOK, blogs)
}

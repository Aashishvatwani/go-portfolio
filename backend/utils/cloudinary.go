package utils

import (
	"context"
	"fmt"
	"os"

	cld "github.com/cloudinary/cloudinary-go/v2"
	"github.com/cloudinary/cloudinary-go/v2/api/uploader"
	"github.com/joho/godotenv"
)

func UploadToCloudinary(ctx context.Context, filePath string) (string, error) {
	if err := godotenv.Load(); err != nil {
		// ignore
	}
	cloudName := os.Getenv("CLOUDINARY_CLOUD_NAME")
	apiKey := os.Getenv("CLOUDINARY_API_KEY")
	apiSecret := os.Getenv("CLOUDINARY_API_SECRET")

	cldURL := fmt.Sprintf("cloudinary://%s:%s@%s", apiKey, apiSecret, cloudName)
	c, err := cld.NewFromURL(cldURL)
	if err != nil {
		return "", err
	}

	resp, err := c.Upload.Upload(ctx, filePath, uploader.UploadParams{Folder: "portfolio_blogs"})
	if err != nil {
		return "", err
	}
	return resp.SecureURL, nil
}

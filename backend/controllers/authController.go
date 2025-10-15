package controllers

import (
	"net/http"
	"os"
	"time"

	"log"

	"github.com/Aashishvatwani/newproject32/utils"
	"github.com/gin-gonic/gin"
)

type loginReq struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

func AdminLogin(c *gin.Context) {
	log.Printf("AdminLogin: request from %s", c.ClientIP())
	var req loginReq
	if err := c.BindJSON(&req); err != nil {
		log.Printf("AdminLogin: error binding JSON from %s: %v", c.ClientIP(), err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	log.Printf("AdminLogin: attempt for username=%s from %s", req.Username, c.ClientIP())
	adminUser := os.Getenv("ADMIN_USER")
	adminPass := os.Getenv("ADMIN_PASS")
	if adminUser == "" || adminPass == "" {
		log.Printf("AdminLogin: ADMIN_USER or ADMIN_PASS not set in environment")
	}

	if req.Username != adminUser || req.Password != adminPass {
		log.Printf("AdminLogin: invalid credentials for username=%s from %s", req.Username, c.ClientIP())
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	token, err := utils.GenerateToken(req.Username, 24*time.Hour)
	if err != nil {
		log.Printf("AdminLogin: error generating token for username=%s: %v", req.Username, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
		return
	}

	log.Printf("AdminLogin: successful login for username=%s from %s", req.Username, c.ClientIP())
	c.JSON(http.StatusOK, gin.H{"token": token})
}

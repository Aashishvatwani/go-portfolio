package routes

import (
	"github.com/Aashishvatwani/newproject32/controllers"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(r *gin.Engine) {
	api := r.Group("/api")
	{
		api.POST("/login", controllers.AdminLogin)

		blog := api.Group("/blogs")
		{
			blog.POST("", controllers.CreateBlog)
			blog.GET("", controllers.GetAllBlogs)
			blog.GET("/:id", controllers.GetBlogByID)
			blog.DELETE("/:id", controllers.DeleteBlog)
			blog.GET("date/:date", controllers.GetBlogsByDate)
		}
	}
}

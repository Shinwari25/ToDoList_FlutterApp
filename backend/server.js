import express from "express";
import mongoose from "mongoose";
import userRoutes from "./routes/user.routes.js";
import todoRoutes from "./routes/todo.routes.js";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();
mongoose
  .connect(process.env.MONGO)
  .then(() => {
    console.log("MongoDB connected");
  })
  .catch((error) => {
    console.log("MongoDB connection error:", error);
    process.exit(1);
  });

const app = express();

// Middleware should be registered before routes
app.use(express.json());
// In your Express backend (server.js)
app.use(
  cors({
    origin: true, // Allow all origins
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  }),
);
app.get("/", (req, res) => {
  res.send("this is the homepage");
});

// Mount routes
app.use("/", userRoutes);
app.use("/", todoRoutes);

// Error handler (keep after routes)
app.use((err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  const message = err.message || "Internal Server Error";
  res.status(statusCode).json({
    success: false,
    statusCode,
    message,
  });
});

// Start server after routes and middleware registered
app.listen(5000, () => {
  console.log("server is running on port 5000");
});

import ToDoModel from "../models/todo.model.js"; // Ensure ToDoModel is imported
export const createToDo = async (req, res, next) => {
  try {
    const { userId, title, desc } = req.body;

    if (!userId || !title || !desc) {
      return res.status(400).json({
        status: false,
        message: "All fields (userId, title, desc) are required",
        received: { userId, title, desc },
      });
    }
    const newToDo = new ToDoModel({
      userId: userId,
      title: title.trim(),
      description: desc.trim(),
    });

    const savedToDo = await newToDo.save();

    res.status(201).json({
      status: true,
      success: savedToDo,
      message: "Todo created successfully",
    });
  } catch (error) {
    res.status(500).json({
      status: false,
      message: error.message,
      error: "Database error occurred",
    });
  }
};

export const getToDoList = async (req, res, next) => {
  try {
    const userId = req.query.userId;
    let todoData = await ToDoModel.find({ userId });
    res.json({ status: true, success: todoData });
    console.log("📥 todo data:", { todoData });
  } catch (error) {
    console.log(error, "err---->");
    next(error);
  }
};

export const deleteToDo = async (req, res, next) => {
  try {
    const id = req.body.id;
    let deletedData = await ToDoModel.findByIdAndDelete({ _id: id });
    res.json({ status: true, success: deletedData });
  } catch (error) {
    next(error);
  }
};

export const toggleTodo = async (req, res, next) => {
  try {
    const { id } = req.body;

    // Validate ID
    if (!id || id.trim() === "") {
      return res.status(400).json({
        status: false,
        message: "Todo ID is required",
      });
    }

    // Find the current todo
    const currentTodo = await ToDoModel.findById(id);

    if (!currentTodo) {
      return res.status(404).json({
        status: false,
        message: "Todo not found",
      });
    }

    const newCompletedStatus = !currentTodo.completed;

    // Prepare update data
    const updateData = {
      completed: newCompletedStatus,
      completedAt: newCompletedStatus ? new Date() : null, // Set timestamp if completed, null if unchecked
    };

    // Update the todo
    const updatedTodo = await ToDoModel.findByIdAndUpdate(id, updateData, {
      new: true, // Return the updated document
      runValidators: true, // Validate the update
    });

    res.json({
      status: true,
      success: updatedTodo,
      message: `Todo marked as ${
        updatedTodo.completed ? "completed" : "incomplete"
      }`,
      data: {
        id: updatedTodo._id,
        completed: updatedTodo.completed,
        completedAt: updatedTodo.completedAt,
        updatedAt: updatedTodo.updatedAt,
      },
    });
  } catch (error) {
    // Handle different types of errors
    if (error.name === "CastError") {
      return res.status(400).json({
        status: false,
        message: "Invalid todo ID format",
      });
    }

    if (error.name === "ValidationError") {
      return res.status(400).json({
        status: false,
        message: "Validation failed",
        errors: error.errors,
      });
    }

    res.status(500).json({
      status: false,
      message: error.message || "Failed to toggle todo status",
      error: process.env.NODE_ENV === "development" ? error.stack : undefined,
    });
  }
};

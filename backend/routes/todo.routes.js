import express from "express";
import {
  createToDo,
  deleteToDo,
  getToDoList,
  toggleTodo,
} from "../controllers/todo.controller.js";

const router = express.Router();

router.post("/createToDo", createToDo);
router.get("/getUserTodoList", getToDoList);
router.post("/deleteTodo", deleteToDo);
router.post("/toggleTodo", toggleTodo);

export default router;

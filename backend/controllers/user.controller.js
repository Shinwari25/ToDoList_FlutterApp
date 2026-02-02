import User from "../models/user.model.js";
import bcryptjs from "bcryptjs";
import { errorHandler } from "../utils/error.js";
import { generateToken } from "../utils/token.js";

export const signup = async (req, res, next) => {
  const { email, password } = req.body;

  if (
    // !username ||
    !email ||
    !password ||
    // username === "" ||
    email === "" ||
    password === ""
  ) {
    return next(errorHandler(400, "All fields are required"));
  }

  const existing = await User.findOne({ email });
  if (existing)
    return res
      .status(400)
      .json({ success: false, message: "User already exists" });
  const hashedPassword = bcryptjs.hashSync(password, 10);

  const newUser = new User({
    email,
    password: hashedPassword,
  });

  try {
    await newUser.save();
    // res.json('Signup succesful');
    res.status(201).json({ success: true, message: "Signup successful" });
  } catch (error) {
    // res.status(500).jason({message: error.message});
    next(error);
  }
};

export const signin = async (req, res, next) => {
  const { email, password } = req.body;

  if (!email || !password || email === "" || password === "") {
    return res.status(400).json({
      success: false,
      message: "All fields are required",
    });
  }

  try {
    const validUser = await User.findOne({ email });

    if (!validUser) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const validPassword = bcryptjs.compareSync(password, validUser.password);

    if (!validPassword) {
      return res.status(400).json({
        success: false,
        message: "Invalid password",
      });
    }

    let tokenData = { id: validUser._id, email: validUser.email };
    const token = generateToken(tokenData, process.env.JWT_SECRET, "7d");

    res.status(200).json({
      success: true,
      message: "Login successful",
      token: token,
    });
  } catch (error) {
    console.error("Signin error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
};

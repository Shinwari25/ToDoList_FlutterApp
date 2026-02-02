import jwt from "jsonwebtoken";
export const generateToken = (tokenData, secretKey, jwtExpiresIn) => {
  return jwt.sign(tokenData, secretKey, { expiresIn: jwtExpiresIn });
};

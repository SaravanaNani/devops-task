# Use official Node.js runtime
FROM node:18-alpine

# Set working directory inside container
WORKDIR /usr/src/app

# Copy package.json & install dependencies
COPY package*.json ./
RUN npm install

# Copy the app source code
COPY . .

# Expose app port
EXPOSE 3000

# Start the app
CMD ["node", "app.js"]

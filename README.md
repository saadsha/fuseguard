# FuseGuard Web Application

FuseGuard is a real-time transformer and fuse monitoring system built with a Node.js/MongoDB backend and a Flutter Web frontend. 

It provides real-time alerts and live dashboards for Admins and Maintenance Engineers to track the health of electrical transformers and their fuses.

## Prerequisites
Before running this project, ensure you have the following installed on your machine:
*   [Node.js](https://nodejs.org/) (v16 or higher)
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (configured for Web development)
*   [MongoDB](https://www.mongodb.com/try/download/community) (running locally, or a remote MongoDB URI)

---

## 1. Running the Backend Server

The backend acts as the central API, database manager, and WebSocket broadcaster.

1.  Open a terminal and navigate to the backend directory:
    ```bash
    cd backend
    ```
2.  Install the required Node.js dependencies:
    ```bash
    npm install
    ```
3.  Ensure your environment variables are configured. Create a `.env` file in the `backend` folder (if it doesn't exist) with:
    ```env
    PORT=5000
    MONGO_URI=mongodb://127.0.0.1:27017/fuseguard
    JWT_SECRET=your_super_secret_jwt_key
    ```
4.  Optionally, populate the database with test users. We have helper scripts for this:
    ```bash
    node create_admin.js
    node create_engineer.js
    node create_viewer.js
    ```
5.  Start the backend server:
    ```bash
    node index.js
    ```
    *(The server will start on port 5000 by default and confirm the MongoDB connection).*

---

## 2. Running the Frontend Web App

The frontend is a Flutter Web application that connects to the backend API and listens for real-time Socket.io events.

1.  Open a NEW terminal and navigate to the frontend directory:
    ```bash
    cd frontend
    ```
2.  Install the Flutter dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the application in the Chrome browser:
    ```bash
    flutter run -d chrome
    ```
    *(Flutter will compile the Dart code and launch a new Chrome window natively. You can log in using the accounts generated in step 1.4).*

---

## 3. Running the Hardware Simulator

If you do not have physical NodeMCU hardware connected to send live sensor data, you can use our built-in interactive terminal simulator.

1.  Open a NEW terminal and navigate to the backend directory:
    ```bash
    cd backend
    ```
2.  Start the interactive simulator script:
    ```bash
    node interactive_simulator.js
    ```
3.  The console will begin sending simulated telemetry data to the backend API every 3 seconds. To simulate a blown fuse, simply press the `f` key in that terminal window. You will see the real-time alerts trigger on the Flutter dashboard instantly!

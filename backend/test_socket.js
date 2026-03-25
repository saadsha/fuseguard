import { io } from "socket.io-client";

const socket = io("http://192.168.1.34:5000", { transports: ["websocket"] });

socket.on("connect", () => {
  console.log("Connected to backend! Socket ID:", socket.id);
  console.log("Waiting for 'transformerUpdate' event...");
});

socket.on("transformerUpdate", (data) => {
  console.log("\\n--- RECEIVED transformerUpdate ---");
  console.log(JSON.stringify(data, null, 2));
  console.log("----------------------------------\\n");
  process.exit(0);
});

socket.on("connect_error", (err) => {
  console.error("Connection error:", err.message);
});

// Timeout after 15 seconds
setTimeout(() => {
  console.log("Timeout waiting for event.");
  process.exit(1);
}, 15000);

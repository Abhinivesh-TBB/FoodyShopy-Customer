importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyChDzyF8zFVXV2KbSoxNC-JubwYQewIjgI",
  authDomain: "customer-app-abhi.firebaseapp.com",
  projectId: "customer-app-abhi",
  storageBucket: "customer-app-abhi.firebasestorage.app",
  messagingSenderId: "214805452047",
  appId: "1:214805452047:web:f8e3b62b5f5b07e4a35a7a"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log("Received background message: ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: payload.notification.icon || "/favicon.png"
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDdVBrcwkQzcu3YgHaUUrUZA4L_8pZC4wk",
  authDomain: "e-commerce-app-34fb2.firebaseapp.com",
  projectId: "e-commerce-app-34fb2",
  storageBucket: "e-commerce-app-34fb2.firebasestorage.app",
  messagingSenderId: "944685668832",
  appId: "1:944685668832:web:cc5abf2cac157833eaf385"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const title = payload.notification ? payload.notification.title : (payload.data ? payload.data.title : '팽이초콜릿 알림');
  const options = {
    body: payload.notification ? payload.notification.body : (payload.data ? payload.data.body : ''),
    icon: '/favicon.png'
  };

  self.registration.showNotification(title, options);
});

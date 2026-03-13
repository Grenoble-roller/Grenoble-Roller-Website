// PWA Service Worker - Grenoble Roller
// Enregistré depuis application.js ; permet une expérience plus fiable (activation immédiate).

self.addEventListener("install", (event) => {
  self.skipWaiting()
})

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim())
})

// Web Push (désactivé par défaut ; décommenter si utilisé plus tard)
// self.addEventListener("push", async (event) => {
//   const { title, options } = await event.data.json()
//   event.waitUntil(self.registration.showNotification(title, options))
// })
// self.addEventListener("notificationclick", (event) => {
//   event.notification.close()
//   event.waitUntil(
//     clients.matchAll({ type: "window" }).then((clientList) => {
//       for (let i = 0; i < clientList.length; i++) {
//         const client = clientList[i]
//         const clientPath = (new URL(client.url)).pathname
//         if (clientPath === event.notification.data?.path && "focus" in client) return client.focus()
//       }
//       if (clients.openWindow) return clients.openWindow(event.notification.data?.path || "/")
//     })
//   )
// })

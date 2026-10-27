// =============================================================================
// CARROM CHAMPIONS - UNIFIED FRONTEND & MULTIPLAYER WEBSOCKET SERVER
// Serves static HTML5 game assets AND handles real-time 2-4 player lobbies.
// Compatible with Local Testing, Wi-Fi LAN devices, and Google Cloud Run.
// =============================================================================

const http = require('http');
const path = require('path');
const fs = require('fs');
const os = require('os');
const { WebSocketServer, WebSocket } = require('ws');

// In GCP Cloud Run, PORT is automatically injected by the environment (default 8080)
// For local Windows testing, default to 3000
const PORT = process.env.PORT || 3000;
const STATIC_ROOT = path.resolve(__dirname, '..');

// MIME types dictionary for static file serving
const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.ico': 'image/x-icon',
  '.svg': 'image/svg+xml',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
  '.wasm': 'application/wasm'
};

// Helper: Get local IPv4 address for LAN testing
function getLocalIp() {
  const ifaces = os.networkInterfaces();
  for (const name of Object.keys(ifaces)) {
    for (const net of ifaces[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return 'localhost';
}

// -----------------------------------------------------------------------------
// 1. HTTP Server: Serves frontend & handles health checks
// -----------------------------------------------------------------------------
const server = http.createServer((req, res) => {
  // CORS & Security headers for game engine
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');
  res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // API Health Check
  if (req.url === '/api/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'online',
      service: 'Carrom Champions Unified Server',
      activeRooms: Object.keys(rooms).length,
      uptime: process.uptime()
    }));
    return;
  }

  // Clean request path
  let reqPath = decodeURI(req.url.split('?')[0]);
  if (reqPath === '/' || reqPath === '') {
    reqPath = '/index.html';
  }

  const safePath = path.normalize(reqPath).replace(/^(\.\.[\/\\])+/, '');
  const filePath = path.join(STATIC_ROOT, safePath);

  // Check if file exists within STATIC_ROOT
  if (!filePath.startsWith(STATIC_ROOT)) {
    res.writeHead(403, { 'Content-Type': 'text/plain' });
    res.end('403 Forbidden');
    return;
  }

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      // Fallback: If requesting HTML-like route, serve index.html (SPA fallback)
      const indexPath = path.join(STATIC_ROOT, 'index.html');
      fs.readFile(indexPath, (readErr, data) => {
        if (readErr) {
          res.writeHead(404, { 'Content-Type': 'text/plain' });
          res.end('404 Not Found');
        } else {
          res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
          res.end(data);
        }
      });
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    res.writeHead(200, {
      'Content-Type': contentType,
      'Content-Length': stats.size,
      'Cache-Control': 'no-cache'
    });

    const stream = fs.createReadStream(filePath);
    stream.pipe(res);
  });
});

// -----------------------------------------------------------------------------
// 2. WebSocket Server: Multi-Player 2-4 Room Matchmaking & Synchronization
// -----------------------------------------------------------------------------
const wss = new WebSocketServer({ server });

// Room Store: rooms[roomCode] = { code, playerCount, isFun, variant, hostId, players: [], matchStarted: false }
const rooms = {};

function generateRoomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 4; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return rooms[code] ? generateRoomCode() : code;
}

function broadcastToRoom(roomCode, message, skipClient = null) {
  const room = rooms[roomCode];
  if (!room) return;
  const data = JSON.stringify(message);
  room.players.forEach(p => {
    if (p.ws !== skipClient && p.ws.readyState === WebSocket.OPEN) {
      p.ws.send(data);
    }
  });
}

wss.on('connection', (ws, req) => {
  const clientIp = req.socket.remoteAddress;
  let playerSession = {
    id: 'user_' + Math.random().toString(36).substring(2, 9),
    roomCode: null,
    slot: null,
    name: 'Player',
    isHost: false
  };

  // Send initial welcome & server status
  ws.send(JSON.stringify({
    type: 'WELCOME',
    playerId: playerSession.id,
    serverUptime: process.uptime()
  }));

  ws.on('message', (raw) => {
    try {
      const msg = JSON.parse(raw);
      handleClientMessage(ws, playerSession, msg);
    } catch (err) {
      console.error('[Error] Invalid message received from ' + clientIp + ':', err.message);
    }
  });

  ws.on('close', () => {
    handlePlayerDisconnect(playerSession);
  });
});

function handleClientMessage(ws, session, msg) {
  switch (msg.type) {
    case 'PING': {
      ws.send(JSON.stringify({ type: 'PONG' }));
      break;
    }

    case 'CREATE_ROOM': {
      const roomCode = msg.roomCode || generateRoomCode();
      const playerCount = Number(msg.playerCount) || 4;
      const isFun = !!msg.isFun;
      const variant = msg.variant || 'normal';

      rooms[roomCode] = {
        code: roomCode,
        playerCount: playerCount,
        isFun: isFun,
        variant: variant,
        hostId: session.id,
        matchStarted: false,
        players: [
          {
            id: session.id,
            ws: ws,
            slot: 1,
            name: msg.playerName || 'Player 1 (Host)',
            isHost: true,
            ready: true
          }
        ]
      };

      session.roomCode = roomCode;
      session.slot = 1;
      session.isHost = true;
      session.name = msg.playerName || 'Player 1 (Host)';

      ws.send(JSON.stringify({
        type: 'ROOM_CREATED',
        roomCode: roomCode,
        slot: 1,
        isHost: true,
        playerCount: playerCount,
        players: rooms[roomCode].players.map(p => ({ slot: p.slot, name: p.name, isHost: p.isHost }))
      }));

      console.log(`[Room Created] Code: ${roomCode} | Host: ${session.name} | Max Players: ${playerCount}`);
      break;
    }

    case 'JOIN_ROOM': {
      const code = (msg.roomCode || '').toUpperCase().trim();
      const room = rooms[code];

      if (!room) {
        ws.send(JSON.stringify({ type: 'ERROR', message: `Room '${code}' not found! Check code and try again.` }));
        return;
      }

      if (room.matchStarted) {
        ws.send(JSON.stringify({ type: 'ERROR', message: `Match already in progress in room '${code}'!` }));
        return;
      }

      if (room.players.length >= room.playerCount) {
        ws.send(JSON.stringify({ type: 'ERROR', message: `Room '${code}' is already full (${room.playerCount}/${room.playerCount})!` }));
        return;
      }

      // Assign first free slot (1..playerCount)
      const occupiedSlots = room.players.map(p => p.slot);
      let assignedSlot = 1;
      for (let s = 1; s <= room.playerCount; s++) {
        if (!occupiedSlots.includes(s)) {
          assignedSlot = s;
          break;
        }
      }

      const newPlayer = {
        id: session.id,
        ws: ws,
        slot: assignedSlot,
        name: msg.playerName || `Player ${assignedSlot}`,
        isHost: false,
        ready: true
      };

      room.players.push(newPlayer);
      session.roomCode = code;
      session.slot = assignedSlot;
      session.isHost = false;
      session.name = newPlayer.name;

      // Notify joining player
      ws.send(JSON.stringify({
        type: 'ROOM_JOINED',
        roomCode: code,
        slot: assignedSlot,
        isHost: false,
        playerCount: room.playerCount,
        players: room.players.map(p => ({ slot: p.slot, name: p.name, isHost: p.isHost }))
      }));

      // Notify other players in the room
      broadcastToRoom(code, {
        type: 'PLAYER_JOINED',
        slot: assignedSlot,
        name: newPlayer.name,
        players: room.players.map(p => ({ slot: p.slot, name: p.name, isHost: p.isHost }))
      }, ws);

      console.log(`[Player Joined] Room: ${code} | Slot: ${assignedSlot} (${newPlayer.name})`);
      break;
    }

    case 'START_MATCH': {
      const room = rooms[session.roomCode];
      if (!room) return;
      if (!session.isHost) {
        ws.send(JSON.stringify({ type: 'ERROR', message: 'Only the room host can start the match.' }));
        return;
      }

      room.matchStarted = true;
      const playerNamesMap = {};
      room.players.forEach(p => {
        playerNamesMap[p.slot] = p.name;
      });

      broadcastToRoom(room.code, {
        type: 'MATCH_STARTED',
        roomCode: room.code,
        playerCount: room.playerCount,
        playerNames: playerNamesMap,
        isFun: room.isFun,
        variant: room.variant
      });

      console.log(`[Match Started] Room: ${room.code} with ${room.players.length} players!`);
      break;
    }

    case 'STRIKER_MOVE': {
      broadcastToRoom(session.roomCode, {
        type: 'STRIKER_MOVE',
        slot: session.slot,
        x: msg.x,
        y: msg.y
      }, ws);
      break;
    }

    case 'STRIKER_AIM': {
      broadcastToRoom(session.roomCode, {
        type: 'STRIKER_AIM',
        slot: session.slot,
        x: msg.x,
        y: msg.y
      }, ws);
      break;
    }

    case 'STRIKER_SHOOT': {
      broadcastToRoom(session.roomCode, {
        type: 'STRIKER_SHOOT',
        slot: session.slot,
        x: msg.x,
        y: msg.y,
        vx: msg.vx,
        vy: msg.vy
      }, ws);
      break;
    }

    case 'LEAVE_ROOM': {
      handlePlayerDisconnect(session);
      break;
    }
  }
}

function handlePlayerDisconnect(session) {
  if (!session.roomCode) return;
  const room = rooms[session.roomCode];
  if (!room) return;

  room.players = room.players.filter(p => p.id !== session.id);
  console.log(`[Player Left] Room: ${session.roomCode} | Slot: ${session.slot}`);

  if (room.players.length === 0) {
    delete rooms[session.roomCode];
    console.log(`[Room Deleted] Room: ${session.roomCode} is now empty.`);
  } else {
    // If host left, elect first remaining player as new host
    if (session.isHost && room.players[0]) {
      room.players[0].isHost = true;
      room.hostId = room.players[0].id;
    }

    broadcastToRoom(room.code, {
      type: 'PLAYER_LEFT',
      slot: session.slot,
      players: room.players.map(p => ({ slot: p.slot, name: p.name, isHost: p.isHost }))
    });
  }

  session.roomCode = null;
  session.slot = null;
}

// -----------------------------------------------------------------------------
// 3. Start Server & Print Access URLs
// -----------------------------------------------------------------------------
server.listen(PORT, '0.0.0.0', () => {
  const localIp = getLocalIp();
  console.log(`=============================================================================`);
  console.log(`  CARROM CHAMPIONS - UNIFIED MULTIPLAYER & WEB SERVER`);
  console.log(`=============================================================================`);
  console.log(`  Local Browser:     http://localhost:${PORT}`);
  console.log(`  Phone / LAN Wi-Fi: http://${localIp}:${PORT}`);
  console.log(`  WebSocket:         ws://localhost:${PORT}`);
  console.log(`  Cloud Ready:       Google Cloud Run / Compute Engine (Port ${PORT})`);
  console.log(`=============================================================================`);
  console.log(`  Ready! Open the URL above in your browser to play.`);
});

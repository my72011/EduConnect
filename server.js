// server.js
require('dotenv').config();
const express = require('express');
const axios = require('axios');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
app.use(express.json());
app.use(cors());

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*', methods: ['GET','POST'] } });

const ACCOUNT_ID = process.env.ZOOM_ACCOUNT_ID;
const CLIENT_ID = process.env.ZOOM_CLIENT_ID;
const CLIENT_SECRET = process.env.ZOOM_CLIENT_SECRET;
const PORT = process.env.PORT || 3000;

const MESSAGES_FILE = path.join(__dirname, 'group_messages.json');
let groupMessages = {};
if (fs.existsSync(MESSAGES_FILE)) {
  try { groupMessages = JSON.parse(fs.readFileSync(MESSAGES_FILE, 'utf8')); } catch(e){ groupMessages = {}; }
}
function persist(){ fs.writeFileSync(MESSAGES_FILE, JSON.stringify(groupMessages, null, 2)); }

let cachedToken = null; let tokenExpiresAt = 0;
async function fetchZoomAccessToken(){
  const now = Date.now();
  if (cachedToken && now < tokenExpiresAt - 5000) return cachedToken;
  if (!ACCOUNT_ID || !CLIENT_ID || !CLIENT_SECRET) throw new Error('Zoom creds missing');
  const tokenUrl = `https://zoom.us/oauth/token?grant_type=account_credentials&account_id=${ACCOUNT_ID}`;
  const auth = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64');
  const resp = await axios.post(tokenUrl, null, { headers: { Authorization: `Basic ${auth}` } });
  cachedToken = resp.data.access_token; tokenExpiresAt = Date.now() + resp.data.expires_in*1000;
  return cachedToken;
}

async function createMeeting(hostEmail, topic='EduConnect', type=1, duration=60){
  const token = await fetchZoomAccessToken();
  const url = `https://api.zoom.us/v2/users/${encodeURIComponent(hostEmail)}/meetings`;
  const body = { topic, type, duration, timezone: 'UTC', settings: { host_video: true, participant_video: false, join_before_host: false } };
  const r = await axios.post(url, body, { headers: { Authorization: `Bearer ${token}` } });
  return r.data;
}

app.get('/', (req,res)=>res.send('EduConnect server running'));
app.post('/create-meeting', async (req,res)=>{
  const { host_email, groups = [], topic='EduConnect' } = req.body;
  if (!host_email) return res.status(400).json({ error: 'host_email required' });
  try {
    const meeting = await createMeeting(host_email, topic);
    const joinUrl = meeting.join_url;
    const id = meeting.id?.toString() || '';
    // persist as notifications per group
    groups.forEach(g => {
      if (!groupMessages[g]) groupMessages[g] = [];
      groupMessages[g].push({ id: `${id}_${Date.now()}`, type: 'meeting', group: g, join_url: joinUrl, meeting_id: id, sent_at: new Date().toISOString() });
    });
    persist();
    return res.json({ success: true, meeting: { id, join_url: joinUrl, start_url: meeting.start_url } });
  } catch (e) {
    return res.status(500).json({ error: e.response?.data || e.message });
  }
});

app.get('/groups', (req,res)=> res.json({ groups: Object.keys(groupMessages) }));
app.get('/groups/:name/messages', (req,res)=> res.json({ group: req.params.name, messages: groupMessages[req.params.name] || [] }));
app.listen(PORT, ()=>console.log('Server listening on', PORT));

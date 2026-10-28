'use strict';

// Collector mínimo sin dependencias externas.
// Producción: poner detrás de HTTPS/auth y limitar el acceso al endpoint.
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PORT = Number(process.env.PORT || 8787);
const DATA_DIR = process.env.NEXUS_TELEMETRY_DIR || path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'events.jsonl');
const ACCOUNTS_DIR = path.join(DATA_DIR, 'accounts');
const MAX_BODY = 8 * 1024 * 1024;
const SCHEMA_VERSION = 1;
const AUTH_TOKEN = process.env.NEXUS_TELEMETRY_TOKEN || '';

fs.mkdirSync(DATA_DIR, { recursive: true });
fs.mkdirSync(ACCOUNTS_DIR, { recursive: true });

function send(res, code, body) {
  res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
}

function authorized(req) {
  if (!AUTH_TOKEN) return true;
  return req.headers.authorization === `Bearer ${AUTH_TOKEN}`;
}

function validEvent(event) {
  const required = ['event_id','timestamp','match_id','mode','outcome','actor_key','rating_before','rating_after','rating_delta','opponent_rating_before','expected','surprise','uncertainty_before','uncertainty_after'];
  return event && event.schema_version === SCHEMA_VERSION && event.event_type === 'competitive_match_result' && required.every(k => Object.prototype.hasOwnProperty.call(event, k));
}

function appendEvents(events) {
  const lines = events.map(e => JSON.stringify(e)).join('\n') + '\n';
  fs.appendFileSync(DATA_FILE, lines, 'utf8');
}

function accountFile(accountId) {
  const key = crypto.createHash('sha256').update(String(accountId)).digest('hex');
  return path.join(ACCOUNTS_DIR, `${key}.json`);
}

function validSnapshot(snapshot) {
  return snapshot && typeof snapshot === 'object' && Number(snapshot.schema_version || 0) >= 2;
}

function readAccount(accountId) {
  const file = accountFile(accountId);
  if (!fs.existsSync(file)) return null;
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch (_) { return null; }
}

function writeAccount(accountId, record) {
  fs.writeFileSync(accountFile(accountId), JSON.stringify(record), 'utf8');
}

function accountAuthorized(req) {
  return authorized(req);
}

const server = http.createServer((req, res) => {
  if (req.method === 'GET' && req.url === '/health') return send(res, 200, { ok: true, schema_version: SCHEMA_VERSION, account_storage: true });

  // Account snapshot storage: provider tokens are not stored here. The client sends only its
  // stable account id plus game snapshot; production must validate the bearer token server-side.
  if (req.method === 'GET' && req.url.startsWith('/v1/account/snapshot?')) {
    if (!accountAuthorized(req)) return send(res, 401, { ok: false, error: 'unauthorized' });
    const parsed = new URL(req.url, 'http://localhost');
    const accountId = String(parsed.searchParams.get('account_id') || '').trim();
    if (!accountId) return send(res, 400, { ok: false, error: 'missing_account_id' });
    const record = readAccount(accountId);
    return send(res, 200, { ok: true, snapshot: record ? record.snapshot : {}, remote_revision: record ? record.revision : 0 });
  }

  if (req.method !== 'POST' || !['/v1/telemetry/nexus','/v1/account/bootstrap','/v1/account/snapshot','/v1/account/events'].includes(req.url)) return send(res, 404, { ok: false, error: 'not_found' });
  if (!authorized(req)) return send(res, 401, { ok: false, error: 'unauthorized' });

  let size = 0;
  let raw = '';
  req.setEncoding('utf8');
  req.on('data', chunk => {
    size += Buffer.byteLength(chunk);
    if (size <= MAX_BODY) raw += chunk;
  });
  req.on('end', () => {
    if (size > MAX_BODY) return send(res, 413, { ok: false, error: 'payload_too_large' });
    try {
      const payload = JSON.parse(raw || '{}');
      if (req.url === '/v1/account/bootstrap') {
        const accountId = String(payload.account_id || '').trim();
        const localRevision = Number.isInteger(payload.local_revision) ? payload.local_revision : 0;
        const snapshot = payload.snapshot;
        if (!accountId || !validSnapshot(snapshot)) return send(res, 400, { ok: false, error: 'invalid_account_bootstrap' });
        const record = readAccount(accountId);
        if (!record) return send(res, 200, { ok: true, snapshot: {}, remote_revision: 0, status: 'new_account' });
        return send(res, 200, { ok: true, snapshot: record.snapshot, remote_revision: record.revision, local_revision: localRevision, status: record.revision === localRevision ? 'synced' : 'remote_available' });
      }
      if (req.url === '/v1/account/snapshot') {
        const accountId = String(payload.account_id || '').trim();
        const revision = Number.isInteger(payload.revision) ? payload.revision : 0;
        const snapshot = payload.snapshot;
        if (!accountId || revision < 0 || !validSnapshot(snapshot)) return send(res, 400, { ok: false, error: 'invalid_account_snapshot' });
        const record = readAccount(accountId);
        if (record && Number(record.revision || 0) > revision) {
          return send(res, 409, { ok: false, status: 'conflict', snapshot: record.snapshot, remote_revision: record.revision });
        }
        writeAccount(accountId, { schema_version: 1, revision, snapshot, updated_at: Date.now() });
        return send(res, 202, { ok: true, status: 'stored', remote_revision: revision });
      }
      if (req.url === '/v1/account/events') {
        const operation = payload.operation;
        if (!operation || typeof operation !== 'object') return send(res, 400, { ok: false, error: 'invalid_operation' });
        const file = path.join(ACCOUNTS_DIR, 'events.jsonl');
        fs.appendFileSync(file, JSON.stringify(operation) + '\n', 'utf8');
        return send(res, 202, { ok: true, accepted: 1 });
      }
      if (payload.schema_version !== SCHEMA_VERSION || !Array.isArray(payload.events)) return send(res, 400, { ok: false, error: 'invalid_batch' });
      const valid = payload.events.filter(validEvent);
      if (valid.length !== payload.events.length) return send(res, 400, { ok: false, error: 'invalid_event' });
      appendEvents(valid);
      return send(res, 202, { ok: true, accepted: valid.length });
    } catch (_) {
      return send(res, 400, { ok: false, error: 'invalid_json' });
    }
  });
});

server.listen(PORT, () => console.log(`NEXUS telemetry collector listening on :${PORT}`));

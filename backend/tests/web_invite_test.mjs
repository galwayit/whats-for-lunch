// Exercise the real invitation page script with fictional DOM/API data; no external requests.
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const html = readFileSync(new URL('../web/invite/index.html', import.meta.url), 'utf8');
const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)];
class Element {
  value = ''; textContent = ''; className = ''; disabled = false; style = {}; dataset = {}; children = []; listeners = {};
  classList = { add: c => { this.className += ' ' + c; }, remove: c => { this.className = this.className.split(/\s+/).filter(x => x !== c).join(' '); }, contains: c => this.className.split(/\s+/).includes(c) };
  addEventListener(name, fn) { this.listeners[name] = fn; }
  focus() {}
  appendChild(child) { this.children.push(child); }
  set innerHTML(value) { assert.equal(value, '', 'untrusted HTML is never injected'); this.children = []; }
}
const elements = Object.fromEntries([...html.matchAll(/id="([^"]+)"/g)].map(([,id]) => [id, new Element()]));
for (const id of ['suggestion-form','suggestion-status','status','error']) elements[id].className = 'hidden';
elements.app.dataset = { functionsUrl: 'https://fictional.test/api', anonKey: 'public-test-key', iosUrl: '#ios', androidUrl: '#android' };
const group = { id:'g', name:'Test lunch', hostName:'Sam', scheduledAtEpochSeconds:Date.now()/1000+86400, placeName:'Cafe', placeAddress:'10 Test Lane',budgetPerPersonMinor:2550,currencyCode:'AUD',paymentArrangement:'split_equally',paymentMethod:'card' };
let invite = { group, attendees:[], myStatus:null };
let failNext = false;
const requests = [], saved = new Map(), documentEvents = {};
const context = { document:{ getElementById:id=>elements[id],createElement:()=>new Element(),addEventListener:(n,f)=>{documentEvents[n]=f;},hidden:false }, location:{ pathname:'/i/TST12345',search:'' }, URLSearchParams, Intl, Date, Number, JSON,
  localStorage:{ getItem:k=>saved.get(k),setItem:(k,v)=>saved.set(k,v) },
  fetch:async(url,options={})=>{
    const body=options.body ? JSON.parse(options.body) : null; requests.push({url,options,body});
    if (failNext) { failNext=false; return {ok:false,json:async()=>({error:{message:'Fictional temporary failure'}})}; }
    if (url.endsWith('/invitations-suggest')) {
      invite={...invite,myStatus:"pending",mySuggestion:{ id:'s',status:'pending',placeName:body.suggestion.placeName,placeAddress:body.suggestion.placeAddress,scheduledAtEpochSeconds:body.suggestion.scheduledAt,note:body.suggestion.note }};
    }
    if (url.endsWith('/invitations-respond')) invite={...invite,myStatus:body.status};
    return {ok:true,json:async()=>({invitation:structuredClone(invite),guestToken:'e'.repeat(64)})};
  }
};
vm.runInNewContext(scripts.at(-1)[1], context);
const settle=()=>new Promise(resolve=>setImmediate(resolve));
await settle();
assert.equal(elements['host-line'].textContent,'Hosted by Sam');
assert.match(elements.budget.textContent,/25\.50 per person/);
assert.equal(elements['payment-arrangement'].textContent,'Split equally');
assert.equal(elements['payment-method'].textContent,'Card');
elements.suggest.listeners.click();
assert.equal(elements['suggestion-form'].classList.contains('hidden'),false);
elements['suggestion-send'].listeners.click();
assert.match(elements.error.textContent,/Enter your name/);
elements['suggestion-name'].value=' Fictional Sam ';
elements['suggestion-send'].listeners.click();
assert.match(elements.error.textContent,/Suggest a place or a time/);
elements['suggestion-place'].value=' <img src=x onerror=alert(1)> ';
elements['suggestion-address'].value='10 Example Street';
elements['suggestion-time'].value='2050-10-03T12:30';
elements['suggestion-note'].value='Can we meet here?';
failNext=true;elements['suggestion-send'].listeners.click();await settle();
assert.match(elements.error.textContent,/Fictional temporary failure/);
assert.equal(elements['suggestion-send'].disabled,false);
assert.equal(elements['suggestion-form'].classList.contains('hidden'),false);
elements['suggestion-send'].listeners.click();await settle();
assert.equal(requests.at(-1).body.suggestion.placeName,'<img src=x onerror=alert(1)>');
assert.ok(requests.at(-1).body.suggestion.scheduledAt > Date.now()/1000);
assert.equal(saved.get('lunch.guestToken.TST12345'),'e'.repeat(64));
assert.equal(elements['suggestion-form'].classList.contains('hidden'),true);
assert.match(elements['suggestion-status'].textContent,/Waiting for the host to review/);
assert.match(elements['suggestion-status'].textContent,/<img src=x onerror=alert\(1\)>/); // rendered as text
assert.equal(elements.suggest.disabled,true);
elements.accept.listeners.click();await settle();
assert.equal(requests.at(-1).options.headers['x-guest-token'],'e'.repeat(64));
assert.match(elements.status.textContent,/You're in/);
invite.myStatus='pending';invite.group.placeName='Updated place';
documentEvents.visibilitychange();await settle();
assert.equal(elements.status.classList.contains('hidden'),true);
assert.match(elements.where.textContent,/Updated place/);
elements['safety-target'].value='group:g';
elements['safety-reason'].value='spam';
failNext=true;elements['safety-report'].listeners.click();await settle();
assert.match(elements['safety-status'].textContent,/Fictional temporary failure/);
assert.equal(elements['safety-report'].disabled,false);
elements['safety-report'].listeners.click();await settle();
assert.equal(requests.at(-1).url,'https://fictional.test/api/groups-safety');
assert.equal(requests.at(-1).options.headers['x-guest-token'],'e'.repeat(64));
assert.deepEqual(requests.at(-1).body,{code:'TST12345',targetKind:'group',targetId:'g',action:'report',reason:'spam'});
assert.match(elements['safety-status'].textContent,/Report sent/);
elements['safety-block'].listeners.click();await settle();
assert.equal(requests.at(-1).body.action,'report_block');
assert.equal(elements.invite.classList.contains('hidden'),true);
assert.match(elements['not-found-detail'].textContent,/Host blocked/);
console.log('PASS: web invitation details, first-RSVP validation despite a GET token, safe rendering, retry, RSVP, plan refresh, report and block (fictional data).');

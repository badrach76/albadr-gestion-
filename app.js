'use strict';
const $ = (id) => document.getElementById(id);
const views = ['dashboard','reception','customers','production','stock','delivery','accounts','expenses','reports','settings'];
let receipts = [];
let nextReceiptNumber = 1;
let defaultRate = 0.70;

$('today').textContent = new Intl.DateTimeFormat('ar-MA',{dateStyle:'full'}).format(new Date());
function showView(name){
  if(!views.includes(name)) return;
  views.forEach(v => { const el=$('view-'+v); if(el) el.hidden = v !== name; });
  document.querySelectorAll('.nav-item').forEach(btn=>btn.classList.toggle('active',btn.dataset.view===name));
  const active=document.querySelector(`.nav-item[data-view="${name}"]`);
  $('pageTitle').textContent=active ? active.textContent.trim() : 'لوحة القيادة';
  $('sidebar').classList.remove('open');
  window.scrollTo({top:0,behavior:'smooth'});
}
document.querySelectorAll('[data-view]').forEach(btn=>btn.addEventListener('click',()=>showView(btn.dataset.view)));
document.querySelectorAll('[data-go]').forEach(btn=>btn.addEventListener('click',()=>showView(btn.dataset.go)));
$('menuToggle').addEventListener('click',()=>$('sidebar').classList.toggle('open'));
document.addEventListener('click',e=>{if(window.innerWidth<=760 && $('sidebar').classList.contains('open') && !$('sidebar').contains(e.target) && !$('menuToggle').contains(e.target)) $('sidebar').classList.remove('open');});
function preview(){
  const form=$('receiptForm'); if(!form) return;
  const gross=Number(form.elements.gross.value)||0;
  const tare=Number(form.elements.tare.value)||0;
  const rate=Number(form.elements.rate.value)||0;
  const net=Math.max(0,gross-tare);
  $('netPreview').textContent=net.toLocaleString('ar-MA',{minimumFractionDigits:2,maximumFractionDigits:2})+' كلغ';
  $('feePreview').textContent=(net*rate).toLocaleString('ar-MA',{minimumFractionDigits:2,maximumFractionDigits:2})+' درهم';
}
['gross','tare','rate'].forEach(n=>$('receiptForm').elements[n].addEventListener('input',preview));
function toast(message){$('toast').textContent=message;$('toast').classList.add('show');setTimeout(()=>$('toast').classList.remove('show'),3200);}
function renderReceipts(){
  const body=$('receiptsBody');body.replaceChildren();
  if(!receipts.length){const tr=document.createElement('tr'),td=document.createElement('td');td.colSpan=5;td.className='empty';td.textContent='لا توجد وصولات في هذه الجلسة.';tr.appendChild(td);body.appendChild(tr);}
  receipts.forEach(r=>{const tr=document.createElement('tr');[r.number,r.customer,r.net.toFixed(2)+' كلغ',r.rate.toFixed(2)+' درهم',r.fee.toFixed(2)+' درهم'].forEach(value=>{const td=document.createElement('td');td.textContent=String(value);tr.appendChild(td);});body.appendChild(tr);});
}
$('receiptForm').addEventListener('submit',e=>{
  e.preventDefault();const f=e.currentTarget;const customer=f.elements.customer.value.trim();const gross=Number(f.elements.gross.value);const tare=Number(f.elements.tare.value);const rate=Number(f.elements.rate.value);
  if(!customer||!Number.isFinite(gross)||gross<=0||!Number.isFinite(tare)||tare<0||tare>gross||!Number.isFinite(rate)||rate<0){toast('يرجى مراجعة الاسم والأوزان وسعر الطحن.');return;}
  const net=Number((gross-tare).toFixed(2));receipts.push({number:nextReceiptNumber++,customer,phone:f.elements.phone.value.trim(),net,rate,fee:Number((net*rate).toFixed(2)),createdAt:new Date().toISOString()});
  renderReceipts();f.reset();f.elements.tare.value='0';f.elements.rate.value=defaultRate.toFixed(2);preview();toast('أُضيف الوصل إلى سجل الجلسة التجريبية.');
});
$('saveSettings').addEventListener('click',()=>{const val=Number($('defaultRate').value);if(!Number.isFinite(val)||val<0){$('settingsMessage').textContent='أدخل سعرًا صحيحًا.';return;}defaultRate=val;$('receiptForm').elements.rate.value=defaultRate.toFixed(2);$('settingsMessage').textContent='تم تحديث السعر الافتراضي لهذه الجلسة فقط.';toast('حُدّث السعر الافتراضي مؤقتًا.');});
preview();

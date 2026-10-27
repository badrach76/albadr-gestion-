"use client";
import { useMemo, useState } from "react";
import { Activity, Archive, Banknote, Boxes, ClipboardList, Droplets, Gauge, Leaf, Settings, ShieldCheck, Users, Wrench } from "lucide-react";
const modules = [
 { title:"استقبال الزيتون والوزن", desc:"تسجيل الزبون والوزن الصافي ووصل الاستلام", icon:ClipboardList, tag:"التشغيل" },
 { title:"طابور الانتظار والطحن", desc:"ترتيب الحمولات ومتابعة حالة كل حمولة", icon:Activity, tag:"التشغيل" },
 { title:"الإنتاج والمردودية", desc:"تسجيل الزيت المستخرج باسم صاحبه", icon:Droplets, tag:"الإنتاج" },
 { title:"المخزون والخزانات", desc:"رصيد كل زبون وموقع التخزين وحركاته", icon:Boxes, tag:"المخزون" },
 { title:"وصولات تسليم الزيت", desc:"إصدار وصل وتتبع الكمية المصروفة", icon:Archive, tag:"المخزون" },
 { title:"مبيعات زيت المعصرة", desc:"مبيعات زيت البدر دون خلطها بزيت الزبائن", icon:Leaf, tag:"المبيعات" },
 { title:"الصندوق والحسابات", desc:"الأداءات والتسبيقات والديون والمستحقات", icon:Banknote, tag:"المالية" },
 { title:"العمال والصيانة", desc:"العمال والأجور والمعدات وأعمال الصيانة", icon:Wrench, tag:"الموارد" },
 { title:"الجودة والتقارير", desc:"التحاليل والمردودية وتقارير الموسم", icon:Gauge, tag:"المراقبة" },
 { title:"الزبائن والإعدادات", desc:"ملفات الزبائن والتعريفة وإعدادات الموسم", icon:Users, tag:"الإدارة" },
];
const money = (n:number) => new Intl.NumberFormat("fr-MA", { style:"currency", currency:"MAD", maximumFractionDigits:2 }).format(n);
export default function Home() {
 const [rate,setRate] = useState("0.70"); const [weight,setWeight] = useState("1000"); const [active,setActive] = useState("نظرة عامة");
 const fee = useMemo(()=>Math.max(0,Number(weight)||0)*Math.max(0,Number(rate)||0),[weight,rate]);
 return <main className="shell">
  <header className="topbar"><div className="brand-mark">البدر</div><div className="brand-title"><p className="eyebrow">نظام الإدارة والتتبع</p><h1>وحدة إنتاج زيت الزيتون البدر</h1><p className="subbrand">منصة التسيير المهني للمعصرة</p></div><span className="status"><span className="status-dot"/> مرحلة التأسيس</span></header>
  <nav className="nav">{["نظرة عامة","التشغيل","المخزون","المالية","الإدارة"].map(x=><button key={x} className={active===x?"nav-active":""} onClick={()=>setActive(x)}>{x}</button>)}</nav>
  <section className="hero"><div><p className="eyebrow">من الاستقبال إلى التسليم</p><h2>إدارة دقيقة لكل حمولة، ولكل لتر زيت، ولكل درهم.</h2><p className="hero-copy">نظام موحد لتسيير الطحن والإنتاج ومخزون الزبائن ومبيعات المعصرة والحسابات، مع توثيق حركة الزيت حسب المالك والدفعة والخزان.</p><div className="hero-tags"><span><ShieldCheck size={15}/> فصل الملكيات</span><span><Activity size={15}/> تتبع العمليات</span><span><Settings size={15}/> إعدادات قابلة للتعديل</span></div></div><div className="hero-seal"><span>وحدة إنتاج</span><strong>البدر</strong><small>زيت الزيتون</small></div></section>
  <section className="notice"><strong>قاعدة أساسية لحماية الحقوق</strong><p>زيت كل زبون يُسجّل باسمه بصورة مستقلة. لا يُعتبر زيت الزبائن مخزونًا مملوكًا للمعصرة ولا يُسجّل إيرادًا لها. ولا يتم صرف أي كمية إلا بوثيقة صرف مسجلة.</p></section>
  <section className="section-head"><div><p className="eyebrow">لوحة القيادة</p><h2>{active === "نظرة عامة" ? "ملخص المعصرة" : active}</h2></div><span className="muted">المؤشرات الحقيقية ستظهر بعد ربط قاعدة البيانات</span></section>
  <section className="metric-grid"><article className="metric"><span className="metric-icon"><Users size={19}/></span><p>الزبائن المسجلون</p><strong>—</strong><small>بانتظار ربط قاعدة البيانات</small></article><article className="metric"><span className="metric-icon"><ClipboardList size={19}/></span><p>حمولات في الانتظار</p><strong>—</strong><small>لن تُعرض أرقام افتراضية</small></article><article className="metric"><span className="metric-icon"><Droplets size={19}/></span><p>مخزون زيت الزبائن</p><strong>—</strong><small>مفصول عن مخزون المعصرة</small></article><article className="metric"><span className="metric-icon"><Banknote size={19}/></span><p>مداخيل الطحن اليوم</p><strong>—</strong><small>تُحسب من الأداءات المسجلة</small></article></section>
  <section className="work-grid"><div className="panel"><div className="panel-head"><div><p className="eyebrow">حاسبة التعريفة</p><h3>تقدير تكلفة الطحن</h3></div><span className="pill">قابل للتعديل</span></div><label>الوزن الصافي للزيتون (كغ)<input type="number" min="0" step="0.001" value={weight} onChange={e=>setWeight(e.target.value)} /></label><label>تعريفة الطحن (درهم/كغ)<input type="number" min="0" step="0.01" value={rate} onChange={e=>setRate(e.target.value)} /></label><div className="estimate"><span>المبلغ التقديري</span><strong>{money(fee)}</strong></div><p className="hint">حساب توضيحي: الوزن الصافي × التعريفة. لا يُنشئ هذا النموذج فاتورة أو قيدًا ماليًا حتى الآن.</p></div><div className="panel principle"><div className="panel-head"><div><p className="eyebrow">ضوابط النظام</p><h3>كيف سنضمن دقة التتبع؟</h3></div><ShieldCheck size={24}/></div><ul><li>لكل حمولة رقم وصل فريد ووزن موثق.</li><li>الإنتاج مرتبط بالحمولة أو بحمولات محددة مع توزيع الكميات.</li><li>رصيد الزيت يُستخرج من حركات المخزون، لا من تعديل رقم يدوي فقط.</li><li>الوصولات المصروفة لا تُصرف مرة ثانية، والتصحيحات تُسجل في سجل التدقيق.</li><li>الأداء الجزئي والتسبيق والدين تُعرض كأرصدة منفصلة.</li></ul></div></section>
  <section className="section-head module-head"><div><p className="eyebrow">خريطة التنفيذ</p><h2>وحدات المنصة</h2></div><span className="muted">10 وحدات أساسية</span></section><section className="modules">{modules.map((m,i)=>{const Icon=m.icon;return <article className="module" key={m.title}><span className="module-number">{String(i+1).padStart(2,"0")}</span><span className="module-icon"><Icon size={21}/></span><div className="module-copy"><span className="module-tag">{m.tag}</span><h3>{m.title}</h3><p>{m.desc}</p></div><span className="arrow">←</span></article>})}</section>
  <footer><span>وحدة إنتاج زيت الزيتون البدر</span><span>واجهة عربية RTL · متجاوبة · نسخة تطوير أولية</span></footer>
 </main>;
}

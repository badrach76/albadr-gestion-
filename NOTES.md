# ربط Supabase — ملاحظات تنفيذية

هذه الواجهة متعددة الصفحات ومرحلة تأسيس للربط، وليست متصلة بعد بقاعدة البيانات. الجداول الموجودة في مشروع المستخدم يجب الحفاظ عليها ومواءمتها قبل أي migration.

## قبل التشغيل الحقيقي
1. إنشاء تسجيل دخول للمالك عبر Supabase Auth.
2. إزالة صلاحيات `anon` غير اللازمة من الجداول، ومراجعة منح `authenticated`.
3. إضافة سياسات RLS محددة للمستخدم المخول فقط.
4. بناء عمليات ذرية (RPC/Postgres functions) لتوليد أرقام الوصولات ومنع تكرار التسليم وتحديث المخزون والحسابات معًا.
5. إضافة جداول العمال والحضور والأجور ومبيعات الزيت إن لم تكن موجودة.
6. عدم وضع `service_role` في المتصفح.

## الجداول الحالية المعروفة
app_settings, audit_logs, batch_receipts, customers, delivery_voucher_items, delivery_vouchers, expenses, financial_transactions, inventory_locations, inventory_movements, oil_lots, olive_receipts, processing_batches, production_allocations, service_charges.

لا تنفذ schema قديمًا فوق قاعدة البيانات الحالية. يجب كتابة migrations إضافية بعد التحقق من الأعمدة والقيود الموجودة.

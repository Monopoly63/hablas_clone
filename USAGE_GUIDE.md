# 📖 دليل استخدام Hablas Virtual Studio v1.0.0

---

## 1. تثبيت التطبيق

### تحميل APK
```
https://github.com/Monopoly63/hablas_clone/releases/download/v1.0.0/app-release.apk
```

### التثبيت على جهاز Android
1. افتح الرابط أعلاه في متصفح الجهاز
2. حمّل ملف `app-release.apk` (56.6 MB)
3. إذا ظهرت رسالة "التثبيت من مصادر غير معروفة" → اذهب إلى:
   - **الإعدادات** → **الأمان** → **تثبيت تطبيقات غير معروفة** → فعّل الخيار
4. افتح ملف APK واضغط **تثبيت**
5. بعد التثبيت → افتح **Hablas Studio**

---

## 2. واجهة التطبيق — Liquid Glass UI

### الشاشة الرئيسية (Dashboard)

```
┌─────────────────────────────────────────┐
│  🔷 Hablas                              │
│     Virtual Studio              [2] 🔵  │ ← عدد النسخ الحالية
│                                         │
│  ┌─────────┬─────────┬─────────┐        │
│  │ Total   │ Active  │ Storage │        │ ← بطاقات إحصائيات
│  │   3     │   2     │ 120MB  │        │
│  └─────────┴─────────┴─────────┘        │
│                                         │
│  WHATSAPP                               │ ← مجموعة النسخ
│  3 instances           120 MB           │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 📱 WhatsApp — Work      🟢 Run │    │ ← بطاقة نسخة (Glass Card)
│  │    com.whatsapp                 │    │
│  │ 📦 45MB  ⏰ 5m ago             │    │
│  │    [▶ Launch]                   │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 📱 WhatsApp — Personal  🔵 Idle│    │
│  │    [▶ Launch]                   │    │
│  └─────────────────────────────────┘    │
│                                         │
│                              [➕ FAB]    │ ← زر إضافة نسخة جديدة
└─────────────────────────────────────────┘
```

### عنصر التصميم
| العنصر | اللون | المعنى |
|--------|-------|---------|
| 🟢 Running | `#00FF87` Neon Emerald | النسخة شغالة الآن |
| 🔵 Idle | `#4FACFE` Cobalt Blue | النسخة موجودة لكن غير شغالة |
| 🌙 Sleeping | `#666680` Gray | النسخة نائمة |
| 🔴 Error | `#FF006E` Neon Pink | النسخة فيها مشكلة |
| الخلفية | `#050505` OLED Black | يوفر طاقة على شاشات AMOLED |

---

## 3. كيفية إنشاء نسخة جديدة

### الخطوة 1: اضغط زر ➕ (Floating Action Button)
```
         ┌──────┐
         │  ➕  │ ← زر إضافة (Liquid Glass Button)
         └──────┘
```

### الخطوة 2: تفتح شاشة App Picker
```
┌─────────────────────────────────────────┐
│         Clone App                       │
│                                         │
│ ┌─────────────────────────────────┐     │
│ │ 🔍 Search apps...               │     │ ← حقل بحث
│ └─────────────────────────────────┘     │
│                                         │
│ [System Apps] ← فلتر تطبيقات النظام    │
│                                         │
│ ★ WhatsApp              [➕] ← تطبيق   │
│   com.whatsapp              مميز       │
│                                         │
│ ★ Telegram              [➕]            │
│   org.telegram.messenger                  │
│                                         │
│   Instagram             [➕]            │
│   com.instagram.android                  │
│                                         │
│   Discord               [➕]            │
│   com.discord                             │
└─────────────────────────────────────────┘
```

### الخطوة 3: اضغط ➕ على التطبيق المطلوب
- التطبيق يتم نسخه فوراً
- يتم إنشاء sandbox معزول:
  ```
  /data/data/com.hablas.studio/virtual/sandbox/
    ├── com.whatsapp_1/
    │   ├── shared_prefs/    ← SharedPreferences معزولة
    │   ├── databases/       ← SQLite databases معزولة
    │   ├── cache/           ← Cache معزولة
    │   ├── files/           ← Files معزولة
    │   └── code_cache/      ← Code cache معزولة
    ├── com.whatsapp_2/
    │   ├── shared_prefs/
    │   ├── databases/
    │   └── ...
    └───────────────────────────────────
  ```

### الخطوة 4: النسخة تظهر في Dashboard
- الاسم الافتراضي: `WhatsApp — Instance 1`
- يمكنك تغيير الاسم (انظر §5)

---

## 4. تشغيل / إيقاف نسخة

### تشغيل نسخة
1. اضغط **▶ Launch** على بطاقة النسخة
2. النسخة تتحول من 🔵 Idle → 🟢 Running
3. التطبيق المنسوخ يبدأ العمل داخل sandbox المعزول

### إيقاف نسخة
1. اضغط **⏹ Terminate** على بطاقة النسخة (تظهر فقط إذا النسخة شغالة)
2. النسخة تتحول من 🟢 Running → 🔵 Idle
3. البيانات يتم حفظها — لا شيء يضيع

---

## 5. إدارة النسخة (Instance Actions)

### الضغط على ⋮ (More) في بطاقة النسخة

```
┌─────────────────────────────────────────┐
│  WhatsApp — Work                        │
│  com.whatsapp                           │
│                                         │
│  📝 Rename           ← تغيير الاسم     │
│     مثلاً: "WhatsApp — شغل"            │
│                                         │
│  🧹 Clear Cache       ← تنظيف          │
│     Cache فقط، البيانات لا تضيع        │
│                                         │
│  🔗 Create Shortcut   ← إنشاء          │
│     أيقونة مباشرة على الشاشة الرئيسية  │
│                                         │
│  🗑️ Delete Instance   ← حذف النسخة     │
│     ⚠️ كل البيانات تضيع نهائياً!       │
└─────────────────────────────────────────┘
```

### Rename — تغيير اسم النسخة
```
┌─────────────────────────────────────────┐
│  Rename Instance                        │
│                                         │
│ ┌─────────────────────────────────┐     │
│ │ ✏️ WhatsApp — شغل              │     │ ← الاسم الجديد
│ └─────────────────────────────────┘     │
│                                         │
│  [Cancel]          [Save]               │
└─────────────────────────────────────────┘
```

### Delete — حذف النسخة (تأكيد مطلوب)
```
┌─────────────────────────────────────────┐
│  ❌ Delete Instance?                    │
│                                         │
│  This will permanently delete           │
│  "WhatsApp — Work" and all its data.    │
│  This action cannot be undone.          │
│                                         │
│  [Cancel]          [Delete]             │
└─────────────────────────────────────────┘
```

---

## 6. العمليات الأساسية (MethodChannel Bridge)

### ما يحدث في الخلفية عند كل عملية

| العملية | Dart → MethodChannel → Kotlin |
|---------|-------------------------------|
| **بحث التطبيقات** | `getSystemInstalledApps()` → `VirtualEngineManager.getSystemInstalledApps()` |
| **إنشاء نسخة** | `createVirtualInstance("com.whatsapp")` → إنشاء sandbox + FileRedirector mapping |
| **تشغيل نسخة** | `launchVirtualInstance("com.whatsapp", 1)` → تفعيل FileRedirector + ActivityManagerHook |
| **إيقاف نسخة** | `terminateVirtualInstance("com.whatsapp", 1)` → إلغاء تفعيل + حفظ البيانات |
| **حجم التخزين** | `getVirtualInstanceStorageSize()` → حساب حجم sandbox directory |
| **تنظيف Cache** | `clearInstanceCache()` → حذف cache/ و code_cache/ فقط |
| **حذف نهائي** | `deleteVirtualInstance()` → حذف sandbox بالكامل |

---

## 7. المحرك الافتراضي (Native Engine Architecture)

### المكونات الأساسية

```
┌─ VirtualEngineManager ─────────────────────────┐
│  orchestrator: ينسق كل العمليات               │
│  ├── ConcurrentHashMap<String, InstanceRecord> │ ← تتبع النسخ
│  ├── AtomicInteger instanceCounter             │ ← توليد IDs
│  └──────────────────────────────────────────────┘
│                                                  │
│  ┌─ PackageManagerHook ──────────────────────┐  │
│  │  ي拦截 package resolution calls           │  │
│  │  registerVirtualPackage()                 │  │
│  │  unregisterVirtualPackage()               │  │
│  └───────────────────────────────────────────┘  │
│                                                  │
│  ┌─ ActivityManagerHook ────────────────────┐  │
│  │  يدير lifecycles + task stacks           │  │
│  │  launchVirtualActivity()                 │  │
│  │  terminateVirtualActivity()              │  │
│  └───────────────────────────────────────────┘  │
│                                                  │
│  ┌─ FileRedirector ──────────────────────────┐  │
│  │  يوجه I/O إلى sandbox معزول             │  │
│  │  registerMapping() → activateMapping()   │  │
│  │  resolvePath():                           │  │
│  │    /data/user/0/com.whatsapp/             │  │
│  │    → /data/.../sandbox/com.whatsapp_1/   │  │
│  └───────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

### نظام الحماية و العزل

```
كل نسخة لها sandbox معزول تماماً:

  النسخة 1 (شغل):                    النسخة 2 ( شخصي):
  ┌──────────────────┐               ┌──────────────────┐
  │ shared_prefs/    │ ← معزول      │ shared_prefs/    │ ← معزول
  │ databases/       │ ← معزول      │ databases/       │ ← معزول
  │ cache/           │ ← معزول      │ cache/           │ ← معزول
  │ files/           │ ← معزول      │ files/           │ ← معزول
  └──────────────────┘               ┌──────────────────┘

  ✅ الحالات لا تضيع
  ✅ البيانات لا تتداخل
  ✅ النسخ اللانهائية
```

---

## 8. إعادة التحميل (Refresh)

### سحب الشاشة لأسفل (Pull to Refresh)
- يحدث حجم التخزين لكل نسخة
- يتحقق من حالة النسخة الحالية

---

## 9. حالات الاستخدام الشائعة

### مثال 1: WhatsApp شغل + شخصي
```
1. ➕ → اختر WhatsApp → النسخة 1 تظهر
2. ⋮ → Rename → "WhatsApp — شغل"
3. ➕ → اختر WhatsApp مرة أخرى → النسخة 2 تظهر
4. ⋮ → Rename → "WhatsApp — شخصي"
5. ▶ Launch على "شغل" → 🟢 Running
6. ▶ Launch على "شخصي" → 🟢 Running
   ← حسابان مختلفان يعملان في نفس الوقت!
```

### مثال 2: Telegram + Discord متعدد
```
1. ➕ → Telegram → Instance 1
2. ➕ → Telegram → Instance 2
3. ➕ → Discord → Instance 1
4. كل نسخة لها حساب مستقل وبيانات معزولة
```

### مثال 3: تنظيف Cache
```
1. ⋮ → Clear Cache على نسخة
2. يحذف cache/ و code_cache/ فقط
3. SharedPreferences و databases لا تضيع ← الحالة محفوظة
```

---

## 10. CI/CD — GitHub Actions Pipeline

### كيف يشتغل ال Build Pipeline
```
Push tag v*.*.*  أو  Manual dispatch
        │
        ▼
┌─ GitHub Actions Runner ──────────────┐
│  1. checkout@v4                       │
│  2. setup-java@v4 (JDK 17)           │
│  3. flutter-action@v2 (stable)       │
│  4. flutter pub get                   │
│  5. flutter test                      │ ← 16 unit tests
│  6. flutter build apk --release       │ ← Build APK
│  7. List artifacts                    │
│  8. Generate release notes            │
│  9. softprops/action-gh-release@v2   │ ← Upload APK to Release
└──────────────────────────────────────┘
        │
        ▼
  GitHub Release + APK artifact
  https://github.com/Monopoly63/hablas_clone/releases/tag/v1.0.0
```

---

## 11. حالة التطبيق الحالية (v1.0.0)

### ✅ ما يشتغل الآن
| الميزة | الحالة |
|--------|--------|
| Liquid Glass UI | ✅ كامل — OLED theme, Glassmorphism, Animated backgrounds |
| Dashboard | ✅ كامل — Instance grid, stats bar, status badges |
| App Picker | ✅ كامل — Search, filter, instant clone |
| Instance Actions | ✅ كامل — Rename, Clear Cache, Delete |
| MethodChannel Bridge | ✅ كامل — 8 methods bridged to Kotlin |
| VirtualEngineManager | ✅ كامل — Instance tracking, sandbox creation, lifecycle |
| FileRedirector | ✅ كامل — Mapping registration, activation, path resolution |
| PackageManagerHook | ✅ كامل — Registration infrastructure |
| ActivityManagerHook | ✅ كامل — Task stack management |
| CI/CD Pipeline | ✅ كامل — Auto build + release |
| Unit Tests | ✅ 16 tests passing |

### 🔧 قيد التطوير (v1.1+)
| الميزة | الحالة |
|--------|--------|
| تشغيل التطبيق المنسوخ فعلياً | 🔧 Needs NDK Binder proxy interception |
| Foreground Service keep-alive | 🔧 Needs native service implementation |
| Hive local persistence | 🔧 Stub ready → needs wiring |
| Home screen shortcuts | 🔧 ShortcutManager implementation |
| App icon extraction | 🔧 BasicMessageChannel for icon bytes |
| R8 minification | 🔧 Needs play-core dependency |

---

## 12. الأذونات المطلوبة

| الأذون | الاستخدام |
|--------|-----------|
| `QUERY_ALL_PACKAGES` | البحث عن التطبيقات القابلة للنسخ |
| `FOREGROUND_SERVICE` | تشغيل خدمة خلفية للحفاظ على النسخ نشطة |
| `INTERNET` | تحديثات |
| `WAKE_LOCK` | منع Doze Mode من إيقاف النسخ |
| `POST_NOTIFICATIONS` | إشعارات حالة النسخ |
| `INSTALL_SHORTCUT` | إنشاء أيقونات مباشرة على الشاشة |

---

*Built with 💎 Liquid Glass · Powered by ⚡ Virtual Engine · Crafted with ❤️*

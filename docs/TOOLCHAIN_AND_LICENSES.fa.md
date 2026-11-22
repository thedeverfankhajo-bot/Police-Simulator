# تهیهٔ ابزارها و وضعیت مجوزها — Police Simulator

تاریخ بررسی: 2026-11-22

## نتیجهٔ بررسی

- فهرست ورودی حدود ۶۰ مورد یکتا دارد. موارد تکراری یک‌بار ثبت شده‌اند: Houdini، Rive و Photoshop. «Blender Animation» قابلیت داخل Blender است، نه برنامهٔ جدا.
- Mixamo و Firebase سرویس آنلاین‌اند؛ ProBuilder و Chaos Physics به Unity/Unreal وابسته‌اند؛ بسیاری از physics SDKها کتابخانهٔ توسعه هستند، نه اپلیکیشن قابل نصب.
- مجوز نرم‌افزار پولی قابل ساختن یا انتقال از طرف مخزن نیست. حساب و مجوز باید توسط استفاده‌کننده از ناشر تهیه شود. هیچ کلید، کرک یا نسخهٔ دستکاری‌شده‌ای در مخزن قرار نمی‌گیرد.
- installerها در Git قرار نمی‌گیرند تا تاریخچهٔ مخزن با فایل‌های چندگیگابایتی آلوده نشود. دانلودها به‌صورت Artifact موقت GitHub Actions تحویل داده می‌شوند.
- در این مرحله هیچ installerای دانلود یا نصب نشده است. فایل‌های راهنما و فهرست ثبت شده‌اند؛ اجرای workflow باید از GitHub Actions انجام شود.

## فایل‌های اضافه‌شده

- toolchain/manifest.json: فهرست ساخت‌یافتهٔ ۶۰ ابزار/فناوری، مجوز، روش دریافت و لینک رسمی.
- tools/download-windows-open-source.ps1: اسکریپت موجود برای دریافت دستهٔ شروع.
- .gitignore: جلوگیری از commit شدن installerها، cacheها و خروجی build.

## دریافت دستهٔ آزادِ آماده

اسکریپت فعلی با WinGet این ۷ برنامه را دریافت می‌کند: Blender، Krita، GIMP، Inkscape، Audacity، LMMS و Tiled. installer را اجرا یا نصب نمی‌کند و SHA-256 فایل‌ها را در download-report.json ثبت می‌کند.

### اجرا روی Windows 11 / Windows Server 2025

از ریشهٔ پروژه در PowerShell این دستورها را اجرا کنید:

    Set-ExecutionPolicy -Scope Process Bypass
    .\tools\download-windows-open-source.ps1 -DownloadDirectory ".\tools\downloads" -Architecture x64

پس از اجرا، فایل‌ها در tools/downloads قرار می‌گیرند. گزارش و SHA-256 در tools/downloads/download-report.json ساخته می‌شود. پیش از نصب، ناشر، امضای دیجیتال، SHA-256 و EULA همان نسخه را بررسی کنید.

### اجرا از GitHub Actions

در GitHub به Actions بروید، workflow با نام Download open-source tool installers (Windows x64) را انتخاب کنید، سپس Run workflow را بزنید و شاخهٔ موردنظر را مشخص کنید. خروجی در Artifact با نام police-simulator-open-source-installers-windows-x64 قرار می‌گیرد و طبق workflow فعلی ۱۴ روز نگهداری می‌شود. Artifact فایل commit‌شده در مخزن نیست.

## دسته‌بندی مجوزها

| نوع | معنی در این پروژه |
|---|---|
| آزاد و متن‌باز | توزیع سورس/باینری تنها با رعایت متن مجوز، اعلان copyright و الزامات copyleft مجاز است. |
| رایگان اما اختصاصی | قیمت صفر به معنی اجازهٔ کپی یا انتشار مجدد نیست. |
| تجاری/اشتراکی | هر کاربر/تیم باید entitlement معتبر ناشر داشته باشد. |
| سرویس آنلاین | چیزی برای قرار دادن داخل مخزن وجود ندارد؛ secretها بیرون از Git نگهداری می‌شوند. |
| وابسته به موتور بازی | از داخل Unity/Unreal و تحت EULA همان موتور دریافت می‌شود. |
| نسخه‌محور/نامشخص | نسخه و EULA دقیق باید قبل از استفاده یا انتشار قفل و بررسی شود. |

## نکات حقوقی انتشار بازی

1. لایسنس ابزار ساخت با لایسنس فایل خروجی یکی نیست؛ مدل‌ها، تکسچرها، فونت‌ها، صداها، موشن‌ها، پلاگین‌ها و asset packها مجوز جداگانه دارند.
2. MIT، Apache-2.0، BSD و Zlib معمولاً استفادهٔ تجاری را اجازه می‌دهند، اما اعلان‌های مجوز و copyright باید حفظ شوند. GPL و LGPL الزام‌های copyleft خود را دارند.
3. Redis نسخهٔ ۸ به بعد انتخاب‌های AGPL-3.0، RSALv2 یا SSPLv1 دارد. نسخه و مجوز باید صریح باشد.
4. MongoDB Server تحت SSPL است؛ آن را بدون توضیح «متن‌باز OSI» معرفی نکنید.
5. FMOD می‌گوید مجوز پروژه‌های non-game از جمله simulator ممکن است سفارشی باشد؛ پوشش Indie game را مفروض نگیرید.
6. Adobe XD و Adobe Animate در maintenance mode هستند. پیش از وابسته‌کردن pipeline به آن‌ها، وضعیت پشتیبانی و جایگزین را بسنجید.
7. API keyها و رمزها در فایل‌های پروژه ذخیره نمی‌شوند؛ از GitHub Actions Secrets یا secret manager استفاده کنید.

## انتخاب عملی برای شروع

- مدل‌سازی و انیمیشن: Blender.
- نقاشی و بافت: Krita یا GIMP؛ Inkscape برای برداری.
- صدا: Audacity و LMMS.
- فیزیک: ابتدا فیزیک خود موتور بازی؛ در صورت نیاز فقط یک SDK مانند PhysX یا Jolt، نه همه.
- داده: PostgreSQL یا Supabase؛ Firebase/Appwrite/PocketBase را هم‌زمان اضافه نکنید.
- UI: Penpot برای طراحی؛ UI نهایی داخل موتور بازی پیاده‌سازی شود.

فهرست کامل و لینک رسمی هر مورد در toolchain/manifest.json است. ثبت‌شدن یک ابزار به معنی نصب‌شدن یا خریداری‌شدن مجوز آن نیست.

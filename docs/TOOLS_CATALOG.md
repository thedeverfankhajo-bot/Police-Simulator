# کاتالوگ ابزارهای تولید Police Simulator 3D

> نسخهٔ کاتالوگ: 1.1 — تاریخ بازبینی: 2026-11-21  
> این فایل فهرست دسترسی به ابزارهای درخواستی و نقش هرکدام در خط تولید بازی است؛ **نصاب یا لایسنس نرم‌افزارها را داخل Git قرار نمی‌دهد**.

نسخهٔ ماشین‌خوان همین فهرست در [tools/manifest.json](../tools/manifest.json) نگه‌داری می‌شود. راهنمای نصب و ترتیب اجرا در [TOOLCHAIN_SETUP.md](TOOLCHAIN_SETUP.md) است. ثبت در کاتالوگ به معنی دانلود یا نصب شدن برنامه روی سیستم توسعه‌دهنده نیست.

## سیاست تهیه و نگه‌داری

- برنامه‌های دسکتاپ، فایل‌های نصبی، لایسنس‌ها و حساب‌های کاربری باید مستقیماً از وب‌سایت رسمی سازنده تهیه شوند. این مخزن فقط لینک رسمی، نقش، وضعیت و راهنمای اتصال را نگه می‌دارد.
- کپی‌کردن برنامه‌های تجاری یا فایل‌های دارای محدودیت توزیع در مخزن مجاز نیست. برای وابستگی‌های متن‌باز نیز باید مجوز همان نسخه بررسی و در صورت لزوم فایل‌های مجوز و اعلان حق‌نشر حفظ شود.
- پیش از افزودن هر ابزار به خط تولید، نسخهٔ سیستم‌عامل، مجوز استفادهٔ تجاری، فرمت خروجی، هزینه و سازگاری آن بررسی شود.
- موارد تکراری فهرست اولیه (Houdini، Photoshop و Rive) یک‌بار ثبت شده‌اند. «Blender Animation» قابلیت داخلی Blender است، نه برنامه‌ای جداگانه.

## 1. مدل‌سازی و ساخت محتوای سه‌بعدی

| ابزار | کاربرد در پروژه | دریافت / وب‌سایت رسمی |
|---|---|---|
| Blender | ابزار اصلی پیشنهادی برای مدل‌سازی، UV، متریال، ریگ و انیمیشن؛ خروجی GLB/glTF | [blender.org/download](https://www.blender.org/download/) |
| Autodesk Maya | مدل‌سازی، ریگ و انیمیشن حرفه‌ای | [Autodesk Maya](https://www.autodesk.com/products/maya/overview) |
| Autodesk 3ds Max | مدل‌سازی محیط، معماری و آبجکت‌ها | [Autodesk 3ds Max](https://www.autodesk.com/products/3ds-max/overview) |
| ZBrush | مجسمه‌سازی دیجیتال و جزئیات سطح بالا | [Maxon ZBrush](https://www.maxon.net/en/zbrush) |
| Cinema 4D | مدل‌سازی، موشن‌گرافیک و رندر | [Maxon Cinema 4D](https://www.maxon.net/en/cinema-4d) |
| Houdini | ساخت رویه‌ای شهر، جاده، محیط و جلوه‌های بصری | [SideFX Houdini](https://www.sidefx.com/products/houdini/) |
| Modo | مدل‌سازی و تکسچرینگ سه‌بعدی؛ **برای خط تولید جدید پیشنهاد نمی‌شود** | [اطلاعیهٔ رسمی Foundry](https://www.foundry.com/news-and-awards/foundry-winds-down-modo-development) |
| SketchUp | بلوک‌اوت و طراحی سریع معماری شهر | [SketchUp](https://www.sketchup.com/) |

## 2. نقاشی، تکسچر و گرافیک دوبعدی

| ابزار | کاربرد در پروژه | دریافت / وب‌سایت رسمی |
|---|---|---|
| Adobe Photoshop | ویرایش تکسچر، آیکون و تصاویر تبلیغاتی | [Adobe Photoshop](https://www.adobe.com/products/photoshop.html) |
| Krita | نقاشی دیجیتال و ساخت تکسچر | [Krita Downloads](https://krita.org/en/download/) |
| GIMP | ویرایش تصویر و پردازش دسته‌ای | [GIMP Downloads](https://www.gimp.org/downloads/) |
| Aseprite | پیکسل‌آرت و آیکون‌های سبک رترو | [Aseprite](https://www.aseprite.org/) |
| Clip Studio Paint | طراحی کاراکتر، تصویرسازی و کانسپت | [Clip Studio Paint](https://www.clipstudio.net/en/) |
| Affinity Photo | نام ابزار قدیمی ویرایش تصویر؛ قابلیت‌های photo/pixel اکنون در برنامهٔ واحد جدید Affinity در کنار ابزارهای vector/layout ارائه می‌شوند | [Affinity Download](https://www.affinity.studio/download) |
| Inkscape | طراحی برداری برای نشان‌ها، نقشه‌ها و آیکون‌ها | [Inkscape Releases](https://inkscape.org/release/) |
| Piskel | ساخت پیکسل‌آرت در مرورگر | [Piskel](https://www.piskelapp.com/) |
| LibreSprite | ویرایشگر آزاد پیکسل‌آرت | [LibreSprite](https://libresprite.github.io/) |

## 3. نقشه، زمین و ساخت محیط

| ابزار | کاربرد در پروژه | دریافت / وب‌سایت رسمی |
|---|---|---|
| Tiled | ساخت نقشه و چیدمان محیط؛ مناسب داده‌های tile-based | [Tiled Map Editor](https://www.mapeditor.org/) |
| LDtk | طراحی مرحله و نقشهٔ دوبعدی ساختاریافته | [LDtk](https://ldtk.io/) |
| World Machine | تولید زمین و ارتفاع‌نگاره | [World Machine](https://www.world-machine.com/) |
| Gaea | تولید زمین رویه‌ای و فرسایش | [QuadSpinner Gaea](https://www.quadspinner.com/Download) |
| Dungeon Alchemist | چیدمان سریع محیط‌ها و فضاهای داخلی | [Dungeon Alchemist](https://www.dungeonalchemist.com/) |
| TrenchBroom | بلوک‌اوت و طراحی مرحلهٔ سه‌بعدی | [TrenchBroom](https://trenchbroom.github.io/) |
| ProBuilder | مدل‌سازی و بلوک‌اوت داخل Unity؛ بستهٔ Unity است، نه برنامهٔ مستقل | [Unity ProBuilder Manual](https://docs.unity3d.com/Packages/com.unity.probuilder@latest) |

## 4. ریگ، انیمیشن و موشن

| ابزار | کاربرد در پروژه | دریافت / وب‌سایت رسمی |
|---|---|---|
| Blender Animation | سیستم داخلی انیمیشن، ریگ و تایم‌لاین Blender | [Blender](https://www.blender.org/download/) |
| Mixamo | ریگ و انیمیشن آمادهٔ کاراکتر؛ خروجی باید از نظر مجوز و سازگاری بررسی شود | [Mixamo](https://www.mixamo.com/) |
| Spine 2D | انیمیشن استخوانی دوبعدی برای UI و عناصر دوبعدی | [Spine](https://esotericsoftware.com/) |
| DragonBones | ابزار و runtime انیمیشن استخوانی دوبعدی؛ سازگاری نسخه و runtime را پیش از استفاده آزمایش کنید | [DragonBones GitHub](https://github.com/DragonBones) |
| Adobe Animate | انیمیشن دوبعدی؛ وضعیت نگه‌داری و release notes رسمی با هم بازبینی شوند، چون یادداشت انتشار نوامبر ۲۰۲۶ نسخهٔ 27.0 و قابلیت‌های تازه را فهرست می‌کند | [Adobe Animate](https://www.adobe.com/products/animate.html) |
| Cascadeur | کمک به ساخت و اصلاح انیمیشن سه‌بعدی | [Cascadeur](https://cascadeur.com/) |
| Autodesk MotionBuilder | موشن‌کپچر و ویرایش انیمیشن کاراکتر | [Autodesk MotionBuilder](https://www.autodesk.com/products/motionbuilder/overview) |
| Rive | انیمیشن تعاملی برای رابط کاربری و عناصر دوبعدی | [Rive](https://rive.app/) |

## 5. صدا، موسیقی و میان‌افزار صوتی

| ابزار | کاربرد در پروژه | دریافت / وب‌سایت رسمی |
|---|---|---|
| Audacity | ضبط، برش و پاک‌سازی صدا | [Audacity](https://www.audacityteam.org/download/) |
| FL Studio | ساخت موسیقی و افکت صوتی | [FL Studio](https://www.image-line.com/fl-studio/) |
| REAPER | ضبط، میکس و پردازش صدا | [REAPER](https://www.reaper.fm/) |
| Ableton Live | آهنگ‌سازی و طراحی صدا | [Ableton Live](https://www.ableton.com/en/live/) |
| LMMS | آهنگ‌سازی با نرم‌افزار آزاد | [LMMS](https://lmms.io/download) |
| GarageBand | ساخت موسیقی و صدا در دستگاه‌های Apple | [GarageBand](https://www.apple.com/mac/garageband/) |
| FMOD | میان‌افزار صوتی تعاملی؛ هنگام اجرا باید با پلتفرم بازی سازگار شود | [FMOD](https://www.fmod.com/) |
| Wwise | میان‌افزار صوتی تعاملی | [Audiokinetic Wwise](https://www.audiokinetic.com/en/wwise/) |
| Bfxr | تولید افکت‌های سادهٔ بازی | [Bfxr](https://www.bfxr.net/) |
| ChipTone | تولید افکت‌های بازی؛ مجوز فایل خروجی را جدا از خود ابزار بررسی کنید | [SFBGames ChipTone](https://sfbgames.itch.io/chiptone) |

## 6. فیزیک و شبیه‌سازی

| ابزار | کاربرد در پروژه | دریافت / وب‌سایت رسمی |
|---|---|---|
| NVIDIA PhysX | موتور فیزیک سه‌بعدی؛ SDK و مجوز نسخهٔ مورد استفاده را بررسی کنید | [PhysX SDK](https://github.com/NVIDIA-Omniverse/PhysX) |
| Box2D | فیزیک دوبعدی؛ برای بخش‌های 2D، نه شبیه‌سازی اصلی خودرو در 3D | [Box2D](https://box2d.org/) |
| Jolt Physics | فیزیک و برخورد سه‌بعدی | [Jolt Physics](https://github.com/jrouwe/JoltPhysics) |
| Bullet Physics | فیزیک و تشخیص برخورد سه‌بعدی | [Bullet](https://github.com/bulletphysics/bullet3) |
| Rapier | کتابخانهٔ فیزیک دوبعدی/سه‌بعدی با اتصال مناسب به وب | [Rapier](https://rapier.rs/) |
| MuJoCo | شبیه‌سازی دقیق سیستم‌های مفصلی و پژوهشی؛ برای نسخهٔ فعلی بازی ضروری نیست | [MuJoCo](https://mujoco.org/) |
| Chaos Physics | سیستم فیزیک Unreal Engine؛ وابسته به Unreal Engine است | [Unreal Engine Physics](https://dev.epicgames.com/documentation/en-us/unreal-engine/physics-in-unreal-engine) |

## 7. پایگاه داده و سرویس‌های بک‌اند

| ابزار | کاربرد در پروژه | وب‌سایت رسمی |
|---|---|---|
| Firebase | احراز هویت، داده و سرویس‌های ابری | [Firebase](https://firebase.google.com/) |
| Supabase | بک‌اند مدیریت‌شده بر پایهٔ PostgreSQL و API | [Supabase](https://supabase.com/) |
| PostgreSQL | پایگاه دادهٔ رابطه‌ای | [PostgreSQL Downloads](https://www.postgresql.org/download/) |
| MySQL | پایگاه دادهٔ رابطه‌ای | [MySQL Downloads](https://dev.mysql.com/downloads/) |
| MongoDB | پایگاه دادهٔ سندمحور | [MongoDB](https://www.mongodb.com/try/download/community) |
| Redis | ذخیره‌سازی دادهٔ سریع و کش | [Redis](https://redis.io/downloads/) |
| PocketBase | بک‌اند سبک و خودمیزبان | [PocketBase](https://pocketbase.io/) |
| Appwrite | سرویس بک‌اند و API | [Appwrite](https://appwrite.io/) |

## 8. طراحی رابط و گرافیک برداری

| ابزار | کاربرد در پروژه | وب‌سایت رسمی |
|---|---|---|
| Figma | وایرفریم، طراحی رابط و پروتوتایپ | [Figma](https://www.figma.com/) |
| Adobe XD | طراحی رابط؛ در وضعیت Maintenance Mode است و برای پروژهٔ جدید انتخاب اول نیست | [Adobe XD Help](https://www.adobe.com/products/xd.html) |
| Penpot | طراحی رابط و پروتوتایپ با گزینهٔ متن‌باز | [Penpot](https://penpot.app/) |
| Adobe Illustrator | طراحی برداری برای آیکون، نشان و عناصر گرافیکی | [Adobe Illustrator](https://www.adobe.com/products/illustrator.html) |

## وضعیت ویژهٔ ابزارها

- **Modo:** Foundry اعلام کرد توسعهٔ Modo متوقف می‌شود؛ مقالهٔ پشتیبانی Foundry که در اکتبر ۲۰۲۶ به‌روزرسانی شده می‌گوید دیگر نسخه، مجوز یا پشتیبانی جدیدی ارائه نمی‌شود. برای خط تولید جدید انتخاب نشود.
- **Adobe XD:** صفحهٔ راهنمای Adobe همچنان آن را در وضعیت maintenance mode اعلام می‌کند؛ قابلیت‌های جدیدی در برنامه نیست.
- **Adobe Animate:** یک FAQ رسمی Adobe (ژوئن ۲۰۲۶) maintenance mode را بیان می‌کند، اما release notes رسمیِ به‌روزشده در ۱۶ نوامبر ۲۰۲۶ برای نسخهٔ 27.0 قابلیت‌هایی را فهرست کرده‌اند. به‌خاطر این تفاوت، پیش از انتخاب، آخرین release notes و اطلاعیهٔ Adobe را بررسی کنید و برچسب قدیمیِ «بدون قابلیت جدید» را قطعی فرض نکنید.
- **Affinity Photo:** تجربهٔ جدید Affinity یک برنامهٔ واحد با ابزارهای photo/pixel، vector و layout است؛ عنوان Affinity Photo برای محصول قدیمی‌تر استفاده می‌شد.
- **Gaea:** صفحهٔ رسمی دانلود ممکن است نسخهٔ پایدار و نسخهٔ آزمایشی را هم‌زمان ارائه کند؛ نسخهٔ آزمایشی را برای تولید نهایی انتخاب نکنید.
- **DragonBones:** پیش از انتخاب نهایی، فرمت export و runtime آن را با نسخهٔ Three.js و مسیر انیمیشن بازی آزمایش کنید.

## منابع رسمی برای وضعیت محصولات

- [Foundry: Modo support status](https://support.foundry.com/hc/en-us/articles/207678535-Q100035)
- [Adobe XD maintenance mode](https://helpx.adobe.com/xd/desktop.html)
- [Adobe Animate maintenance-mode FAQ](https://helpx.adobe.com/animate/desktop/kb/maintenance-mode.html)
- [Adobe Animate release notes](https://helpx.adobe.com/mena_en/animate/desktop/introduction-to-animate/release-notes.html)
- [Canva: all-new Affinity](https://www.canva.com/newsroom/news/all-new-affinity/)

## قاعدهٔ انتخاب

وجود یک ابزار در این کاتالوگ به معنی نیاز قطعی به نصب آن نیست. برای نسخهٔ فعلی مرورگری Three.js، یک مسیر اصلی و سبک انتخاب می‌کنیم و ابزارهای دیگر فقط در صورت داشتن نیاز مشخص وارد خط تولید می‌شوند. جزئیات انتخاب در [PRODUCTION_PIPELINE.md](PRODUCTION_PIPELINE.md) آمده است.

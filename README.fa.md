# Speed Tunneling
🚀 **اسکریپت حرفه‌ای مدیریت تونل‌های امن و ضد فیلترینگ با GOST**
> با تمرکز ویژه بر عبور از DPI، پایداری بالا در شبکه‌های ناپایدار و پشتیبانی از پروتکل‌های متنوع و ترکیبی (Shadowsocks، KCP، obfs4، QUIC، gRPC، TLS، WebSocket و بیش از 30 ترکیب آماده).

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.0.0-blue?style=for-the-badge&logo=linux" alt="Version">
  <img src="https://img.shields.io/badge/Platform-Linux-orange?style=for-the-badge" alt="Platform">
  <img src="https://img.shields.io/github/stars/SpeedwiT/Speed-Tunneling?style=for-the-badge&color=yellow" alt="Stars">
  <img src="https://img.shields.io/github/forks/SpeedwiT/Speed-Tunneling?style=for-the-badge&color=green" alt="Forks">
</p>

<p align="center">
  <b>ضد فیلترینگ شدید | شبکه‌های ضعیف | استریم و گیمینگ</b>
</p>

---

## ✨ ویژگی‌های کلیدی

- **پشتیبانی از بیش از ۴۰ پروفایل ترکیبی** (KCP, QUIC, gRPC, Shadowsocks, obfs4, TLS, WebSocket, Multiplex و غیره)
- **منوی تعاملی زیبا** با رنگ‌بندی و انتخاب آسان پروتکل
- **ساخت خودکار سرویس systemd** + **Restart=always**
- **Watchdog هوشمند** (با cron) برای نظارت و ری‌استارت خودکار
- **فایروال اتوماتیک** (UFW / iptables)
- **لاگ زنده** و مدیریت سرویس‌ها (Start/Stop/Edit/Logs/Delete)
- **پشتیبانی از Multi-Port Forwarding** (TCP + UDP همزمان)
- **گواهی TLS مخفی** (Stealth certificate شبیه speedtest.net)
- **بهینه برای VPS ایران و خارج** – پایداری بالا در packet loss و فیلترینگ

---

## ⚡ پروتکل‌ها و ترکیب‌های پشتیبانی‌شده

| خانواده              | پروتکل‌های اصلی                              | کاربرد اصلی                          | سطح Stealth / سرعت |
|-----------------------|-----------------------------------------------|--------------------------------------|---------------------|
| KCP Family            | Normal / Fast / Fast2 / Fast3 / Manual + obfs4 | ضد packet loss، گیمینگ، دانلود     | ★★★★☆              |
| TLS/SSL Family        | TLS, mTLS                                     | امنیت سازمانی                       | ★★★☆☆              |
| WebSocket Family      | WS, MWS, WSS, MWSS + Bind                     | شبیه ترافیک وب، عبور آسان           | ★★★★★              |
| gRPC Family           | gRPC, gRPC+TLS, gRPC+Keepalive                | ضد فیلترینگ قوی، عملکرد بالا       | ★★★★★              |
| Modern UDP            | QUIC                                          | کمترین تأخیر، استریم               | ★★★★★              |
| HTTP/2 Family         | HTTP2, H2C                                    | شبیه HTTP/2 واقعی                    | ★★★★☆              |
| Shadowsocks Family    | SS, SSU, SS+TLS, SS+WS + aes-256-gcm          | استاندارد، سریع روی سخت‌افزار مدرن | ★★★★☆              |
| Obfuscation           | obfs4, obfs4+TLS                              | حداکثر مخفی‌کاری                   | ★★★★★★             |
| Combined Recipes      | KCP+TLS, SS+QUIC, gRPC+obfs4 و بیش از ۲۰ ترکیب دیگر | سناریوهای خاص ایران               | ★★★★★              |

---

## 📥 نصب سریع (One-Click)

روی **هر دو سرور** (ایران و خارج) به عنوان **root** اجرا کنید:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SpeedwiT/Speed-Tunneling/main/Gost-Manager.sh)
```

> بعد از نصب، دستور `gost-manager` را بزنید تا منوی اصلی باز شود.


## 🖥️ راهنمای استفاده

### 🖥️ راهنمای استفاده سریع

#### ۱. سرور خارج (Kharej – Server)
1. از منوی اصلی گزینه **[2] Configure Server Tunnel (Kharej)** را انتخاب کنید  
2. **پروتکل دلخواه** را از لیست انتخاب کنید (مثلاً KCP-Fast3، SS-TCP، obfs4+TLS و غیره)  
3. **پورت Listen** (پورت گوش‌دهی سرور) را وارد کنید  
   - پیش‌فرض: ۸۴۴۳  
   - پیشنهاد: ۴۴۳، ۸۴۴۳، ۲۰۸۳ یا پورت‌های غیراستاندارد برای عبور بهتر  
4. **پسورد** تولیدشده را تأیید کنید (Y) یا دستی وارد کنید (N)  
5. اسکریپت به طور خودکار:  
   - گواهی TLS مخفی (در صورت نیاز پروتکل) تولید می‌کند  
   - فایروال (TCP/UDP) را باز می‌کند  
   - سرویس systemd می‌سازد، فعال و شروع می‌کند  
   - IP عمومی و پسورد نهایی را نمایش می‌دهد (حتماً ذخیره کنید!)

#### ۲. سرور ایران (Client)
1. از منوی اصلی گزینه **[1] Configure Client Tunnel (Iran)** را انتخاب کنید
2.  **پروتکل تونل** را انتخاب کنید  
   - **باید دقیقاً همان پروتکل سرور خارج باشد** (مثلاً اگر سرور KCP-Fast3 است، اینجا هم همان را انتخاب کنید)  
3. **اطلاعات سرور خارج** را وارد کنید:  
   - IP سرور خارج  
   - پورت تونل (همان پورت Listen سرور خارج)  
   - پسورد (دقیقاً همان پسوردی که در سرور خارج ساختید)  
4. **پورت‌های Forward** (پورت‌هایی که می‌خواهید روی ایران باز شوند) را وارد کنید  
   - مثال: `80,443,2083` (با کاما جدا کنید)   
5. **برای هر پورت** پروتکل را انتخاب کنید:  
   - ۱ = TCP only  
   - ۲ = UDP only  
   - ۳ = Both (TCP + UDP)  
   - اسکریپت فایروال را برای پروتکل انتخاب‌شده باز می‌کند
     
6. اسکریپت به طور خودکار:  
   - سرویس systemd کلاینت را می‌سازد و شروع می‌کند  
   - Watchdog (نظارت و ری‌استارت خودکار) را فعال می‌کند  
   - جزئیات اتصال (با پروتکل هر پورت) را نمایش می‌دهد


### ۳. مدیریت تونل‌ها
- List / Start / Stop / Restart / Logs / Edit / Delete
- مشاهده لاگ زنده: `journalctl -u gost-client-... -f`

---

## 📸 اسکرین‌شات‌ها

<details>
<summary>منوی اصلی (Main Menu)</summary>
<br>
<img src="images/Main_Menu.png" width="800" alt="Main Menu">
</details>

<details>
<summary>مدیریت سرویس‌ها (Manage Tunnels / Service Management)</summary>
<br>
<img src="images/Manage_Service.png" width="800" alt="Manage Service">
</details>

<details>
<summary>لاگ زنده (Live Logs)</summary>
<br>
<img src="images/Live_Logs.png" width="800" alt="Live Logs">
</details>

---

## ⭐ حمایت از پروژه

اگر این اسکریپت برات مفید بود و می‌خوای توسعه‌ش ادامه پیدا کنه:

- **ستاره** (Star) بده  
- **فورک** کن و تغییر بده  
- در گروه تلگرام یا کانال به اشتراک بذار  

**کانال تلگرام توسعه‌دهنده:** [t.me/Speedw_IT](https://t.me/Speedw_IT)  
**پشتیبانی تلگرام:** [t.me/SpeedwIT](https://t.me/SpeedwIT)  
**گیت‌هاب:** [github.com/SpeedwiT](https://github.com/SpeedwiT)

---

## 💖 حمایت مالی / Support / Donate

اگر از **Speed Tunneling** استفاده می‌کنید و می‌خواهید از توسعه این پروژه حمایت کنید، می‌توانید از طریق موارد زیر کمک کنید:

<summary>💰 ارز دیجیتال / Crypto</summary>
<br>

**Trx (TRC20):** `TWUcNhGugfjTdMiREsWfDbrZR2yq5WLsyR`  

**Usdt (Bep20):** `0xEaE80700A282970C2d7d7993F9F31a2689e37E31`
---

## 📄 لایسنس

این پروژه تحت لایسنس **MIT** منتشر شده است.  
می‌تونی آزادانه استفاده، تغییر و توزیع کنی (با ذکر منبع).


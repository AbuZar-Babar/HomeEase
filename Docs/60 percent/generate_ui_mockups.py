import os
from PIL import Image, ImageDraw, ImageFont

def create_ui_mockups(output_dir):
    os.makedirs(output_dir, exist_ok=True)
    width, height = 720, 1280
    
    # Try to load standard fonts, fallback to default
    try:
        font_large_bold = ImageFont.truetype("arialbd.ttf", 32)
        font_med_bold = ImageFont.truetype("arialbd.ttf", 24)
        font_med = ImageFont.truetype("arial.ttf", 22)
        font_small_bold = ImageFont.truetype("arialbd.ttf", 18)
        font_small = ImageFont.truetype("arial.ttf", 17)
        font_tiny = ImageFont.truetype("arial.ttf", 14)
    except:
        font_large_bold = ImageFont.load_default()
        font_med_bold = ImageFont.load_default()
        font_med = ImageFont.load_default()
        font_small_bold = ImageFont.load_default()
        font_small = ImageFont.load_default()
        font_tiny = ImageFont.load_default()

    def draw_phone_frame(draw, title="HomeEase", is_rtl=False):
        # Background
        draw.rectangle([0, 0, width, height], fill="#F8FAFC")
        
        # Status Bar
        draw.rectangle([0, 0, width, 44], fill="#0F766E")
        draw.text((36, 12), "09:41", fill="#FFFFFF", font=font_small_bold)
        draw.text((width - 120, 12), "5G  85%", fill="#FFFFFF", font=font_small_bold)
        
        # App Bar
        draw.rectangle([0, 44, width, 114], fill="#0F766E")
        if not is_rtl:
            draw.text((36, 62), title, fill="#FFFFFF", font=font_large_bold)
            # Language toggle pill
            draw.rounded_rectangle([width - 160, 60, width - 36, 100], radius=12, fill="#115E59", outline="#14B8A6", width=2)
            draw.text((width - 145, 68), "EN | اردو", fill="#FFFFFF", font=font_small_bold)
        else:
            draw.text((width - 240, 62), title, fill="#FFFFFF", font=font_large_bold)
            draw.rounded_rectangle([36, 60, 160, 100], radius=12, fill="#115E59", outline="#14B8A6", width=2)
            draw.text((50, 68), "اردو | EN", fill="#FFFFFF", font=font_small_bold)

    def draw_bottom_nav(draw, active_idx=0, is_worker=False):
        draw.rectangle([0, height - 90, width, height], fill="#FFFFFF", outline="#E2E8F0", width=1)
        labels = ["Explore", "Bookings", "Post Gig", "Profile"] if not is_worker else ["Dashboard", "Job Feed", "Schedule", "Profile"]
        slot_w = width // len(labels)
        for idx, lbl in enumerate(labels):
            cx = idx * slot_w + (slot_w // 2)
            color = "#0F766E" if idx == active_idx else "#64748B"
            fn = font_small_bold if idx == active_idx else font_small
            draw.ellipse([cx - 16, height - 76, cx + 16, height - 44], fill="#CCFBF1" if idx == active_idx else "#F1F5F9")
            draw.text((cx - len(lbl)*4, height - 34), lbl, fill=color, font=fn)

    # ---------------- 1. HOME SEARCH SCREEN ----------------
    im1 = Image.new("RGB", (width, height), "#F8FAFC")
    d1 = ImageDraw.Draw(im1)
    draw_phone_frame(d1, "HomeEase Discovery")
    
    # Location bar
    d1.rounded_rectangle([36, 130, width - 36, 180], radius=10, fill="#FFFFFF", outline="#CBD5E1", width=1)
    d1.text((56, 144), "Location: Mandian, Abbottabad (Change)", fill="#334155", font=font_small_bold)
    
    # Post Job Quick Action Banner
    d1.rounded_rectangle([36, 195, width - 36, 305], radius=14, fill="#0F766E")
    d1.text((56, 215), "Need Domestic Help Fast?", fill="#FFFFFF", font=font_med_bold)
    d1.text((56, 248), "Post an open household gig. Local cooks & cleaners apply directly.", fill="#CCFBF1", font=font_small)
    d1.rounded_rectangle([56, 270, 220, 298], radius=8, fill="#F59E0B")
    d1.text((76, 275), "POST A JOB NOW", fill="#FFFFFF", font=font_small_bold)
    
    # Service Categories Grid Header
    d1.text((36, 325), "Explore Domestic Services", fill="#0F172A", font=font_med_bold)
    
    cats = [
        ("Desi Cooking", "Breakfast, Lunch, Dinner", "#EFF6FF", "#1D4ED8"),
        ("Deep Cleaning", "Full house, Dusting, Bath", "#F0FDF4", "#15803D"),
        ("Childcare & Nanny", "Experienced Caretakers", "#FEF3C7", "#B45309"),
        ("Elderly Care", "Medical & Daily Assistance", "#FDF2F8", "#BE185D")
    ]
    for idx, (cname, cdesc, cbg, ccol) in enumerate(cats):
        row = idx // 2
        col = idx % 2
        x1 = 36 + col * (320 + 8)
        y1 = 365 + row * (115 + 10)
        d1.rounded_rectangle([x1, y1, x1 + 320, y1 + 115], radius=12, fill=cbg, outline="#E2E8F0", width=1)
        d1.ellipse([x1 + 16, y1 + 16, x1 + 60, y1 + 60], fill=ccol)
        d1.text((x1 + 28, y1 + 22), cname[0], fill="#FFFFFF", font=font_med_bold)
        d1.text((x1 + 72, y1 + 20), cname, fill="#0F172A", font=font_small_bold)
        d1.text((x1 + 72, y1 + 46), cdesc, fill="#64748B", font=font_tiny)
        d1.text((x1 + 72, y1 + 78), "View 12+ Available", fill=ccol, font=font_tiny)

    # AI Recommendation Section
    d1.text((36, 625), "AI Recommended for You (In Mandian)", fill="#0F172A", font=font_med_bold)
    d1.text((36, 655), "Matched via Skill Cosine Similarity, Haversine Proximity & Ratings", fill="#64748B", font=font_tiny)

    # Worker Card 1
    d1.rounded_rectangle([36, 680, width - 36, 850], radius=14, fill="#FFFFFF", outline="#CBD5E1", width=1)
    d1.ellipse([56, 705, 116, 765], fill="#0F766E")
    d1.text((76, 720), "SB", fill="#FFFFFF", font=font_med_bold)
    d1.text((130, 705), "Sultana Bibi", fill="#0F172A", font=font_med_bold)
    d1.text((280, 707), "[NADRA Verified]", fill="#15803D", font=font_small_bold)
    d1.text((130, 735), "Expert Desi Cook & Daily Cleaner • 7 yrs exp", fill="#475569", font=font_small)
    # AI Match Badge
    d1.rounded_rectangle([130, 765, 480, 798], radius=8, fill="#CCFBF1")
    d1.text((142, 772), "95% AI Match • 1.1 km away • Desi Cooking fit", fill="#0F766E", font=font_small_bold)
    d1.text((130, 810), "PKR 750 / visit  |  4.8 ★ (24 reviews)", fill="#0F172A", font=font_small_bold)
    d1.rounded_rectangle([width - 180, 795, width - 56, 835], radius=8, fill="#0F766E")
    d1.text((width - 155, 804), "Book Now", fill="#FFFFFF", font=font_small_bold)

    # Worker Card 2
    d1.rounded_rectangle([36, 865, width - 36, 1035], radius=14, fill="#FFFFFF", outline="#CBD5E1", width=1)
    d1.ellipse([56, 890, 116, 950], fill="#3B82F6")
    d1.text((76, 905), "MR", fill="#FFFFFF", font=font_med_bold)
    d1.text((130, 890), "Muhammad Rafiq", fill="#0F172A", font=font_med_bold)
    d1.text((330, 892), "[Verified]", fill="#15803D", font=font_small_bold)
    d1.text((130, 920), "General Maintenance, Dusting & Painting • 5 yrs exp", fill="#475569", font=font_small)
    d1.rounded_rectangle([130, 950, 480, 983], radius=8, fill="#CCFBF1")
    d1.text((142, 957), "91% AI Match • 1.8 km away • All-Rounder", fill="#0F766E", font=font_small_bold)
    d1.text((130, 995), "PKR 650 / hr  |  4.9 ★ (38 reviews)", fill="#0F172A", font=font_small_bold)
    d1.rounded_rectangle([width - 180, 980, width - 56, 1020], radius=8, fill="#0F766E")
    d1.text((width - 155, 989), "Book Now", fill="#FFFFFF", font=font_small_bold)

    draw_bottom_nav(d1, 0, is_worker=False)
    im1.save(os.path.join(output_dir, "fig_5_1_home_search.png"))

    # ---------------- 2. POST JOB SCREEN ----------------
    im2 = Image.new("RGB", (width, height), "#F8FAFC")
    d2 = ImageDraw.Draw(im2)
    draw_phone_frame(d2, "Post a Domestic Job")
    
    # Step indicator
    d2.rounded_rectangle([36, 130, width - 36, 175], radius=10, fill="#E0F2FE")
    d2.text((56, 142), "Step 2 of 4: Task Scope & Abbottabad Locality", fill="#0369A1", font=font_small_bold)
    
    # Form fields
    fields = [
        ("Job Title", "Need Daily Cook for Family of 5 in Mandian"),
        ("Service Category", "Cooking (Breakfast & Lunch Preparation)"),
        ("Abbottabad Locality", "Mandian, Near Women Medical College"),
        ("Preferred Schedule", "Daily Morning (08:00 AM - 11:30 AM)"),
        ("Proposed Budget (PKR)", "18,000 / Month (Negotiable)"),
        ("Special Instructions", "Must know hygienic Pakistani desi dishes (Roti, Salan, Daal). Non-smoker required.")
    ]
    cur_y = 195
    for label, val in fields:
        d2.text((36, cur_y), label, fill="#0F172A", font=font_small_bold)
        d2.rounded_rectangle([36, cur_y + 24, width - 36, cur_y + 78], radius=8, fill="#FFFFFF", outline="#CBD5E1", width=1)
        d2.text((50, cur_y + 38), val, fill="#334155", font=font_small)
        cur_y += 92

    # Verification notice
    d2.rounded_rectangle([36, cur_y + 20, width - 36, cur_y + 110], radius=10, fill="#FEF3C7", outline="#F59E0B", width=1)
    d2.text((56, cur_y + 35), "Instant Matching Notification:", fill="#B45309", font=font_small_bold)
    d2.text((56, cur_y + 60), "Publishing this gig will alert 14 verified cooks in Mandian & Jhangi.", fill="#78350F", font=font_tiny)

    # Submit button
    d2.rounded_rectangle([36, height - 190, width - 36, height - 120], radius=12, fill="#0F766E")
    d2.text((width // 2 - 120, height - 165), "PUBLISH GIG TO MARKETPLACE", fill="#FFFFFF", font=font_med_bold)
    
    draw_bottom_nav(d2, 2, is_worker=False)
    im2.save(os.path.join(output_dir, "fig_5_2_post_job.png"))

    # ---------------- 3. WORKER JOB FEED SCREEN ----------------
    im3 = Image.new("RGB", (width, height), "#F8FAFC")
    d3 = ImageDraw.Draw(im3)
    draw_phone_frame(d3, "Available Jobs Feed")
    
    # Filter chip row
    d3.rounded_rectangle([36, 130, 220, 170], radius=20, fill="#0F766E")
    d3.text((56, 140), "All Abbottabad (14)", fill="#FFFFFF", font=font_small_bold)
    d3.rounded_rectangle([230, 130, 420, 170], radius=20, fill="#FFFFFF", outline="#CBD5E1")
    d3.text((250, 140), "Mandian (6)", fill="#475569", font=font_small)
    d3.rounded_rectangle([430, 130, 600, 170], radius=20, fill="#FFFFFF", outline="#CBD5E1")
    d3.text((450, 140), "Cooking Only (8)", fill="#475569", font=font_small)

    gigs = [
        ("Need Daily Cook for Family of 5", "Ahmed Khan (Household Employer)", "Mandian (1.2 km away)", "PKR 18,000 / month", "Starts Oct 5 • 8am-11am", "#10B981"),
        ("Weekend Deep Cleaning & Dusting", "Tariq Mehmood (Household Employer)", "Supply Bazaar (2.4 km away)", "PKR 4,500 / 2 Days", "Oct 10-11 • Flexible", "#3B82F6"),
        ("Full-Time Maid for Housework", "Dr. Usman (Household Employer)", "Jhangi Syedan (1.8 km away)", "PKR 22,000 / month", "Starts Immediately", "#8B5CF6"),
        ("Elderly Care Companion", "Mrs. Aslam (Household Employer)", "Nawan Shehr (3.5 km away)", "PKR 15,000 / month", "Evening 4pm-8pm", "#EC4899")
    ]
    cur_y = 190
    for title, emp, loc, bud, time_str, col in gigs:
        d3.rounded_rectangle([36, cur_y, width - 36, cur_y + 195], radius=14, fill="#FFFFFF", outline="#CBD5E1", width=1)
        d3.rectangle([36, cur_y, 46, cur_y + 195], fill=col)
        d3.text((60, cur_y + 16), title, fill="#0F172A", font=font_med_bold)
        d3.text((60, cur_y + 48), emp, fill="#475569", font=font_small)
        d3.text((60, cur_y + 76), f"Location: {loc}  |  {time_str}", fill="#64748B", font=font_tiny)
        
        d3.rounded_rectangle([60, cur_y + 110, 260, cur_y + 145], radius=8, fill="#F1F5F9")
        d3.text((70, cur_y + 118), f"Budget: {bud}", fill="#0F766E", font=font_small_bold)
        
        # 1-Tap Apply Button
        d3.rounded_rectangle([width - 220, cur_y + 120, width - 56, cur_y + 175], radius=10, fill="#0F766E")
        d3.text((width - 190, cur_y + 135), "1-Tap Apply", fill="#FFFFFF", font=font_small_bold)
        cur_y += 215

    draw_bottom_nav(d3, 1, is_worker=True)
    im3.save(os.path.join(output_dir, "fig_5_3_worker_job_feed.png"))

    # ---------------- 4. WORKER LIST WITH XAI BADGES ----------------
    im4 = Image.new("RGB", (width, height), "#F8FAFC")
    d4 = ImageDraw.Draw(im4)
    draw_phone_frame(d4, "Ranked Workers (XAI)")
    
    # XAI Info header
    d4.rounded_rectangle([36, 130, width - 36, 210], radius=12, fill="#CCFBF1", outline="#14B8A6", width=1)
    d4.text((56, 142), "Explainable AI (XAI) Scoring Active:", fill="#0F766E", font=font_small_bold)
    d4.text((56, 170), "Rank = 0.50(Skill Cosine) + 0.35(Haversine Geo) + 0.15(Rating)", fill="#115E59", font=font_tiny)
    d4.text((56, 188), "Proximity Decay Alpha = 0.2 km^-1 | Bayesian Prior R = 3.5", fill="#115E59", font=font_tiny)

    workers = [
        ("Sultana Bibi", "95% Match", "Mandian (1.1 km away)", "4.8 ★ (24)", "PKR 750 / visit", "Desi Cooking, Roti, Biryani", "Verified CNIC & Police Clear", "#0F766E"),
        ("Parveen Akhtar", "89% Match", "Jhangi Syedan (2.3 km away)", "4.9 ★ (41)", "PKR 650 / visit", "Baking, Continental, Cleaning", "Verified CNIC", "#0284C7"),
        ("Razia Begum", "84% Match", "Supply Bazaar (3.1 km away)", "4.7 ★ (18)", "PKR 800 / visit", "Desi Cooking, Cleaning", "Verified CNIC", "#7C3AED"),
        ("Kiran Shahzadi", "79% Match", "PMA Road (4.2 km away)", "New (3.5 prior)", "PKR 600 / visit", "Cooking Assistant, Salan", "Verification Pending", "#D97706")
    ]
    cur_y = 225
    for name, match, loc, rat, rate, skills, ver, col in workers:
        d4.rounded_rectangle([36, cur_y, width - 36, cur_y + 185], radius=12, fill="#FFFFFF", outline="#CBD5E1", width=1)
        d4.ellipse([56, cur_y + 16, 106, cur_y + 66], fill=col)
        d4.text((70, cur_y + 26), name[0], fill="#FFFFFF", font=font_med_bold)
        
        d4.text((120, cur_y + 16), name, fill="#0F172A", font=font_med_bold)
        # Match Pill
        d4.rounded_rectangle([width - 190, cur_y + 14, width - 56, cur_y + 46], radius=16, fill="#CCFBF1")
        d4.text((width - 175, cur_y + 20), match, fill="#0F766E", font=font_small_bold)
        
        d4.text((120, cur_y + 48), f"{loc}  |  {rat}", fill="#475569", font=font_small)
        d4.text((120, cur_y + 74), f"Skills: {skills}", fill="#64748B", font=font_tiny)
        d4.text((120, cur_y + 98), f"Trust: {ver}", fill="#15803D" if "Verified" in ver else "#B45309", font=font_tiny)
        
        d4.rounded_rectangle([56, cur_y + 130, 240, cur_y + 168], radius=8, fill="#F8FAFC")
        d4.text((68, cur_y + 140), rate, fill="#0F172A", font=font_small_bold)
        
        d4.rounded_rectangle([width - 180, cur_y + 128, width - 56, cur_y + 172], radius=8, fill="#0F766E")
        d4.text((width - 150, cur_y + 138), "View Profile", fill="#FFFFFF", font=font_small)
        cur_y += 200

    draw_bottom_nav(d4, 0, is_worker=False)
    im4.save(os.path.join(output_dir, "fig_5_4_worker_list_xai.png"))

    # ---------------- 5. WORKER DASHBOARD SCREEN ----------------
    im5 = Image.new("RGB", (width, height), "#F8FAFC")
    d5 = ImageDraw.Draw(im5)
    draw_phone_frame(d5, "Worker Dashboard")
    
    # Active Status & Language
    d5.rounded_rectangle([36, 130, width - 36, 190], radius=12, fill="#FFFFFF", outline="#CBD5E1")
    d5.ellipse([56, 150, 76, 170], fill="#10B981")
    d5.text((90, 146), "You are Online & Available in Mandian", fill="#0F172A", font=font_small_bold)
    d5.text((90, 168), "Locals can discover your profile for cooking tasks", fill="#64748B", font=font_tiny)

    # Metric Cards (3 stats)
    metrics = [
        ("Earnings", "PKR 32.5k", "#10B981"),
        ("Jobs Done", "18 Tasks", "#3B82F6"),
        ("Rating", "4.85 ★", "#F59E0B")
    ]
    for idx, (mtitle, mval, mcol) in enumerate(metrics):
        x1 = 36 + idx * (205 + 15)
        d5.rounded_rectangle([x1, 205, x1 + 205, 295], radius=12, fill="#FFFFFF", outline="#CBD5E1")
        d5.text((x1 + 16, 218), mtitle, fill="#64748B", font=font_tiny)
        d5.text((x1 + 16, 246), mval, fill=mcol, font=font_med_bold)

    # Bidirectional Marketplace Quick Nav
    d5.rounded_rectangle([36, 310, width - 36, 420], radius=14, fill="#0F766E")
    d5.text((56, 328), "14 Open Household Gigs in Abbottabad!", fill="#FFFFFF", font=font_med_bold)
    d5.text((56, 362), "Employers posted tasks in Mandian & Supply. Browse and bid now.", fill="#CCFBF1", font=font_small)
    d5.rounded_rectangle([56, 385, 260, 412], radius=6, fill="#F59E0B")
    d5.text((70, 390), "BROWSE OPEN GIGS FEED", fill="#FFFFFF", font=font_small_bold)

    # Incoming Booking Requests
    d5.text((36, 440), "Direct Booking Requests (Action Required)", fill="#0F172A", font=font_med_bold)
    
    requests = [
        ("Tariq Mehmood", "Mandian (0.8 km)", "Deep Cleaning - 4 Rooms", "Tomorrow, 09:00 AM", "PKR 2,200", "#10B981"),
        ("Ayesha Siddiqui", "Supply (2.1 km)", "Desi Dinner Party Cooking", "Oct 6, 04:00 PM", "PKR 3,500", "#3B82F6")
    ]
    cur_y = 475
    for rname, rloc, rserv, rdate, rfee, rcol in requests:
        d5.rounded_rectangle([36, cur_y, width - 36, cur_y + 200], radius=14, fill="#FFFFFF", outline="#CBD5E1")
        d5.text((56, cur_y + 16), rname, fill="#0F172A", font=font_med_bold)
        d5.text((260, cur_y + 18), f"• {rloc}", fill="#64748B", font=font_small)
        d5.text((56, cur_y + 50), f"Service: {rserv}", fill="#334155", font=font_small_bold)
        d5.text((56, cur_y + 78), f"Requested Time: {rdate}", fill="#64748B", font=font_small)
        d5.text((56, cur_y + 106), f"Offered Fee: {rfee}", fill="#0F766E", font=font_small_bold)
        
        # Action Buttons
        d5.rounded_rectangle([56, cur_y + 140, 240, cur_y + 185], radius=8, fill="#10B981")
        d5.text((95, cur_y + 152), "ACCEPT", fill="#FFFFFF", font=font_small_bold)
        d5.rounded_rectangle([260, cur_y + 140, 420, cur_y + 185], radius=8, fill="#EF4444")
        d5.text((300, cur_y + 152), "DECLINE", fill="#FFFFFF", font=font_small_bold)
        cur_y += 220

    draw_bottom_nav(d5, 0, is_worker=True)
    im5.save(os.path.join(output_dir, "fig_5_5_worker_dashboard.png"))

    # ---------------- 6. BILINGUAL URDU & VISUAL ICONS SCREEN ----------------
    im6 = Image.new("RGB", (width, height), "#F8FAFC")
    d6 = ImageDraw.Draw(im6)
    draw_phone_frame(d6, "ہوم ایز (HomeEase)", is_rtl=True)
    
    # Locality in Urdu
    d6.rounded_rectangle([36, 130, width - 36, 180], radius=10, fill="#FFFFFF", outline="#CBD5E1")
    d6.text((width - 320, 144), "مقام: مانڈہ، ایبٹ آباد (تبدیل کریں)", fill="#334155", font=font_small_bold)
    
    # High-Affordance Icon Category Grid for Low-Literacy Workers
    d6.text((width - 360, 200), "گھریلو کام کی کیٹیگریز (بصری نشانات)", fill="#0F172A", font=font_med_bold)
    
    urdu_cats = [
        ("کھانا پکانا (Cooking)", "روٹی، سالن اور ناشتہ", "#EFF6FF", "#1D4ED8", "[ دیگچی / Pot ]"),
        ("جھاڑو اور صفائی (Cleaning)", "گھر اور کمروں کی صفائی", "#F0FDF4", "#15803D", "[ جھاڑو / Broom ]"),
        ("بچوں کی دیکھ بھال (Child)", "تجربہ کار آیا / نینی", "#FEF3C7", "#B45309", "[ پرام / Stroller ]"),
        ("بزرگوں کی نگہداشت (Care)", "بزرگوں کے کام میں مدد", "#FDF2F8", "#BE185D", "[ وہیل چیئر / Wheelchair ]")
    ]
    cur_y = 245
    for ctitle, csub, cbg, ccol, icon_label in urdu_cats:
        d6.rounded_rectangle([36, cur_y, width - 36, cur_y + 115], radius=14, fill=cbg, outline="#CBD5E1")
        # Visual Icon Pill on left/right
        d6.rounded_rectangle([width - 190, cur_y + 16, width - 56, cur_y + 95], radius=12, fill=ccol)
        d6.text((width - 180, cur_y + 45), icon_label[:6], fill="#FFFFFF", font=font_small_bold)
        
        d6.text((60, cur_y + 24), ctitle, fill="#0F172A", font=font_med_bold)
        d6.text((60, cur_y + 58), csub, fill="#475569", font=font_small)
        d6.text((60, cur_y + 86), icon_label, fill=ccol, font=font_tiny)
        cur_y += 130

    # Urdu Job Card
    d6.text((width - 320, cur_y + 10), "نئی ملازمتیں (ملازمین کیلئے فیڈ)", fill="#0F172A", font=font_med_bold)
    cur_y += 50
    d6.rounded_rectangle([36, cur_y, width - 36, cur_y + 175], radius=14, fill="#FFFFFF", outline="#CBD5E1")
    d6.text((width - 350, cur_y + 18), "پانچ افراد کے کھانے کیلئے باورچی درکار", fill="#0F172A", font=font_med_bold)
    d6.text((width - 290, cur_y + 54), "مقام: مانڈہ (1.2 کلومیٹر فاصلہ)", fill="#475569", font=font_small)
    d6.text((width - 240, cur_y + 82), "معاوضہ: 18,000 روپے ماہانہ", fill="#0F766E", font=font_small_bold)
    
    d6.rounded_rectangle([56, cur_y + 115, 260, cur_y + 160], radius=8, fill="#0F766E")
    d6.text((75, cur_y + 125), "درخواست جمع کریں (Apply)", fill="#FFFFFF", font=font_small_bold)

    draw_bottom_nav(d6, 0, is_worker=True)
    im6.save(os.path.join(output_dir, "fig_5_6_bilingual_urdu_icons.png"))

    print("All 6 UI mockup screens successfully created in:", output_dir)

if __name__ == "__main__":
    create_ui_mockups(r"c:\Users\AbuZar\Desktop\Fyp\HomeEase\Docs\60 percent\diagrams")

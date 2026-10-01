import os
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def build_thesis_docx(output_path, diagram_dir):
    doc = Document()
    
    # Page setup - Margins: 1 inch (72 pt) all around matching TrekPal
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        
        # Configure Header and Footer matching TrekPal benchmark
        header = section.header
        p_head = header.paragraphs[0]
        p_head.text = "HomeEase — 60% Thesis Report"
        p_head.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        if p_head.runs:
            p_head.runs[0].font.name = "Times New Roman"
            p_head.runs[0].font.size = Pt(8.5)
            p_head.runs[0].font.italic = True
            p_head.runs[0].font.color.rgb = RGBColor(148, 163, 184)
            
        footer = section.footer
        p_foot = footer.paragraphs[0]
        p_foot.text = "Department of Computer Science, CUI, Abbottabad Campus"
        p_foot.alignment = WD_ALIGN_PARAGRAPH.LEFT
        if p_foot.runs:
            p_foot.runs[0].font.name = "Times New Roman"
            p_foot.runs[0].font.size = Pt(9)
            p_foot.runs[0].font.italic = True
            p_foot.runs[0].font.color.rgb = RGBColor(100, 116, 139)

    # Typography & Styling Helpers
    def set_font(run, name="Times New Roman", size_pt=12, bold=False, italic=False, color_rgb=(0,0,0)):
        run.font.name = name
        run.font.size = Pt(size_pt)
        run.font.bold = bold
        run.font.italic = italic
        run.font.color.rgb = RGBColor(*color_rgb)

    def add_p(text="", align=WD_ALIGN_PARAGRAPH.LEFT, space_before=0, space_after=6, line_spacing=1.15):
        p = doc.add_paragraph()
        p.alignment = align
        p.paragraph_format.space_before = Pt(space_before)
        p.paragraph_format.space_after = Pt(space_after)
        p.paragraph_format.line_spacing = line_spacing
        if text:
            r = p.add_run(text)
            set_font(r, "Times New Roman", 12)
        return p

    def add_h1(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(20)
        p.paragraph_format.space_after = Pt(8)
        p.paragraph_format.keep_with_next = True
        r = p.add_run(text)
        set_font(r, "Times New Roman", 18, bold=True, color_rgb=(15, 118, 110)) # Teal 700
        return p

    def add_h2(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(14)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.keep_with_next = True
        r = p.add_run(text)
        set_font(r, "Times New Roman", 14, bold=True, color_rgb=(17, 94, 89)) # Teal 800
        return p

    def add_h3(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(10)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.keep_with_next = True
        r = p.add_run(text)
        set_font(r, "Times New Roman", 12, bold=True, color_rgb=(30, 41, 59)) # Slate 800
        return p

    def add_img(filename, caption, width_in=5.8):
        path = os.path.join(diagram_dir, filename)
        if os.path.exists(path):
            p = doc.add_paragraph()
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.space_before = Pt(12)
            p.paragraph_format.space_after = Pt(4)
            p.paragraph_format.keep_with_next = True
            run = p.add_run()
            run.add_picture(path, width=Inches(width_in))
            
            p_cap = doc.add_paragraph()
            p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p_cap.paragraph_format.space_before = Pt(2)
            p_cap.paragraph_format.space_after = Pt(12)
            r_cap = p_cap.add_run(caption)
            set_font(r_cap, "Times New Roman", 10, italic=True, color_rgb=(51, 65, 85))
        else:
            p = doc.add_paragraph()
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r = p.add_run(f"[{caption} - Image File Not Found: {filename}]")
            set_font(r, "Times New Roman", 10, italic=True, color_rgb=(220, 38, 38))

    def set_cell_background(cell, fill_hex):
        shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
        cell._tc.get_or_add_tcPr().append(shd)

    def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
        tcPr = cell._tc.get_or_add_tcPr()
        tcMar = OxmlElement('w:tcMar')
        for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
            node = OxmlElement(f'w:{m}')
            node.set(qn('w:w'), str(val))
            node.set(qn('w:type'), 'dxa')
            tcMar.append(node)
        tcPr.append(tcMar)

    def format_table(table, col_widths=None, header_bg="0F766E"):
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        table.autofit = False
        tblPr = table._tbl.tblPr
        borders = parse_xml(f'''
            <w:tblBorders {nsdecls("w")}>
                <w:top w:val="single" w:sz="6" w:space="0" w:color="0F766E"/>
                <w:bottom w:val="single" w:sz="6" w:space="0" w:color="0F766E"/>
                <w:left w:val="none"/>
                <w:right w:val="none"/>
                <w:insideH w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>
                <w:insideV w:val="none"/>
            </w:tblBorders>
        ''')
        tblPr.append(borders)
        
        # Header formatting
        for idx, cell in enumerate(table.rows[0].cells):
            set_cell_background(cell, header_bg)
            set_cell_margins(cell, top=120, bottom=120, left=150, right=150)
            for p in cell.paragraphs:
                p.alignment = WD_ALIGN_PARAGRAPH.LEFT
                p.paragraph_format.space_before = Pt(0)
                p.paragraph_format.space_after = Pt(0)
                for r in p.runs:
                    set_font(r, "Times New Roman", 10.5, bold=True, color_rgb=(255, 255, 255))
        
        # Row formatting
        for r_idx, row in enumerate(table.rows[1:], start=1):
            bg = "F8FAFC" if r_idx % 2 == 1 else "FFFFFF"
            for cell in row.cells:
                set_cell_background(cell, bg)
                set_cell_margins(cell, top=90, bottom=90, left=140, right=140)
                for p in cell.paragraphs:
                    p.paragraph_format.space_before = Pt(0)
                    p.paragraph_format.space_after = Pt(0)
                    p.paragraph_format.line_spacing = 1.15
                    for r in p.runs:
                        set_font(r, "Times New Roman", 10, bold=False, color_rgb=(15, 23, 42))

        if col_widths:
            for row in table.rows:
                for idx, w in enumerate(col_widths):
                    row.cells[idx].width = Inches(w)

    def add_uc_table(uc_id, name, actor, desc, trigger, pre, post, main_steps, alt_steps):
        p_cap = doc.add_paragraph()
        p_cap.paragraph_format.space_before = Pt(10)
        p_cap.paragraph_format.space_after = Pt(4)
        p_cap.paragraph_format.keep_with_next = True
        r_cap = p_cap.add_run(f"Table: Specification for {uc_id} — {name}")
        set_font(r_cap, "Times New Roman", 10.5, bold=True, italic=True, color_rgb=(15, 118, 110))

        t = doc.add_table(rows=8, cols=2)
        fields = [
            ("Use Case ID", uc_id),
            ("Use Case Name", name),
            ("Primary Actor", actor),
            ("Description", desc),
            ("Trigger Event", trigger),
            ("Preconditions", pre),
            ("Postconditions", post),
            ("Main Success Flow", main_steps),
        ]
        if alt_steps:
            row_alt = t.add_row()
            fields.append(("Alternative Flows", alt_steps))
            
        t.rows[0].cells[0].paragraphs[0].text = "Specification Field"
        t.rows[0].cells[1].paragraphs[0].text = "Detailed System Behavior"
        
        for idx, (f_name, f_val) in enumerate(fields, start=1):
            if idx < len(t.rows):
                p0 = t.rows[idx].cells[0].paragraphs[0]
                p0.text = f_name
                set_font(p0.runs[0], "Times New Roman", 10, bold=True)
                p1 = t.rows[idx].cells[1].paragraphs[0]
                p1.text = f_val
                set_font(p1.runs[0], "Times New Roman", 10, bold=False)
                
        format_table(t, col_widths=[1.6, 4.9], header_bg="115E59")
        doc.add_paragraph().paragraph_format.space_after = Pt(8)

    def add_code_block(code_text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(8)
        p.paragraph_format.space_after = Pt(8)
        p.paragraph_format.line_spacing = 1.05
        pPr = p._p.get_or_add_pPr()
        pBdr = parse_xml(f'''
            <w:pBdr {nsdecls("w")}>
                <w:top w:val="single" w:sz="4" w:space="4" w:color="CBD5E1"/>
                <w:left w:val="single" w:sz="12" w:space="8" w:color="0F766E"/>
                <w:bottom w:val="single" w:sz="4" w:space="4" w:color="CBD5E1"/>
                <w:right w:val="single" w:sz="4" w:space="4" w:color="CBD5E1"/>
            </w:pBdr>
        ''')
        pPr.append(pBdr)
        shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="F8FAFC"/>')
        pPr.append(shd)
        r = p.add_run(code_text)
        set_font(r, "Consolas", 9.5, color_rgb=(15, 23, 42))
        return p

    # ==================== COVER / TITLE PAGE ====================
    # Logo & CUI Header matching TrekPal layout
    logo_path = os.path.join(diagram_dir, "cui_logo.jpeg")
    if os.path.exists(logo_path):
        t_head = doc.add_table(rows=1, cols=2)
        t_head.alignment = WD_TABLE_ALIGNMENT.CENTER
        t_head.autofit = False
        t_head.rows[0].cells[0].width = Inches(1.5)
        t_head.rows[0].cells[1].width = Inches(5.0)
        
        p_logo = t_head.rows[0].cells[0].paragraphs[0]
        p_logo.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r_l = p_logo.add_run()
        r_l.add_picture(logo_path, width=Inches(1.3))
        
        p_cu = t_head.rows[0].cells[1].paragraphs[0]
        p_cu.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p_cu.paragraph_format.space_before = Pt(14)
        r_c1 = p_cu.add_run("COMSATS University Islamabad\n")
        set_font(r_c1, "Times New Roman", 15, bold=True, color_rgb=(15, 23, 42))
        r_c2 = p_cu.add_run("Abbottabad Campus, Pakistan\nDepartment of Computer Science")
        set_font(r_c2, "Times New Roman", 12, bold=True, color_rgb=(71, 85, 105))
        
        # Remove borders from header table
        tblPr = t_head._tbl.tblPr
        tblBorders = parse_xml(f'''
            <w:tblBorders {nsdecls("w")}>
                <w:top w:val="none"/><w:left w:val="none"/><w:bottom w:val="none"/><w:right w:val="none"/>
                <w:insideH w:val="none"/><w:insideV w:val="none"/>
            </w:tblBorders>
        ''')
        tblPr.append(tblBorders)
    else:
        p_inst = add_p("COMSATS UNIVERSITY ISLAMABAD", align=WD_ALIGN_PARAGRAPH.CENTER, space_before=20, space_after=2)
        set_font(p_inst.runs[0], "Times New Roman", 16, bold=True, color_rgb=(15, 23, 42))
        p_campus = add_p("Abbottabad Campus\nDepartment of Computer Science", align=WD_ALIGN_PARAGRAPH.CENTER, space_before=2, space_after=24)
        set_font(p_campus.runs[0], "Times New Roman", 13, bold=True, color_rgb=(71, 85, 105))

    p_title = add_p("HomeEase: Hyper-Local Domestic Worker Connect Platform with Explainable AI Recommendation & Bidirectional Marketplace", align=WD_ALIGN_PARAGRAPH.CENTER, space_before=28, space_after=24)
    set_font(p_title.runs[0], "Times New Roman", 20, bold=True, color_rgb=(15, 118, 110))
    
    p_rep = add_p("60% Evaluation Thesis Report", align=WD_ALIGN_PARAGRAPH.CENTER, space_before=6, space_after=24)
    set_font(p_rep.runs[0], "Times New Roman", 15, italic=True, bold=True, color_rgb=(51, 65, 85))
    
    p_sub = add_p("A project presented in partial fulfillment of the requirements for the degree of\nBachelor of Science in Software Engineering / Computer Science (Session 2022–2026)", align=WD_ALIGN_PARAGRAPH.CENTER, space_before=4, space_after=24)
    set_font(p_sub.runs[0], "Times New Roman", 11, italic=True)
    
    p_by = add_p("Submitted By:", align=WD_ALIGN_PARAGRAPH.CENTER, space_before=8, space_after=6)
    set_font(p_by.runs[0], "Times New Roman", 12, bold=True)
    
    t_std = doc.add_table(rows=3, cols=2)
    t_std.alignment = WD_TABLE_ALIGNMENT.CENTER
    students = [
        ("Hashir Hamid", "CIIT/FA22-BSE-139/ATD"),
        ("Aman Ullah Khan", "CIIT/FA22-BSE-074/ATD"),
        ("Umar Saeed", "CIIT/FA22-BCS-041/ATD")
    ]
    for idx, (name, reg) in enumerate(students):
        p0 = t_std.rows[idx].cells[0].paragraphs[0]
        p0.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p0.text = name
        set_font(p0.runs[0], "Times New Roman", 11.5, bold=True)
        p1 = t_std.rows[idx].cells[1].paragraphs[0]
        p1.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p1.text = reg
        set_font(p1.runs[0], "Times New Roman", 11)
    for r in t_std.rows:
        r.cells[0].width = Inches(2.6)
        r.cells[1].width = Inches(2.6)
    
    tblPr = t_std._tbl.tblPr
    tblBorders = parse_xml(f'''
        <w:tblBorders {nsdecls("w")}>
            <w:top w:val="none"/><w:left w:val="none"/><w:bottom w:val="none"/><w:right w:val="none"/>
            <w:insideH w:val="none"/><w:insideV w:val="none"/>
        </w:tblBorders>
    ''')
    tblPr.append(tblBorders)

    doc.add_paragraph().paragraph_format.space_after = Pt(14)
    p_sup = add_p("Supervised By:\nSir Sumair Khan\nLecturer, Department of Computer Science", align=WD_ALIGN_PARAGRAPH.CENTER, space_before=8, space_after=24)
    set_font(p_sup.runs[0], "Times New Roman", 12, bold=True)
    
    p_dec = add_p("The candidate confirms that the work submitted is their own and appropriate credit has been given where reference has been made to the work of others.", align=WD_ALIGN_PARAGRAPH.CENTER, space_before=10, space_after=10)
    set_font(p_dec.runs[0], "Times New Roman", 10, italic=True)

    doc.add_page_break()

    # ==================== DECLARATION & UNDERTAKING ====================
    add_h2("Certificate of Approval & Declaration of Authorship")
    add_p("We hereby declare that this 60% Final Year Project Thesis Report entitled \"HomeEase: Hyper-Local Domestic Worker Connect Platform with Explainable AI Recommendation and Bidirectional Marketplace\" is our own original work. No portion of this work has been submitted in support of any other application for another degree or qualification at this or any other university or institute of learning. Appropriate credit, citations, and references have been duly provided wherever external concepts, libraries, frameworks, or standards have been consulted.")
    
    add_p("The project has been developed under the academic supervision of Sir Sumair Khan at the Department of Computer Science, COMSATS University Islamabad, Abbottabad Campus. The active system adheres strictly to the directives and scope refinements issued by the FYP Evaluation Committee on 2026-09-29, introducing an authentic Content-Based AI recommendation engine, a bidirectional job marketplace, bilingual (Urdu/English) localization, and an Abbottabad cold-start evaluation dataset.")
    
    doc.add_paragraph().paragraph_format.space_after = Pt(28)
    
    t_sig = doc.add_table(rows=2, cols=3)
    t_sig.alignment = WD_TABLE_ALIGNMENT.CENTER
    t_sig.rows[0].cells[0].paragraphs[0].text = "____________________\nHashir Hamid\n(FA22-BSE-139)"
    t_sig.rows[0].cells[1].paragraphs[0].text = "____________________\nAman Ullah Khan\n(FA22-BSE-074)"
    t_sig.rows[0].cells[2].paragraphs[0].text = "____________________\nUmar Saeed\n(FA22-BCS-041)"
    
    t_sig.rows[1].cells[1].paragraphs[0].text = "\n\n____________________\nSir Sumair Khan\nProject Supervisor"
    for r in t_sig.rows:
        for c in r.cells:
            for p in c.paragraphs:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                if p.runs:
                    set_font(p.runs[0], "Times New Roman", 10.5)
    
    tblPr = t_sig._tbl.tblPr
    tblBorders = parse_xml(f'''
        <w:tblBorders {nsdecls("w")}>
            <w:top w:val="none"/><w:left w:val="none"/><w:bottom w:val="none"/><w:right w:val="none"/>
            <w:insideH w:val="none"/><w:insideV w:val="none"/>
        </w:tblBorders>
    ''')
    tblPr.append(tblBorders)

    doc.add_page_break()

    # ==================== EXECUTIVE SUMMARY / ABSTRACT ====================
    add_h2("Executive Summary & Abstract")
    add_p("In Pakistan, the domestic informal labor sector—encompassing cooks, cleaners, maids, child nannies, and elderly caregivers—remains largely opaque, decentralized, and governed by informal word-of-mouth networks. This informal hiring paradigm introduces severe friction: households confront safety risks, lack of identity verification, and unpredictable service quality, while domestic workers suffer from arbitrary wage negotiation, undefined task scopes, delayed cash compensations, and lack of professional reputation portability. Furthermore, conventional digital platforms fail in the Pakistani local market because they assume universal English literacy, rely on automated credit card payment gateways that domestic workers cannot access, and employ static database dropdown filters disguised as \"recommendations\".")
    
    add_p("To overcome these socio-economic and technical deficits, this project presents HomeEase, a hyper-local domestic worker marketplace designed specifically for local Pakistani dynamics, with primary empirical validation in Abbottabad. HomeEase establishes a structured mobile ecosystem built using Flutter and Dart, backed by Supabase PostgreSQL with Row Level Security (RLS). At this 60% evaluation milestone, HomeEase successfully fulfills the four official mandates issued by the FYP Evaluation Committee: (1) an authentic Content-Based Vector Similarity Recommender System combining Cosine Similarity on skill feature spaces, Haversine geospatial proximity decay, and min-max rating normalization with Explainable AI (XAI) transparent match badges; (2) a Bidirectional Job Marketplace allowing households to publish open gigs and domestic workers to actively browse and apply for local neighborhood opportunities; (3) a Bilingual Urdu/English localization layer (`EN | اردو`) with high-affordance visual task icons tailored for low-literacy informal workers; and (4) an Abbottabad synthetic seed dataset and cold-start evaluation benchmark. This document presents the complete 60% system engineering lifecycle, spanning theoretical foundations, rigorous UML design models, relational schema specifications, algorithmic implementations, and comprehensive verification test suites.")
    
    doc.add_paragraph().paragraph_format.space_after = Pt(14)
    add_h2("Acknowledgements")
    add_p("We express our deepest gratitude to Almighty Allah for bestowing upon us the wisdom, health, and perseverance to accomplish this mid-term 60% software engineering milestone. We extend our sincere appreciation to our project supervisor, Sir Sumair Khan, for his invaluable technical mentorship, constructive critiques, and continuous guidance throughout the architectural design and implementation stages.")
    add_p("We also thank the faculty members of the Department of Computer Science at COMSATS University Islamabad, Abbottabad Campus, for their rigorous evaluation feedback during the 30% milestone review, which fundamentally elevated the technical depth of this project. Lastly, we owe immense appreciation to our families, fellow students, and our technical mentor AbuZar Babar for their unwavering encouragement, collaborative discussions, and continuous moral support.")

    doc.add_page_break()

    # ==================== TABLE OF CONTENTS ====================
    add_h2("Table of Contents")
    toc_items = [
        ("Certificate of Approval & Declaration of Authorship", "ii"),
        ("Executive Summary & Abstract", "iii"),
        ("Acknowledgements", "iv"),
        ("List of Abbreviations & Acronyms", "v"),
        ("Table of Development Requirements & Technology Stack", "vi"),
        ("Chapter 1: Introduction", "1"),
        ("    1.1 Brief Introduction", "1"),
        ("    1.2 Relevance to Course Modules", "2"),
        ("    1.3 Project Background", "3"),
        ("    1.4 Literature Review", "3"),
        ("    1.5 Analysis from Literature Review", "5"),
        ("    1.6 Methodology and Software Lifecycle for This Project", "6"),
        ("Chapter 2: Problem Definition", "8"),
        ("    2.1 Problem Statement", "8"),
        ("    2.2 Deliverables and Development Requirements", "9"),
        ("Chapter 3: Requirement Analysis", "11"),
        ("    3.1 System Boundary & Use Case Diagram", "11"),
        ("    3.2 Detailed Use Cases", "12"),
        ("    3.3 Functional Requirements", "17"),
        ("    3.4 Non-Functional Requirements", "20"),
        ("Chapter 4: Design and Architecture", "22"),
        ("    4.1 System Architecture", "22"),
        ("    4.2 Process Flow Representation", "23"),
        ("    4.3 Design Models", "24"),
        ("        4.3.1 Class Diagram", "24"),
        ("        4.3.2 Sequence Diagram", "25"),
        ("        4.3.3 State Transition Model", "26"),
        ("References", "30")
    ]
    t_toc = doc.add_table(rows=len(toc_items) + 1, cols=2)
    t_toc.rows[0].cells[0].paragraphs[0].text = "Section Title"
    t_toc.rows[0].cells[1].paragraphs[0].text = "Page"
    for idx, (item, page) in enumerate(toc_items, start=1):
        t_toc.rows[idx].cells[0].paragraphs[0].text = item
        t_toc.rows[idx].cells[1].paragraphs[0].text = page
    format_table(t_toc, col_widths=[5.5, 1.0], header_bg="0F766E")

    doc.add_page_break()

    # ==================== LIST OF FIGURES ====================
    add_h2("List of Figures")
    fig_items = [
        ("Figure 3.1", "Complete Use Case Diagram for HomeEase Platform", "12"),
        ("Figure 4.1", "High-Level System Architecture of HomeEase Platform", "22"),
        ("Figure 4.2", "End-to-End Operational Process Flow in HomeEase", "23"),
        ("Figure 4.3", "Class Diagram of HomeEase Core Domain Models", "24"),
        ("Figure 4.4", "Sequence Diagram for AI Recommendation and Booking Lifecycle", "25"),
        ("Figure 4.5", "State Transition Diagram for Booking, Job Post, and Verification Lifecycles", "26"),
        ("Figure 4.6", "Entity-Relationship Diagram (ERD) of HomeEase PostgreSQL Database", "27")
    ]
    t_lof = doc.add_table(rows=len(fig_items) + 1, cols=3)
    t_lof.rows[0].cells[0].paragraphs[0].text = "Figure #"
    t_lof.rows[0].cells[1].paragraphs[0].text = "Caption Description"
    t_lof.rows[0].cells[2].paragraphs[0].text = "Page"
    for idx, (fnum, fdesc, fpage) in enumerate(fig_items, start=1):
        t_lof.rows[idx].cells[0].paragraphs[0].text = fnum
        t_lof.rows[idx].cells[1].paragraphs[0].text = fdesc
        t_lof.rows[idx].cells[2].paragraphs[0].text = fpage
    format_table(t_lof, col_widths=[1.2, 4.5, 0.8], header_bg="0F766E")

    doc.add_page_break()

    # ==================== ABBREVIATIONS & TECH STACK ====================
    add_h2("List of Abbreviations & Acronyms")
    t_abbr = doc.add_table(rows=15, cols=2)
    t_abbr.rows[0].cells[0].paragraphs[0].text = "Abbreviation"
    t_abbr.rows[0].cells[1].paragraphs[0].text = "Definition"
    abbr_data = [
        ("AI", "Artificial Intelligence"),
        ("BaaS", "Backend as a Service"),
        ("CNIC", "Computerized National Identity Card (Pakistan NADRA)"),
        ("ERD", "Entity Relationship Diagram"),
        ("FK", "Foreign Key"),
        ("HCI", "Human-Computer Interaction"),
        ("JWT", "JSON Web Token"),
        ("KYC", "Know Your Customer (Identity & Background Verification)"),
        ("PK", "Primary Key"),
        ("REST", "Representational State Transfer"),
        ("RLS", "Row Level Security (PostgreSQL)"),
        ("SDD", "Software Design Description"),
        ("SRS", "Software Requirements Specification"),
        ("XAI", "Explainable Artificial Intelligence")
    ]
    for idx, (ab, df) in enumerate(abbr_data, start=1):
        t_abbr.rows[idx].cells[0].paragraphs[0].text = ab
        t_abbr.rows[idx].cells[1].paragraphs[0].text = df
    format_table(t_abbr, col_widths=[1.8, 4.7], header_bg="0F766E")
    
    add_p("", space_after=14)
    add_h2("Table of Development Requirements & Technology Stack")
    t_stack = doc.add_table(rows=9, cols=3)
    t_stack.rows[0].cells[0].paragraphs[0].text = "Category"
    t_stack.rows[0].cells[1].paragraphs[0].text = "Selected Technology"
    t_stack.rows[0].cells[2].paragraphs[0].text = "Purpose & Role in HomeEase"
    stack_data = [
        ("Mobile Client", "Flutter SDK 3.x + Dart 3.x", "Cross-platform mobile app for Households and Domestic Workers with custom Material 3 theming and responsive layouts."),
        ("Admin Web Portal", "React 18 + Vite + TypeScript + Tailwind", "Administrative governance portal for worker CNIC document verification, booking audits, and dispute resolution."),
        ("Backend Database", "Supabase (Managed PostgreSQL 15+)", "ACID-compliant relational database enforcing multi-role data relationships and granular Row Level Security (RLS)."),
        ("Authentication", "Supabase Auth (JWT & Phone OTP)", "Secure role-based session management, password hashing, and planned SMS/Phone verification."),
        ("Cloud Object Storage", "Supabase Storage Buckets", "Encrypted cloud bucket storage for worker CNIC front/back scans, police certificates, and manual payment receipt images."),
        ("AI Recommendation Engine", "Content-Based Vector Scorer (Dart/Python)", "Algorithmic worker recommendation using Cosine Similarity on skill embeddings, Haversine geo-decay, and rating normalization."),
        ("Bilingual Localization", "Custom In-App Localization Engine", "Dynamic English/Urdu (`اردو`) text translation dictionary, right-to-left layout adaptation, and visual iconography affordance."),
        ("Offline & Local Data", "Dart Seed Models & Abbottabad Dataset", "Synthetic dataset representing 50 Abbottabad workers and 30 household gigs across Mandian, Jhangi, Supply, and Nawan Shehr.")
    ]
    for idx, (cat, tech, purp) in enumerate(stack_data, start=1):
        t_stack.rows[idx].cells[0].paragraphs[0].text = cat
        t_stack.rows[idx].cells[1].paragraphs[0].text = tech
        t_stack.rows[idx].cells[2].paragraphs[0].text = purp
    format_table(t_stack, col_widths=[1.5, 2.0, 3.0], header_bg="115E59")
    
    doc.add_page_break()

    # ==================== CHAPTER 1 ====================
    add_h1("Chapter 1: Introduction")
    
    add_h2("1.1 Brief Introduction")
    add_p("HomeEase is an enterprise-grade, hyper-local domestic worker connect platform specifically architected to formalize and secure the informal home-services sector in Pakistan. The platform bridges the deep trust deficit between two primary stakeholders: urban households seeking reliable, safe domestic assistance (such as cooks, cleaners, maids, child nannies, and elderly caregivers), and informal domestic workers who require reliable employment visibility, fair compensation, and professional reputation portability.")
    add_p("In urban and semi-urban Pakistani centers like Abbottabad, domestic worker hiring has historically been restricted to physical word-of-mouth, informal intermediaries, or gatekeeper referrals. These informal channels lack background identity checks, verifiable service histories, transparent task specifications, and standardized wage metrics. Consequently, employers face security risks and unpredictable absenteeism, while domestic workers are exposed to exploitative working hours, arbitrary wage cuts, and zero dispute recourse.")
    add_p("HomeEase establishes a structured digital bridge through a three-tier architecture comprising a Flutter mobile application for both households and workers, a React/Vite admin dashboard for regulatory governance, and a Supabase PostgreSQL backend. At this 60% evaluation stage, HomeEase extends beyond conventional single-sided directory apps by delivering an Explainable AI (XAI) Recommendation Engine, a Bidirectional Job Marketplace, and a specialized Bilingual/Iconographic accessibility interface tailored for low-literacy workers.")

    add_h2("1.2 Relevance to Course Modules")
    add_p("The engineering lifecycle and architectural implementation of HomeEase synthesize theoretical knowledge and practical competencies acquired across five core academic modules of the Software Engineering curriculum at COMSATS University Islamabad:")
    add_p("1. CSC392 (Software Engineering): Methodical application of the Agile Scrum methodology, requirement identification techniques, formal SRS and SDD authoring, UML object-oriented modeling, and Software Requirements Traceability Matrices (RTM).")
    add_p("2. CSC341 (Database Systems): Relational database architecture, Third Normal Form (3NF) relational decomposition, entity integrity, foreign key cascading constraints, index optimization, and PostgreSQL Row Level Security (RLS) policies.")
    add_p("3. CSC475 (Artificial Intelligence): Formalization of a Content-Based Recommender System, multi-dimensional feature space vectorization, Cosine Similarity distance metrics in high-dimensional discrete spaces, Haversine spherical distance formulas, min-max normalization, and Explainable AI (XAI) badge synthesis.")
    add_p("4. CSC483 (Mobile Application Development): Cross-platform Flutter architecture, Dart asynchronous programming (Futures, Streams), reactive UI state binding, localized layout constraints, and native hardware sensor integration.")
    add_p("5. CSC412 (Human-Computer Interaction): Usability engineering, accessibility for low-literacy demographics, bilingual right-to-left (RTL) typography handling, and visual iconography affordance design.")

    add_h2("1.3 Project Background")
    add_p("The HomeEase project commenced with the 10% Proposal Milestone, identifying the socio-technical breakdown of informal domestic worker hiring in Pakistan. The subsequent 30% Milestone formulated the complete Software Requirements Specification (SRS v1.0) and Software Design Description (SDD v1.0), along with a 15-screen client-side Flutter prototype executing on an interactive state machine.")
    add_p("During the 60% evaluation review on 2026-09-29, the FYP Evaluation Committee established four mandatory technical directives: (1) implementing an authentic AI recommendation engine rather than simple SQL filter dropdowns; (2) creating a two-sided bidirectional marketplace enabling workers to search and apply for household gigs; (3) introducing bilingual English/Urdu localization with visual iconography for low-literacy workers; and (4) validating the system with an empirical dataset from Abbottabad. This report documents the successful architectural realization of these mandates.")

    add_h2("1.4 Literature Review")
    add_p("A rigorous literature review of international and regional on-demand service platforms reveals distinct operational models and limitations:")
    add_p("1. Urban Company (formerly UrbanClap, India/UAE): Employs a full-stack managed marketplace model where the platform sets prices, trains workers, and takes commission. While highly standardized, it requires heavy capital investment, complete digital banking penetration, and excludes informal, low-literacy workers who lack formal trade licenses.")
    add_p("2. Care.com (USA / Global): A subscription-based caregiving directory connecting families with nannies and caregivers. It relies heavily on Social Security Number (SSN) background checks, mandatory monthly credit card subscriptions, and extensive written text profiles, rendering it completely unsuited for the cash-based, low-literacy Pakistani market.")
    add_p("3. Handy & TaskRabbit (USA / Europe): Gig platforms focusing on handyman tasks, cleaning, and furniture assembly. Both rely on automated credit card escrow and gig-worker bidding. Neither accommodates informal cash settlement, nor do they support visual affordance for workers who cannot read Latin scripts.")
    add_p("4. KaamKaaj & Local Classifieds (Pakistan / OLX): Local classified platforms simply publish unverified phone numbers and raw text blurbs. They offer zero identity verification, no auto-generated service agreements, no double-booking prevention, no dispute resolution, and zero recommendation intelligence.")

    add_h2("1.5 Analysis from Literature Review")
    add_p("The following comparative matrix synthesizes the competitive landscape against seven critical engineering dimensions:")
    
    t_lit = doc.add_table(rows=6, cols=8)
    t_lit.rows[0].cells[0].paragraphs[0].text = "Platform"
    t_lit.rows[0].cells[1].paragraphs[0].text = "Hyper-Local Matching"
    t_lit.rows[0].cells[2].paragraphs[0].text = "Verification Pipeline"
    t_lit.rows[0].cells[3].paragraphs[0].text = "Payment Inclusivity"
    t_lit.rows[0].cells[4].paragraphs[0].text = "Bidirectional Job Board"
    t_lit.rows[0].cells[5].paragraphs[0].text = "AI-Driven Recommender"
    t_lit.rows[0].cells[6].paragraphs[0].text = "Low-Literacy & Urdu UI"
    t_lit.rows[0].cells[7].paragraphs[0].text = "Formal Service Agreement"
    
    lit_rows = [
        ("Urban Company", "High", "Full Trade Audit", "Credit/Debit Cards Only", "No (Assigned)", "Complex Proprietary", "English/Hindi (Text)", "Standard Terms"),
        ("Care.com", "Zipcode", "SSN Check", "Credit Cards Only", "Yes (Job Posts)", "Collaborative Filtering", "English Only", "No"),
        ("TaskRabbit", "Zipcode", "Third-Party KYC", "Automated Escrow", "Yes (Tasks Feed)", "Heuristic Search", "English Only", "Platform Terms"),
        ("Pak Classifieds", "City Level", "None (Unverified)", "Informal Cash (Untracked)", "No (Raw Listings)", "Static Dropdown Query", "English / Urdu Text", "None"),
        ("HomeEase (Ours)", "Abbottabad Geo-Proximity", "CNIC + Police KYC", "Manual Cash/JazzCash + Receipts", "Yes (Post & Browse Feed)", "Content-Based Vector XAI", "Bilingual EN/اردو + Visual Icons", "Auto-Generated Agreement")
    ]
    for idx, row_vals in enumerate(lit_rows, start=1):
        for c_idx, val in enumerate(row_vals):
            t_lit.rows[idx].cells[c_idx].paragraphs[0].text = val
    format_table(t_lit, col_widths=[1.1, 0.8, 0.8, 0.9, 0.8, 0.9, 0.9, 0.8], header_bg="0F766E")
    
    add_p("", space_after=8)
    add_p("Critical Research Gaps Identified: The comparative analysis demonstrates that no existing platform bridges hyper-local domestic worker connectivity with explainable AI matching, informal payment auditability (Cash/JazzCash/EasyPaisa), formal contract generation, and bilingual accessibility tailored for low-literacy workers in semi-urban Pakistan. HomeEase directly addresses this vacuum.")

    add_h2("1.6 Methodology and Software Lifecycle for This Project")
    add_p("HomeEase is developed following the Agile Scrum methodology, organized into two-week development sprints. Agile was selected because domestic worker marketplace workflows require continuous usability testing with both high-literacy employers and low-literacy service providers.")
    add_p("The project lifecycle maps directly to academic milestone checkpoints:")
    add_p("- 10% Milestone (Proposal): Problem definition, literature review, technical feasibility, and high-level module planning.")
    add_p("- 30% Milestone (SRS & SDD): Formal specification of 32 functional requirements, comprehensive UML design suite, 14-table database schema, and client-side Flutter prototype.")
    add_p("- 60% Milestone (Mid-Term Implementation - Active): Incorporation of the four Committee Mandates: Content-Based AI Recommendation Engine with XAI match badges, Bidirectional Job Marketplace, Bilingual Urdu/English Engine with visual icons, Abbottabad synthetic dataset, and Supabase PostgreSQL integration.")
    add_p("- 100% Milestone (Final Defense): Live SMS OTP gateway, comprehensive Usability Testing across Abbottabad demographic cohorts, performance benchmarking, and final thesis.")

    doc.add_page_break()

    # ==================== CHAPTER 2 ====================
    add_h1("Chapter 2: Problem Definition")
    
    add_h2("2.1 Problem Statement")
    add_p("The informal domestic hiring sector in Pakistan suffers from systemic institutional and technological failure, manifested across six core operational pillars:")
    add_p("1. Complete Lack of Background Verification: Households admit domestic workers into private residential spaces with zero verifiable identity records. No centralized repository exists to inspect CNIC authenticity, police character clearance, or past disciplinary histories, creating significant personal and physical security risks.")
    add_p("2. Information Asymmetry and Informal Wage Exploitation: Absence of standardized rate cards leads to arbitrary price gouging by workers or unfair wage depression by employers. Workers lack reputation portability; five years of honest service for one household cannot be digitally proven when seeking employment with another.")
    add_p("3. Single-Sided Friction in Gig Discovery: Traditional platforms treat workers as passive entries in a directory. Workers sitting idle have no mechanism to view nearby households needing immediate assistance, creating severe underemployment.")
    add_p("4. Exclusionary Literacy and Language Barriers: The majority of domestic workers in Pakistan cannot read English, and many have limited Urdu text literacy. Digital platforms built exclusively with dense text menus and complex navigation exclude the very demographic they aim to empower.")
    add_p("5. Cold-Start Failure in Traditional Recommender Systems: Collaborative filtering algorithms rely on millions of historical interaction matrices, causing complete failure during early deployment. Conversely, simple SQL WHERE queries lack algorithmic intelligence and fail academic standards.")
    add_p("6. Unrealistic Digital Payment Gateways: Mandating automated credit card escrow excludes 95% of domestic workers who operate exclusively in cash or basic mobile wallets (EasyPaisa / JazzCash).")

    add_h2("2.2 Deliverables and Development Requirements")
    add_p("The HomeEase project delivers a production-grade multi-role digital platform. The table below delineates the cumulative deliverables across project stages:")
    
    t_deliv = doc.add_table(rows=5, cols=4)
    t_deliv.rows[0].cells[0].paragraphs[0].text = "Stage"
    t_deliv.rows[0].cells[1].paragraphs[0].text = "Scope Focus"
    t_deliv.rows[0].cells[2].paragraphs[0].text = "Deliverables Completed / Targeted"
    t_deliv.rows[0].cells[3].paragraphs[0].text = "Status"
    
    deliv_data = [
        ("10% Stage", "Concept & Proposal", "Initial proposal document, slide deck, competitive analysis, feasibility assessment.", "Approved"),
        ("30% Stage", "Analysis & Prototyping", "SRS v1.0 (32 FRs), SDD v1.0 (14 tables, 9 UML diagrams), client Flutter prototype (15 screens).", "Approved"),
        ("60% Stage", "Main Full-Stack & AI", "AI Content Recommender with XAI badges, Bidirectional Job Board, Bilingual EN/اردو toggle, Abbottabad seed data, Supabase schema & RLS, 60% Thesis.", "Active (Delivered)"),
        ("100% Stage", "Final Polish & Defense", "Live SMS OTP integration, field usability testing in Abbottabad, performance benchmarking, final thesis and defense.", "Roadmap")
    ]
    for idx, row in enumerate(deliv_data, start=1):
        for c_idx, val in enumerate(row):
            t_deliv.rows[idx].cells[c_idx].paragraphs[0].text = val
    format_table(t_deliv, col_widths=[1.0, 1.5, 3.2, 1.1], header_bg="0F766E")

    doc.add_page_break()

    # ==================== CHAPTER 3 ====================
    add_h1("Chapter 3: Requirement Analysis")
    
    add_h2("3.1 System Boundary & Use Case Diagram")
    add_p("The HomeEase system boundary encompasses three primary external actors (Household User, Domestic Worker User, and Platform Administrator) interacting with core backend services (Authentication Service, Database Service, AI Recommendation Service, and Notification Service).")
    add_p("Household users execute worker discovery, inspect AI match badges, post open gigs, initiate bookings, sign formal agreements, log manual payments, and file disputes. Domestic workers manage digital profiles, submit KYC documents, set availability calendars, browse open household gigs, submit job proposals, accept bookings, and confirm payment receipts. Administrators govern verification queues, audit transactions, and mediate disputes.")
    
    add_img("Use_Case_Diagram.png", "Figure 3.1: Complete Use Case Diagram for HomeEase Platform")

    add_h2("3.2 Detailed Use Cases")
    add_p("The following use case specifications detail the primary interactions across household, worker, administrative, and algorithmic system actors:")

    # Detailed Use Cases
    add_uc_table("UC-HH-01", "Household Registration & Profile Setup", "Household User",
                 "A household employer registers a secure account and configures neighborhood location preferences.",
                 "User selects 'Register as Household' on the mobile onboarding screen.",
                 "Device has network connectivity. User has a valid mobile number or email.",
                 "User account and household profile record are created in Supabase database.",
                 "1. User opens app and selects Household role.\n2. User enters full name, email/phone, password, and Abbottabad locality (e.g., Mandian).\n3. System validates credential formats.\n4. System creates authentication record and household profile.\n5. User is redirected to Household Discovery Home.",
                 "AF-1: Email/phone already registered: System displays duplicate error.\nAF-2: Weak password: System enforces 8-character minimum.")

    add_uc_table("UC-HH-02", "Discover Workers via Content-Based AI Recommender", "Household User",
                 "Household views an algorithmically ranked list of domestic workers tailored to service category, geographic proximity, and ratings.",
                 "User opens the HomeEase search hub and selects a service category.",
                 "Household location is set. Worker profiles exist in the target region.",
                 "System displays sorted worker cards accompanied by Explainable AI (XAI) match percentage badges.",
                 "1. Household selects service category (e.g., Cooking).\n2. System extracts household feature vector (category, locality coordinates).\n3. AI Recommendation Engine computes Cosine similarity, Haversine distance decay, and normalized ratings across active worker profiles.\n4. System ranks workers by composite score.\n5. UI displays worker cards with match percentage (e.g., '94% Match') and reasoning tags.",
                 "AF-1: No workers within 5 km: System expands geographic radius and displays 'Extended Proximity' notice.")

    add_uc_table("UC-HH-03", "Publish Open Household Gig / Job Post", "Household User",
                 "Household publishes an open domestic task request for local workers to browse and apply (Bidirectional Marketplace).",
                 "Household selects 'Post a Job' from the mobile dashboard.",
                 "Household user is authenticated.",
                 "New record is created in JOB_POSTS with status 'open' and dispatched to worker feeds.",
                 "1. Household enters task title, service category, date/time, Abbottabad locality, and proposed budget.\n2. User submits the gig posting.\n3. System validates inputs and persists job record.\n4. Notification service alerts matching domestic workers in the vicinity.\n5. Job appears in the Worker 'Available Jobs' feed.",
                 "AF-1: Incomplete task details: System highlights required input fields.")

    add_uc_table("UC-HH-04", "Direct Booking Request Initiation", "Household User",
                 "Household books a specific domestic worker for a defined date, time, and service scope.",
                 "Household taps 'Book Now' on a worker profile screen.",
                 "Worker is verified and has open availability slots for the requested date.",
                 "Booking record created with status 'Pending'. Double-booking lock engaged.",
                 "1. Household selects date, start time, end time, and service tasks.\n2. System checks worker availability and verifies no scheduling conflict.\n3. Household reviews booking summary and taps 'Send Booking Request'.\n4. System creates booking record in BOOKINGS.\n5. Notification sent to worker's mobile device.",
                 "AF-1: Worker already booked during requested time slot: System alerts household and displays worker's next open slot.")

    add_uc_table("UC-HH-05", "Sign Auto-Generated Formal Service Agreement", "Household & Worker",
                 "Both parties inspect and digitally sign an auto-generated service contract prior to service commencement.",
                 "Worker accepts a pending booking request.",
                 "Booking status is 'Accepted'.",
                 "Service agreement record generated in SERVICE_AGREEMENTS with status 'Signed'.",
                 "1. System compiles agreed task items, working hours, total wage, locality address, and dispute cancellation policy.\n2. Household reviews contract text and clicks 'Agree & Sign'.\n3. Worker reviews contract on their mobile device and clicks 'Confirm Agreement'.\n4. Agreement status transitions to 'Active'.",
                 "AF-1: Either party disputes terms: Booking is cancelled without penalty.")

    add_uc_table("UC-HH-06", "Log Manual Payment & Upload Receipt", "Household User",
                 "Household logs cash or mobile wallet payment (JazzCash/EasyPaisa) and uploads receipt proof.",
                 "Service agreement reaches completion date.",
                 "Booking status is 'Completed'.",
                 "Record created in PAYMENT_RECORDS with status 'Submitted'. Worker notified to confirm.",
                 "1. Household selects payment method (Cash, JazzCash, EasyPaisa).\n2. Household enters transaction ID / reference and amount paid.\n3. User captures image of receipt / screenshot and uploads.\n4. System uploads image to Supabase Storage bucket.\n5. Notification dispatched to Worker for confirmation.",
                 "AF-1: Image upload fails: System prompts for retry; preserves text inputs.")

    add_uc_table("UC-WK-03", "Browse Available Jobs Feed (Bidirectional Marketplace)", "Domestic Worker",
                 "Worker browses open household job postings matching their trade and location.",
                 "Worker taps 'Find Jobs' tab on the mobile dashboard.",
                 "Worker profile has active service categories assigned.",
                 "Worker views scrollable list of open gigs with budget, locality, and time requirements.",
                 "1. Worker opens 'Available Jobs' feed.\n2. System queries JOB_POSTS where status = 'open' matching worker category and locality.\n3. Worker inspects job requirements and budget.\n4. Worker taps 'Apply Now'.\n5. System registers application in JOB_APPLICATIONS and alerts household.",
                 "AF-1: No matching gigs: System suggests expanding service categories.")

    add_uc_table("UC-SYS-01", "Content-Based AI Worker Scoring Engine", "System Recommender",
                 "Calculates multi-dimensional vector similarity and geographic decay for worker recommendations.",
                 "Household initiates worker search or opens discovery hub.",
                 "Household location coordinates and target category vector available.",
                 "Normalized match scores and Explainable AI badge strings generated for all candidate workers.",
                 "1. System extracts binary category/skill vector u for household requirement.\n2. System computes Cosine Similarity against worker vectors w_i.\n3. System computes Haversine distance d_i in kilometers between household and worker coordinates.\n4. System computes proximity decay score S_geo = 1 / (1 + 0.2 d_i).\n5. System normalizes worker ratings to [0, 1].\n6. System calculates composite score S = 0.50 S_skills + 0.35 S_geo + 0.15 S_rating.\n7. System formats explainability string (e.g., '94% Match • 1.2 km away • Desi Cooking fit').",
                 "AF-1: Worker profile has 0 ratings (Cold-Start): System imputes prior neutral rating R=3.5 to avoid penalizing new entrants.")

    add_uc_table("UC-GEN-01", "Bilingual Language & Visual Affordance Toggle", "Household & Worker",
                 "User toggles application language between English and Urdu (`اردو`) with visual icon adaptation.",
                 "User taps the language toggle button (`EN | اردو`) in the app bar.",
                 "Application is running on device.",
                 "All screen strings re-render in selected language; RTL direction enabled for Urdu.",
                 "1. User clicks language toggle.\n2. Localization manager updates active locale state.\n3. String resources switch between English and Urdu dictionaries.\n4. Layout direction mirrors to Right-To-Left (RTL) for Urdu.\n5. Service category cards display high-affordance pictorial icons (Broom, Pot, Stroller, Wheelchair) for immediate visual recognition by low-literacy workers.",
                 "AF-1: Device language changes at OS level: App automatically adopts matching locale.")

    add_h2("3.3 Functional Requirements")
    add_p("The HomeEase system implements 36 detailed functional requirements categorized by functional subsystem:")
    
    t_fr = doc.add_table(rows=37, cols=4)
    t_fr.rows[0].cells[0].paragraphs[0].text = "ID"
    t_fr.rows[0].cells[1].paragraphs[0].text = "Subsystem"
    t_fr.rows[0].cells[2].paragraphs[0].text = "Functional Requirement Specification"
    t_fr.rows[0].cells[3].paragraphs[0].text = "Priority"
    
    fr_specs = [
        ("FR-01", "Auth", "The system shall allow household and worker users to register accounts using email/phone and secure password.", "High"),
        ("FR-02", "Auth", "The system shall authenticate registered users and issue role-specific JSON Web Tokens (JWT).", "High"),
        ("FR-03", "Auth", "The mobile login interface shall allow instant switching and demo credential auto-fill for testing.", "Medium"),
        ("FR-04", "Auth", "The system shall enforce strict role-based route guards preventing unauthorized cross-role access.", "High"),
        ("FR-05", "Household", "The system shall allow households to manage profile details, contact numbers, and Abbottabad locality address.", "High"),
        ("FR-06", "Worker", "The system shall allow domestic workers to create professional profiles with bio, experience years, and locality.", "High"),
        ("FR-07", "Worker", "The system shall allow workers to select multiple service categories (Cooking, Cleaning, Childcare, Elderly Care).", "High"),
        ("FR-08", "Worker", "The system shall allow workers to configure hourly or visit-based charge rates per service category.", "Medium"),
        ("FR-09", "Worker", "The system shall provide a weekly calendar allowing workers to toggle availability time slots by day of week.", "High"),
        ("FR-10", "KYC", "The system shall allow workers to upload CNIC front/back images and character certificates for verification.", "High"),
        ("FR-11", "AI Matching", "The system shall vectorize household requirements and compute Content-Based Cosine Similarity on worker skills.", "High"),
        ("FR-12", "AI Matching", "The system shall calculate Haversine geographic distance between household and worker coordinates.", "High"),
        ("FR-13", "AI Matching", "The system shall compute a composite recommendation match score and display transparent Explainable AI badges.", "High"),
        ("FR-14", "Job Board", "The system shall allow households to publish open domestic job postings with category, budget, date, and locality.", "High"),
        ("FR-15", "Job Board", "The system shall display a live feed of open household gigs to domestic workers matching their category and locality.", "High"),
        ("FR-16", "Job Board", "The system shall allow domestic workers to apply to open household job postings with a single tap.", "High"),
        ("FR-17", "Job Board", "The system shall notify households immediately upon receiving worker job applications.", "High"),
        ("FR-18", "Booking", "The system shall allow households to create direct booking requests with date, start time, end time, and notes.", "High"),
        ("FR-19", "Booking", "The system shall prevent double-booking by verifying worker availability and detecting overlapping booking intervals.", "High"),
        ("FR-20", "Booking", "The system shall allow workers to accept or reject incoming booking requests with immediate household alert.", "High"),
        ("FR-21", "Booking", "The system shall maintain booking state transitions across: Pending, Accepted, Rejected, Completed, and Cancelled.", "High"),
        ("FR-22", "Agreement", "The system shall auto-generate a structured service agreement specifying tasks, hours, rate, and terms upon acceptance.", "High"),
        ("FR-23", "Agreement", "The system shall require both household and worker to view and digitally sign the agreement before job start.", "High"),
        ("FR-24", "Payment", "The system shall allow households to log manual payments made via Cash, JazzCash, or EasyPaisa.", "High"),
        ("FR-25", "Payment", "The system shall allow households to upload digital receipt images or transaction screenshots.", "High"),
        ("FR-26", "Payment", "The system shall allow workers to inspect payment details and confirm payment receipt.", "High"),
        ("FR-27", "Review", "The system shall allow households to submit segmented ratings for punctuality, behavior, and quality (1-5 stars).", "High"),
        ("FR-28", "Review", "The system shall automatically recompute worker cumulative average ratings upon review submission.", "High"),
        ("FR-29", "Dispute", "The system shall allow either party to raise a transaction dispute linked to a specific booking or payment record.", "Medium"),
        ("FR-30", "Dispute", "The system shall allow users to upload evidence photos and descriptions for admin dispute mediation.", "Medium"),
        ("FR-31", "Admin", "The system shall provide a secure React web dashboard for platform administrators.", "High"),
        ("FR-32", "Admin", "The admin web dashboard shall display a worker verification queue with full-resolution document inspection.", "High"),
        ("FR-33", "Admin", "The admin web dashboard shall provide dispute mediation tools allowing admins to review evidence and resolve claims.", "High"),
        ("FR-34", "Admin", "The admin web dashboard shall provide platform audit tables for users, bookings, and payments with CSV export.", "Medium"),
        ("FR-35", "Localization", "The mobile app shall provide a global bilingual toggle supporting English and Urdu (`اردو`) with RTL layout.", "High"),
        ("FR-36", "Accessibility", "The system shall render high-affordance pictorial icons for all service tasks and booking states to support low-literacy workers.", "High")
    ]
    for idx, row in enumerate(fr_specs, start=1):
        for c_idx, val in enumerate(row):
            t_fr.rows[idx].cells[c_idx].paragraphs[0].text = val
    format_table(t_fr, col_widths=[0.8, 1.2, 4.0, 0.7], header_bg="0F766E")

    add_h2("3.4 Non-Functional Requirements")
    add_p("The platform complies with stringent quality attributes and operational constraints:")
    add_p("1. Usability & Low-Literacy Accessibility: All critical worker interactions (accepting bookings, browsing jobs, confirming payments) must be executable within a maximum of 3 taps from the home screen. Category selection must provide high-contrast pictorial icons recognizable without reading text. Urdu layout must render cleanly in Noto Nastaliq / Urdu fonts with correct right-to-left padding.")
    add_p("2. Performance & Algorithmic Latency: The Content-Based AI recommendation algorithm must compute match scores across up to 500 active worker profiles in less than 250 milliseconds on modern smartphone hardware. Mobile UI transitions must maintain 60 frames per second (FPS).")
    add_p("3. Reliability & Scheduling Integrity: The system must enforce strict concurrency controls preventing overlapping bookings for the same worker. Service uptime must exceed 99.5% excluding announced maintenance.")
    add_p("4. Security & Data Protection: User passwords must be salted and hashed using bcrypt before database storage. Document scans (CNIC, character certificates) stored in Supabase Storage must be protected by Row Level Security (RLS) policies allowing access solely to the document owner and authenticated administrators.")
    add_p("5. Portability & Maintainability: The Flutter mobile codebase must execute uniformly across Android (API level 24+) and iOS (iOS 13+). Business logic must be cleanly decoupled from presentation widgets using service repositories.")

    doc.add_page_break()

    # ==================== CHAPTER 4 ====================
    add_h1("Chapter 4: Design and Architecture")
    
    add_h2("4.1 System Architecture")
    add_p("HomeEase is designed around a three-tier, service-oriented architecture incorporating modern cloud infrastructure and local algorithmic intelligence. The architectural decomposition comprises:")
    add_p("1. Presentation Tier: Cross-platform Flutter mobile client providing role-adaptive interfaces for households and workers, integrated with a dynamic Bilingual Engine (EN/اردو) and a Visual Iconography Affordance layer. Platform administrators access a dedicated React + Vite + TypeScript web dashboard.")
    add_p("2. Application & Service Tier: Decoupled business logic services governing Authentication, Booking state machines, Service Agreement generation, Bidirectional Job Marketplace dispatching, Dispute tracking, and the Content-Based AI Recommendation Engine.")
    add_p("3. Data & Cloud Storage Tier: Supabase managed PostgreSQL 15+ relational database with Row Level Security (RLS) policy enforcement, PostgREST API layer, and encrypted object storage buckets for KYC documents and payment receipts.")
    
    add_img("Archtecture.png", "Figure 4.1: High-Level System Architecture of HomeEase Platform")

    add_h2("4.2 Process Flow Representation")
    add_p("The platform orchestrates multi-step, multi-actor operational workflows across the booking, marketplace, recommendation, and verification cycles:")
    add_p("- Worker Booking & Service Agreement Flow: Household discovers worker via AI search -> submits booking request -> worker receives alert and reviews scope -> worker accepts -> system auto-compiles legal terms and signs agreement -> service performed -> payment logged and confirmed -> review recorded.")
    add_p("- Bidirectional Job Marketplace Flow: Household posts open gig -> job validated and saved -> matching workers alerted via feed -> worker applies with one tap -> household reviews worker profile -> household accepts proposal -> transitions to active booking.")
    add_p("- Content-Based AI Recommendation Flow: Household selects category and enters locality -> system retrieves nearby active profiles -> vectorizes skills -> calculates Cosine Similarity, Haversine geo-decay, and rating factor -> computes composite score -> renders Explainable AI match badge.")
    
    add_img("ProcessFlow.png", "Figure 4.2: End-to-End Operational Process Flow in HomeEase")

    add_h2("4.3 Design Models")
    
    add_h3("4.3.1 Class Diagram")
    add_p("The object-oriented design model encapsulates the system domain into cohesive entity and service classes:")
    add_p("- User: Base authentication class managing credentials, contact data, and role type.")
    add_p("- HouseholdProfile & WorkerProfile: Specialized role models capturing addresses, GPS coordinates, bios, charges, and verification states.")
    add_p("- ServiceCategory & WorkerService: Defines domain specializations and pricing structures.")
    add_p("- Booking & ServiceAgreement: Transactional entities coordinating scheduling, financial terms, and legal contractual state.")
    add_p("- JobPost & JobApplication: Bidirectional marketplace classes managing open gigs and worker proposals.")
    add_p("- AIRecommendationEngine & LocalizationService: Algorithmic matching and multilingual presentation components.")
    add_p("- PaymentRecord, Review, Dispute, and VerificationRequest: Regulatory, audit, and quality governance classes.")
    
    add_img("Class.png", "Figure 4.3: Class Diagram of HomeEase Core Domain Models")

    add_h3("4.3.2 Sequence Diagram")
    add_p("The sequence model formalizes dynamic message passing between user interfaces, controllers, recommendation engines, and database services during the AI Search, Booking Request, and Job Application lifecycles.")
    
    add_img("Sequence.png", "Figure 4.4: Sequence Diagram for AI Recommendation and Booking Lifecycle")

    add_h3("4.3.3 State Transition Model")
    add_p("HomeEase coordinates several critical state machines:")
    add_p("1. Booking Lifecycle State Machine: Draft -> Pending -> Accepted (or Rejected / Expired) -> AgreementSigned -> InProgress -> Completed -> PaymentLogged -> Confirmed -> Closed (with branch to Disputed).")
    add_p("2. Job Post Lifecycle State Machine: Open -> ApplicationsReceived -> Assigned -> Completed (or Cancelled).")
    add_p("3. Worker Verification State Machine: Unverified -> DocumentsSubmitted -> InReview -> Verified (or RejectedWithFeedback).")
    
    add_img("StateTransition.png", "Figure 4.5: State Transition Diagram for Booking, Job Post, and Verification Lifecycles")

    add_h3("4.3.4 Entity-Relationship Diagram & Data Dictionary")
    add_p("The relational database schema is modeled in PostgreSQL and normalized to Third Normal Form (3NF). It comprises 16 relational tables:")
    
    add_img("ERD.png", "Figure 4.6: Entity-Relationship Diagram (ERD) of HomeEase PostgreSQL Database")

    add_p("Data Dictionary Table Overview:")
    t_dd = doc.add_table(rows=17, cols=4)
    t_dd.rows[0].cells[0].paragraphs[0].text = "Table Name"
    t_dd.rows[0].cells[1].paragraphs[0].text = "Primary Key"
    t_dd.rows[0].cells[2].paragraphs[0].text = "Foreign Keys"
    t_dd.rows[0].cells[3].paragraphs[0].text = "Functional Purpose"
    
    dd_data = [
        ("USERS", "id (UUID)", "None", "Master account records, email, phone, role, password hash, account status."),
        ("HOUSEHOLD_PROFILES", "id (UUID)", "user_id -> USERS(id)", "Household employer profile, Abbottabad address, locality, preferred language."),
        ("WORKER_PROFILES", "id (UUID)", "user_id -> USERS(id)", "Worker profile, experience years, bio, latitude, longitude, verified flag, rating."),
        ("SERVICE_CATEGORIES", "id (UUID)", "None", "Service classifications (Cooking, Cleaning, Childcare, Elderly Care, Maid)."),
        ("WORKER_SERVICES", "id (UUID)", "worker_id, category_id", "Associative table mapping worker specializations with hourly/visit rates."),
        ("AVAILABILITY_SLOTS", "id (UUID)", "worker_id -> WORKER_PROFILES(id)", "Weekly day-of-week worker availability intervals and active toggles."),
        ("BOOKINGS", "id (UUID)", "household_id, worker_id, category_id", "Central transactional entity linking employer, worker, date, hours, and status."),
        ("SERVICE_AGREEMENTS", "id (UUID)", "booking_id, household_id, worker_id", "Auto-generated formal service contract text, agreed fee, and signing status."),
        ("JOB_POSTS", "id (UUID)", "household_id, category_id", "Bidirectional marketplace open gig listings with budget, locality, and date."),
        ("JOB_APPLICATIONS", "id (UUID)", "job_post_id, worker_id", "Worker applications submitted against open gigs with proposed rates."),
        ("PAYMENT_RECORDS", "id (UUID)", "booking_id, household_id, worker_id", "Manual payment audit records (Cash/JazzCash/EasyPaisa), receipt URLs, confirmation."),
        ("REVIEWS", "id (UUID)", "booking_id, household_id, worker_id", "Multi-factor ratings (punctuality, behavior, quality) and written comments."),
        ("VERIFICATION_REQUESTS", "id (UUID)", "worker_id, admin_id", "KYC audit submissions containing CNIC front/back URLs and review remarks."),
        ("DISPUTES", "id (UUID)", "booking_id, raised_by, admin_id", "Transaction grievances, evidence URLs, mediation status, and admin resolution."),
        ("NOTIFICATIONS", "id (UUID)", "user_id -> USERS(id)", "In-app and push notification alerts for booking status and gig updates."),
        ("ISSUE_REPORTS", "id (UUID)", "reporter_id, booking_id", "General platform feedback, technical bug reports, and safety alerts.")
    ]
    for idx, row in enumerate(dd_data, start=1):
        for c_idx, val in enumerate(row):
            t_dd.rows[idx].cells[c_idx].paragraphs[0].text = val
    format_table(t_dd, col_widths=[1.8, 1.2, 1.8, 2.2], header_bg="0F766E")

    doc.add_page_break()

    # ==================== REFERENCES ====================
    add_h1("References")
    references = [
        "Sommerville, I. (2016). Software Engineering (10th ed.). Pearson Education.",
        "Pressman, R. S., & Maxim, B. R. (2020). Software Engineering: A Practitioner's Approach (9th ed.). McGraw-Hill Education.",
        "Ricci, F., Rokach, L., & Shapira, B. (2022). Recommender Systems Handbook (3rd ed.). Springer US.",
        "Sinnott, R. W. (1984). Virtues of the Haversine. Sky and Telescope, 68(2), 159.",
        "Nielsen, J. (1994). Usability Engineering. Morgan Kaufmann Publishers.",
        "Medhi, I., Sagar, A., & Toyama, K. (2007). Text-Free User Interfaces for Illiterate and Semi-Literate Users. Information Technologies and International Development, 4(1), 37-50.",
        "Google. (2024). Flutter Documentation: Architectural Overview and Reactive State. https://docs.flutter.dev/",
        "Supabase Inc. (2024). Supabase PostgreSQL & Row Level Security Architecture Guide. https://supabase.com/docs/",
        "International Labour Organization (ILO). (2021). Making Decent Work a Reality for Domestic Workers: Progress and Prospects Ten Years After the Adoption of the Domestic Workers Convention, 2011 (No. 189). Geneva: ILO.",
        "Pakistan Bureau of Statistics (PBS). (2022). Labour Force Survey 2020-21 (Annual Report). Government of Pakistan.",
        "Salton, G., & McGill, M. J. (1983). Introduction to Modern Information Retrieval. McGraw-Hill.",
        "Pazzani, M. J., & Billsus, D. (2007). Content-Based Recommendation Systems. In The Adaptive Web (pp. 325-341). Springer Berlin Heidelberg.",
        "Lundberg, S. M., & Lee, S. I. (2017). A Unified Approach to Interpreting Model Predictions. Advances in Neural Information Processing Systems (NeurIPS 2017), 30.",
        "Fielding, R. T. (2000). Architectural Styles and the Design of Network-based Software Architectures. Doctoral dissertation, University of California, Irvine.",
        "ISO/IEC/IEEE. (2017). Systems and software engineering — Architecture description. ISO/IEC/IEEE 42010:2011 standard.",
        "World Bank. (2023). Pakistan Digital Economy Assessment: Unleashing Inclusive Growth. Washington, DC: World Bank."
    ]
    for idx, ref in enumerate(references, start=1):
        p = add_p(f"[{idx}] {ref}", space_before=2, space_after=6)
        p.paragraph_format.left_indent = Inches(0.4)
        p.paragraph_format.first_line_indent = Inches(-0.4)
        set_font(p.runs[0], "Times New Roman", 10.5)

    doc.save(output_path)
    print(f"Thesis docx successfully generated at: {output_path}")

if __name__ == "__main__":
    out_file = r'c:\Users\AbuZar\Desktop\Fyp\HomeEase\Docs\60 percent\HomeEase 60% Thesis.docx'
    diag_dir = r'c:\Users\AbuZar\Desktop\Fyp\HomeEase\Docs\60 percent\diagrams'
    build_thesis_docx(out_file, diag_dir)

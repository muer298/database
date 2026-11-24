from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_ALIGN_VERTICAL, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
OUTPUT = DOCS / "电影院票务预订管理系统_第1周综合报告.docx"
ER_IMAGE = DOCS / "er-diagram-v1.png"
CONNECTION_IMAGE = DOCS / "week1-db-connection-success.jpg"

BODY_FONT = "Arial Unicode MS"
HEADING_FONT = "Arial Unicode MS"
BLUE = "1F4E78"
LIGHT_BLUE = "DCE6F1"
PALE_BLUE = "F3F7FB"
LIGHT_GRAY = "D9D9D9"


def set_run_font(run, name=BODY_FONT, size=10.5, bold=False, color="000000"):
    run.font.name = name
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.color.rgb = RGBColor.from_string(color)
    run._element.get_or_add_rPr().rFonts.set(qn("w:eastAsia"), name)
    run._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), name)
    run._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), name)


def set_cell_shading(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=90, start=110, bottom=90, end=110):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for margin, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{margin}"))
        if node is None:
            node = OxmlElement(f"w:{margin}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_table_borders(table, color=LIGHT_GRAY, size="6"):
    tbl_pr = table._tbl.tblPr
    borders = tbl_pr.find(qn("w:tblBorders"))
    if borders is None:
        borders = OxmlElement("w:tblBorders")
        tbl_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        element = borders.find(qn(f"w:{edge}"))
        if element is None:
            element = OxmlElement(f"w:{edge}")
            borders.append(element)
        element.set(qn("w:val"), "single")
        element.set(qn("w:sz"), size)
        element.set(qn("w:color"), color)


def repeat_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def add_table(doc, headers, rows, widths=None, font_size=9.5):
    table = doc.add_table(rows=1, cols=len(headers))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    set_table_borders(table)
    repeat_header(table.rows[0])
    for index, text in enumerate(headers):
        cell = table.rows[0].cells[index]
        if widths:
            cell.width = Inches(widths[index])
        set_cell_shading(cell, BLUE)
        set_cell_margins(cell)
        cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        paragraph = cell.paragraphs[0]
        paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
        paragraph.paragraph_format.space_after = Pt(0)
        run = paragraph.add_run(text)
        set_run_font(run, HEADING_FONT, font_size, True, "FFFFFF")
    for row_index, values in enumerate(rows):
        cells = table.add_row().cells
        for index, value in enumerate(values):
            cell = cells[index]
            if widths:
                cell.width = Inches(widths[index])
            set_cell_margins(cell)
            if row_index % 2 == 1:
                set_cell_shading(cell, PALE_BLUE)
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            paragraph = cell.paragraphs[0]
            paragraph.paragraph_format.space_after = Pt(0)
            paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER if index < 2 else WD_ALIGN_PARAGRAPH.LEFT
            run = paragraph.add_run(str(value))
            set_run_font(run, BODY_FONT, font_size)
    doc.add_paragraph().paragraph_format.space_after = Pt(0)
    return table


def add_heading(doc, text, level=1):
    paragraph = doc.add_heading(text, level=level)
    paragraph.paragraph_format.keep_with_next = True
    return paragraph


def add_body(doc, text, bold_lead=None):
    paragraph = doc.add_paragraph()
    paragraph.paragraph_format.first_line_indent = Pt(21)
    paragraph.paragraph_format.space_after = Pt(6)
    paragraph.paragraph_format.line_spacing = 1.25
    if bold_lead and text.startswith(bold_lead):
        run = paragraph.add_run(bold_lead)
        set_run_font(run, BODY_FONT, 10.5, True)
        text = text[len(bold_lead):]
    run = paragraph.add_run(text)
    set_run_font(run)
    return paragraph


def add_bullet(doc, text):
    paragraph = doc.add_paragraph(style="List Bullet")
    paragraph.paragraph_format.left_indent = Inches(0.28)
    paragraph.paragraph_format.first_line_indent = Inches(-0.18)
    paragraph.paragraph_format.space_after = Pt(3)
    run = paragraph.add_run(text)
    set_run_font(run)
    return paragraph


def add_number(doc, text):
    paragraph = doc.add_paragraph(style="List Number")
    paragraph.paragraph_format.left_indent = Inches(0.32)
    paragraph.paragraph_format.first_line_indent = Inches(-0.2)
    paragraph.paragraph_format.space_after = Pt(3)
    run = paragraph.add_run(text)
    set_run_font(run)
    return paragraph


def add_manual_number(doc, number, text):
    paragraph = doc.add_paragraph()
    paragraph.paragraph_format.left_indent = Inches(0.18)
    paragraph.paragraph_format.first_line_indent = Inches(-0.18)
    paragraph.paragraph_format.space_after = Pt(3)
    run = paragraph.add_run(f"{number}. {text}")
    set_run_font(run)
    return paragraph


def add_caption(doc, text):
    paragraph = doc.add_paragraph()
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    paragraph.paragraph_format.space_before = Pt(3)
    paragraph.paragraph_format.space_after = Pt(9)
    run = paragraph.add_run(text)
    set_run_font(run, BODY_FONT, 9, False, "595959")


def draw_er_diagram():
    canvas = Image.new("RGB", (1800, 1180), "white")
    draw = ImageDraw.Draw(canvas)
    font_path = "/System/Library/Fonts/Hiragino Sans GB.ttc"
    title_font = ImageFont.truetype(font_path, 46)
    node_font = ImageFont.truetype(font_path, 25)
    label_font = ImageFont.truetype(font_path, 22)
    note_font = ImageFont.truetype(font_path, 20)
    draw.text((900, 35), "电影院票务预订管理系统 E-R 图 v1.0", font=title_font,
              fill="#111111", anchor="ma")

    nodes = {
        "users": (50, 145, 405, 335, "用户 users\nPK user_id\nusername  role\naccount_status"),
        "movies": (695, 145, 1105, 335, "电影 movies\nPK movie_id\ntitle  duration_minutes\nshowing_status"),
        "halls": (1345, 145, 1750, 335, "影厅 halls\nPK hall_id\nhall_name  hall_type\nrow_count  column_count"),
        "orders": (50, 475, 405, 685, "订单 orders\nPK order_id\nFK user_id  screening_id\norder_status  total_amount"),
        "screenings": (695, 475, 1105, 685, "场次 screenings\nPK screening_id\nFK movie_id  hall_id\nstart_time  ticket_price"),
        "seats": (1345, 475, 1750, 685, "座位 seats\nPK seat_id  FK hall_id\nseat_row  seat_column\nseat_type  use_status"),
        "tickets": (50, 825, 455, 1055, "电影票 tickets\nPK ticket_id\nFK order_id  screening_id  seat_id\nticket_status  ticket_price"),
        "occupancies": (695, 825, 1105, 1055, "场次座位 seat_occupancies\nPK screening_id + seat_id\nFK order_id 可空\nAVAILABLE  LOCKED  SOLD"),
    }

    def center(key):
        x1, y1, x2, y2, _ = nodes[key]
        return (x1 + x2) // 2, (y1 + y2) // 2

    def connect(a, b, left_label, right_label):
        x1, y1 = center(a)
        x2, y2 = center(b)
        draw.line((x1, y1, x2, y2), fill="#7F8C8D", width=3)
        for ratio, text in ((0.2, left_label), (0.8, right_label)):
            tx = x1 + (x2 - x1) * ratio
            ty = y1 + (y2 - y1) * ratio
            bbox = draw.textbbox((tx, ty), text, font=label_font, anchor="mm")
            draw.rectangle((bbox[0] - 4, bbox[1] - 2, bbox[2] + 4, bbox[3] + 2), fill="white")
            draw.text((tx, ty), text, font=label_font, fill="#4F4F4F", anchor="mm")

    connect("users", "orders", "1", "N")
    connect("movies", "screenings", "1", "N")
    connect("halls", "screenings", "1", "N")
    connect("halls", "seats", "1", "N")
    connect("screenings", "orders", "1", "N")
    connect("orders", "tickets", "1", "N")
    connect("screenings", "occupancies", "1", "N")
    connect("seats", "occupancies", "1", "N")
    connect("orders", "occupancies", "0..1", "N")
    connect("screenings", "tickets", "1", "N")
    connect("seats", "tickets", "1", "N")

    for key, (x1, y1, x2, y2, label) in nodes.items():
        fill = "#EAF2F8" if key != "occupancies" else "#F3EAF8"
        edge = "#2F75B5" if key != "occupancies" else "#7030A0"
        draw.rounded_rectangle((x1, y1, x2, y2), radius=24, fill=fill, outline=edge, width=4)
        draw.multiline_text((x1 + 22, y1 + 18), label, font=node_font, fill="#1F1F1F", spacing=9)

    draw.text((1740, 1142), "注：总座位数由 seats 统计；订单只对应一个场次。",
              font=note_font, fill="#666666", anchor="ra")
    canvas.save(ER_IMAGE, quality=95)


def configure_document(doc):
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(0.72)
    section.bottom_margin = Inches(0.68)
    section.left_margin = Inches(0.78)
    section.right_margin = Inches(0.78)

    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = BODY_FONT
    normal.font.size = Pt(10.5)
    normal._element.rPr.rFonts.set(qn("w:eastAsia"), BODY_FONT)
    normal.paragraph_format.space_after = Pt(6)

    title = styles["Title"]
    title.font.name = HEADING_FONT
    title.font.size = Pt(25)
    title.font.bold = True
    title.font.color.rgb = RGBColor(0, 0, 0)
    title._element.rPr.rFonts.set(qn("w:eastAsia"), HEADING_FONT)

    for style_name, size in (("Heading 1", 16), ("Heading 2", 13), ("Heading 3", 11.5)):
        style = styles[style_name]
        style.font.name = HEADING_FONT
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = RGBColor(0, 0, 0)
        style._element.rPr.rFonts.set(qn("w:eastAsia"), HEADING_FONT)
        style.paragraph_format.space_before = Pt(10)
        style.paragraph_format.space_after = Pt(6)

    footer = section.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
    footer_run = footer.add_run("电影院票务预订管理系统  第 1 周综合版")
    set_run_font(footer_run, BODY_FONT, 8.5, False, "7F7F7F")


def build_report():
    draw_er_diagram()
    doc = Document()
    configure_document(doc)

    title = doc.add_paragraph(style="Title")
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    title.paragraph_format.space_before = Pt(88)
    title.paragraph_format.space_after = Pt(18)
    title_run = title.add_run("电影院票务预订管理系统")
    set_run_font(title_run, HEADING_FONT, 25, True)

    subtitle = doc.add_paragraph()
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    subtitle.paragraph_format.space_after = Pt(42)
    subtitle_run = subtitle.add_run("第 1 周综合报告")
    set_run_font(subtitle_run, HEADING_FONT, 18, True)

    add_table(doc, ["项目", "内容"], [
        ("版本", "v1.0"),
        ("日期", "2026 年 11 月 23 日"),
        ("成员 A", "需求分析、E-R 设计、关系模式与业务规则"),
        ("成员 B", "Java、Maven、JDBC、DAO 与 Service 项目骨架"),
        ("结论", "第一周综合交付通过，可进入第二周 DAO 开发"),
    ], widths=[1.35, 5.25], font_size=10)

    cover_note = doc.add_paragraph()
    cover_note.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cover_note.paragraph_format.space_before = Pt(28)
    run = cover_note.add_run("本报告整合并修正成员 A 与成员 B 的第一周成果")
    set_run_font(run, BODY_FONT, 10, False, "595959")

    doc.add_page_break()

    add_heading(doc, "1 综合结论", 1)
    add_body(doc, "成员 A 的需求和数据库设计经过修订后，已与成员 B 的 Java/JDBC 项目骨架形成统一的第一周版本。数据库接口约定 v1.0 已冻结，建表脚本和测试数据已在本机 MySQL 中执行通过；Java 项目编译、IntelliJ IDEA 构建和实际数据库连接也已验证成功。第二周可以开始实现 DAO 和查询功能，但购票、退票事务仍属于后续开发范围。")

    add_table(doc, ["验收项", "负责人", "状态", "说明"], [
        ("需求范围与角色", "A", "通过", "普通用户和管理员职责已明确"),
        ("E-R 与关系模式", "A", "通过", "7 个基础实体加 1 个关联实体"),
        ("字段与完整性约束", "A", "通过", "主键、外键、唯一、检查约束已落入 SQL"),
        ("Java 与 Maven 骨架", "B", "通过", "Java 17 与 Connector/J 8.4.0"),
        ("JDBC 实际连接", "B", "通过", "MySQL 9.6.0 本机连接成功"),
        ("完整购票业务", "B", "未开始", "按计划在后续周次实现"),
    ], widths=[2.0, 0.75, 0.8, 3.05])

    add_heading(doc, "2 成员 A 第一周任务修订结果", 1)
    add_body(doc, "原设计已经覆盖用户、电影、影厅、座位、场次、订单和电影票，但用户角色、场次座位主键、退票后的座位状态以及数据库删除策略存在不一致。综合版已统一为下列可执行约定。")
    for item in [
        "在 users 表增加 role 字段，使用 CUSTOMER 和 ADMIN 区分普通用户与管理员。",
        "将 seat_occupancies 确定为关联实体，采用 (screening_id, seat_id) 联合主键。",
        "场次座位状态统一为 AVAILABLE、LOCKED、SOLD；退票恢复 AVAILABLE。",
        "一个订单只能购买同一场次的多张票，订单与场次建立直接外键。",
        "订单、电影票和场次作为历史数据保留，采用 RESTRICT，避免级联物理删除。",
        "金额统一为 DECIMAL(10,2)，业务时间统一为 DATETIME 和 Asia/Shanghai 本地时间。",
        "总座位数由 seats 表统计，不再同时保存容易失真的冗余总数。",
    ]:
        add_bullet(doc, item)

    add_heading(doc, "3 需求范围与角色", 1)
    add_table(doc, ["角色", "第一阶段功能", "不在当前范围"], [
        ("普通用户", "注册登录、查询电影和场次、选座购票、查看订单、整单退票", "真实在线支付、电子核销设备"),
        ("管理员", "维护电影、影厅和座位、排片、查询订单与票房统计", "多影院集团管理、复杂会员营销"),
    ], widths=[1.1, 3.25, 2.25])
    add_body(doc, "系统采用 Java 命令行界面、JDBC 和 MySQL，当前面向单影院课程项目。第一周重点是明确需求、冻结数据库接口并打通 Java 到 MySQL 的连接，不把尚未实现的业务功能写成已完成。")

    add_heading(doc, "4 数据模型", 1)
    add_table(doc, ["表", "用途", "关键约束"], [
        ("users", "用户和管理员账户", "username 唯一，role 和状态受限"),
        ("movies", "电影基本信息", "片名与上映日期组合唯一"),
        ("halls", "影厅规格", "影厅名称唯一"),
        ("seats", "影厅内物理座位", "影厅、排号、列号组合唯一"),
        ("screenings", "电影放映场次", "结束晚于开始，同厅同开始时间唯一"),
        ("orders", "用户购票订单", "订单号唯一，一个订单对应一个场次"),
        ("seat_occupancies", "每场次的座位销售状态", "screening_id 与 seat_id 联合主键"),
        ("tickets", "出票与历史记录", "票号唯一，同时校验订单场次与场次座位"),
    ], widths=[1.55, 2.2, 2.85])

    doc.add_page_break()
    add_heading(doc, "5 E-R 图", 1)
    add_body(doc, "下图是在原 E-R 图基础上的 v1.0 修订版。它补充了用户角色，并把场次与座位的多对多联系明确转换为 seat_occupancies 关联实体。")
    paragraph = doc.add_paragraph()
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    paragraph.add_run().add_picture(str(ER_IMAGE), width=Inches(6.6))
    add_caption(doc, "图 1  电影院票务预订管理系统 E-R 图 v1.0")

    add_heading(doc, "6 状态与核心业务规则", 1)
    add_table(doc, ["对象", "状态", "主要流转"], [
        ("用户", "NORMAL, FROZEN", "冻结用户不得新购票"),
        ("电影", "UPCOMING, SHOWING, OFFLINE", "由管理员维护"),
        ("场次", "SCHEDULED, SELLING, ENDED, CANCELLED", "只有 SELLING 可购票"),
        ("订单", "PENDING, PAID, CANCELLED, REFUNDED", "PENDING→PAID/CANCELLED；PAID→REFUNDED"),
        ("电影票", "VALID, USED, REFUNDED", "VALID→USED/REFUNDED"),
        ("场次座位", "AVAILABLE, LOCKED, SOLD", "AVAILABLE→LOCKED→SOLD；退票恢复 AVAILABLE"),
    ], widths=[1.05, 2.75, 2.8], font_size=9)
    for item in [
        "同一影厅的场次时间不得重叠，第二周由 ScreeningDAO 在新增和修改时检查。",
        "锁座必须放在事务中，任何一个座位锁定失败时整单回滚。",
        "目前只允许开场前整单退票，且订单必须为 PAID、电影票必须为 VALID。",
        "票房统计排除 REFUNDED 订单和电影票。",
    ]:
        add_bullet(doc, item)

    add_heading(doc, "7 成员 B 第一周技术成果", 1)
    add_table(doc, ["项目", "结果"], [
        ("Maven", "Java 17 编译目标，MySQL Connector/J 8.4.0"),
        ("分层结构", "Main、DBUtil、DAO、Service 已建立"),
        ("安全配置", "数据库账号和密码通过环境变量读取"),
        ("命令行入口", "支持连接测试、无效输入处理和正常退出"),
        ("编译与 IDE", "mvn clean compile 与 IntelliJ IDEA 构建通过"),
        ("实际连接", "cinema_app 成功连接 cinema_ticket"),
    ], widths=[1.55, 5.05])

    if CONNECTION_IMAGE.exists():
        paragraph = doc.add_paragraph()
        paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
        paragraph.paragraph_format.space_before = Pt(5)
        paragraph.add_run().add_picture(str(CONNECTION_IMAGE), width=Inches(6.45))
        add_caption(doc, "图 2  Java 程序连接 MySQL 成功记录")

    add_heading(doc, "8 数据库脚本验证", 1)
    add_body(doc, "综合版建表脚本和测试数据已经在本机 cinema_ticket 数据库执行。测试结果为 8 张表、2 个示例用户、1 个影厅、6 个座位、1 个场次和 6 条可售场次座位记录。测试数据脚本可以重复执行，不会重复创建同一批示例记录。")
    add_table(doc, ["文件", "用途", "验证结果"], [
        ("sql/create_tables.sql", "创建 8 张表、索引、外键和检查约束", "执行通过"),
        ("sql/insert_data.sql", "插入最小联调数据并初始化场次座位", "执行通过"),
        ("docs/schema-contract.md", "A 与 B 的字段、状态和事务接口依据", "v1.0 已冻结"),
    ], widths=[2.0, 3.15, 1.45])
    add_body(doc, "本机验证使用 MySQL 9.6.0。课程目标环境建议使用 MySQL 8.4 LTS，第二周联调前应再做一次目标版本执行验证。")

    add_heading(doc, "9 A 与 B 的协作边界", 1)
    add_table(doc, ["事项", "A 负责", "B 负责", "是否需要双方确认"], [
        ("需求和业务规则", "提出并维护", "检查可实现性", "是"),
        ("E-R 图和关系模式", "主责", "检查 JDBC 映射", "是"),
        ("SQL 字段和状态变更", "提出或审核", "评估代码影响", "是"),
        ("DAO 普通实现细节", "无需逐行检查", "主责", "否"),
        ("购票和退票事务", "确认规则", "实现与测试", "关键规则需要"),
        ("README 和交付清单", "核对设计部分", "维护技术部分", "提交前需要"),
    ], widths=[1.35, 1.65, 1.85, 1.75], font_size=9)
    add_body(doc, "A 不需要阅读 B 的每一行 Java 代码，但必须能够看到项目仓库，并审核数据库契约、SQL、业务状态和涉及需求的接口变更。B 可以独立完成普通 DAO 实现，但不能私自改变字段或业务规则。")

    add_heading(doc, "10 GitHub 协作建议", 1)
    add_body(doc, "建议把项目上传到 GitHub 私有仓库。即使课程没有强制要求，GitHub 也能保存版本历史、支持 A 查看设计和 SQL、避免通过聊天软件反复发送 ZIP。提交前再根据课程要求决定是否公开。")
    for item in [
        "仓库应只包含项目文件，不包含 .env、数据库密码、IDE 缓存、target 或个人配置。",
        "A 主要查看 docs、sql、README 和涉及业务规则的 Pull Request，不必审查每个 Java 细节。",
        "B 维护主开发分支，涉及数据库结构的修改通过独立分支或 Pull Request 让 A 确认。",
        "当前项目目录尚不是独立 Git 仓库；上传前应在 CinemaTicketSystem 目录单独初始化，避免把整个用户主目录误加入版本控制。",
    ]:
        add_bullet(doc, item)

    add_heading(doc, "11 第二周任务", 1)
    add_heading(doc, "11.1 成员 A", 2)
    for number, item in enumerate([
        "根据教师反馈维护需求、E-R 图和 schema-contract 版本。",
        "补充课程要求的典型查询场景和预期结果。",
        "审核排片冲突、锁座、整单退票和票房统计规则。",
        "准备覆盖正常、重复座位、冲突场次和非法状态的测试数据。",
    ], start=1):
        add_manual_number(doc, number, item)
    b_heading = add_heading(doc, "11.2 成员 B", 2)
    b_heading.paragraph_format.page_break_before = True
    for number, item in enumerate([
        "建立 Java 实体类和状态枚举，完成 SQL 到 Java 的类型映射。",
        "实现 UserDAO、MovieDAO、HallDAO、SeatDAO 和 ScreeningDAO。",
        "实现电影、场次和可售座位查询，并全部使用 PreparedStatement。",
        "为 DAO 增加正常路径、空结果、唯一约束和外键异常测试。",
        "开始设计 BookingService 的事务和并发锁座方案，但不要跳过 DAO 验证。",
    ], start=1):
        add_manual_number(doc, number, item)

    add_heading(doc, "12 第一周最终验收清单", 1)
    checklist = [
        "需求分析、角色和系统边界已明确",
        "E-R 图和 8 张表关系模式已经统一",
        "主键、外键、唯一约束和状态规则已经落入 SQL",
        "建表脚本和测试数据执行成功",
        "Maven 编译和 IntelliJ IDEA 构建成功",
        "Java 程序实际连接 MySQL 成功",
        "数据库密码和 .env 未进入交付文件",
        "第二周 A、B 分工和变更流程已明确",
    ]
    for item in checklist:
        add_bullet(doc, f"已完成  {item}")

    add_heading(doc, "附录 交付文件", 1)
    add_table(doc, ["类别", "文件"], [
        ("综合报告", "docs/电影院票务预订管理系统_第1周综合报告.docx"),
        ("共同契约", "docs/schema-contract.md"),
        ("验收记录", "docs/week1-handoff.md"),
        ("E-R 图", "docs/er-diagram-v1.png"),
        ("数据库", "sql/create_tables.sql, sql/insert_data.sql"),
        ("Java", "pom.xml, src/main/java/edu/course/cinema"),
    ], widths=[1.35, 5.25])

    doc.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    build_report()

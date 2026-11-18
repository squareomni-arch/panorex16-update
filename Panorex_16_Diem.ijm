// =====================================================================
//  Copyright (c) 2026 Dr.Le Van Thanh. All rights reserved.
//  Ban quyen (c) 2026 thuoc ve Dr.Le Van Thanh. Moi quyen duoc bao luu.
//
//  GIAY PHEP SU DUNG (doc day du trong file LICENSE.txt di kem):
//  - Phan mem nay la tai san rieng cua Dr.Le Van Thanh. Chi nguoi duoc Dr.Le Van Thanh
//    cho phep moi duoc cai dat va su dung.
//  - Khong duoc sao chep, phan phoi, ban, cho thue, sua doi, dich nguoc
//    hoac go bo dau hieu ban quyen / nhan "Dr.Le Van Thanh" khi chua co su dong y
//    bang van ban cua Dr.Le Van Thanh.
//  - Phan mem duoc cung cap "nguyen trang", khong kem bat ky bao dam nao.
//    Ket qua do chi mang tinh tham khao, khong thay the danh gia lam sang.
// =====================================================================
// =====================================================================
//  PANOREX 16 DIEM  -  Bo cong cu do phim toan canh cho Fiji / ImageJ
//  - 1 click: mo phim (.dcm uu tien / .jpg) + hien 16 diem moi ben (+ Me)
//  - Don vi: mm (lay tu Pixel Spacing cua DICOM) va do (goc)
//  - Keo chinh diem truc tiep, thong so cap nhat ngay tren phim
//  - Xac nhan -> luu BN00x_ed.jpg + BN00x_ed.dcm + bang tong hop CSV
//
//  Cai dat: chep file nay vao  Fiji.app/macros/toolsets/
//           roi tren thanh cong cu Fiji bam ">>" -> chon "Panorex_16_Diem"
// =====================================================================

// ---------- Cau hinh ----------
var DEFAULT_MM_PER_PX = 0.077;   // dung khi khong doc duoc Pixel Spacing (JPG 330 dpi = 0.077 mm)
var PREF = "panorex16.";
var VERSION = "1.5";
// Thu muc phat hanh ban cap nhat (latest.txt + .ijm + .jar). Fiji tu kiem tra moi lan mo.
var UPDATE_URL = "https://raw.githubusercontent.com/squareomni-arch/panorex16-update/main/";
var OWNER = "Dr.Le Van Thanh";
var COPYRIGHT = "(c) 2026 Dr.Le Van Thanh";
var TBL_TITLE = "Thong so Panorex  -  (c) 2026 Dr.Le Van Thanh";

// Diem moi ben (hau to _r = ben phai BN = nua TRAI cua phim; _l = ben trai BN = nua PHAI phim)
//   Landmarks: Co, Ar, Cor, Snp, Prnc, Arnc, PMC, Go, IMCa, IMCb, Or (+ Me chung o giua)
//   D7  : diem loi nhat phia xa rang 7 (chi hien 1 cham, khong ghi ten)
//   Z   : diem tiep xuc cua mp Z voi bo truoc canh len XHD.
//         mp Z = duong qua Z, vuong goc voi mp khuyet sigma (duong qua Snp, song song mp Or)
//   O8m, O8d : dinh mui gan / mui xa tren mat nhai rang khon.
//         Truc rang khon = duong vuong goc voi mat nhai (O8m-O8d), di qua giua mat nhai
//   CoA : diem giua co loi cau  -> truc dai loi cau = duong Co-CoA  (a do doc truc nay den mp sigma)
//   CorA: diem giua co mom vet  -> truc dai mom vet = duong Cor-CorA (b do doc truc nay den mp sigma)
//   (CoA, CorA them o cuoi tu v1.2 de giu tuong thich mau diem da hoc)
var BASE = newArray("Co","Ar","Cor","Snp","Prnc","Arnc","PMC","Go","IMCa","IMCb","Or","D7","Z","O8m","O8d","CoA","CorA");
var NOLABEL = ",D7,";
// Vi tri mau mac dinh (ti le chieu rong / chieu cao) cho ben PHAI BN (nua trai phim); ben trai = doi xung
var TPL_X = newArray(0.175,0.150,0.270,0.215,0.137,0.250,0.140,0.150,0.175,0.320,0.300,0.300,0.255,0.285,0.262,0.180,0.266);
var TPL_Y = newArray(0.170,0.250,0.310,0.270,0.420,0.450,0.580,0.660,0.720,0.860,0.130,0.600,0.480,0.535,0.520,0.225,0.285);
var ME_X = 0.5;
var ME_Y = 0.96;

// ---------- Trang thai ----------
var NAMES = newArray(0);
var PX = newArray(0);
var PY = newArray(0);
var NP = 0;
var MMPX = 0.077;
var MAG = 1.0;        // he so phong dai cua may (mm thuc = pixel * spacing / MAG)
var SPACING = 0.077;  // Pixel Spacing goc trong DICOM
var TABLE_PLACED = false;
var RES_R = newArray(10);
var RES_L = newArray(10);
var MLABEL = newArray("a. Co -> mp sigma (doc truc)","b. Cor -> mp sigma (doc truc)","c. Co-Go (thang dung)","d. Prnc-Arnc","e. Go-Me","f. Snp -> Co-Cor","g. Loi xa R7 - mp Z","h. Ar-PMC / IMCa-IMCb","i. Truc rang 8 / Go-Me","j. Truc rang 8 / IMCa-IMCb");
var MSHORT = newArray("Co_mpSigma","Cor_mpSigma","Co-Go","Prnc-Arnc","Go-Me","Snp_CoCor","D7_Z","Ang_ArPMC_IMC","Ang_8_GoMe","Ang_8_IMC");
var MUNIT = newArray("mm","mm","mm","mm","mm","mm","mm","do","do","do");

// =====================================================================
//  CONG CU (thanh toolbar)
// =====================================================================
macro "1. Mo phim + hien diem tham chieu Action Tool - C037T0f161T8f10P" {
    openFilm();
}

macro "2. Hien / an phep do (khoang cach + goc) Action Tool - C037T0f162T8f10D" {
    toggleMeasure();
}

macro "Keo chinh diem (giu chuot trai) Tool - C037O22aaL7777Cf00o6622" {
    dragPoint();
}

macro "3. Do + Xac nhan + Luu file Action Tool - C037T0f163T8f10S" {
    measureAndSave();
}

macro "He so phong dai (M) Action Tool - C037T0f16M" {
    setMagnification();
}

macro "Dat lai 16 diem theo mau Action Tool - C037T0f16RT8f10P" {
    if (nImages == 0) exit("Chua mo phim.");
    if (!getBoolean("Dat lai TAT CA diem ve vi tri mau?\n(Co the bam U de hoan tac)")) exit;
    pushHist(Property.get("panorex_pts"));
    placeTemplate();
    savePts();
    redraw();
    if (isMeasure()) showTable();
}

macro "Hoan tac (U) Action Tool - C037T0f16UT9f10z" {
    undoPts();
}

macro "Hoan tac [u]" {
    undoPts();
}

macro "Mo bang tong hop Action Tool - C037T0f16TT8f10H" {
    dir = outDir("");
    f = dir + "TongHop_DoDac.csv";
    if (!File.exists(f)) exit("Chua co bang tong hop:\n" + f);
    open(f);
}

macro "Panorex 16 diem - (c) 2026 Dr.Le Van Thanh Action Tool - C037T0e11DT9e11r" {
    showMessage("Ban quyen", "<html><b>Panorex 16 diem v" + VERSION + "</b><br>"
      + "Copyright (c) 2026 Dr.Le Van Thanh. All rights reserved.<br>"
      + "Ban quyen thuoc ve Dr.Le Van Thanh. Moi quyen duoc bao luu.<br><br>"
      + "Khong duoc sao chep, phan phoi, sua doi, dich nguoc hoac go bo<br>"
      + "thong tin ban quyen khi chua co su dong y bang van ban cua Dr.Le Van Thanh.<br>"
      + "Xem day du trong file LICENSE.txt.");
}

macro "Kiem tra cap nhat (UP) Action Tool - C080T0f12UT8f12P" {
    r = call("PanorexDicom.checkUpdate", "manual");
    showStatus("Panorex: dang kiem tra ban moi...");
}

macro "Huong dan Action Tool - C037T4f16?" {
    showMessage("Huong dan Panorex 16 diem",
      "<html><b>1</b> - Mo phim (.dcm hoac .jpg): cap ma BN00x + hien cac diem tham chieu.<br>"
    + "&nbsp;&nbsp;&nbsp;&nbsp;Neu da mo phim bang File > Open, bam 1 de dat diem ngay tren phim do.<br>"
    + "<b>2</b> - Hien cac phep do (mat phang, khoang cach, goc) + bang thong so. Bam lan nua de an.<br>"
    + "<b>O</b> - Cong cu keo diem: giu chuot trai keo tung cham do ve dung vi tri.<br>"
    + "<b>U</b> - Lo tay keo sai: bam nut U (hoac phim U) de lui lai tung buoc.<br>"
    + "<b>M</b> - Nhap he so phong dai cua may chup (mac dinh 1.000).<br>"
    + "<b>RP</b> - Dat lai tat ca diem ve vi tri mau.<br>"
    + "<b>3</b> - Bam de xem bang thong so -> Xac nhan -> luu BN00x_ed.jpg, BN00x_ed.dcm<br>"
    + "&nbsp;&nbsp;&nbsp;&nbsp;va them 1 dong vao TongHop_DoDac.csv.<br>"
    + "<b>UP</b> - Kiem tra va cai ban cap nhat moi (Fiji cung tu kiem tra moi lan mo).<br><br>"
    + "_r = ben phai benh nhan (nua TRAI phim), _l = ben trai benh nhan (nua PHAI phim).<br>"
    + "Phan mem tu hoc: sau moi phim da luu, vi tri mau duoc cap nhat de lan sau dat sat hon.<br><br>"
    + "<font color=gray>Panorex 16 diem v" + VERSION + " - " + COPYRIGHT + ". Moi quyen duoc bao luu.</font>");
}

// =====================================================================
//  MO PHIM + HIEU CHUAN mm
// =====================================================================
function openFilm() {
    r = call("PanorexDicom.setMainTitle", "(Fiji Is Just) ImageJ   |   Panorex 16 diem v" + VERSION + "  " + COPYRIGHT);
    // Neu dang mo san 1 phim (vd. mo bang File > Open) ma chua co diem -> dat diem ngay tren phim do
    useCurrent = false;
    if (nImages > 0) {
        if (Property.get("panorex_pts") == "") useCurrent = true;
    }
    if (useCurrent) {
        path = getInfo("image.directory") + getInfo("image.filename");
    } else {
        path = File.openDialog("Chon phim panorex (.dcm uu tien, hoac .jpg)");
        if (path == "") exit;
    }
    lower = toLowerCase(path);
    mm = 0;
    if (endsWith(lower, ".dcm")) {
        if (!useCurrent) openDicom(path);
        mm = dicomSpacing(path);
    } else {
        if (!useCurrent) open(path);
        // neu co file .dcm cung ten, lay Pixel Spacing tu do
        if (lastIndexOf(path, ".") > 0) {
            dcm = substring(path, 0, lastIndexOf(path, ".")) + ".dcm";
            if (File.exists(dcm)) mm = dicomSpacing(dcm);
        }
    }
    if (bitDepth() == 24) run("8-bit");
    if (mm <= 0) {
        mm = parseFloat(call("ij.Prefs.get", PREF + "mmpx", "" + DEFAULT_MM_PER_PX));
        Dialog.create("Hieu chuan mm");
        Dialog.addMessage("Khong doc duoc Pixel Spacing trong file.\nNhap kich thuoc 1 pixel (mm):");
        Dialog.addNumber("mm / pixel", mm, 4, 8, "mm");
        Dialog.show();
        mm = Dialog.getNumber();
        call("ij.Prefs.set", PREF + "mmpx", "" + mm);
    }
    SPACING = mm;
    MAG = parseFloat(call("ij.Prefs.get", PREF + "mag", "1"));
    if (isNaN(MAG) || MAG <= 0) MAG = 1;
    mm = SPACING / MAG;
    run("Properties...", "unit=mm pixel_width=" + mm + " pixel_height=" + mm + " voxel_depth=1");
    Property.set("panorex_src", path);
    Property.set("panorex_spacing", "" + SPACING);
    Property.set("panorex_mag", "" + MAG);
    Property.set("panorex_mmpx", "" + mm);
    MMPX = mm;
    Property.set("panorex_mode", "pts");
    code = nextCode(outDir(path));
    Property.set("panorex_code", code);
    rename(winTitle(code, path));
    run("Select None");
    placeTemplate();
    savePts();
    redraw();
    setTool("Keo chinh diem (giu chuot trai) Tool");
    showStatus(Property.get("panorex_code") + "  -  " + d2s(mm, 4) + " mm/pixel  -  keo diem de chinh, bam 2 de hien phep do   |   " + COPYRIGHT);
}

function openDicom(path) {
    // Phim HDXWILL nen JPEG-Lossless + co truong so rong -> sua tam (PanorexDicom) roi mo bang Bio-Formats
    r = call("PanorexDicom.fix", path);
    q = split(r, "|");
    if (q[0] == "ERR") exit("Khong mo duoc DICOM:\n" + r);
    run("Bio-Formats Macro Extensions");
    Ext.openImagePlus(q[0]);
    ok = File.delete(q[0]);
    rename(File.getName(path));
    resetMinAndMax();
}

function dicomSpacing(path) {
    // Doc Pixel Spacing (0028,0030), neu khong co thi Imager Pixel Spacing (0018,1164)
    r = call("PanorexDicom.fix", path);
    q = split(r, "|");
    if (q[0] == "ERR") return 0;
    ok = File.delete(q[0]);
    if (q.length < 2) return 0;
    mm = parseFloat(q[1]);
    if (isNaN(mm) || mm <= 0) return 0;
    return mm;
}

// =====================================================================
//  DIEM: dat mau, luu / doc tu anh
// =====================================================================
function buildNames() {
    NP = 2 * BASE.length + 1;
    NAMES = newArray(NP);
    for (i = 0; i < BASE.length; i++) {
        NAMES[i] = BASE[i] + "_r";
        NAMES[BASE.length + i] = BASE[i] + "_l";
    }
    NAMES[NP - 1] = "Me";
}

// doc mau diem da hoc trong Prefs; tu nang cap mau cu (it diem hon) bang cach them diem moi tu mau mac dinh
function tplValues() {
    s = call("ij.Prefs.get", PREF + "tpl", "");
    if (s == "") return newArray(0);
    v = split(s, ",");
    nb = BASE.length;
    if (v.length == 2 * nb + 2) return v;
    nold = (v.length - 2) / 2;
    if (nold != floor(nold) || nold < 1 || nold > nb) return newArray(0);
    out = newArray(2 * nb + 2);
    for (i = 0; i < nb; i++) {
        if (i < nold) { out[2*i] = v[2*i]; out[2*i+1] = v[2*i+1]; }
        else { out[2*i] = "" + TPL_X[i]; out[2*i+1] = "" + TPL_Y[i]; }
    }
    out[2*nb] = v[2*nold]; out[2*nb+1] = v[2*nold+1];
    return out;
}

function placeTemplate() {
    buildNames();
    w = getWidth(); h = getHeight();
    tx = TPL_X; ty = TPL_Y; mex = ME_X; mey = ME_Y;
    v = tplValues();
    if (v.length > 0) {
        if (v.length == 2 * BASE.length + 2) {
            tx = newArray(BASE.length); ty = newArray(BASE.length);
            for (i = 0; i < BASE.length; i++) { tx[i] = parseFloat(v[2*i]); ty[i] = parseFloat(v[2*i+1]); }
            mex = parseFloat(v[2*BASE.length]); mey = parseFloat(v[2*BASE.length+1]);
        }
    }
    PX = newArray(NP); PY = newArray(NP);
    for (i = 0; i < BASE.length; i++) {
        PX[i] = tx[i] * w;                   PY[i] = ty[i] * h;
        PX[BASE.length + i] = (1 - tx[i]) * w; PY[BASE.length + i] = ty[i] * h;
    }
    PX[NP-1] = mex * w; PY[NP-1] = mey * h;
}

function savePts() {
    s = "";
    for (i = 0; i < NP; i++) s = s + d2s(PX[i], 2) + "," + d2s(PY[i], 2) + ";";
    Property.set("panorex_pts", s);
}

function loadPts() {
    if (nImages == 0) return false;
    s = Property.get("panorex_pts");
    if (s == "") return false;
    buildNames();
    p = split(s, ";");
    if (p.length < NP) return false;
    PX = newArray(NP); PY = newArray(NP);
    for (i = 0; i < NP; i++) { q = split(p[i], ","); PX[i] = parseFloat(q[0]); PY[i] = parseFloat(q[1]); }
    m = Property.get("panorex_mmpx");
    if (m != "") MMPX = parseFloat(m); else { getPixelSize(u, pw, ph); MMPX = pw; }
    g = Property.get("panorex_mag"); if (g != "") MAG = parseFloat(g); else MAG = 1;
    g = Property.get("panorex_spacing"); if (g != "") SPACING = parseFloat(g); else SPACING = MMPX * MAG;
    return true;
}

function idx(name) {
    for (i = 0; i < NP; i++) if (NAMES[i] == name) return i;
    exit("Khong tim thay diem " + name);
}

// =====================================================================
//  KEO DIEM
// =====================================================================
function dragPoint() {
    if (!loadPts()) { showStatus("Bam nut 1 de mo phim va dat diem truoc."); exit; }
    getCursorLoc(x, y, z, flags);
    tol = 20 / getZoom();
    best = -1; bd = 1e9;
    for (i = 0; i < NP; i++) {
        if (startsWith(NAMES[i], "Go_")) continue;   // Go tu tinh tu Ar-PMC x IMCa-IMCb
        d = sqrt((PX[i]-x)*(PX[i]-x) + (PY[i]-y)*(PY[i]-y));
        if (d < bd) { bd = d; best = i; }
    }
    if (best < 0 || bd > tol) exit;
    before = Property.get("panorex_pts");
    dx = PX[best] - x; dy = PY[best] - y;
    while (flags & 16 != 0) {
        getCursorLoc(x, y, z, flags);
        nx = x + dx; ny = y + dy;
        if (nx != PX[best] || ny != PY[best]) {
            PX[best] = nx; PY[best] = ny;
            redraw();
            showStatus(NAMES[best] + "  (" + d2s(nx * MMPX, 1) + ", " + d2s(ny * MMPX, 1) + ") mm");
        }
        wait(20);
    }
    savePts();
    if (Property.get("panorex_pts") != before) pushHist(before);
    redraw();
    if (isMeasure()) showTable();
}

// lich su de hoan tac (toi da 50 buoc), luu trong anh
function pushHist(state) {
    if (state == "") return;
    h = Property.get("panorex_hist");
    if (h == "") h = state; else h = h + "#" + state;
    a = split(h, "#");
    if (a.length > 50) {
        h = a[a.length - 50];
        for (i = a.length - 49; i < a.length; i++) h = h + "#" + a[i];
    }
    Property.set("panorex_hist", h);
}

function undoPts() {
    if (!loadPts()) { showStatus("Chua co diem de hoan tac."); exit; }
    h = Property.get("panorex_hist");
    if (h == "") { showStatus("Khong con buoc nao de hoan tac (da ve trang thai ban dau)."); exit; }
    k = lastIndexOf(h, "#");
    if (k < 0) { last = h; h = ""; } else { last = substring(h, k + 1); h = substring(h, 0, k); }
    Property.set("panorex_hist", h);
    Property.set("panorex_pts", last);
    loadPts();
    redraw();
    if (isMeasure()) showTable();
    n = 0; if (h != "") { a = split(h, "#"); n = a.length; }
    showStatus("Da hoan tac. Con " + n + " buoc co the hoan tac.");
}

// =====================================================================
//  HINH HOC (tinh bang mm)
// =====================================================================
function distMM(a, b) {
    i = idx(a); j = idx(b);
    return MMPX * sqrt((PX[i]-PX[j])*(PX[i]-PX[j]) + (PY[i]-PY[j])*(PY[i]-PY[j]));
}

// khoang cach theo phuong THANG DUNG (truc doc cua phim) giua a va b
function vertMM(a, b) {
    i = idx(a); j = idx(b);
    return MMPX * abs(PY[i]-PY[j]);
}

// khoang cach vuong goc tu diem p den duong thang a-b
function perpMM(p, a, b) {
    k = idx(p); i = idx(a); j = idx(b);
    ux = PX[j]-PX[i]; uy = PY[j]-PY[i];
    L = sqrt(ux*ux + uy*uy);
    if (L == 0) return NaN;
    return MMPX * abs(ux*(PY[k]-PY[i]) - uy*(PX[k]-PX[i])) / L;
}

// goc (do) giua vector a1->a2 va vector b1->b2
function angVec(a1, a2, b1, b2) {
    i1 = idx(a1); i2 = idx(a2); j1 = idx(b1); j2 = idx(b2);
    ux = PX[i2]-PX[i1]; uy = PY[i2]-PY[i1];
    vx = PX[j2]-PX[j1]; vy = PY[j2]-PY[j1];
    lu = sqrt(ux*ux+uy*uy); lv = sqrt(vx*vx+vy*vy);
    if (lu == 0 || lv == 0) return NaN;
    c = (ux*vx + uy*vy) / (lu*lv);
    if (c > 1) c = 1; if (c < -1) c = -1;
    return acos(c) * 180 / PI;
}

// huong mp sigma (don vi) = song song mp Or (Or_r -> Or_l), dung chung cho 2 ben
function sigmaDir(s) {
    i = idx("Or_r"); j = idx("Or_l");
    ux = PX[j]-PX[i]; uy = PY[j]-PY[i];
    L = sqrt(ux*ux+uy*uy); if (L == 0) return newArray(1, 0);
    return newArray(ux/L, uy/L);
}

// huong truc rang khon (don vi), vuong goc mat nhai, chi ve phia chan rang (xuong duoi)
function axisDir(s) {
    i = idx("O8m"+s); j = idx("O8d"+s);
    vx = PX[i]-PX[j]; vy = PY[i]-PY[j];
    L = sqrt(vx*vx+vy*vy); if (L == 0) return newArray(0, 1);
    ax = -vy/L; ay = vx/L;
    if (ay < 0) { ax = -ax; ay = -ay; }
    return newArray(ax, ay);
}

function angDirVec(d, b1, b2) {
    j1 = idx(b1); j2 = idx(b2);
    vx = PX[j2]-PX[j1]; vy = PY[j2]-PY[j1];
    lv = sqrt(vx*vx+vy*vy); if (lv == 0) return NaN;
    c = (d[0]*vx + d[1]*vy) / lv;
    if (c > 1) c = 1; if (c < -1) c = -1;
    return acos(c) * 180 / PI;
}

function computeSide(s) {
    r = newArray(10);
    // a, b: tu Co / Cor do DOC TRUC DAI (Co-CoA / Cor-CorA) den mp khuyet sigma
    r[0] = axisSigmaMM("Co"+s, "CoA"+s, s);
    r[1] = axisSigmaMM("Cor"+s, "CorA"+s, s);
    r[2] = vertMM("Co"+s, "Go"+s);   // c: chieu cao THANG DUNG Co -> Go (hieu toa do doc)
    r[3] = distMM("Prnc"+s, "Arnc"+s);
    r[4] = distMM("Go"+s, "Me");
    r[5] = perpMM("Snp"+s, "Co"+s, "Cor"+s);
    // g: khoang cach vuong goc tu diem loi xa R7 den mp Z (= thanh phan theo huong sigma)
    //    DUONG khi R7 nam phia truoc mp Z (con cho), AM khi R7 lan qua mp Z ve phia canh len
    u = sigmaDir(s); k = idx("D7"+s); z = idx("Z"+s); me = idx("Me");
    gd = (PX[k]-PX[z])*u[0] + (PY[k]-PY[z])*u[1];
    gf = (PX[me]-PX[z])*u[0] + (PY[me]-PY[z])*u[1];
    if (gf < 0) gd = -gd;
    r[6] = MMPX * gd;
    // h: goc goc ham - nhanh dung (PMC->Ar) voi bo duoi (IMCa->IMCb)
    r[7] = angVec("PMC"+s, "Ar"+s, "IMCa"+s, "IMCb"+s);
    // i, j: truc rang khon (huong chan rang) voi huong ra truoc cua Go-Me / IMCa-IMCb
    a = axisDir(s);
    r[8] = angDirVec(a, "Go"+s, "Me");
    r[9] = angDirVec(a, "IMCa"+s, "IMCb"+s);
    return r;
}

// tham so t de diem p + t*(q-p) nam tren mp khuyet sigma ben s (NaN neu truc song song mp sigma)
function axisT(p, q, s) {
    u = sigmaDir(s); k = idx(p); m = idx(q); sn = idx("Snp"+s);
    nx = -u[1]; ny = u[0];
    dd = (PX[m]-PX[k])*nx + (PY[m]-PY[k])*ny;
    if (abs(dd) < 1e-6) return NaN;
    return ((PX[sn]-PX[k])*nx + (PY[sn]-PY[k])*ny) / dd;
}

// khoang cach tu p, doc theo duong p-q, den mp khuyet sigma ben s
function axisSigmaMM(p, q, s) {
    t = axisT(p, q, s);
    if (isNaN(t)) return NaN;
    k = idx(p); m = idx(q);
    return MMPX * abs(t) * sqrt((PX[m]-PX[k])*(PX[m]-PX[k]) + (PY[m]-PY[k])*(PY[m]-PY[k]));
}

// Go = giao diem duong Ar-PMC va duong IMCa-IMCb (tu tinh, khong keo tay)
function updateGo(s) {
    a = idx("Ar"+s); p = idx("PMC"+s); i = idx("IMCa"+s); j = idx("IMCb"+s); g = idx("Go"+s);
    ux = PX[p]-PX[a]; uy = PY[p]-PY[a];
    vx = PX[j]-PX[i]; vy = PY[j]-PY[i];
    den = ux*vy - uy*vx;
    if (abs(den) < 1e-9) return;
    t = ((PX[i]-PX[a])*vy - (PY[i]-PY[a])*vx) / den;
    PX[g] = PX[a] + t*ux; PY[g] = PY[a] + t*uy;
}

function computeAll() {
    updateGo("_r"); updateGo("_l");
    RES_R = computeSide("_r");
    RES_L = computeSide("_l");
}

function fmt(v, k) {
    if (isNaN(v)) return "-";
    return d2s(v, 3);
}

// =====================================================================
//  VE LEN PHIM
// =====================================================================
function oline(a, b, col, w) {
    i = idx(a); j = idx(b);
    makeLine(PX[i], PY[i], PX[j], PY[j]);
    Overlay.addSelection(col, w);
}

// duong thang keo dai qua a, b (mat phang tham chieu)
function oplane(a, b, col, w, ext) {
    i = idx(a); j = idx(b);
    ux = PX[j]-PX[i]; uy = PY[j]-PY[i];
    L = sqrt(ux*ux+uy*uy); if (L == 0) return;
    ux = ux/L; uy = uy/L;
    makeLine(PX[i]-ux*ext, PY[i]-uy*ext, PX[j]+ux*ext, PY[j]+uy*ext);
    Overlay.addSelection(col, w);
}

// doan vuong goc tu p xuong duong a-b
function operp(p, a, b, col, w) {
    k = idx(p); i = idx(a); j = idx(b);
    ux = PX[j]-PX[i]; uy = PY[j]-PY[i];
    L2 = ux*ux+uy*uy; if (L2 == 0) return;
    t = ((PX[k]-PX[i])*ux + (PY[k]-PY[i])*uy) / L2;
    fx = PX[i] + t*ux; fy = PY[i] + t*uy;
    makeLine(PX[k], PY[k], fx, fy);
    Overlay.addSelection(col, w);
}

function otext(str, x, y, col, size) {
    setFont("SansSerif", size, "bold antialiased");
    makeText(str, x, y);
    Overlay.addSelection(col);
}

function drawSide(s, col) {
    w = getWidth();
    lw = maxOf(2, round(w / 1200));
    ext = w * 0.02;
    // 4 mat phang tham chieu
    oplane("Co"+s, "Cor"+s, col, lw, ext);
    oplane("Ar"+s, "PMC"+s, col, lw, ext);
    oplane("IMCa"+s, "IMCb"+s, col, lw, ext);
    oline("Go"+s, "Me", col, lw);
    oline("PMC"+s, "Go"+s, col, lw);
    oline("IMCa"+s, "Go"+s, col, lw);
    // mp sigma (qua Snp, song song mp Or) va mp Z (qua Z, vuong goc sigma)
    u = sigmaDir(s);
    sn = idx("Snp"+s); z = idx("Z"+s); k = idx("D7"+s);
    // a, b: doan doc truc dai tu Co (qua CoA) va Cor (qua CorA) den mp sigma
    co = idx("Co"+s); ca = idx("CoA"+s); cr = idx("Cor"+s); cra = idx("CorA"+s);
    p1 = 0; p2 = 0;
    t = axisT("Co"+s, "CoA"+s, s);
    if (!isNaN(t)) {
        ix = PX[co] + t*(PX[ca]-PX[co]); iy = PY[co] + t*(PY[ca]-PY[co]);
        makeLine(PX[co], PY[co], ix, iy); Overlay.addSelection("#ffff66", lw);
        p1 = (ix-PX[sn])*u[0] + (iy-PY[sn])*u[1];
    }
    t = axisT("Cor"+s, "CorA"+s, s);
    if (!isNaN(t)) {
        ix = PX[cr] + t*(PX[cra]-PX[cr]); iy = PY[cr] + t*(PY[cra]-PY[cr]);
        makeLine(PX[cr], PY[cr], ix, iy); Overlay.addSelection("#ffff66", lw);
        p2 = (ix-PX[sn])*u[0] + (iy-PY[sn])*u[1];
    }
    // mp sigma keo dai phu ca 2 chan doan a, b
    pmin = minOf(minOf(p1, p2), 0) - w*0.015; pmax = maxOf(maxOf(p1, p2), 0) + w*0.015;
    makeLine(PX[sn]+u[0]*pmin, PY[sn]+u[1]*pmin, PX[sn]+u[0]*pmax, PY[sn]+u[1]*pmax);
    Overlay.addSelection("#ff66ff", lw);
    nx = -u[1]; ny = u[0];
    zc = idx("Cor"+s);
    t1 = (PX[zc]-PX[z])*nx + (PY[zc]-PY[z])*ny;
    t2 = (PX[k]-PX[z])*nx + (PY[k]-PY[z])*ny;
    tmin = minOf(minOf(t1, t2), 0) - w*0.01; tmax = maxOf(maxOf(t1, t2), 0) + w*0.03;
    makeLine(PX[z]+nx*tmin, PY[z]+ny*tmin, PX[z]+nx*tmax, PY[z]+ny*tmax);
    Overlay.addSelection("#ff66ff", lw);
    // doan vuong goc tu D7 den mp Z
    makeLine(PX[k], PY[k], PX[z]+nx*t2, PY[z]+ny*t2);
    Overlay.addSelection("#ffff66", lw);
    // mat nhai rang khon + truc rang (vuong goc mat nhai)
    m = idx("O8m"+s); d = idx("O8d"+s);
    makeLine(PX[m], PY[m], PX[d], PY[d]);
    Overlay.addSelection("#ff9900", lw);
    a = axisDir(s);
    mx = (PX[m]+PX[d])/2; my = (PY[m]+PY[d])/2;
    // keo truc den duong IMCa-IMCb (neu cat), toi da 0.35*chieu cao anh
    ia = idx("IMCa"+s); ib = idx("IMCb"+s);
    ex = PX[ib]-PX[ia]; ey = PY[ib]-PY[ia];
    den = a[0]*ey - a[1]*ex;
    tl = getHeight() * 0.35;
    if (den != 0) { tt = ((PX[ia]-mx)*ey - (PY[ia]-my)*ex) / den; if (tt > 0 && tt < tl) tl = tt + w*0.01; }
    makeLine(mx - a[0]*w*0.015, my - a[1]*w*0.015, mx + a[0]*tl, my + a[1]*tl);
    Overlay.addSelection("#ff9900", lw);
    // cac doan do chieu dai
    thin = maxOf(1, lw - 1);
    // c: duong ngang qua Co + doan thang dung tai Go (chieu cao Co-Go)
    ic = idx("Co"+s); ig = idx("Go"+s);
    //    mau trang dac, net dam (truoc la trang mo, net manh -> ben phai gan nhu khong thay)
    makeLine(PX[ic], PY[ic], PX[ig], PY[ic]); Overlay.addSelection("#ffffff", lw);
    makeLine(PX[ig], PY[ic], PX[ig], PY[ig]); Overlay.addSelection("#ffffff", lw);
    oline("Prnc"+s, "Arnc"+s, "#88ffffff", thin);
    operp("Snp"+s, "Co"+s, "Cor"+s, "#ffff66", thin);
}

function redraw() {
    if (NP == 0) return;
    Overlay.remove;
    w = getWidth(); h = getHeight();
    computeAll();
    colR = "#00e5ff"; colL = "#7CFF4F";
    if (isMeasure()) {
        drawSide("_r", colR);
        drawSide("_l", colL);
        oline("Or_r", "Or_l", "#ffffff", maxOf(2, round(w / 1200)));
    }
    // diem + nhan
    rad = maxOf(5, round(w / 400));
    fs = maxOf(14, round(w / 110));
    for (i = 0; i < NP; i++) {
        col = colR;
        if (endsWith(NAMES[i], "_l")) col = colL;
        if (NAMES[i] == "Me") col = "#ffffff";
        makeOval(PX[i] - rad, PY[i] - rad, 2*rad, 2*rad);
        if (startsWith(NAMES[i], "Go_")) Overlay.addSelection("#ffff00", 2);   // Go tu tinh: vong rong mau vang
        else Overlay.addSelection("#000000", 1, "#ff2020");
        bn = NAMES[i]; if (endsWith(bn, "_r") || endsWith(bn, "_l")) bn = substring(bn, 0, lengthOf(bn) - 2);
        if (indexOf(NOLABEL, "," + bn + ",") < 0) otext(NAMES[i], PX[i] + rad + 2, PY[i] - fs - 2, col, fs);
    }
    // ma benh nhan goc tren trai
    code = Property.get("panorex_code");
    if (code != "") otext(code, w * 0.008, h * 0.008, "#ffff00", maxOf(24, round(w / 45)));
    // nhan hieu chuan
    otext(calibText(), w * 0.40, h * 0.005, "#ffffff", maxOf(12, round(w / 140)));
    run("Select None");
    Overlay.show;
}

// tieu de cua so phim (thanh tieu de, khong ve len phim)
function winTitle(code, path) {
    return "Panorex v" + VERSION + " " + COPYRIGHT + "   |   " + code + " - " + File.getName(path);
}

function isMeasure() {
    m = Property.get("panorex_mode");
    if (m == "meas") return true;
    return false;
}

function toggleMeasure() {
    if (!loadPts()) exit("Bam nut 1 de mo phim va dat diem truoc.");
    if (isMeasure()) {
        Property.set("panorex_mode", "pts");
        redraw();
        if (isOpen(TBL_TITLE)) { selectWindow(TBL_TITLE); run("Close"); }
        showStatus("Da an phep do - chi hien diem tham chieu.");
    } else {
        Property.set("panorex_mode", "meas");
        redraw();
        showTable();
        showStatus("Da hien phep do. Keo diem -> thong so cap nhat ngay.");
    }
}

function showTable() {
    id = getImageID();
    title = TBL_TITLE;
    Table.create(title);
    for (k = 0; k < 10; k++) {
        Table.set("Chi so", k, MLABEL[k]);
        vR = "" + fmt(RES_R[k], k);
        vL = "" + fmt(RES_L[k], k);
        Table.set("Phai (R)", k, vR);
        Table.set("Trai (L)", k, vL);
        Table.set("Don vi", k, MUNIT[k]);
    }
    Table.set("Chi so", 10, "Panorex 16 diem v" + VERSION + "  " + COPYRIGHT);
    Table.set("Phai (R)", 10, ""); Table.set("Trai (L)", 10, ""); Table.set("Don vi", 10, "");
    Table.update;
    if (!TABLE_PLACED) {
        r = call("PanorexDicom.placeRight", title, "560", "330");
        TABLE_PLACED = true;
    }
    selectImage(id);
}

// ve bang so do vao dai phia duoi anh da flatten
function calibText() {
    t = "Hieu chuan: " + d2s(SPACING, 4) + " mm/pixel (DICOM)";
    if (MAG != 1) t = t + " / he so phong dai " + d2s(MAG, 3) + " = " + d2s(MMPX, 5) + " mm/pixel";
    return t;
}

// ghi do phan giai in (dpi) vao JPG: in 100% (Actual size) = dung kich thuoc phim goc (0.077 mm -> 330 dpi)
function setPrintDpi(f) {
    r = call("PanorexDicom.setJpegDpi", f, d2s(25.4 / SPACING, 2));
}

// thanh thuoc 10 mm (goc duoi phai) de kiem tra ti le khi in / do tay
function drawScaleBar() {
    w = getWidth(); h = getHeight();
    L = round(10 / MMPX);
    lw = maxOf(4, round(w / 500));
    fs = maxOf(16, round(w / 110));
    x2 = w - round(w * 0.09); x1 = x2 - L; y = h - round(h * 0.03);
    setColor("#000000"); fillRect(x1 - fs/2, y - fs*2, L + fs, fs*2 + lw*3);
    setColor("#ffffff"); setLineWidth(lw);
    drawLine(x1, y, x2, y); drawLine(x1, y - lw*3, x1, y + lw); drawLine(x2, y - lw*3, x2, y + lw);
    setFont("SansSerif", fs, "bold antialiased");
    drawString("10 mm", x1 + L/2 - getStringWidth("10 mm")/2, y - lw*2);
    setLineWidth(1);
}

function setMagnification() {
    m = parseFloat(call("ij.Prefs.get", PREF + "mag", "1"));
    Dialog.create("He so phong dai");
    Dialog.addMessage("Kich thuoc that (mm) = so pixel x Pixel Spacing / he so phong dai.\n"
      + "Pixel Spacing do may chup ghi trong file DICOM (may HDXWILL: 0.077 mm).\n"
      + "De 1.000 neu Pixel Spacing cua may da hieu chinh phong dai.\n"
      + "Vd: may phong dai 1.25 lan -> nhap 1.25");
    Dialog.addNumber("He so phong dai", m, 3, 8, "lan");
    Dialog.addCheckbox("Ap dung cho phim dang mo", true);
    Dialog.show();
    m = Dialog.getNumber();
    applyNow = Dialog.getCheckbox();
    if (isNaN(m) || m <= 0) exit("He so khong hop le.");
    call("ij.Prefs.set", PREF + "mag", "" + m);
    if (applyNow && loadPts()) {
        MAG = m; MMPX = SPACING / MAG;
        Property.set("panorex_mag", "" + MAG);
        Property.set("panorex_mmpx", "" + MMPX);
        run("Properties...", "unit=mm pixel_width=" + MMPX + " pixel_height=" + MMPX + " voxel_depth=1");
        redraw();
        if (isMeasure()) showTable();
    }
    showStatus("He so phong dai = " + d2s(m, 3));
}

function drawPanel(pcode, psrc) {
    w = getWidth(); h = getHeight();
    fs = maxOf(16, round(w / 110));
    lh = round(fs * 1.35);
    ph = lh * 13 + fs;
    run("Canvas Size...", "width=" + w + " height=" + (h + ph) + " position=Top-Center zero");
    setFont("SansSerif", fs, "bold antialiased");
    x1 = round(w * 0.02); x2 = round(w * 0.45); x3 = round(w * 0.62); x4 = round(w * 0.78);
    setColor("#ffff00");
    drawString(pcode + "   -   " + File.getName(psrc), x1, h + lh);
    h = h + lh;
    y = h + lh;
    setColor("#ffffff");
    drawString("Chi so", x1, y); drawString("Phai (R)", x2, y); drawString("Trai (L)", x3, y); drawString("Don vi", x4, y);
    for (k = 0; k < 10; k++) {
        y = h + lh * (k + 2);
        setColor("#ffffff"); drawString(MLABEL[k], x1, y);
        vR = "" + fmt(RES_R[k], k);
        vL = "" + fmt(RES_L[k], k);
        setColor("#00e5ff"); drawString(vR, x2, y);
        setColor("#7CFF4F"); drawString(vL, x3, y);
        setColor("#ffffff"); drawString(MUNIT[k], x4, y);
    }
    setColor("#aaaaaa");
    drawString(calibText(), x1, h + lh * 12);
    // dong ban quyen mo (chi nam trong dai bang so, khong de len phim)
    setFont("SansSerif", fs, "antialiased");
    setColor("#555555");
    drawString("Panorex 16 diem v" + VERSION + "  " + COPYRIGHT, w - getStringWidth("Panorex 16 diem v" + VERSION + "  " + COPYRIGHT) - x1, h + lh * 12);
}

// =====================================================================
//  DO + XAC NHAN + LUU
// =====================================================================
function outDir(imgPath) {
    d = call("ij.Prefs.get", PREF + "outdir", "");
    if (d == "" && imgPath != "") d = File.getParent(imgPath) + File.separator + "KetQua" + File.separator;
    if (d == "") d = getDirectory("home") + "Panorex_KetQua" + File.separator;
    if (!endsWith(d, File.separator)) d = d + File.separator;
    return d;
}

// ma BN00x tiep theo: chua co file da luu va chua dung cho phim nao dang mo
function nextCode(dir) {
    used = ",";
    cur = getImageID();
    for (i = 1; i <= nImages; i++) {
        selectImage(i);
        if (getImageID() != cur) { c = Property.get("panorex_code"); if (c != "") used = used + c + ","; }
    }
    selectImage(cur);
    n = 1;
    while (File.exists(dir + "BN" + IJ.pad(n, 3) + "_ed.jpg") || indexOf(used, ",BN" + IJ.pad(n, 3) + ",") >= 0) n++;
    return "BN" + IJ.pad(n, 3);
}

function measureAndSave() {
    if (!loadPts()) exit("Bam nut 1 de mo phim va dat diem truoc.");
    Property.set("panorex_mode", "meas");
    redraw();
    src = Property.get("panorex_src");
    dir = outDir(src);
    code0 = Property.get("panorex_code");
    if (code0 == "") code0 = nextCode(dir);

    showTable();

    Dialog.create("Xac nhan thong so");
    Dialog.addMessage("Kiem tra bang 'Thong so Panorex'. Neu chua dung, bam Cancel va keo chinh lai diem.");
    Dialog.addString("Ma benh nhan", code0, 12);
    Dialog.addDirectory("Thu muc luu", dir);
    Dialog.addCheckbox("Luu file DICOM (.dcm)", true);
    Dialog.addCheckbox("Cap nhat vi tri mau (tu hoc)", true);
    Dialog.show();
    code = Dialog.getString();
    dir = Dialog.getString();
    doDcm = Dialog.getCheckbox();
    learn = Dialog.getCheckbox();
    if (!endsWith(dir, File.separator)) dir = dir + File.separator;
    call("ij.Prefs.set", PREF + "outdir", dir);
    File.makeDirectory(dir);
    base = dir + code + "_ed";
    if (code != code0) {
        Property.set("panorex_code", code);
        rename(winTitle(code, src));
        redraw();
    }

    if (File.exists(base + ".jpg")) {
        if (!getBoolean(code + "_ed da ton tai. Ghi de?")) exit;
    }

    orig = getImageID();
    setBatchMode(true);
    selectImage(orig);
    run("Flatten");
    flat = getImageID();
    drawScaleBar();
    saveAs("Jpeg", base + "_phim.jpg");
    setPrintDpi(base + "_phim.jpg");
    drawPanel(code, src);
    saveAs("Jpeg", base + ".jpg");
    setPrintDpi(base + ".jpg");
    if (doDcm) {
        selectImage(flat);
        hdr = src;
        if (!endsWith(toLowerCase(src), ".dcm")) hdr = substring(src, 0, lastIndexOf(src, ".")) + ".dcm";
        r = call("PanorexDicom.writeRGB", hdr, base + ".dcm", d2s(MMPX, 6));
        if (r != "OK") showMessage("Loi luu DICOM", r);
    }
    selectImage(flat); close();
    setBatchMode(false);
    selectImage(orig);

    // file toa do diem (de kiem tra / mo lai)
    s = "Diem,X_px,Y_px,X_mm,Y_mm\n";
    for (i = 0; i < NP; i++)
        s = s + NAMES[i] + "," + d2s(PX[i],2) + "," + d2s(PY[i],2) + "," + d2s(PX[i]*MMPX,3) + "," + d2s(PY[i]*MMPX,3) + "\n";
    File.saveString(s, base + "_diem.csv");

    appendSummary(dir, code);
    if (learn) updateTemplate();
    showMessage("Da luu", "Da luu:\n" + base + ".jpg  (phim + bang so)\n" + base + "_phim.jpg  (chi phim, dung kich thuoc goc)\n" + base + ".dcm\n" + base + "_diem.csv\n\nBang tong hop: " + dir + "TongHop_DoDac.csv");
}

function appendSummary(dir, code) {
    f = dir + "TongHop_DoDac.csv";
    head = "Ma_benh_nhan,File_goc";
    for (k = 0; k < 10; k++) head = head + "," + MSHORT[k] + "_r(" + MUNIT[k] + ")";
    for (k = 0; k < 10; k++) head = head + "," + MSHORT[k] + "_l(" + MUNIT[k] + ")";
    head = head + ",mm_per_pixel,He_so_phong_dai";
    src = Property.get("panorex_src");
    row = code + "_ed," + File.getName(src);
    for (k = 0; k < 10; k++) row = row + "," + fmt(RES_R[k], k);
    for (k = 0; k < 10; k++) row = row + "," + fmt(RES_L[k], k);
    row = row + "," + d2s(MMPX, 5) + "," + d2s(MAG, 3);
    out = head + "\n";
    if (File.exists(f)) {
        lines = split(File.openAsString(f), "\n");
        for (i = 1; i < lines.length; i++)
            if (lines[i] != "" && !startsWith(lines[i], code + "_ed,")) out = out + lines[i] + "\n";
    }
    out = out + row + "\n";
    File.saveString(out, f);
}

function updateTemplate() {
    w = getWidth(); h = getHeight();
    n = parseInt(call("ij.Prefs.get", PREF + "tplN", "0"));
    if (isNaN(n)) n = 0;
    nb = BASE.length;
    old = newArray(2 * nb + 2);
    v = tplValues();
    if (v.length == 2 * nb + 2) {
        for (i = 0; i < v.length; i++) old[i] = parseFloat(v[i]);
    } else {
        for (i = 0; i < nb; i++) { old[2*i] = TPL_X[i]; old[2*i+1] = TPL_Y[i]; }
        old[2*nb] = ME_X; old[2*nb+1] = ME_Y;
        n = 0;
    }
    m = minOf(n, 19) + 1;   // trung binh truot, toi da 20 phim gan nhat
    out = "";
    for (i = 0; i < nb; i++) {
        // gop ca 2 ben (doi xung) vao mau ben phai
        cx = (PX[i] / w + (1 - PX[nb + i] / w)) / 2;
        cy = (PY[i] / h + PY[nb + i] / h) / 2;
        old[2*i]   = old[2*i]   + (cx - old[2*i]) / m;
        old[2*i+1] = old[2*i+1] + (cy - old[2*i+1]) / m;
    }
    old[2*nb]   = old[2*nb]   + (PX[NP-1] / w - old[2*nb]) / m;
    old[2*nb+1] = old[2*nb+1] + (PY[NP-1] / h - old[2*nb+1]) / m;
    for (i = 0; i < old.length; i++) { if (i > 0) out = out + ","; out = out + d2s(old[i], 4); }
    call("ij.Prefs.set", PREF + "tpl", out);
    call("ij.Prefs.set", PREF + "tplN", "" + (n + 1));
}
